// Wyss Apps for Claude: PeopleSoft helpers.
// Runs in the person's own Chrome through Claude in Chrome's JavaScript tool.
// Layers, so later PeopleSoft tasks reuse the first:
//   PS      - generic PeopleSoft layer: the page document (the TargetContent iframe on classic
//             pages opened through /psp/, the top document on fluid pages and /psc/), the
//             processing-indicator wait, set a field like a person would, click a control,
//             page errors, and the coarse session gate PS.state() (ready | harvardkey | duo |
//             not_authorized | timeout | maintenance | unknown).
//   WYSS    - the "Department Budget Earnings" costing page (Beth's page map, 2026-10-27):
//             state (PS.state plus which costing page), probe, readPage, checkBefore, fill,
//             verify, cancel, saved. Nothing here clicks Save; pay rates are never read.
//   TIMEOFF - the fluid "Balances" self-service page: URL, state, read (the absence balances).
//
// Nothing returned here carries a URL with its query string or a host name: Claude in Chrome
// refuses to return those from a page ("Cookie/query string data"), so results carry only
// the path, the title and short text.
//
// Usage from the skill: evaluate this whole file once per tab, then call
//   WYSS.state()                      -> the coarse gate, with page: costing_search | department_budget_earnings | other_peoplesoft
//   WYSS.probe()                      -> what the page looks like (ids found, rows, state)
//   WYSS.readPage()                   -> the costing shown now (inputs or spans), as the readback
//   WYSS.checkBefore(spec)            -> [] when the page's current lines equal spec.current_costing
//   await WYSS.fill(spec)             -> adds the effective-dated row and keys every line; returns the readback
//   await WYSS.recalc()               -> makes PeopleSoft recompute the Distribution Total (tabbing out of the last %), returns the readback
//   WYSS.verify(spec, readback)       -> [] when the readback equals the spec (same rules as the server)
//   WYSS.cancel()                     -> clicks Cancel (rehearsal only; never Save)
//   WYSS.saved(spec)                  -> whether the page shows the row saved

var PS = (function () {
  function sleep(ms) { return new Promise(function (r) { setTimeout(r, ms); }); }

  // The classic page lives in the TargetContent iframe when opened through the portal (/psp/);
  // opened through /psc/ it is the top document. `probeId` is any id that only the page has.
  function doc(probeId) {
    var f = document.getElementById('ptifrmtgtframe') || document.querySelector('iframe[name="TargetContent"]');
    try { if (f && f.contentDocument && (!probeId || f.contentDocument.getElementById(probeId))) return f.contentDocument; } catch (e) {}
    return document;
  }

  // PeopleSoft refreshes the page after most field changes. Wait until the
  // processing indicator is gone and the DOM has been stable for a moment.
  async function idle(d, maxMs, signature) {
    var start = Date.now(), last = null, stableSince = Date.now();
    while (Date.now() - start < (maxMs || 15000)) {
      var wait = d.getElementById('WAIT_win0') || d.getElementById('processing');
      var busy = wait && wait.offsetParent !== null && getComputedStyle(wait).visibility !== 'hidden';
      var sig = (d.body ? d.body.innerHTML.length : 0) + ':' + (signature ? signature() : '');
      if (sig !== last) { last = sig; stableSince = Date.now(); }
      if (!busy && Date.now() - stableSince > 400) return true;
      await sleep(150);
    }
    return false;
  }

  function fire(e, type) { e.dispatchEvent(new Event(type, { bubbles: true })); }
  function valueOf(e) { return (('value' in e && e.tagName !== 'SPAN') ? e.value : e.textContent || '').trim(); }

  // Set one input the way a person would: focus, type, tab out (change + blur), then wait for the refresh.
  async function setField(d, id, value, waitFn) {
    var e = d.getElementById(id);
    if (!e) throw new Error('missing field ' + id);
    if (e.tagName !== 'INPUT' && e.tagName !== 'SELECT') throw new Error(id + ' is not editable (' + e.tagName + ')');
    e.focus();
    e.value = value;
    fire(e, 'input'); fire(e, 'change'); fire(e, 'blur');
    await waitFn();
    var now = valueOf(d.getElementById(id) || e);
    if (e.tagName === 'INPUT' && now !== value) throw new Error(id + ' shows ' + JSON.stringify(now) + ' after setting ' + JSON.stringify(value));
    return now;
  }

  async function click(d, id, waitFn) {
    var e = d.getElementById(id);
    if (!e) throw new Error('missing control ' + id);
    e.click();
    await waitFn();
  }

  function errorsOnPage(d) {
    var out = [];
    var alert = d.querySelector('#alertmsg, .PSERRORTEXT, .ps_error, [id^="win0divPSERROR"]');
    if (alert && alert.textContent.trim()) out.push(alert.textContent.trim().slice(0, 300));
    d.querySelectorAll('.PSERROR, input.PSERROR, .psc_error').forEach(function (x) { out.push((x.id || x.className) + ' flagged'); });
    return out;
  }

  // The coarse session gate, usable on any page (top document and the iframe).
  // `pageReady(d)` says whether the expected PeopleSoft page is present in document d.
  function state(pageReady) {
    var top = document, host = location.host, title = top.title || '';
    var body = (top.body ? top.body.textContent : '').replace(/\s+/g, ' ').slice(0, 6000);
    var path = location.pathname;
    if (/login\.harvard\.edu|key\.harvard\.edu/i.test(host) || (/HarvardKey/i.test(body) && top.querySelector('input[type="password"]'))) return { state: 'harvardkey', path: path };
    if (/duosecurity\.com/i.test(host) || top.querySelector('iframe[src*="duosecurity"], #duo_iframe') || /Verify it.s you|Duo Push|Duo Mobile|Check for a Duo/i.test(body)) return { state: 'duo', path: path };
    if (/not authorized|You are not authorized/i.test(body)) return { state: 'not_authorized', snippet: body.slice(0, 200) };
    if (/session has expired|session expired|session timed out|sign in again|Your session is no longer valid/i.test(body)) return { state: 'timeout', snippet: body.slice(0, 200) };
    var d = doc(), ready = pageReady ? pageReady(d) : null;
    if (!ready && /temporarily unavailable|under maintenance|Service Unavailable|Bad Gateway|Gateway Time-out|cannot be displayed/i.test(title + ' ' + body.slice(0, 800))) return { state: 'maintenance', title: title };
    var inner = (d.body ? d.body.textContent : '').replace(/\s+/g, ' ').slice(0, 6000);
    if (ready) return Object.assign({ state: 'ready' }, ready);
    if (/HarvardKey/i.test(inner) && d.querySelector('input[type="password"]')) return { state: 'harvardkey', path: path, frame: 'TargetContent' };
    if (d.querySelector('form[name="win0"]') || /psp\/psprdaws|psc\/psprdaws/i.test(path)) return { state: 'ready', page: 'other_peoplesoft', title: title, path: path };
    return { state: 'unknown', title: title, path: path, snippet: body.slice(0, 300) };
  }

  // The visible text of the page document, whitespace collapsed (for reading, never for ids).
  function pageText(d) { d = d || doc(); var b = d.body; return (b ? (b.innerText || b.textContent || '') : '').replace(/\s+/g, ' ').trim(); }

  return { doc: doc, idle: idle, setField: setField, click: click, errorsOnPage: errorsOnPage, state: state, valueOf: valueOf, sleep: sleep, pageText: pageText };
})();

var WYSS = (function () {
  var F = 'HU_DEPBUDERN_VW_';
  var SEG = { tub: 'FUND_CODE', org: 'OPERATING_UNIT', fund: 'PROJECT_ID', activity: 'PRODUCT',
              subactivity: 'PROGRAM_CODE', root: 'CLASS_FLD', pct: 'DIST_PCT' };
  var OBJECT = 'ACCOUNT';
  var EFFDT = 'HU_DPTBGT_VW_EFFDT$0', EFFSEQ = 'HU_DPTBGT_VW_EFFSEQ$0', STATUS = 'HU_DPTBGT_VW_EFF_STATUS$0';
  var EMPLID = 'HU_POSINCUM_DRV_EMPLID$0', EMPLRCD = 'HU_POSINCUM_DRV_EMPL_RCD$0';
  var ADD_ROW = '$ICField16$new$0$$0';
  var SAVE = 'HU_DPBUDERN_WRK_SAVE_BTN', CANCEL = 'HU_DPBUDERN_WRK_HOME_BUTTON';

  function doc() { return PS.doc(EMPLID); }
  function el(id) { return doc().getElementById(id); }
  function text(id) { var e = el(id); return e ? PS.valueOf(e) : null; }
  function isInput(id) { var e = el(id); return !!e && (e.tagName === 'INPUT' || e.tagName === 'SELECT' || e.tagName === 'TEXTAREA'); }
  function lineCount() { var n = 0; while (el(F + SEG.pct + '$' + n)) n++; return n; }
  function pad(n) { return (n < 10 ? '0' : '') + n; }
  function toUS(iso) { var m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(iso); return m ? m[2] + '/' + m[3] + '/' + m[1] : iso; }
  function toISO(us) { var m = /^(\d{1,2})\/(\d{1,2})\/(\d{4})$/.exec(us); return m ? m[3] + '-' + pad(+m[1]) + '-' + pad(+m[2]) : us; }
  function pct3(v) { var n = parseFloat(String(v).replace(/[^\d.\-]/g, '')); return isNaN(n) ? '' : n.toFixed(3); }

  function idle(maxMs) { return PS.idle(doc(), maxMs, lineCount); }

  function setField(id, value) { return PS.setField(doc(), id, value, idle); }
  function click(id) { return PS.click(doc(), id, idle); }

  function errorsOnPage() { return PS.errorsOnPage(doc()); }

  function totalShown() {
    var d = doc();
    var lab = Array.prototype.find.call(d.querySelectorAll('span, label, td, div'), function (x) { return /Distribution Total/i.test(x.textContent) && x.children.length < 3; });
    if (!lab) return null;
    var m = /Distribution Total[^\d\-]*([\d.,\-]+)/i.exec(lab.parentElement ? lab.parentElement.textContent : lab.textContent);
    return m ? pct3(m[1]) : null;
  }

  function readLines() {
    var lines = [], n = lineCount();
    for (var i = 0; i < n; i++) {
      var seg = {};
      Object.keys(SEG).forEach(function (k) { seg[k] = text(F + SEG[k] + '$' + i); });
      seg.object = text(F + OBJECT + '$' + i);
      lines.push({ coa: [seg.tub, seg.org, seg.object, seg.fund, seg.activity, seg.subactivity, seg.root].join('.'), pct: pct3(seg.pct), editable: isInput(F + SEG.pct + '$' + i) });
    }
    return lines;
  }

  // The readback. `total` is what the page shows as Distribution Total when that label is
  // found, else the sum of the lines; `total_shown` and `lines_sum` carry both so a stale
  // display (PeopleSoft recomputes the total on its own field-change round trip, which a
  // scripted value change does not always trigger) is visible instead of hidden.
  function readPage() {
    var lines = readLines();
    var sum = lines.reduce(function (a, l) { return a + (parseFloat(l.pct) || 0); }, 0).toFixed(3);
    var shown = totalShown();
    return {
      empl_id: text(EMPLID), empl_rcd: parseInt(text(EMPLRCD), 10),
      effective_date: toISO(text(EFFDT)), eff_seq: parseInt(text(EFFSEQ) || '0', 10), status: text(STATUS),
      distributions: lines.map(function (l) { return { coa: l.coa, pct: l.pct }; }),
      total: shown || sum, total_shown: shown, lines_sum: sum,
      editable: lines.length > 0 && lines.every(function (l) { return l.editable; }),
      errors: errorsOnPage()
    };
  }

  // The coarse gate plus which costing page this is.
  function costingPage(d) {
    if (d.getElementById(EMPLID) || d.getElementById(EFFDT)) return { page: 'department_budget_earnings', employee: text(EMPLID) };
    var inner = (d.body ? d.body.textContent : '').replace(/\s+/g, ' ').slice(0, 6000);
    if (/Manage Costing|Costing Summary|Include Inactive Employees|Costing Search/i.test(inner) || d.querySelector('[id^="HU_COSTING_SRCH"], [id*="HU_COSTING_SEARCH"]')) return { page: 'costing_search' };
    return null;
  }
  function state() { return PS.state(costingPage); }

  function probe() {
    var d = doc();
    var ids = {};
    [EFFDT, EFFSEQ, STATUS, EMPLID, EMPLRCD, ADD_ROW, SAVE, CANCEL, F + SEG.pct + '$0', F + OBJECT + '$0'].forEach(function (id) { var e = el(id); ids[id] = e ? e.tagName + (isInput(id) ? ' (input)' : '') : null; });
    var rowButtons = Array.prototype.map.call(d.querySelectorAll('[id*="$new$"], [id*="$delete$"]'), function (e) { return e.id; });
    return { frame: d === document ? 'top' : 'TargetContent', path: (d.location || {}).pathname, signIn: /HarvardKey|login|Sign In/i.test(d.title + ' ' + (d.body ? d.body.textContent.slice(0, 2000) : '')),
             ids: ids, lineCount: lineCount(), rowButtons: rowButtons.slice(0, 20), page: readPage() };
  }

  function sortedLines(list) { return (list || []).map(function (l) { return l.coa.trim() + '|' + pct3(l.pct); }).sort(); }

  function checkBefore(spec) {
    var out = [], page = readPage();
    if (page.empl_id !== String(spec.empl_id)) out.push('empl_id: page ' + page.empl_id + ', spec ' + spec.empl_id);
    if (spec.empl_rcd !== undefined && page.empl_rcd !== parseInt(spec.empl_rcd, 10)) out.push('empl_rcd: page ' + page.empl_rcd + ', spec ' + spec.empl_rcd);
    var want = sortedLines((spec.current_costing || {}).lines), have = sortedLines(page.distributions);
    if (JSON.stringify(want) !== JSON.stringify(have)) out.push('current lines: page ' + JSON.stringify(have) + ', spec ' + JSON.stringify(want));
    if (page.editable) out.push('the page already has an unsaved editable row (someone started it); do not add another');
    return out;
  }

  function verify(spec, rb) {
    var out = [];
    if (String(rb.empl_id) !== String(spec.empl_id)) out.push('empl_id');
    if (rb.effective_date !== spec.effective_date) out.push('effective_date: page ' + rb.effective_date + ', spec ' + spec.effective_date);
    if (Math.abs(parseFloat(rb.lines_sum !== undefined ? rb.lines_sum : rb.total) - 100) > 0.001) out.push('lines sum to ' + (rb.lines_sum || rb.total) + ', not 100.000');
    if (rb.total_shown && Math.abs(parseFloat(rb.total_shown) - 100) > 0.001) out.push('Distribution Total shows ' + rb.total_shown + ' (lines sum to ' + rb.lines_sum + '): the page has not recalculated; run WYSS.recalc(), or click the last percentage field and press Tab, then read again');
    var want = sortedLines(spec.distributions), have = sortedLines(rb.distributions);
    if (JSON.stringify(want) !== JSON.stringify(have)) out.push('distributions: page ' + JSON.stringify(have) + ', spec ' + JSON.stringify(want));
    if (rb.errors && rb.errors.length) out.push('page errors: ' + rb.errors.join('; '));
    return out;
  }

  // Row controls at the end of each line: the "+" inserts a line below, the "−" deletes it.
  function lineButton(kind, i) {
    var d = doc();
    var cands = Array.prototype.filter.call(d.querySelectorAll('[id*="$' + kind + '$"]'), function (e) { return e.id !== ADD_ROW && new RegExp('\\$' + kind + '\\$' + i + '\\$').test(e.id); });
    return cands[0] || null;
  }

  async function setLine(i, d) {
    var order = ['tub', 'org', 'fund', 'activity', 'subactivity', 'root', 'pct'];
    for (var k = 0; k < order.length; k++) {
      var key = order[k], id = F + SEG[key] + '$' + i;
      var value = key === 'pct' ? pct3(d.pct) : String(d[key]);
      if (text(id) === value) continue;
      await setField(id, value);
    }
  }

  // Add the effective-dated row and make the lines equal the spec. Returns the readback.
  async function fill(spec) {
    if (spec.version !== 2) throw new Error('fill spec version ' + spec.version + ' not supported');
    var before = checkBefore(spec);
    if (before.length) throw new Error('before check failed: ' + before.join('; '));
    await click(ADD_ROW);
    if (!isInput(EFFDT)) throw new Error('no editable Effective Date after "+"');
    await setField(EFFDT, toUS(spec.effective_date));
    var want = spec.distributions;
    // Shrink or grow the grid to the right number of lines first.
    while (lineCount() > want.length) {
      var minus = lineButton('delete', lineCount() - 1);
      if (!minus) throw new Error('cannot find the delete control on line ' + (lineCount() - 1));
      minus.click(); await idle();
    }
    while (lineCount() < want.length) {
      var plus = lineButton('new', lineCount() - 1);
      if (!plus) throw new Error('cannot find the add-line control on line ' + (lineCount() - 1));
      plus.click(); await idle();
    }
    for (var i = 0; i < want.length; i++) await setLine(i, want[i]);
    await idle(5000);
    var rb = readPage();
    if (rb.total_shown && Math.abs(parseFloat(rb.total_shown) - 100) > 0.001) rb = await recalc();
    var problems = verify(spec, rb);
    if (problems.length) throw new Error('filled page does not match: ' + problems.join('; '));
    return rb;
  }

  // Make PeopleSoft recompute the Distribution Total: run the page's own field-change
  // submit on the last percentage field (what tabbing out of it does), wait, read back.
  // Harmless when the total is already current. Returns the readback.
  async function recalc() {
    var n = lineCount();
    if (!n) return readPage();
    var id = F + SEG.pct + '$' + (n - 1), d = doc(), e = d.getElementById(id), w = d.defaultView || window;
    if (e && e.tagName === 'INPUT') {
      e.focus();
      try {
        if (typeof w.addchg_win0 === 'function') w.addchg_win0(e);
        if (typeof w.submitAction_win0 === 'function' && e.form) w.submitAction_win0(e.form, e.id);
        else { fireOn(e, 'change'); fireOn(e, 'blur'); }
      } catch (err) { fireOn(e, 'change'); fireOn(e, 'blur'); }
      await idle(8000);
    }
    return readPage();
  }
  function fireOn(e, type) { e.dispatchEvent(new Event(type, { bubbles: true })); }

  async function cancel() { await click(CANCEL); return readPage(); }

  // After the person clicks Save. PeopleSoft keeps the row editable in update
  // mode, so "editable" alone proves nothing: the SAVED_win0 flash is the
  // strong signal; without it, reopen the direct URL and read the top row.
  function saved(spec) {
    var page = readPage();
    var flag = el('SAVED_win0');
    var banner = !!flag && flag.offsetParent !== null;
    var matches = page.effective_date === spec.effective_date && verify(spec, page).length === 0;
    return { saved: matches && banner, matches: matches, banner: banner, editable: page.editable, page: page };
  }

  return { state: state, probe: probe, readPage: readPage, checkBefore: checkBefore, fill: fill, verify: verify, recalc: recalc, cancel: cancel, saved: saved, ids: { SAVE: SAVE, CANCEL: CANCEL, ADD_ROW: ADD_ROW } };
})();

// The fluid "Balances" page (Absence Balances self-service), as seen 2026-10-28: one block per
// absence type, "Vacation Balance As Of 10/24/2026 41.76 Hours 5.97 Days Max Vacation 280.00
// Hours 40.00 Days", Sick the same, Personal with "Award Date" and "Expiration Date" instead
// of a maximum. Served from /psc/ with no iframe, so PS.doc() is the top document.
var TIMEOFF = (function () {
  var URL = 'https://peoplesoft.hrapps.harvard.edu/psc/psprdaws/EMPLOYEE/HRMS/c/HGA_EMPLOYEE_FL.HGA_SS_BAL_FLU.GBL?pts_Portal=EMPLOYEE&pts_PortalHostNode=HRMS&pts_Market=GBL';
  var HOME = 'https://peoplesoft.hrapps.harvard.edu/psp/psprdaws/EMPLOYEE/HRMS/h/?tab=DEFAULT';
  var TYPE = '((?:Floating Holiday|Comp(?:ensatory)? Time|[A-Z][a-z]+))';

  function balancesPage() { return /Balance As Of \d{1,2}\/\d{1,2}\/\d{4}/.test(PS.pageText()) ? { page: 'absence_balances' } : null; }
  function state() { return PS.state(balancesPage); }
  function num(v) { var n = parseFloat(String(v).replace(/,/g, '')); return isNaN(n) ? null : n; }

  function read() {
    var t = PS.pageText(), out = [], m;
    var re = new RegExp(TYPE + ' Balance As Of (\\d{1,2}\\/\\d{1,2}\\/\\d{4}) ([\\d.,]+) Hours ([\\d.,]+) Days(.*?)(?=' + TYPE + ' Balance As Of|Forecast Balance|$)', 'g');
    while ((m = re.exec(t))) {
      var b = { type: m[1], as_of: m[2], hours: num(m[3]), days: num(m[4]) }, rest = m[5] || '';
      var max = /Max [A-Za-z ]*?([\d.,]+) Hours ([\d.,]+) Days/.exec(rest);
      if (max) { b.max_hours = num(max[1]); b.max_days = num(max[2]); }
      var award = /Award Date (\d{1,2}\/\d{1,2}\/\d{4})/.exec(rest); if (award) b.award_date = award[1];
      var exp = /Expiration Date (\d{1,2}\/\d{1,2}\/\d{4})/.exec(rest); if (exp) b.expiration_date = exp[1];
      out.push(b);
    }
    var notice = /The current balance does not reflect[^.]*\./.exec(t);
    return { page: out.length ? 'absence_balances' : null, as_of: out.length ? out[0].as_of : null, balances: out, notice: notice ? notice[0] : null, title: document.title };
  }

  return { URL: URL, HOME: HOME, state: state, read: read };
})();
'ok';

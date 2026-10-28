---
name: wyss-costing-changes
description: Do the payroll costing changes - "run the costing changes", "do the costing changes", "key the costing queue", "rehearse the costing changes", "what costing changes are waiting", "did Rebecca's change go in". Keys every pending change into PeopleSoft in the person's own Chrome (Claude in Chrome) with a scripted fill, stops at Save for them, then files the backup itself and tidies the tabs. The person signs in and clicks Save; nothing else. Use for anything about costing changes, re-costing someone's payroll, the PeopleSoft entry queue, or Beth's queue.
---

# Costing changes

The person's job is to click **Save** in PeopleSoft. Everything else is Claude's: finding the
work, opening the pages, keying the rows, checking them, recording what happened, filing the
backup and closing the tabs. The person does not know or care how Wyss Apps tracks a request, so
never show them its machinery: no tool names, no statuses ("claimed", "staged", "ready", "needs
review", "backup filed"), no ids unless they ask. Speak in work words: *waiting to be keyed*,
*filled in PeopleSoft, waiting for your Save*, *saved*, *done and filed*, *skipped because …*.

## Before anything (silent when it passes)

1. `whoami`. If it fails, repeat its one-sentence fix (missing token, expired token, not on the
   VPN, no access) and stop. If the Wyss Apps tools are missing altogether: "The Wyss Apps
   plugin is not enabled for this chat. In Cowork: Customize, Plugins, add
   https://github.com/Wyss/wyss-apps-claude." If `tools` lacks Costing Changes: "Your account
   does not have costing changes yet; ask Matthew Laubach." Stop.
2. Claude in Chrome. PeopleSoft runs in the person's **own Chrome**, signed in with HarvardKey
   and Duo; Cowork's built-in browser cannot complete Duo. If the Claude in Chrome tools (tabs,
   navigate, read page, screenshot, JavaScript) are not among your tools: "Install Claude in
   Chrome from the Chrome Web Store, sign in to it, and turn it on for this chat. Then say run
   again." If the tools are there but no tab can be opened (Chrome is not running): "Open
   Chrome, then say go." Stop.
3. Both pass: say nothing about setup. Start the work.

Never type a password. Never click Save (`HU_DPBUDERN_WRK_SAVE_BTN`). Never read the pay rates
shown on the page into anything.

## "Run" (the default, also what the hourly scheduled task says)

"Run the costing changes", "do the costing changes", "go", or anything that means key the queue.
No summary first, no menu, no previews, no questions except the two hand-overs. The word run is
the go-ahead for every recording step; call every write with `confirm: true`. On a scheduled
run with nothing to do, answer with one line, "Nothing waiting.", and stop.

### Gather the work

`list_costing_changes` with `status: ["claimed", "staged", "ready"]`; `whoami` gives the
person's email for `claimed_by`. In this order:

- **Theirs, already filled** (`staged`, `claimed_by` them): from an earlier run. Find its
  PeopleSoft tab. Still open and `WYSS.readPage()` shows the unsaved row: straight into the
  Save list. `WYSS.saved(spec).saved` is true, or they say it is saved: After Save, below. Tab
  gone, or at the sign-in page: the unsaved row is lost; `report_costing_change_error`
  ("filled page lost before Save") then `review_costing_change` `mark_ready`, and key it again.
- **Theirs, started** (`claimed`, `claimed_by` them): key it now (claiming again renews).
- Someone else's: leave alone; mention at the end.
- **Waiting** (`ready`): oldest first.

If `payroll_blackout` is set: "Payroll blackout until <date>: nothing is keyed today." Never
answer "nothing to do" while the person has unfinished work of their own.

### Key each request

1. `claim_costing_change` (`confirm: true`), then `get_costing_change` for `ps_fill_spec`
   (`spec`). Refused because someone else holds it: skip, mention at the end.
2. Open one PeopleSoft tab per request by direct URL, no menus (reuse the kept tab for the
   first one):
   ```
   https://peoplesoft.hrapps.harvard.edu/psp/psprdaws/EMPLOYEE/HRMS/c/HU_CUSTOM_CACTG.HU_DPTBGT_ERN.GBL?Page=HU_DPTBGT_ERN&Action=U&ForceSearch=Y&BUDGET_LEVEL_INDC=<spec.budget_level>&DEPTID=<spec.deptid>&EMPL_RCD=<spec.empl_rcd>&FISCAL_YEAR=<spec.fiscal_year>&POSITION_NBR=<spec.position_no>
   ```
   **Hand-over one:** the tab shows the HarvardKey sign-in (PeopleSoft times out after 20 to
   30 minutes idle, so expect this on most runs). Say "Sign in to PeopleSoft in that tab
   (HarvardKey and Duo), then say go." Wait, then reopen the same URL. `spec.budget_level` `A`
   (no position number) is not automated: `report_costing_change_error` ("appointment-level
   costing, not automated yet"), skip, mention at the end as "needs keying by hand".
3. **Load the script.** Read `peoplesoft.js` from this skill's folder and evaluate the whole
   file in the tab with the JavaScript tool (once per tab; it defines `WYSS`). Then
   `WYSS.probe()`: if `signIn` is true, hand-over one; if `ids` shows the employee or
   effective-date fields missing, the page is not the costing page: `report_costing_change_error`
   with the probe, skip.
4. **Check the before.** `WYSS.checkBefore(spec)` must return `[]` (the page's current lines
   equal `spec.current_costing.lines` and the employee matches). Otherwise
   `report_costing_change_error` with the list, skip, mention at the end as "skipped:
   PeopleSoft already shows different costing; flagged for Matthew".
5. **Fill by script.** `await WYSS.fill(spec)`: it clicks the "+" beside Effective Date, sets
   the date, makes the lines equal `spec.distributions` (adding or deleting lines), waits for
   each PeopleSoft refresh, and returns the readback only when `WYSS.verify(spec, readback)` is
   empty. If it throws, record the reason without bothering the person
   (`rehearse_costing_change` with `outcome: "failed"`, the error as `note`, and whatever
   `WYSS.readPage()` returns) and **fall back to keying by hand** (next step).
6. **Keying by hand** (fallback only). The page is a classic PeopleSoft page inside the
   `TargetContent` iframe. Click the "+" beside Effective Date (`$ICField16$new$0$$0`); set
   `HU_DPTBGT_VW_EFFDT$0` to `spec.effective_date` as MM/DD/YYYY and tab out. Make the lines
   equal `spec.distributions` ("+" at the end of a line inserts below, "−" deletes): line `n`
   has `tub` in `HU_DEPBUDERN_VW_FUND_CODE$n`, `org` in `HU_DEPBUDERN_VW_OPERATING_UNIT$n`,
   `fund` in `HU_DEPBUDERN_VW_PROJECT_ID$n`, `activity` in `HU_DEPBUDERN_VW_PRODUCT$n`,
   `subactivity` in `HU_DEPBUDERN_VW_PROGRAM_CODE$n`, `root` in `HU_DEPBUDERN_VW_CLASS_FLD$n`,
   `pct` (three decimals) in `HU_DEPBUDERN_VW_DIST_PCT$n`, tabbing out after each. Never type
   the object code (`HU_DEPBUDERN_VW_ACCOUNT$n`, derived); leave Earnings Code blank. Wait until
   "Distribution Total" reads 100.000 with no error text, then `WYSS.readPage()` for the
   readback and check `WYSS.verify(spec, readback)` is empty. An error that a retry does not
   clear: `report_costing_change_error` with the message, skip, mention at the end.
7. **Record it as filled.** `mark_costing_change_staged` with the readback (`empl_id`,
   `empl_rcd`, `effective_date`, `distributions`, `total`), `confirm: true`. Keep the result's
   `backup_upload_url` for After Save. A mismatch means the page and the request disagree:
   leave the tab, skip, mention at the end as "flagged for review".

### Hand-over two: Save

When every request is filled or skipped, one message and nothing else:

> Filled in PeopleSoft, waiting for your Save:
> 1. Andyna Vernet, effective 10/25/2026, 5 lines, total 100.000 (tab 2)
> 2. Rebecca Perelman, effective 11/01/2026, 2 lines, total 100.000 (tab 3)
> Click Save on each tab, then say done.

Then wait. A change they ask for is made on the page and recorded again (step 7).

### After Save (all Claude)

When they say done (or name the ones they saved), for each tab:

1. **Confirm the save.** `WYSS.saved(spec)`: `saved` true means the Saved flash is showing and
   the row matches. If `banner` is false, reopen the direct URL in that tab, load the script
   again and check `WYSS.readPage()` shows the top row with the spec's date and lines; if it
   still shows the unsaved edit instead, say which one still needs Save and wait.
2. **File the backup yourself.** Scroll the saved page so the Effective Date, the lines and
   the Distribution Total are in view and take a screenshot. Open `backup_upload_url` (from
   step 7, or `get_costing_change`) in a new tab: it needs no sign-in. `find` the file input
   `#backup-file`, `upload_image` the screenshot to it with filename
   `LastName_FirstName_YYYY-MM-DD.png` (the effective date), click `#attach-backup`, and check
   the page shows `#backup-filed`. That records the save and closes the request in one step;
   the confirmation email goes out by itself. If the page shows `#backup-link-expired`, call
   `get_costing_change` for a fresh `backup_upload_url`. If the upload fails twice, ask for a
   PDF ("Press Ctrl+P on that tab, Save as PDF to Downloads, say done") and attach that file
   with `file_upload` on the same page.
3. **Tidy the tabs.** Close the backup tab and every PeopleSoft tab whose request is done,
   except one: leave one PeopleSoft tab open on the Costing search page
   (`https://peoplesoft.hrapps.harvard.edu/psp/psprdaws/EMPLOYEE/HRMS/c/HU_CUSTOM_POS.HU_COSTING_SEARCH.GBL`)
   so the next run, and the next change that arrives, has somewhere to start. Never close a
   tab whose row is unsaved.
4. **Report**, in work words, then stop:

> Done: 2 costing changes saved in PeopleSoft and filed (Andyna Vernet, Rebecca Perelman).
> Skipped: none.

## "Rehearse" (dry run, nothing saved)

"Rehearse the costing changes", or the first run on a new computer: prove the script on real
requests without touching payroll. For each waiting request (no claim): open the page, load
the script, `WYSS.probe()`, `WYSS.checkBefore(spec)`, `await WYSS.fill(spec)`, then
`WYSS.cancel()` (the Cancel button, never Save) and `rehearse_costing_change` with the readback,
`outcome: "cancelled"` (or `"failed"` with the error as `note`, after `WYSS.cancel()` all the
same). Report one line per request: "rehearsed, matched" or "rehearsed, mismatch: …" or
"script failed at …: …", and include the probe of the first page for Matthew. Nothing changes
in PeopleSoft or in Wyss Apps beyond the rehearsal notes.

## Questions (no run)

Answer in work words, never statuses.

- "What's waiting?" → `list_costing_changes` `status: ["ready","claimed","staged"]`: "3 are
  waiting to be keyed (names, effective dates); 1 is filled and waiting for your Save." Mention
  a blackout.
- "Why is Rebecca's stuck?" → `search: "Rebecca"`, `get_costing_change`; translate `errors`,
  `warnings`, `review_note` and the last `history` entry into one plain sentence.
- "Did HUID 81657165 go in?" → search by HUID: `submitted`/`backup_filed` means "yes, saved on
  <date>" (`confirmed_in_peoplesoft_at` adds "and PeopleSoft confirmed it overnight"); `staged`
  means "filled, not yet saved"; anything earlier means "not yet keyed".
- Reviewers only, when they ask: `review_costing_change` (`mark_ready`, `send_back` with a note,
  `cancel` with a note); preview, then confirm on their yes.

## Claude's bookkeeping (never shown to the person)

| Tool | When |
|---|---|
| `list_costing_changes` | gather work; `status` list, `search`, `counts_by_status`, `payroll_blackout` |
| `get_costing_change` | `ps_fill_spec`, `current_costing`, `url`, `backup_upload_url`, `history`, `errors`, `warnings` |
| `claim_costing_change` | before keying (2-hour lock, renewable) |
| `mark_costing_change_staged` | page filled; readback checked against the spec; returns `backup_upload_url` |
| `mark_costing_change_submitted` | optional after Save (the backup upload records the save by itself) |
| `rehearse_costing_change` | a dry run's readback, or a script failure, as a note; status unchanged |
| `report_costing_change_error` | anything that stops a request; flags it for review |
| `review_costing_change` | `mark_ready` to re-queue a lost one; reviewer decisions |
| `file_costing_change_backup` | only for a backup that must live somewhere other than the request |

Statuses: new → validated → ready → claimed → staged → submitted → backup_filed; side exits
needs_review, error, cancelled. `ps_fill_spec` (version 2) is the whole of what gets keyed:
`budget_level`, `deptid`, `empl_rcd`, `fiscal_year`, `position_no` build the URL;
`effective_date` is ISO (typed MM/DD/YYYY); `distributions[]` carries `tub`, `org`, `fund`,
`activity`, `subactivity`, `root`, `pct` (`object` is readback only); `current_costing.lines` is
the before. `peoplesoft.js` (this folder) is the script: `probe`, `readPage`, `checkBefore`,
`fill`, `verify`, `cancel`, `saved`. Nothing here writes to PeopleSoft.

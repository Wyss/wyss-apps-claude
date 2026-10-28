---
name: wyss-timeoff
description: Check the person's time off - "check my time off", "how much vacation do I have", "what are my absence balances", "how many sick days do I have left". Opens PeopleSoft in the person's own Chrome (Claude in Chrome), asks them to sign in only if the page asks, finds their absence balances and reports them in the chat. Also the quick test that PeopleSoft in the signed-in browser works for this person. Use for any question about someone's own vacation, sick, personal or other leave balance.
---

# Time off

The person asks how much time off they have and gets the numbers. They do not need to know
that Claude is driving their Chrome or where in PeopleSoft the page lives. The only thing they
may be asked to do is sign in (HarvardKey and Duo) when PeopleSoft asks for it.

This is also the smallest test of the pattern every PeopleSoft skill uses: open PeopleSoft in
the person's own browser, gate on `PS.state()`, nudge for sign-in once, navigate, read, report.
Anyone can run it, with or without costing access.

## Before anything (silent when it passes)

1. Claude in Chrome. If its tools (tabs, navigate, read page, JavaScript) are not among your
   tools: "Install Claude in Chrome from the Chrome Web Store, sign in to it, and turn it on
   for this chat. Then ask again." Stop. If the tools exist but no tab can be opened: "Open
   Chrome, then ask again." Stop.
2. Nothing else. No Wyss Apps call is needed for this; the balances come from PeopleSoft and
   are never written anywhere.

## Do it

1. **Open PeopleSoft** in a new tab:
   `https://peoplesoft.hrapps.harvard.edu/psp/psprdaws/EMPLOYEE/HRMS/h/?tab=DEFAULT`
2. **Gate.** Read `lib/peoplesoft.js` from the plugin root (`${CLAUDE_PLUGIN_ROOT}/lib/peoplesoft.js`),
   evaluate the whole file in the tab, then `PS.state()`:
   - `harvardkey` or `duo`: one line, "Sign in to PeopleSoft in that tab (HarvardKey and Duo),
     then say go." Wait, then open the same URL again and re-check. Never type a password.
   - `timeout`: open the URL again once (the HarvardKey session often re-signs in silently),
     then as above.
   - `maintenance` or `unknown`: "PeopleSoft is not responding right now (<what the page
     shows>); try later." Stop.
   - `ready`: continue.
3. **Find the balances page.** Try, in order, until a page shows balances:
   - the direct self-service URL, if it is known for this person (keep it once it worked:
     `https://peoplesoft.hrapps.harvard.edu/psp/psprdaws/EMPLOYEE/HRMS/c/ROLE_EMPLOYEE.HR_ABS_BALANCES.GBL`
     is the first guess; a 404 or "not authorized" just means try the next);
   - the homepage tile or menu entry named "Time Off", "Absence Balances", "My Time" or
     "Absence"; open it and look for "Balances";
   - the search box on the homepage ("Search in Menu") with "absence balances", then
     "time off"; open the first result that mentions balances.
   After each navigation, `PS.state()` again: a sign-in page mid-way is the nudge above.
4. **Read.** Take the page's text (the `TargetContent` iframe holds it on classic pages;
   `PS.doc()` returns the right document). The balances are a table of absence types
   (Vacation, Sick, Personal, Floating Holiday, Compensatory...) with a balance and a unit
   (hours or days) and usually an "as of" date. Read exactly what the page shows; do not
   convert hours to days or add anything up unless the page does.
5. **Report**, then stop:

> Time off as of 10/15/2026: Vacation 112.5 hours, Sick 240 hours, Personal 16 hours.

   One line per balance type the page shows, the "as of" date first, nothing else. If the
   page shows accrual rates or carry-over limits and the person asked, add them as a second
   short line.
6. **Tidy.** Leave the PeopleSoft tab open on the balances page (the person may want to look)
   and say nothing about it.

## When it does not work

Say what happened in one line, in the person's words, and stop:

- No balances page could be found after the three tries: "I could not find the absence
  balances page in your PeopleSoft; tell me where you usually see it and I will use that."
- `not_authorized` on every candidate page: "Your PeopleSoft account does not show absence
  balances to me; HR Systems can confirm the self-service access."
- The sign-in never completes after two nudges: "PeopleSoft did not finish the sign-in;
  try again when you are signed in."

For Matthew, as the tester: when it fails, add `PS.state()` and the page title and URL of the
last page to the line so the pattern can be fixed. For anyone else, the one line is enough.

## Never

Never type a password, never complete Duo, never change anything on a PeopleSoft page, never
read pay or compensation figures that may appear nearby into the answer.

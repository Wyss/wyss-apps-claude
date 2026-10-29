---
name: wyss-timeoff
description: Check the person's time off - "check my time off", "how much vacation do I have", "what are my absence balances", "how many sick days do I have left", "when does my personal day expire". Opens PeopleSoft in the person's own Chrome (Claude in Chrome), asks them to sign in only if the page asks, opens their absence balances and reports them in the chat. Also the quick test that PeopleSoft in the signed-in browser works for this person. Use for any question about someone's own vacation, sick, personal or other leave balance.
---

# Time off

The person asks how much time off they have and gets the numbers. They do not need to know
that Claude is driving their Chrome or where in PeopleSoft the page lives. The only thing they
may be asked to do is sign in (HarvardKey and Duo) when PeopleSoft asks for it.

This is also the smallest test of the pattern every PeopleSoft skill uses: open PeopleSoft in
the person's own browser, gate on the page state, nudge for sign-in once, navigate, read,
report. Anyone can run it, with or without costing access.

## Before anything (silent when it passes)

1. Claude in Chrome. If its tools (tabs, navigate, find, JavaScript) are not among your tools:
   "Install Claude in Chrome from the Chrome Web Store, sign in to it, and turn it on for this
   chat. Then ask again." Stop. If the tools exist but `tabs_context_mcp` fails: "Open Chrome,
   then ask again." Stop.
2. Nothing else. No Wyss Apps call is needed; the balances come from PeopleSoft and are never
   written anywhere.

## Do it

1. **Open the balances page** in a new tab of this conversation:
   `https://peoplesoft.hrapps.harvard.edu/psc/psprdaws/EMPLOYEE/HRMS/c/HGA_EMPLOYEE_FL.HGA_SS_BAL_FLU.GBL?pts_Portal=EMPLOYEE&pts_PortalHostNode=HRMS&pts_Market=GBL`
   Wait about five seconds.
2. **Gate.** Read `lib/peoplesoft.js` from the plugin root (`${CLAUDE_PLUGIN_ROOT}/lib/peoplesoft.js`),
   evaluate the whole file in the tab, then `TIMEOFF.state()`. Its results never carry a URL
   or a host (Claude in Chrome refuses to return those), only `state`, `page`, `path`, `title`.
   - `harvardkey` or `duo`: one line, "Sign in to PeopleSoft in that tab (HarvardKey and Duo),
     then say go." Wait, then open the same URL again, load the script again and re-check.
     Never type a password, never touch Duo.
   - `timeout`: open the URL again once (the HarvardKey session often re-signs in silently),
     then as above.
   - `maintenance`: "PeopleSoft is unavailable right now; try later." Stop.
   - `ready` with `page: "absence_balances"`: go to step 4.
   - `ready` with any other page, or `not_authorized`, or `unknown`: the direct link is not
     available to this person; that is normal, go to step 3. It is not a failure.
3. **Find it through the menu.** Open `TIMEOFF.HOME`
   (`https://peoplesoft.hrapps.harvard.edu/psp/psprdaws/EMPLOYEE/HRMS/h/?tab=DEFAULT`) in the
   same tab. The homepage is usually empty apart from "Personalize Content"; do not look for
   tiles. `find` the "Search in Menu" box in the header, click it, type `absence balances` and
   press Enter. The results page lists "Balances" and "Absence Balances" ("View your absence
   balance detail"): click **Absence Balances**. Wait, load the script again, `TIMEOFF.state()`
   must now be `ready` with `page: "absence_balances"`; a sign-in page here is the nudge above.
4. **Read.** `TIMEOFF.read()`: `as_of`, one entry per absence type with `hours`, `days`, and
   where the page shows them `max_hours`, `max_days`, `award_date`, `expiration_date`, plus the
   page's own notice. The page is fluid (no iframe); the script reads the top document. If
   `balances` is empty, `get_page_text` and read the balances from the text yourself: each
   type has "Balance As Of <date>", an amount in hours and in days, and for vacation and sick a
   maximum, for personal an award and expiration date. Never convert or add anything up; quote
   the page.
5. **Report**, then stop:

> Time off as of 10/24/2026: Vacation 41.76 hours (5.97 days; max 280), Sick 603.50 hours
> (86.21 days; max 910), Personal 7.00 hours (1.00 day; expires 12/31/2026). Requests not yet
> processed are not counted.

   One sentence, the "as of" date first, every type the page shows, hours then days, the
   maximum or expiry in brackets. Nothing else, unless the person asked about accrual or the
   forecast (then one more line from the page).
6. **Tidy.** Close the tab this conversation opened, and say nothing about it. If the person
   asked to see the page, leave it open instead.

## When it does not work

Say what happened in one line, in the person's words, and stop:

- Neither the direct link nor the menu search reaches a balances page: "I could not find the
  absence balances page in your PeopleSoft; tell me where you usually see it and I will use
  that."
- `not_authorized` on the page the menu opened: "Your PeopleSoft account does not show absence
  balances; HR Systems can confirm the self-service access."
- The sign-in never completes after two nudges: "PeopleSoft did not finish the sign-in; try
  again once you are signed in."

For Matthew, as the tester: when it fails, add `TIMEOFF.state()` (state, page, title and path)
of the last page so the pattern can be fixed. For anyone else, the one line is enough.

## Never

Never type a password, never complete Duo, never change anything on a PeopleSoft page, never
read pay or compensation figures that may appear nearby into the answer, never return a page's
URL or host from the JavaScript tool (paths and titles only).

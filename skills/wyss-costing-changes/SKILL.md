---
name: wyss-costing-changes
description: Do the payroll costing changes, attended or unattended - "run the costing changes", "scheduled run of the costing changes", "keepalive for the costing changes", "rehearse the costing changes", "what costing changes are waiting", "did Rebecca's change go in". Keys every pending change into PeopleSoft in the person's own Chrome (Claude in Chrome) with a scripted fill, leaves each one ready for their Save, files the backup once saved and tidies the tabs. The person signs in once and clicks Save; nothing else. Use for anything about costing changes, re-costing someone's payroll, the PeopleSoft entry queue, or Beth's queue.
---

# Costing changes

The person's job is to click **Save** in PeopleSoft. Everything else is Claude's: finding the
work, opening the pages, keying the rows, checking them, recording what happened, filing the
backup and closing the tabs. Claude never clicks Save, never types a password and never
completes Duo: a run with nobody present can fill and verify, it cannot commit payroll. "Come
back to 4 done" means "come back to 4 filled and verified, one Save each."

The person does not know or care how Wyss Apps tracks a request, so never show them its
machinery: no tool names, no statuses ("claimed", "staged", "ready"), no ids unless they ask.
Work words only: *waiting to be keyed*, *filled in PeopleSoft, waiting for your Save*, *saved*,
*done and filed*, *skipped because …*. Never read the pay rates shown on the page into anything.

## Modes (from the prompt)

| Prompt says | Mode | Who is there |
|---|---|---|
| "run the costing changes", "do the costing changes", "go", or no argument | **present run** | the person, in the chat |
| "scheduled run" | **scheduled run** | nobody; blockers go through `report_run_status`, not the chat |
| "keepalive" | **keepalive** | nobody; touch the session, finish saved ones, say nothing |
| "rehearse" | **rehearsal** | the person; fill and Cancel, never Save |
| a question | **answer** | the person |

A scheduled run and a keepalive print at most one line at the end ("Nothing waiting.", or the
Save list). Everything a person must fix is reported with `report_run_status`, which posts one
card to the costing channel per reason per day; the chat is not read when they are away.

## Preflight (in this order; fail fast, claim nothing until it passes)

| # | Check | How | Fail → |
|---|---|---|---|
| 1 | Wyss Apps token | `whoami` answers and `tools` includes Costing Changes (if `plugin.update_available`, say its `plugin.update` line once and go on) | present: repeat the bridge's one-sentence fix; scheduled: `report_run_status` `token_invalid` or `vpn` (from the message) and stop |
| 2 | Work exists | `list_costing_changes` `status: ["ready","claimed","staged"]`: anything ready, or claimed/staged by this person | "Nothing waiting." and stop (scheduled: that one line, no card) |
| 3 | Not blackout | `payroll_blackout` is null | "Payroll blackout until <date>; nothing keyed." Stop; no card |
| 4 | Chrome reachable | the Claude in Chrome tools exist and `tabs_context_mcp` answers | present: "Open Chrome and leave it open, then say go." scheduled: `report_run_status` `chrome_closed` ("Open Chrome and leave it open; the next run is at <time>") and stop |
| 5 | PeopleSoft session | open the Costing search URL in a new tab, load `lib/peoplesoft.js`, `WYSS.state()` | see the state table |
| 6 | PeopleSoft access | state is `ready` with `page: "costing_search"` | `report_run_status` `no_access` ("Your PeopleSoft account cannot open costing pages; ask HR Systems for the Department Budget Earnings role"). Stop the whole run; do not try each request |

Costing search URL:
`https://peoplesoft.hrapps.harvard.edu/psp/psprdaws/EMPLOYEE/HRMS/c/HU_CUSTOM_POS.HU_COSTING_SEARCH.GBL`

Checks 4 to 6 run once per run, not per request. When all pass in a scheduled run or keepalive,
call `report_run_status` with `state: "ok"` once (it clears the person's open notices).

### State table (`WYSS.state()`)

| state | Present run | Scheduled run / keepalive |
|---|---|---|
| `ready` | continue | continue |
| `harvardkey` | "Sign in to PeopleSoft in that tab (HarvardKey and Duo), then say go." Wait, then re-check | `signed_out`, stop |
| `duo` | same as harvardkey | wait 2 minutes, re-check once, then `duo_pending`, stop |
| `timeout` | reopen the same URL once (the HarvardKey session often re-signs in silently), re-check; then as harvardkey | same, then `signed_out` |
| `not_authorized` | "Your PeopleSoft account cannot open costing pages; ask HR Systems for the Department Budget Earnings role." Stop | `no_access`, stop |
| `maintenance` | "PeopleSoft is unavailable right now; try later." Stop | `system_down`, stop |
| `unknown` | screenshot, say what the page shows, stop | `unknown_page` with the title in the message, stop |

## Gather the work (after preflight)

From the preflight list, `whoami` gives the person's email for `claimed_by`:

- **Theirs, already filled** (`staged`, `claimed_by` them): filled by an earlier run, in a tab
  this conversation may not be able to see. Never fill it again. Check whether it was saved by
  reopening its direct URL in a new tab (see After Save): saved → finish it; not saved → keep it
  in the Save list as "filled earlier (tab from the previous run)" and close the tab you opened.
  Only when a person says in the chat that the old tab is gone: `report_costing_change_error`
  ("filled page lost before Save"), `review_costing_change` `mark_ready`, and key it again.
- **Theirs, started** (`claimed`, `claimed_by` them): key it now (claiming again renews).
- Someone else's claimed or staged: leave alone; list in the report.
- **Waiting** (`ready`): oldest first. `ps_fill_spec.budget_level` `A` (no position number) is
  not automated: do not claim it; list it as "needs keying by hand".

Two unsaved filled pages for the same request must never exist. That is why a staged request is
never refilled by a scheduled run.

## Key each request

1. `claim_costing_change` (`confirm: true`), then `get_costing_change` for `ps_fill_spec`
   (`spec`). Refused because someone else holds it: skip, list at the end.
2. Open the direct URL in a **new tab of this run** (never touch other tabs):
   ```
   https://peoplesoft.hrapps.harvard.edu/psp/psprdaws/EMPLOYEE/HRMS/c/HU_CUSTOM_CACTG.HU_DPTBGT_ERN.GBL?Page=HU_DPTBGT_ERN&Action=U&ForceSearch=Y&BUDGET_LEVEL_INDC=<spec.budget_level>&DEPTID=<spec.deptid>&EMPL_RCD=<spec.empl_rcd>&FISCAL_YEAR=<spec.fiscal_year>&POSITION_NBR=<spec.position_no>
   ```
3. Load the script: read `lib/peoplesoft.js` from the plugin root (`${CLAUDE_PLUGIN_ROOT}/lib/peoplesoft.js`)
   and evaluate the whole file in the tab; it defines `PS`, the generic PeopleSoft layer, and
   `WYSS`, the costing page. `WYSS.state()`
   again: the session can drop mid-run. Not `ready`: `release_costing_change` (back to the
   queue), then the state table, and stop the run. `ready` but `page` is not
   `department_budget_earnings`: `report_costing_change_error` with `WYSS.probe()`, skip.
4. `WYSS.checkBefore(spec)` must return `[]`. Otherwise `report_costing_change_error` with the
   list, close the tab, skip ("PeopleSoft already shows different costing; flagged for
   Matthew").
5. `await WYSS.fill(spec)`: adds the effective-dated row, sets the date, makes the lines equal
   `spec.distributions`, waits for each refresh, returns the readback only when
   `WYSS.verify(spec, readback)` is empty. If it throws: record it with
   `rehearse_costing_change` (`outcome: "failed"`, the error as `note`, `WYSS.readPage()` as
   the readback). Present run: fall back to keying by hand (next step). Scheduled run:
   `report_costing_change_error` with the error, close the tab, skip.
6. **Keying by hand** (present run only). Classic PeopleSoft page in the `TargetContent`
   iframe. Click the "+" beside Effective Date (`$ICField16$new$0$$0`); set
   `HU_DPTBGT_VW_EFFDT$0` to `spec.effective_date` as MM/DD/YYYY and tab out. Make the lines
   equal `spec.distributions` ("+" at the end of a line inserts below, "−" deletes): line `n`
   has `tub` in `HU_DEPBUDERN_VW_FUND_CODE$n`, `org` in `HU_DEPBUDERN_VW_OPERATING_UNIT$n`,
   `fund` in `HU_DEPBUDERN_VW_PROJECT_ID$n`, `activity` in `HU_DEPBUDERN_VW_PRODUCT$n`,
   `subactivity` in `HU_DEPBUDERN_VW_PROGRAM_CODE$n`, `root` in `HU_DEPBUDERN_VW_CLASS_FLD$n`,
   `pct` (three decimals) in `HU_DEPBUDERN_VW_DIST_PCT$n`, tabbing out after each. Never type
   the object code (`HU_DEPBUDERN_VW_ACCOUNT$n`); leave Earnings Code blank. Wait until
   "Distribution Total" reads 100.000 with no error text; `WYSS.readPage()` for the readback
   and `WYSS.verify(spec, readback)` must be empty.
7. `mark_costing_change_staged` with the readback, `confirm: true`; keep the result's
   `backup_upload_url`. A mismatch: leave the tab open, skip ("flagged for review").

Never close a tab whose row is filled and unsaved.

## The Save list

When every request is filled or skipped, one message (a scheduled run prints the same text as
its only output):

> 4 costing changes filled in PeopleSoft, waiting for your Save (tabs 2 to 5): Vernet 10/25 ·
> Perelman 11/01 · Okafor 11/01 · Li 10/18, each 100.000. Skipped: 1 (Diaz, appointment-level,
> needs keying by hand). Click Save on each tab, then type done, or just leave them: the next
> keepalive files the backups for anything you have saved.

Present run: wait for "done" and run After Save. Scheduled run: stop here.

## After Save (the finisher; any mode can run it)

For each request of theirs that is `staged`:

1. **Confirm the save without trusting any old tab.** Open the direct URL in a new tab of this
   run, load `peoplesoft.js`, `WYSS.state()` must be `ready`, then `WYSS.readPage()`: the top
   row shows `spec.effective_date` and `WYSS.verify(spec, page)` is empty → saved. The top row
   is still the old costing → not saved: close this tab, leave the request as it is (present
   run: say which one still needs Save). The page shows an unsaved editable row → this tab
   is the one with the edit (same conversation): leave it, not saved.
2. **File the backup.** On the saved page, scroll so the Effective Date, the lines and the
   Distribution Total are in view and take a screenshot. Open `backup_upload_url` (from the
   staged result or `get_costing_change`) in a new tab: no sign-in needed. `find`
   `#backup-file`, `upload_image` the screenshot to it as `LastName_FirstName_YYYY-MM-DD.png`
   (the effective date), click `#attach-backup`, check for `#backup-filed`. That records the
   save and closes the request; the confirmation email goes out by itself.
   `#backup-link-expired` → `get_costing_change` for a fresh link. Upload failing twice in a
   present run → ask for a PDF (Ctrl+P, Save as PDF to Downloads, "done") and `file_upload` it
   on the same page; scheduled → leave it, the next keepalive tries again.
3. **Tidy.** Close the tabs this run opened for finished requests and the backup tabs. Leave
   one PeopleSoft tab open on the Costing search page. Never close a tab with an unsaved row.
4. Present run: one line, "Done: 2 saved and filed (Vernet, Perelman)."; scheduled: nothing.

## Keepalive (every 15 minutes in working hours, nobody present)

Purpose: keep the PeopleSoft session alive so the lunch run finds it signed in, and finish
anything the person saved since the last run. No clicks or typing on PeopleSoft pages, no
messages.

1. `whoami`; `list_costing_changes` `status: ["claimed","staged"]`. If any request is claimed
   by this person within the last 10 minutes (`claimed_at`), a run is in progress: stop.
2. Open the Costing search URL in a new tab, load `peoplesoft.js`, `WYSS.state()`. Not
   `ready`: close the tab and stop silently (the main run reports). `ready`: reload the tab
   once (that is the keepalive), then `report_run_status` `ok`.
3. Run After Save for the person's `staged` requests (reopen each by URL; file the backup for
   the saved ones; leave the rest). Close every tab this keepalive opened.
4. Print nothing, except "Filed: Vernet." when a backup was filed.

## Rehearsal (dry run, nothing saved)

"Rehearse the costing changes", or the first run on a new computer: prove the script on real
requests without touching payroll. Preflight as above. For each waiting request (no claim):
open the page, load the script, `WYSS.probe()`, `WYSS.checkBefore(spec)`, `await
WYSS.fill(spec)`, then `WYSS.cancel()` (the Cancel button, never Save) and
`rehearse_costing_change` with the readback, `outcome: "cancelled"` (or `"failed"` with the
error as `note`, after `WYSS.cancel()` all the same). Report one line per request ("rehearsed,
matched", "rehearsed, mismatch: …", "script failed at …: …") and include the probe of the first
page for Matthew. Nothing changes in PeopleSoft or in Wyss Apps beyond the rehearsal notes.

## Questions (no run)

Work words, never statuses.

- "What's waiting?" → `list_costing_changes` `status: ["ready","claimed","staged"]`: "3 are
  waiting to be keyed (names, effective dates); 1 is filled and waiting for your Save."
- "Why is Rebecca's stuck?" → `search: "Rebecca"`, `get_costing_change`; translate `errors`,
  `warnings`, `review_note` and the last `history` entry into one plain sentence.
- "Did HUID 81657165 go in?" → `submitted`/`backup_filed` means "yes, saved on <date>"
  (`confirmed_in_peoplesoft_at` adds "and PeopleSoft confirmed it overnight"); `staged` means
  "filled, not yet saved"; earlier means "not yet keyed".
- Reviewers, when they ask: `review_costing_change` (`mark_ready`, `send_back` with a note,
  `cancel` with a note); preview, then confirm on their yes.

## Setting up the scheduled tasks (once, in Cowork)

- "scheduled run of the costing changes": weekdays 12:10 and 15:40.
- "keepalive for the costing changes": every 15 minutes, weekdays 9:00 to 17:00.
- The person's side: sign in to PeopleSoft in Chrome once in the morning, leave Chrome and the
  Claude desktop app open and the computer awake. Closing Chrome means the next run asks for a
  sign-in (through the costing channel).

## Claude's bookkeeping (never shown to the person)

| Tool | When |
|---|---|
| `whoami` | preflight; the person's email for `claimed_by` |
| `list_costing_changes` | gather work; `status` list, `search`, `payroll_blackout` |
| `get_costing_change` | `ps_fill_spec`, `current_costing`, `backup_upload_url`, `history` |
| `claim_costing_change` | before keying (2-hour lock, renewable) |
| `release_costing_change` | the run cannot continue with a claimed request (session dropped) |
| `mark_costing_change_staged` | page filled; readback checked; returns `backup_upload_url` |
| `rehearse_costing_change` | a dry run's readback, or a script failure, as a note |
| `report_costing_change_error` | anything that stops one request; flags it for review |
| `report_run_status` | scheduled runs and keepalives: `blocked` with a reason code (`chrome_closed`, `signed_out`, `duo_pending`, `no_access`, `system_down`, `token_invalid`, `vpn`, `unknown_page`; one card per reason per day), or `ok` |
| `review_costing_change` | `mark_ready` to re-queue a lost one; reviewer decisions |
| `mark_costing_change_submitted` | optional; the backup upload records the save by itself |
| `file_costing_change_backup` | only for a backup kept somewhere other than the request |

Statuses: new → validated → ready → claimed → staged → submitted → backup_filed; side exits
needs_review, error, cancelled. `ps_fill_spec` (version 2): `budget_level`, `deptid`,
`empl_rcd`, `fiscal_year`, `position_no` build the URL; `effective_date` is ISO (typed
MM/DD/YYYY); `distributions[]` carries `tub`, `org`, `fund`, `activity`, `subactivity`, `root`,
`pct` (`object` is readback only); `current_costing.lines` is the before. `lib/peoplesoft.js`:
`PS` (generic: `doc`, `idle`, `setField`, `click`, `state`) and `WYSS` (this page: `state`,
`probe`, `readPage`, `checkBefore`, `fill`, `verify`, `cancel`, `saved`). Nothing here writes
to PeopleSoft.

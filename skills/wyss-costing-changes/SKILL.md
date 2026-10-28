---
name: wyss-costing-changes
description: Run the Wyss payroll costing-change queue into PeopleSoft. "Run the costing changes" opens each ready request's Department Budget Earnings page in the person's own Chrome (Claude in Chrome), keys the new distribution, and stops at Save for them to review; after Save it records the submission and files the backup PDF on the request in Wyss Apps. Also answers what is pending, why a request needs review, and whether a change went in. Use for costing changes, re-costing someone's payroll, the PeopleSoft entry queue, or Beth's queue.
---

# Costing changes

The job is to get costing changes **into PeopleSoft, filled and ready for the person to click
Save**. Everything else (listing, explaining, recording) serves that. A costing change moves part
of a person's payroll to a new distribution (chart-of-account strings and percentages summing to
100) from an effective date. Finance managers type them into SharePoint; Wyss Apps validates them
and queues the clean ones as **ready**; this skill keys them. Only the person clicks Save.

## Browser rule

PeopleSoft and Wyss Apps are driven in the person's **own Chrome through Claude in Chrome**,
never in Cowork's built-in browser: HarvardKey with Duo only works in their real browser. If the
Claude in Chrome tools are not available, stop with one line ("Claude in Chrome is not connected.
Turn on the Chrome extension, then say run again.") and do nothing else. Never type a password;
never press Save (`HU_DPBUDERN_WRK_SAVE_BTN`).

## "Run" (the default)

When the person says run, go, do the costing changes, or anything that means "key the queue",
do the whole procedure without narrating it. No queue summary, no menu, no previews: the word run
is the go-ahead for every Wyss Apps status change below. Speak only at the two hand-over points
and at the end.

1. **Queue.** `list_costing_changes` with `status: ["ready"]`. If `payroll_blackout` is set,
   say "Payroll blackout until <date>; nothing is keyed today" and stop. If the list is empty,
   say "Nothing ready" and stop. Otherwise take every ready request, oldest first.
2. **Tabs.** In Chrome open the Costing Changes queue,
   `https://wigt.med.harvard.edu/tools/costing_changes`, in one tab and leave it. Then, for each
   request, one PeopleSoft tab (steps 3 to 7). If PeopleSoft refuses a second open page, finish
   one request through Save before opening the next.
3. **Claim.** `claim_costing_change` with `confirm: true`, then `get_costing_change` for the
   `ps_fill_spec` (`spec` below). If the claim is refused (someone else holds it), skip the
   request and note it for the end.
4. **Open the page** by direct URL, no menus:
   ```
   https://peoplesoft.hrapps.harvard.edu/psp/psprdaws/EMPLOYEE/HRMS/c/HU_CUSTOM_CACTG.HU_DPTBGT_ERN.GBL?Page=HU_DPTBGT_ERN&Action=U&ForceSearch=Y&BUDGET_LEVEL_INDC=<spec.budget_level>&DEPTID=<spec.deptid>&EMPL_RCD=<spec.empl_rcd>&FISCAL_YEAR=<spec.fiscal_year>&POSITION_NBR=<spec.position_no>
   ```
   If the tab shows the HarvardKey sign-in instead, this is hand-over point one: say "Sign in to
   PeopleSoft in that tab (HarvardKey and Duo), then say go", wait, and continue from the same
   URL. Do not type credentials. If `spec.budget_level` is `A` (no position), the page needs the
   appointment path, which is untested: `report_costing_change_error` ("appointment-level
   costing, not automated yet"), skip, and move on.
5. **Check the before.** The page (classic PeopleSoft inside the `TargetContent` iframe) shows
   the current lines as read-only spans. Compare them with `spec.current_costing.lines` (COA and
   percent, order ignored). Also check `HU_POSINCUM_DRV_EMPLID$0` equals `spec.empl_id`. Any
   difference: `report_costing_change_error` with what the page shows, skip the request, move on.
6. **Fill.** Click the "+" beside Effective Date (`$ICField16$new$0$$0`): it adds an
   effective-dated row with the current lines copied in as inputs. Set `HU_DPTBGT_VW_EFFDT$0` to
   `spec.effective_date` as MM/DD/YYYY and tab out. Then make the lines match
   `spec.distributions` exactly: edit, add ("+" at the end of a line inserts below) or delete
   ("−") so that each line `n` has `tub` in `HU_DEPBUDERN_VW_FUND_CODE$n`, `org` in
   `HU_DEPBUDERN_VW_OPERATING_UNIT$n`, `fund` in `HU_DEPBUDERN_VW_PROJECT_ID$n`, `activity` in
   `HU_DEPBUDERN_VW_PRODUCT$n`, `subactivity` in `HU_DEPBUDERN_VW_PROGRAM_CODE$n`, `root` in
   `HU_DEPBUDERN_VW_CLASS_FLD$n` and `pct` (three decimals) in `HU_DEPBUDERN_VW_DIST_PCT$n`,
   tabbing out after each field. Never type the object code (`HU_DEPBUDERN_VW_ACCOUNT$n`,
   derived). Leave Earnings Code blank. Wait for "Distribution Total" to read 100.000 and for no
   error text on the page; if an error shows and a retry does not clear it,
   `report_costing_change_error` with the message, skip, move on.
7. **Stage.** Read the inputs back from the page (`empl_id`, `empl_rcd`, `effective_date`,
   `distributions` as `[{coa, pct}]`, `total`) and call `mark_costing_change_staged` with
   `confirm: true`. A mismatch sends the request to needs review: leave that tab alone and move
   on.
8. **Hand over** once every request is filled or skipped. One message, nothing else:
   "Filled and ready for Save: <tab n>: <employee>, effective <date>, <k> lines, total 100.000
   (one line per request). Review each tab and click Save. Say done when they are saved."
   Then wait. If the person wants a change, make it on the page and stage again.
9. **After Save.** When they say done (or name the ones they saved), for each saved tab read
   what the page shows after Save (message, any id, timestamps) and call
   `mark_costing_change_submitted` with it and `confirm: true`. The confirmation email goes out
   from Wyss Apps.
10. **Backup.** The backup is the saved page as PDF, named `LastName_FirstName_YYYY-MM-DD.pdf`
    (the effective date). Printing is the person's: say "Press Ctrl+P on each saved tab and Save
    as PDF to Downloads (Cmd+P on a Mac); say done." Then, for each request, open its `url` (the
    request page in Wyss Apps) in the Chrome tab, choose the matching file from Downloads under
    "Backup: the saved PeopleSoft page printed to PDF" and click "Attach backup and complete".
    Wyss Apps keeps the file on the row and closes the request. If a file cannot be found,
    leave the request at submitted and say which one.
11. **Report.** One short table: request id, employee, effective date, result (filed / submitted,
    backup pending / skipped: reason). Nothing more. Claims expire after two hours; a run that
    takes longer re-claims as it goes.

Sessions time out after about 20 to 30 minutes idle: if a tab has gone back to the sign-in page
when the person returns to it, hand over as in step 4 and refill from step 5 (the unsaved row is
lost).

## The spec

`ps_fill_spec` (version 2) is the whole of what gets keyed; never invent a line.

| Field | Used for |
|---|---|
| `budget_level`, `deptid`, `empl_rcd`, `fiscal_year`, `position_no` | the direct URL (P = position level; `A` = appointment level, not automated) |
| `empl_id` | checked against the page's Incumbent Empl ID |
| `effective_date` | ISO in the spec, typed MM/DD/YYYY |
| `distributions[]` | `tub`, `org`, `fund`, `activity`, `subactivity`, `root`, `pct`; `object` is readback only |
| `current_costing.lines` | the "before" the page must show |

The page also shows the incumbent's annual, monthly, comp and hourly rates. Never read those into
anything: not the readback, not the chat, not a summary.

## Tools

| Tool | What it does |
|---|---|
| `list_costing_changes` | The queue: `status: ["ready"]` for what to key; `status: ["needs_review"]` for what a finance manager must fix; `search` by employee, HUID, requester or id. Returns `counts_by_status` and `payroll_blackout`. |
| `get_costing_change` | One request: `ps_fill_spec`, current vs requested distribution and `diff`, `errors`, `warnings`, `review_note`, `history`, `url`, backup file. |
| `claim_costing_change` | Lock a ready request for two hours (refused on blackout days or when someone else holds it). |
| `mark_costing_change_staged` | Page filled, not saved; takes the readback and checks it against the spec. |
| `mark_costing_change_submitted` | The person pressed Save; takes what the page shows; sends the confirmation email. |
| `file_costing_change_backup` | Only for a backup kept somewhere other than the request page: records a link and closes the request. |
| `report_costing_change_error` | Anything that stops a request (page differs, login failed, PeopleSoft error); no confirm needed. |
| `review_costing_change` | Reviewer decisions outside a run: `mark_ready`, `send_back` (note), `cancel` (note). |

All writes change the request's status in Wyss Apps only; nothing writes to PeopleSoft. Outside a
run (a one-off "mark #12 submitted", a reviewer decision) show the preview first and confirm on a
yes. Inside a run, "run" is the yes.

## Statuses

`new` (seen by intake) → `validated` (checked; waits for a reviewer only when it is a no-op or
auto-ready is off) → `ready` (automatic when validation finds no errors) → `claimed` → `staged`
(filled, awaiting Save) → `submitted` (saved) → `backup_filed` (PDF on the row; done).
Side exits: `needs_review` (validation errors, source edited mid-flight, readback mismatch, sent
back), `error` (reported during a run), `cancelled`. `confirmed_in_peoplesoft_at` is the
independent confirmation from the overnight sync, whatever the status says.

## Questions, not runs

- "What's waiting?" → `list_costing_changes` with `status: ["ready"]`; employee, effective date,
  warnings, `url`; mention a blackout.
- "Why is Rebecca's stuck?" → `search: "Rebecca"`, then `get_costing_change`; quote `errors`,
  `warnings`, `review_note` and the last `history` entry.
- "Did HUID 81657165 go in?" → search by HUID: `submitted` or `backup_filed`, plus
  `confirmed_in_peoplesoft_at`, means yes; `staged` means Save has not been pressed.
- "What do I type for #12?" → read `ps_fill_spec` line by line.
- Warnings to read out when asked: *Retroactive* (effective date in the past), *new pairing,
  PeopleSoft will create it*, *no position on a position-costed job*.

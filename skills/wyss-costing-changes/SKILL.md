---
name: wyss-costing-changes
description: Do the payroll costing changes - "run the costing changes", "do the costing changes", "key the costing queue", "what costing changes are waiting", "did Rebecca's change go in". Keys every pending change into PeopleSoft in the person's own Chrome (Claude in Chrome), stops at Save for them, then records and files the backup itself. The person signs in and clicks Save; nothing else. Use for anything about costing changes, re-costing someone's payroll, the PeopleSoft entry queue, or Beth's queue.
---

# Costing changes

The person's job is to click **Save** in PeopleSoft. Everything else is Claude's: finding the
work, opening the pages, keying the rows, checking them, recording what happened and filing the
backup. The person does not know or care how Wyss Apps tracks a request, so never show them its
machinery: no tool names, no statuses ("claimed", "staged", "ready", "needs review", "backup
filed"), no ids unless they ask. Speak in work words: *waiting to be keyed*, *filled in
PeopleSoft, waiting for your Save*, *saved*, *done and filed*, *skipped because …*, *sent back
to <finance manager> because …*.

## Before anything (silent when it passes)

1. `whoami`. If it fails, repeat its one-sentence fix (missing token, expired token, not on the
   VPN, no access) and stop. If the Wyss Apps tools are missing altogether, say: "The Wyss Apps
   plugin is not enabled for this chat. In Cowork: Customize, Plugins, add
   https://github.com/Wyss/wyss-apps-claude." If `tools` does not include Costing Changes, say:
   "Your account does not have costing changes yet; ask Matthew Laubach." and stop.
2. Claude in Chrome. PeopleSoft runs in the person's **own Chrome**, signed in with HarvardKey
   and Duo; Cowork's built-in browser cannot complete Duo. If the Claude in Chrome tools (tabs,
   navigate, read page, screenshot) are not among your tools, say: "Install Claude in Chrome
   from the Chrome Web Store, sign in to it, and turn it on for this chat. Then say run again."
   and stop.
3. Both pass: say nothing about setup. Start the work.

Never type a password. Never click Save (`HU_DPBUDERN_WRK_SAVE_BTN`). Never read the pay rates
shown on the page into anything.

## "Run" (the default)

"Run the costing changes", "do the costing changes", "go", or anything that means key the queue.
No summary first, no menu, no previews, no questions except the two hand-overs below. The word
run is the go-ahead for every recording step; call every write with `confirm: true`.

### Gather the work

`list_costing_changes` with `status: ["claimed", "staged", "ready"]`; `whoami` gives the
person's email for `claimed_by`. In this order:

- **Theirs, already filled** (`staged`, `claimed_by` them): from an earlier run. Look at its
  PeopleSoft tab. Still open and showing the filled, unsaved row: it goes straight into the
  hand-over list. Already saved (the row is there and no longer editable, or they say so):
  treat it as saved (After Save, below). Tab gone or back at the sign-in page: the unsaved row
  is lost; `report_costing_change_error` ("filled page lost before Save") then
  `review_costing_change` with `action: "mark_ready"`, and key it again as new work.
- **Theirs, started** (`claimed`, `claimed_by` them): key it now (claiming again renews).
- Someone else's (`claimed`/`staged` by another email): leave alone; mention at the end.
- **Waiting** (`ready`): oldest first.

If nothing is theirs and nothing is waiting: "No costing changes are waiting." If
`payroll_blackout` is set: "Payroll blackout until <date>: nothing is keyed today." Never
answer "nothing to do" while the person has unfinished work of their own.

### Key each request

1. `claim_costing_change` (`confirm: true`), then `get_costing_change` for `ps_fill_spec`
   (`spec`). Refused because someone else holds it: skip, mention at the end.
2. Open the Costing Changes queue, `https://wigt.med.harvard.edu/tools/costing_changes`, once in
   its own Chrome tab and leave it. Open one PeopleSoft tab per request by direct URL, no menus:
   ```
   https://peoplesoft.hrapps.harvard.edu/psp/psprdaws/EMPLOYEE/HRMS/c/HU_CUSTOM_CACTG.HU_DPTBGT_ERN.GBL?Page=HU_DPTBGT_ERN&Action=U&ForceSearch=Y&BUDGET_LEVEL_INDC=<spec.budget_level>&DEPTID=<spec.deptid>&EMPL_RCD=<spec.empl_rcd>&FISCAL_YEAR=<spec.fiscal_year>&POSITION_NBR=<spec.position_no>
   ```
   If PeopleSoft refuses a second open page, finish one request through Save before the next.
   **Hand-over one:** the tab shows the HarvardKey sign-in. Say "Sign in to PeopleSoft in that
   tab (HarvardKey and Duo), then say go." Wait, then reopen the same URL. `spec.budget_level`
   `A` (no position number) is not automated: `report_costing_change_error` ("appointment-level
   costing, not automated yet"), skip, mention at the end as "needs keying by hand".
3. **Check the before.** The page (classic PeopleSoft in the `TargetContent` iframe) shows the
   current lines as read-only spans. They must equal `spec.current_costing.lines` (COA and
   percent, any order) and `HU_POSINCUM_DRV_EMPLID$0` must equal `spec.empl_id`. Any
   difference: `report_costing_change_error` with what the page shows, skip, mention at the end
   as "skipped: PeopleSoft already shows different costing; flagged for Matthew".
4. **Fill.** Click the "+" beside Effective Date (`$ICField16$new$0$$0`); it adds an
   effective-dated row with the current lines copied in as inputs. Set `HU_DPTBGT_VW_EFFDT$0` to
   `spec.effective_date` as MM/DD/YYYY, tab out. Make the lines equal `spec.distributions`:
   edit, add ("+" at the end of a line inserts below) or delete ("−") until line `n` has `tub` in
   `HU_DEPBUDERN_VW_FUND_CODE$n`, `org` in `HU_DEPBUDERN_VW_OPERATING_UNIT$n`, `fund` in
   `HU_DEPBUDERN_VW_PROJECT_ID$n`, `activity` in `HU_DEPBUDERN_VW_PRODUCT$n`, `subactivity` in
   `HU_DEPBUDERN_VW_PROGRAM_CODE$n`, `root` in `HU_DEPBUDERN_VW_CLASS_FLD$n`, `pct` (three
   decimals) in `HU_DEPBUDERN_VW_DIST_PCT$n`, tabbing out after each. Never type the object code
   (`HU_DEPBUDERN_VW_ACCOUNT$n`, derived); leave Earnings Code blank. Wait until "Distribution
   Total" reads 100.000 with no error text. An error that a retry does not clear:
   `report_costing_change_error` with the message, skip, mention at the end.
5. **Record it as filled.** Read the inputs back from the page (`empl_id`, `empl_rcd`,
   `effective_date`, `distributions` as `[{coa, pct}]`, `total`) and
   `mark_costing_change_staged` (`confirm: true`). A mismatch means the page and the request
   disagree: leave the tab, skip, mention at the end as "flagged for review".

### Hand-over two: Save

When every request is filled or skipped, one message and nothing else:

> Filled in PeopleSoft, waiting for your Save:
> 1. Andyna Vernet, effective 10/25/2026, 5 lines, total 100.000 (tab 2)
> 2. Rebecca Perelman, effective 11/01/2026, 2 lines, total 100.000 (tab 3)
> Click Save on each tab, then say done.

Then wait. A change they ask for is made on the page and recorded again (step 5).

### After Save (all Claude)

When they say done (or name the ones they saved):

1. For each tab, read the page: the new row is saved when its inputs are no longer the unsaved
   entry (the page reloaded after Save, any confirmation message or id is visible). Not saved:
   say which one still needs Save and wait. Saved: `mark_costing_change_submitted` with what the
   page shows (`confirm: true`). The confirmation email goes out by itself.
2. **File the backup yourself.** Take a screenshot of the saved page showing the new row and its
   lines (scroll so the Effective Date, the lines and the Distribution Total are in view). Open
   the request's `url` (its page in Wyss Apps) in the queue tab, find the file input under
   "Backup" with `find`, and `upload_image` the screenshot to it with filename
   `LastName_FirstName_YYYY-MM-DD.png` (the effective date). Click "Attach backup and complete"
   and check the page now shows "Backup file:". Only if the upload fails twice: ask for a PDF
   ("Press Ctrl+P on that tab, Save as PDF to Downloads, say done") and attach that file with
   `file_upload` instead.
3. **Report**, in work words, then stop:

> Done: 2 costing changes saved in PeopleSoft and filed (Andyna Vernet, Rebecca Perelman).
> Skipped: none.

Sessions time out after 20 to 30 minutes idle. A tab that has gone back to sign-in when they
return has lost its unsaved row: hand-over one, then key it again from step 3.

## Questions (no run)

Answer in work words, never statuses.

- "What's waiting?" → `list_costing_changes` `status: ["ready","claimed","staged"]`: "3 are
  waiting to be keyed (names, effective dates); 1 is filled and waiting for your Save." Mention
  a blackout.
- "Why is Rebecca's stuck?" → `search: "Rebecca"`, `get_costing_change`; translate `errors`,
  `warnings`, `review_note` and the last `history` entry into one plain sentence ("sent back to
  Jane Doe on 10/24: the percentages add up to 95").
- "Did HUID 81657165 go in?" → search by HUID: `submitted`/`backup_filed` means "yes, saved on
  <date>" (`confirmed_in_peoplesoft_at` adds "and PeopleSoft confirmed it overnight"); `staged`
  means "filled, not yet saved"; anything earlier means "not yet keyed".
- Reviewers only, when they ask: `review_costing_change` (`mark_ready`, `send_back` with a note,
  `cancel` with a note); preview, then confirm on their yes.

## Claude's bookkeeping (never shown to the person)

| Tool | When |
|---|---|
| `list_costing_changes` | gather work; `status` list, `search`, `counts_by_status`, `payroll_blackout` |
| `get_costing_change` | `ps_fill_spec`, `current_costing`, `url`, `history`, `errors`, `warnings` |
| `claim_costing_change` | before keying (2-hour lock, renewable) |
| `mark_costing_change_staged` | page filled; readback checked against the spec |
| `mark_costing_change_submitted` | after their Save; sends the confirmation email |
| `report_costing_change_error` | anything that stops a request; flags it for review |
| `review_costing_change` | `mark_ready` to re-queue a lost one; reviewer decisions |
| `file_costing_change_backup` | only for a backup that must live somewhere other than the request page |

Statuses: new → validated → ready → claimed → staged → submitted → backup_filed; side exits
needs_review, error, cancelled. `ps_fill_spec` (version 2) is the whole of what gets keyed:
`budget_level`, `deptid`, `empl_rcd`, `fiscal_year`, `position_no` build the URL;
`effective_date` is ISO (typed MM/DD/YYYY); `distributions[]` carries `tub`, `org`, `fund`,
`activity`, `subactivity`, `root`, `pct` (`object` is readback only); `current_costing.lines` is
the before. Nothing here writes to PeopleSoft.

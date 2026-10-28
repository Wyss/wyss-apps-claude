---
name: wyss-costing-changes
description: Work the Wyss payroll costing-change queue in Wyss Apps through the wyss-apps MCP server: what is pending, what is ready for PeopleSoft, why a request needs review, what the before/after distribution is, and the exact fill spec to key into PeopleSoft. Use when someone asks about costing changes, a pending costing request, re-costing someone's payroll, the PeopleSoft entry queue, or Beth's queue.
---

# Costing changes

A **costing change** moves part of a person's payroll from one chart-of-account string to others:
a new distribution (COA strings and percentages summing to 100) from an effective date. Finance
managers type them as *Pending* rows in the SharePoint "Costing & Compensation" list; Wyss Apps
reads them every hour on workdays, checks them against PeopleSoft's current costing and the chart
of accounts, and queues the clean ones. Beth keys them into PeopleSoft (page: Department Budget
Earnings) and **submits herself**; nothing in Wyss Apps or Claude submits to PeopleSoft.

Everything below goes through the `wyss-apps` MCP tools, which answer as the person connected and
need the **Costing Changes** tool on their Wyss Apps account (Beth, Matthew and finance leads have
it). The first two tools are read-only; the rest change a request's status (never PeopleSoft).

| Tool | Use it for |
|---|---|
| `list_costing_changes` | The queue. Default = every open request. `status: ["ready"]` for what can go into PeopleSoft now; `status: ["needs_review"]` for what a finance manager must fix; `search` by employee name, HUID, requester or id. Also returns `counts_by_status`. |
| `get_costing_change` | One request: current vs requested distribution, the diff, validation `errors` and `warnings`, `review_note`, `payroll_blackout`, `ps_fill_spec` (what to key into PeopleSoft), `history` (who did what, when), and `url` of the review page. |
| `claim_costing_change` | Take a ready request before keying it (2-hour claim, renewable). Refused on blackout days or when someone else holds it. `confirm: true` after the person agrees. |
| `mark_costing_change_staged` | The PeopleSoft page is filled, not saved: record it with a readback of what the page shows. A mismatch sends it to needs review. |
| `mark_costing_change_submitted` | The person has pressed Save in PeopleSoft: record it with what the page showed. Sends the confirmation email. |
| `file_costing_change_backup` | The backup PDF is filed: record the link and close the request. |
| `report_costing_change_error` | Anything went wrong (page changed, employee not found, session expired): mark it error with a message. No confirm needed. |
| `review_costing_change` | Reviewer decisions: `mark_ready`, `send_back` (note), `cancel` (note), with the review page's rules. |

Every write changes the request's status in Wyss Apps only; nothing writes to PeopleSoft. All of
them answer with a preview unless called with `confirm: true`: show the preview, get a yes, then
confirm. The person acts under their own name (the history shows `user:<id>`).

## Statuses

| Status | Meaning | Who moves it on |
|---|---|---|
| `new` | Seen by intake, not yet checked | Wyss Apps (automatic) |
| `validated` | Checked, no errors (warnings possible) | A reviewer marks it **ready** on the review page |
| `ready` | Cleared for PeopleSoft entry | The PeopleSoft plugin / Beth claims it |
| `claimed` | Someone is keying it now (claim expires after 2 h) | → staged |
| `staged` | Filled in PeopleSoft, waiting for Beth to press Save | Beth |
| `submitted` | Saved in PeopleSoft (reported, or confirmed when the PeopleSoft→SharePoint sync cleared the Pending flag) | → backup_filed |
| `backup_filed` | Backup PDF filed; done | |
| `needs_review` | Validation errors, the source rows were edited mid-flight, a readback mismatch, or sent back by a reviewer | The finance manager who typed it, or a reviewer |
| `error` | The plugin hit a problem (page changed, session expired) | A reviewer re-prepares or sends back |
| `cancelled` | Rows disappeared from SharePoint, or cancelled on the review page | |

`confirmed_in_peoplesoft_at` is the independent confirmation: the overnight sync cleared the
request's Pending flag, whatever the status says.

## Reading a request

- `current_distribution` is PeopleSoft's costing today (from the nightly effort feed);
  `requested_distribution` is what the finance manager asked for; `diff` lists each COA with
  before/after percentages and `change` (added / removed / changed / unchanged).
- `errors` block the request (percentages not 100, unknown chart-of-account combination,
  effective date earlier than the costing row in force, wrong employee record). `warnings` do not
  block but should be read out: *Retroactive* (effective date in the past), *new pairing,
  PeopleSoft will create it*, *no position on a position-costed job*.
- `payroll_blackout` is non-null on the Monday and Tuesday before a payday: ready requests are
  held and nothing should be keyed those days. Say so instead of suggesting a workaround.
- `ps_fill_spec` is exactly what goes into PeopleSoft (version 2: budget level, department,
  employee record, fiscal year, position, the COA lines with percentages). It contains no salary.
  If asked to "prepare" a change, read this back line by line; do not invent lines.
- `history` shows actors as `user:<id>` (a person on the review page), `client:<name>` (the
  PeopleSoft plugin) or `intake`.

## Working a request end to end (Beth's flow, with Claude in Chrome)

The person keys changes in PeopleSoft in their own browser, signed in with their own HarvardKey
and Duo; Claude fills, the person saves. One request at a time.

1. **Pick up the work.** `list_costing_changes` with `status: ["ready"]`. If `payroll_blackout`
   is set, stop and say when the next payday is. Otherwise show the list (employee, effective
   date, warnings) and let the person choose one, or take the oldest.
2. **Claim it.** `claim_costing_change` (preview, then `confirm: true`). Then
   `get_costing_change` for the `ps_fill_spec`.
3. **Open PeopleSoft** in the person's browser (Claude in Chrome): the Department Budget
   Earnings page (component `HU_CUSTOM_CACTG.HU_DPTBGT_ERN`), keyed by the spec's
   `budget_level` (P or A), `deptid`, `empl_rcd`, `fiscal_year` and `position_no`. If the
   browser asks to sign in, tell the person to sign in (HarvardKey and Duo) and wait; never type
   a password.
4. **Check the before.** Compare the page's existing rows with `ps_fill_spec.current_costing`.
   If they differ, do not continue: `report_costing_change_error` with what you saw.
5. **Fill, do not save.** Add the new effective-dated row for `effective_date` and type each
   distribution's chart segments (`tub`, `org`, `fund`, `activity`, `subactivity`, `root`) and
   `pct`; the object code is derived by PeopleSoft, never typed. Then read the page back.
6. **Stage it.** `mark_costing_change_staged` with the readback (`empl_id`, `empl_rcd`,
   `effective_date`, `distributions` as `[{coa, pct}]` read from the page). A mismatch sends the
   request to needs review; say so and stop.
7. **Hand over.** Tell the person: "The page is filled and matches the request. Please check it
   and press Save; tell me when it is done." Do not press Save yourself.
8. **Submitted.** When they say it is saved, `mark_costing_change_submitted` with what the page
   shows after Save (any transaction id, timestamps, message). The confirmation email goes out.
9. **Backup.** When the backup PDF is filed in the SharePoint library, `file_costing_change_backup`
   with its link. The request is complete; the overnight sync confirms it independently.
10. Next request: back to step 1. Claims expire after two hours; renew by claiming again.

## What Claude can and cannot do here

- Can: everything above, plus list, filter, explain, compare before/after, summarise what is
  waiting for whom, draft the email to a finance manager about a `needs_review` request (include
  the `url`), and check the history when someone asks "did this go in?". Reviewers can also
  `review_costing_change` (mark ready, send back, cancel) from here.
- Cannot: press Save in PeopleSoft, sign in for the person, or change a request's status without
  their yes. Writes without `confirm: true` only preview.
- Never read or infer pay rates, salaries or hours; they are deliberately absent.

## Typical asks

- "What's waiting for me?" → `list_costing_changes` with `status: ["ready"]`, group by employee,
  mention blackout if set, give the `url` of each.
- "Why is Rebecca's change stuck?" → `list_costing_changes` with `search: "Rebecca"`, then
  `get_costing_change`; quote `errors`, `warnings`, `review_note` and the last `history` entry.
- "Did the change for HUID 81657165 go through?" → search by HUID; `submitted`/`backup_filed`
  plus `confirmed_in_peoplesoft_at` answers yes; `staged` means Beth has not pressed Save yet.
- "What exactly do I type for #12?" → `get_costing_change` and read out `ps_fill_spec`.

---
name: costing-changes
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
it). Both tools are read-only.

| Tool | Use it for |
|---|---|
| `list_costing_changes` | The queue. Default = every open request. `status: ["ready"]` for what can go into PeopleSoft now; `status: ["needs_review"]` for what a finance manager must fix; `search` by employee name, HUID, requester or id. Also returns `counts_by_status`. |
| `get_costing_change` | One request: current vs requested distribution, the diff, validation `errors` and `warnings`, `review_note`, `payroll_blackout`, `ps_fill_spec` (what to key into PeopleSoft), `history` (who did what, when), and `url` of the review page. |

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

## What Claude can and cannot do here

- Can: list, filter, explain, compare before/after, summarise what is waiting for whom, draft
  the email to a finance manager about a `needs_review` request (include the `url`), prepare the
  numbers Beth will key, and check the history when someone asks "did this go in?".
- Cannot: mark ready, send back, cancel, claim, stage or submit. Those happen on the review page
  (`url`) or through the PeopleSoft plugin. Say which, and link the page.
- Never read or infer pay rates, salaries or hours; they are deliberately absent.

## Typical asks

- "What's waiting for me?" → `list_costing_changes` with `status: ["ready"]`, group by employee,
  mention blackout if set, give the `url` of each.
- "Why is Rebecca's change stuck?" → `list_costing_changes` with `search: "Rebecca"`, then
  `get_costing_change`; quote `errors`, `warnings`, `review_note` and the last `history` entry.
- "Did the change for HUID 81657165 go through?" → search by HUID; `submitted`/`backup_filed`
  plus `confirmed_in_peoplesoft_at` answers yes; `staged` means Beth has not pressed Save yet.
- "What exactly do I type for #12?" → `get_costing_change` and read out `ps_fill_spec`.

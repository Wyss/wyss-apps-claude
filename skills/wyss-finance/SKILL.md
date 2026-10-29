---
name: wyss-finance
description: Institute-wide Wyss finance answers from the general ledger and GMAS - "how much IDC did Ingber generate in FY26", "sponsored spend by sponsor this year", "payroll vs non-payroll", "how are we doing year to date vs last year", "how many proposals are pending, federal vs non-federal", "success rate by faculty or by funder", "how much new money did we ask for", "how much of our awards is obligated", plus charts, tables and spreadsheets of any of these. Use for any money question across the Institute, a sponsor, a faculty member's whole portfolio or a category of spend, rather than one grant.
---

# Wyss finance

Finance questions across the Institute are answered with `query_finance`: one read-only SQL
statement against the finance views, at most 500 rows back. This file is everything needed to
write that SQL correctly and to say what the numbers mean. For one grant in depth use
`sponsored_project_lookup`; for one faculty member's submitted / awarded / declined record use
`faculty_view`. Call `wyss_guide` (topic finance) if this file is not loaded.

## Before anything (silent when it passes)

Call `whoami` once per session before the first answer. If it answers, say nothing about setup
and do the work. If `whoami` answers with `plugin.update_available` true, add one line, its `plugin.update` text, and go on. If it fails, its message already says the one thing to do (missing token,
expired token, not on the VPN, account without access): repeat that sentence and stop. If the
Wyss Apps tools are missing altogether, say both causes and stop: this Cowork session may be
running in the cloud, where the plugin cannot run (Settings, Cowork, turn off "Run new tasks in
the cloud", then start a new session), or the plugin is not enabled for this chat (Customize,
Plugins, add `https://github.com/Wyss/wyss-apps-claude` and enable it).
The person does not need to know Wyss Apps: no tool names, no permission talk beyond "you do
not have access to <thing>; ask Matthew Laubach". Lead with the result.

If `whoami` shows no financial access, or `query_finance` refuses for access, say "You do not
have access to the Institute's finance data; ask Matthew Laubach." and stop.

## How to answer

- **Lead with the answer in dollars and dates**, one or two sentences: "Sponsored spending in
  FY2026 was $44.3M, of which $14.7M was indirect costs." Round in prose ($44.3M, $1.25M,
  $18,212); tables can show whole dollars.
- **Say how fresh the data is**, every time: "Data as of this morning's 7:22 AM ET refresh;
  transactions posted through Sep 23, 2026." Run query F first in a conversation. If the
  refresh is not today, say so.
- **Name the fiscal year and its months**: "FY2026 (July 2025 to June 2026)".
- **Give the definition used in one short line** ("spend = actual expenses posted, including
  indirect costs on sponsored awards") and any caveat that changes the reading (month not closed,
  spend not linked to a project).
- No SQL, column names, table names or tool names unless asked: say "the general ledger" and
  "GMAS". If a query fails because of the SQL, fix it and retry without mentioning it.
- At most about 15 to 20 rows in the chat. For longer lists offer a spreadsheet (see Charts,
  tables and spreadsheets).
- If the data cannot answer, say so and what is missing (see What this data cannot answer).
  Never estimate or fill gaps and present it as data.
- A figure that looks odd (negative, very large) gets one sentence: credits, reversals, cost
  transfers, the indirect-cost offset.
- **People**: report totals and counts of people. Names and Harvard IDs of people paid are never
  returned; count people with `COUNT(DISTINCT univ_id)`.
- "This year" is the current **fiscal** year unless they say calendar year; say which. Answer the
  most likely reading of an ambiguous question and state it, with one exception:
- **Which projects?** Finance says **WIGT** for sponsored projects (grants and contracts in GMAS)
  and **Wyss projects** for internal ones (WP numbers). When listing or counting someone's
  projects and the scope is not clear, ask once: "WIGT (sponsored) projects, Wyss internal
  projects, or both?" Do not ask when the topic implies WIGT: IDC, sponsors, federal,
  proposals, pending, awards and success rates exist only for WIGT. With "both", show the two
  groups separately.
- **Names**: match loosely, forgive typos. Search on the last name
  (`faculty_name ILIKE '%ingber%'`); if nothing matches, list
  `SELECT DISTINCT faculty_name FROM wyss_apps_all_projects ORDER BY 1`, pick the closest and say
  so ("I took 'Ignber' to mean Donald Ingber"). Then filter on the exact name. Two possible
  people: ask which.

## Fiscal year and periods

- Harvard's fiscal year runs **July to June**, named for the year it ends: **FY2026 = July 1,
  2025 to June 30, 2026**. Period 1 = July ... period 12 = June. Fiscal quarter `quarter_no`:
  Q1 = Jul to Sep.
- Current fiscal year in SQL: `EXTRACT(YEAR FROM CURRENT_DATE + INTERVAL '6 months')::int`.
- Period number: `fiscal_period_order % 100` (`fiscal_period_order` is YYYYPP, `202603`). Month
  label: `period_name` (`JUL-25`). Do not use `fiscal_year_period_no` (text like `'1.0'`).
- **"August 2026" means the accounting period** (`period_name = 'AUG-26'`), not posting dates.
  Say so when it matters.
- **Month close**: postings for a month keep arriving 1 to 2 weeks after it ends (longer for
  July, December and June; year-end runs to late July). The current month is always "month to
  date"; the previous month is "essentially complete", not final (the last two months are
  re-pulled every morning). Year-over-year compares **the same closed periods** in both years
  (query 8), never a partial month.
- **Single months are lumpy**, payroll especially. Before calling a change a trend, compare
  several months or the year to date, and say which.
- Everything refreshes **every morning** from about 7:15 AM ET (done by about 7:30 to 7:50).

## What the money means

- Every transaction row is an **actual expense posting** from Harvard's general ledger for the
  Wyss Institute's funds (tub 635, plus a few lines elsewhere), FY2010 onward (FY2009 partial).
  **No budgets, forecasts, commitments, open POs, revenue or gift receipts.**
- `transaction_amount`: positive = expense, negative = credit (refund, reversal, cost transfer).
  Always sum including negatives.
- **Sponsored vs non-sponsored**: `sponsored = 'S'` is a sponsored fund (grants and contracts);
  `sponsored IS NULL` is non-sponsored (gifts, endowment, institutional and Harvard funds).
- **Direct vs indirect**: `expense_type` is `'MTDC'` (direct costs that carry overhead),
  `'NonMTDC'` (direct costs exempt from overhead: equipment, large subawards, rent) or `'IDC'`
  (indirect costs, overhead).
- **The IDC offset (important)**: IDC charged to each sponsored fund is credited back, negative,
  on the Institute's own funds (mainly fund `000001`, object `8400`). Across the Institute the
  IDC lines cancel to about zero. So:
  - **Sponsored, project, sponsor or faculty questions**: include IDC (a real cost to the award)
    and show direct and indirect separately.
  - **Institute-wide totals**: leave IDC out (`expense_type IS DISTINCT FROM 'IDC'`) and call it
    "direct spend". The total is the same; it just avoids a confusing negative.
- **Payroll** = `giga_object = 'G601'` (Salaries+Wages) plus `'G624'` (Employee Benefits).
  Everything else is non-payroll. Scholarships and stipends (`G640`) are separate; say so if they
  matter.
- **Expense categories** (`giga_object_name`): G601 Salaries+Wages, G624 Employee Benefits, G640
  Scholarships+Awards, G650 Supplies, Materials+Equipment, G709 Space+Occupancy (rent), G755
  Capital-Related (depreciation), G760 Other Expenses (services, travel, subcontracts), G887
  Expense Credits, G890 Transfers. Finer: `mega_object_name`, then `object_name`.
- **Sponsor** (sponsored only): `seg_sponsor_name` is the **direct sponsor** (who Harvard's award
  is with, for example MIT); `primary_sponsor_name` is the **prime sponsor** (the original
  funder, for example NIH through MIT). "By sponsor" defaults to the direct sponsor; mention the
  prime where it differs.
- **Award** (sponsored only), the figure the app shows as awarded:
  `CASE WHEN use_wyss_anticipated_amounts THEN wyss_anticipated_total ELSE wigt_anticipated_total END`
  (direct + indirect, whole segment). On transaction rows it **repeats on every row**: take
  `MAX` per project, never `SUM`. **An award of $0 is not an overspend**: the Wyss override can be
  on with no amount entered; say "award amount not entered in Wyss Apps (GMAS shows $X)" from
  `wigt_anticipated_total`. When the override and GMAS differ by more than about 10%, show both
  and say which the percentage uses (the override is often the Wyss share only).
- **Faculty**: `faculty_name` is the Wyss faculty lead on the project (falling back to the GMAS
  PI); it exists only on transactions linked to a sponsored project. It can differ from the GMAS
  PI `project_wigt_pi` ("Last, First"). Non-sponsored spend (about half of all spend) has **no
  project or faculty**: analyse it by fund (`fund_name`), area (`org_name`) or category.
- **Area**: `org_name` (Administration, Shared Research, Synthetic Biology ...). Sponsored spend
  mostly sits in "Sponsored Research"; for sponsored work by platform use the project's
  `platform_initiatives`.
- Tidy-up: some names start with a space: `TRIM()` when grouping or showing. ` ? ` in a name is a
  lost character (almost always a dash): write a dash in prose, keep the stored text in filters.
- **Sponsored lines with no sponsor** can be negative: credits on capital-equipment contra funds
  (fund names starting FG, NE or NG), about -$0.76M in FY2026. Label them so, and give "spend
  charged to projects" (the total without them) next to the net sponsored total.

### IDC, what finance watches most

IDC (indirect costs, overhead, F&A) is the part of each sponsored award that pays for the
Institute's administration and facilities.

- **"IDC generated"** by a person, sponsor or project = `SUM(transaction_amount)` with
  `sponsored = 'S' AND expense_type = 'IDC'`, net of credits. Always filter `sponsored = 'S'`;
  that leaves out the offset.
- **By faculty**: `faculty_name = '<exact name>'`. This credits IDC to the Wyss faculty lead, as
  the Wyss Apps pages do, including projects where a staff scientist is the GMAS PI.
- Show the **direct spend** that generated it and the number of projects. Effective rate =
  IDC ÷ MTDC direct spend; negotiated account rates are in `idc_rate`.
- **Year to date** = current fiscal year, all periods posted so far: name the months, say "posted
  through <date>", note the current month is open. "Up on last year?": same closed periods.
- **Future IDC**: pending proposals carry proposed IDC; a fair expectation is proposed IDC ×
  expected success rate (query P6). Proposed amounts cover the **whole proposed project period**
  (several years), and awards are often cut.
- Low IDC against direct spend is often real (many foundations cap or refuse overhead), not
  missing data.

## Proposals, pending and success rates (WIGT only)

Source: `wigt_projects`, one row per GMAS proposal (about 1,480). Join the project list for the
faculty name and the funder-type tables for federal / non-federal.

- **Outcome** `success_status`: `1` successful (Active, Completed, Closed), `0` unsuccessful (Not
  Funded, Cancelled, Terminated), `2` pending.
- **Pending** = `success_status = 2` (87 on 2026-09-28). Mention two groups (query P2 counts
  both): **no submission date yet** (still being prepared: "in the pipeline") and **submitted over
  a year ago** (probably never updated in GMAS).
- **When**: `wigt_projects.fiscal_year` is the fiscal year the proposal was **submitted**
  (`date_submitted`). Decisions: `segment_award_date`, `segment_reject_date`.
- **Amounts** (whole project period, direct + indirect). Proposed:
  `CASE WHEN use_wyss_proposed_amounts THEN wyss_proposed_total ELSE wigt_proposed_total END`
  (same for `_direct` / `_indirect`). Awarded:
  `CASE WHEN use_wyss_anticipated_amounts THEN wyss_anticipated_total ELSE wigt_anticipated_total END`.
  The award caveats above apply. Pending proposals have no award.
- **Federal vs non-federal**: funder type `fs.name` from the funder-type tables. Federal types
  start `DHHS` (NIH, ARPA-H, BARDA, FDA, Other), `DOD`, `DOE`, `DOT`, `IARPA`, `NASA`, `NSF`;
  `Foundation / Other Non-Profit`, `Industry / For Profit`, `Other External` are non-federal.
  Many new proposals have no funder type yet and a few are mis-tagged, so count **federal if the
  funder type, the prime sponsor or the direct sponsor is federal**, with this expression:

  ```sql
  (COALESCE(fs.name, '') ~ '^(DHHS|DOD|DOE|DOT|IARPA|NASA|NSF)'
   OR COALESCE(w.primary_sponsor_name, '') ~* '^(NIH|DHHS|Office of the Director, NIH|U\.?S\.? |United States Department|Department of (Defense|Energy|the Army|the Navy)|Defense (Advanced|Health|Threat)|Advanced Research Projects Agency|Air Force|Army Research|Office of Naval Research|NASA|National Science Foundation$|Intelligence Advanced|Central Intelligence|CDC|FDA|Veterans Health|National Institute of Food|Interior Business Center)|National Laborator'
   OR COALESCE(w.seg_sponsor_name, '') ~* '^(NIH|DHHS|Office of the Director, NIH|U\.?S\.? |United States Department|Department of (Defense|Energy|the Army|the Navy)|Defense (Advanced|Health|Threat)|Advanced Research Projects Agency|Air Force|Army Research|Office of Naval Research|NASA|National Science Foundation$|Intelligence Advanced|Central Intelligence|CDC|FDA|Veterans Health|National Institute of Food|Interior Business Center)|National Laborator') AS federal
  ```

  Federal money through another organisation counts as federal. State (MLSC), foreign
  government and university money is non-federal. When the answer depends on proposals with no
  funder type, say how many, how many were federal by sponsor name, and that the rest were
  counted as non-federal.
- **Success rate** = successful ÷ decided (`success_status IN (0, 1)`; pending left out). State
  the defaults in the answer:
  - Count proposals, not dollars (offer awarded $ ÷ proposed $ of decided proposals).
  - **Window**: proposals submitted in the **last five complete fiscal years** (FY2022 to FY2026
    while FY2027 is current); "based on historicals" means this. Show all years beside it. The
    latest year can look better than it will end up (late-recorded rejections).
  - **Faculty**: by default those with at least 10 decided proposals in the window, most first;
    say how many others there are and offer the full list.
  - Always show **how many decided proposals** each rate rests on.
  - **Expected rate** per faculty member or sponsor blends the record with the Institute rate as
    if they had 5 more proposals at that rate: `(wins + 5 × institute_rate) / (decided + 5)`. One
    line: "adjusted toward the Institute average of 32% where the record is short". Under about 10
    decided, say the record is too short to judge.
  - **By sponsor**: default to funder type (groups NIH's institutes). For named sponsors use
    `primary_sponsor_name`, only those with at least 5 decided.
  - Fellowships (`research_type_desc = 'Fellowship'`) are credited to the faculty mentor: offer to
    leave them out when comparing faculty.

### Obligated vs awarded

"Awarded" is the whole-period award; **obligated** (`wigt_obligated_direct/_indirect/_total`,
GMAS only) is what the sponsor has formally committed so far. NIH funds a budget year at a time
and ARPA-H / DARPA in milestones, so active awards are often partly obligated: timing, not a
shortfall. Compare obligated with GMAS `wigt_anticipated_*`, never the Wyss override. Awards =
`success_status = 1`; lead with active awards (`is_active` on the project list), then all time
(Oct 2026: active 103 awards, $222.7M obligated of $273.7M, 81%). On a closed award the gap is
money that never came.

### GMAS requests (asked for, supplemented, awarded)

- `wigt_requests`: one row per GMAS request (initial, supplement, continuation, renewal,
  change). Asked for = `total_proposed_direct_amt + total_proposed_indirect_amt` (whole period).
- **New money = `request_type_cd IN ('IR', 'S', 'R')`** (initial, supplement, competing renewal).
  **Never add `C`** (continuation: the next slice of money already awarded) or `IRPV` / `RPV`
  (prior versions: double counting). `E`, `CRT`, `ERT`, `I`, `INTL`, `JIT`, `CS` are never asks.
- **Year** of a request = fiscal year of `request_sent_date`, else `req_create_date`. Status:
  `request_status_group` (Awarded, Submitted, Rejected by Sponsor, Withdrawn; blank = not sent).
- "Segment PI" is `wigt_projects.wigt_pi` (the request's own PI field is often blank); show the
  Wyss faculty lead when it differs.
- `wigt_award_revisions`: each applied change to a segment's award;
  `anticipated_direct/_indirect` and `obligated_direct/_indirect` are the **change** (can be
  negative). Count `revision_status_desc = 'Applied'`, date by `committed_date`.
- Awards for a request: `wigt_award_revisions v JOIN wigt_notice_requests nr ON nr.dw_notice_key = v.dw_notice_key WHERE nr.dw_request_key = r.dw_request_key`,
  plus revisions with `v.dw_internal_request_key = r.dw_request_key`; `DISTINCT v.dw_revision_key`
  before adding across requests. Show asked for, awarded (anticipated change) and obligated.
- `wigt_request_investigators`: who GMAS names on each request (`last_name`, `first_name`,
  `role_cd`: PI, RTCOI co-investigator, RTCOPIINV co-PI, RTPI mentor). Join on `dw_request_key`.
- These four join `wigt_projects` on `dw_segment_key`. Sponsored funds starting with 1 are
  federal, with 2 non-federal.

## The views

| View | What it is | Key columns |
|---|---|---|
| `wyss_apps_active_projects` | Every active project, sponsored and Wyss (about 324) | `source` (`'sponsored'` / `'wyss'`), `project_key` (GMAS `8952233-01` or `WP-2025-00418`; the stable id with `source`), `display_name`, `faculty_name` ("First Last", may be blank), `fund_number`, `funding_source` (sponsored: prime sponsor; wyss: its funding pools), `platform_initiatives`, `status`, `refreshed_at` (UTC) |
| `wyss_apps_all_projects` | Same columns for every project, any status, plus `is_active` | For "how many active", filter `is_active`, never `status = 'Active'` (Wyss projects need an active funding source too). No dollars: join `wigt_projects` |
| `wyss_apps_transaction_details` | Every expense line, about 2M rows, 236 columns, 6 GB | When: `fiscal_year`, `fiscal_period_order`, `period_name`, `quarter_no`, `posted_date`. Amount: `transaction_amount`. Kind: `sponsored`, `expense_type`. On: `giga_object(_name)`, `mega_object_name`, `object_name`. Chart of accounts: `org_name`, `fund`, `fund_name`, `fund_category_description`. Paid to: `vendor_name`. Project (sponsored only): `project_number`, `title`, `faculty_name`, `project_wigt_pi`, `seg_sponsor_name`, `primary_sponsor_name`, `effective_status`, `seg_anticipated_start_date` / `_end_date`, award columns, `platform_initiatives`, `grand_challenges`. Account: `account_id`, `allocated_amt`, `idc_rate` |
| `wigt_projects` | Every sponsored proposal and award (about 1,480) | `project_number` (= `project_key`), `title`, `wyss_name`, `status` / `wyss_status` (effective = `COALESCE(NULLIF(wyss_status, ''), status)`), `success_status`, `fiscal_year`, `date_submitted`, decision and period dates, sponsors, `wigt_proposed_*`, `wigt_anticipated_*`, `wigt_obligated_*`, `wyss_*` overrides and their `use_wyss_*` switches, `selected_for_funding`, `wigt_pi`, `research_type_desc`, `fund`; `id` only for joining |
| `funding_sources` + `funding_sources_wigt_projects` | Funder type per proposal | `LEFT JOIN funding_sources_wigt_projects j ON j.wigt_project_id = w.id LEFT JOIN funding_sources fs ON fs.id = j.funding_source_id`; `fs.name` |
| `wigt_requests`, `wigt_award_revisions`, `wigt_award_notices`, `wigt_notice_requests`, `wigt_request_investigators` | GMAS requests and the award chain | As above |

**Joins**: proposals to the project list `w.project_number = a.project_key AND a.source = 'sponsored'`;
transactions to projects `t.project_number = p.project_key AND p.source = 'sponsored'`;
proposals to transactions `t.project_number = w.project_number`. **Never join transactions on
`dw_segment_key`** (empty for several years on the transaction view). Internal Wyss projects
have **no link to transactions**: their spending cannot be attributed (only their funding pool,
by `fund_name`).

## Query rules (each query stops at 20 seconds)

1. Aggregate in SQL (`GROUP BY`, `SUM`, `COUNT`); never pull raw rows to add up.
2. **Always filter transactions by `fiscal_year`** (indexed). For life-to-date on particular
   projects, pre-filter by `fund` as in query 4. Unfiltered scans are slow and may time out.
3. Name the columns: no `SELECT *` (person columns and whole rows are refused anyway).
4. One statement per call, `SELECT` or `WITH` only; literals in single quotes (no `$$`).
5. More than 500 rows means the query should aggregate further.

## What this data cannot answer (say so plainly)

Budgets, forecasts or budget vs actual; commitments, encumbrances, open POs, fund balances, cash,
revenue or gift receipts; spending by internal Wyss project or by faculty for non-sponsored money
(only by fund, area or category); headcount, FTEs, titles or HR data (distinct people paid can be
counted); anything outside the Wyss Institute's funds.

## Worked queries

Replace the fiscal years as needed. Figures in brackets are sanity checks from production on the
date given, not answers: always run the query.

**F. Freshness (first in a conversation).**

```sql
SELECT (SELECT MAX(refreshed_at) AT TIME ZONE 'UTC' AT TIME ZONE 'America/New_York' FROM wyss_apps_active_projects) AS projects_refreshed_et,
       (SELECT MAX(posted_date) FROM wyss_apps_transaction_details
         WHERE fiscal_year = EXTRACT(YEAR FROM CURRENT_DATE + INTERVAL '6 months')::int) AS posted_through,
       EXTRACT(YEAR FROM CURRENT_DATE + INTERVAL '6 months')::int AS current_fiscal_year
```

**1. Total spend, sponsored vs non-sponsored, direct vs indirect** (the two IDC figures cancel).

```sql
SELECT CASE WHEN sponsored = 'S' THEN 'Sponsored' ELSE 'Non-sponsored' END AS funding_type,
       SUM(transaction_amount) FILTER (WHERE expense_type IS DISTINCT FROM 'IDC') AS direct_spend,
       SUM(transaction_amount) FILTER (WHERE expense_type = 'IDC') AS indirect_idc,
       SUM(transaction_amount) AS total
FROM wyss_apps_transaction_details WHERE fiscal_year = 2026 GROUP BY 1 ORDER BY 1
```

**2. Sponsored spend by sponsor** (about 70; show the top 15). Prime sponsor: `primary_sponsor_name`.

```sql
SELECT COALESCE(seg_sponsor_name, '(not matched to a GMAS project)') AS sponsor,
       COUNT(DISTINCT project_number) AS projects,
       SUM(transaction_amount) FILTER (WHERE expense_type IS DISTINCT FROM 'IDC') AS direct_spend,
       SUM(transaction_amount) FILTER (WHERE expense_type = 'IDC') AS indirect_spend,
       SUM(transaction_amount) AS total_spend
FROM wyss_apps_transaction_details WHERE fiscal_year = 2026 AND sponsored = 'S'
GROUP BY 1 ORDER BY total_spend DESC
```

**3. Sponsored spend and IDC by faculty, this fiscal year to date.** For one person use P1.

```sql
SELECT COALESCE(faculty_name, '(not linked to a project)') AS faculty,
       COUNT(DISTINCT project_number) AS projects,
       SUM(transaction_amount) FILTER (WHERE expense_type IS DISTINCT FROM 'IDC') AS direct_spend,
       SUM(transaction_amount) FILTER (WHERE expense_type = 'IDC') AS idc,
       SUM(transaction_amount) AS total_spend
FROM wyss_apps_transaction_details
WHERE fiscal_year = EXTRACT(YEAR FROM CURRENT_DATE + INTERVAL '6 months')::int AND sponsored = 'S'
GROUP BY 1 ORDER BY total_spend DESC
```

**P1. IDC generated by one faculty member, last full year and this year to date.** [Donald
Ingber: FY2026 $6.26M IDC on $13.17M direct, 41 projects (2026-09-28).]

```sql
SELECT fiscal_year,
       SUM(transaction_amount) FILTER (WHERE expense_type = 'IDC') AS idc,
       SUM(transaction_amount) FILTER (WHERE expense_type IS DISTINCT FROM 'IDC') AS direct,
       COUNT(DISTINCT project_number) AS projects,
       MAX(fiscal_period_order % 100) AS last_period, MAX(posted_date) AS posted_through
FROM wyss_apps_transaction_details
WHERE fiscal_year IN (2026, 2027) AND sponsored = 'S' AND faculty_name = 'Donald Ingber'
GROUP BY fiscal_year ORDER BY fiscal_year
```

**4. Burn vs award, active sponsored projects, life to date.** `pct_spent` well ahead of
`pct_time_elapsed` = spending faster than the period; an `award_total` of 0 with a
`gmas_award_total` = award not entered, not an overspend.

```sql
WITH active AS (SELECT project_key, display_name, faculty_name, fund_number
                FROM wyss_apps_active_projects WHERE source = 'sponsored'),
to_date AS (
  SELECT project_number, MAX(seg_sponsor_name) AS sponsor,
         MAX(CASE WHEN use_wyss_anticipated_amounts THEN wyss_anticipated_total ELSE wigt_anticipated_total END) AS award_total,
         MAX(wigt_anticipated_total) AS gmas_award_total, SUM(transaction_amount) AS spent_to_date,
         MIN(seg_anticipated_start_date) AS start_date, MAX(seg_anticipated_end_date) AS end_date
  FROM wyss_apps_transaction_details
  WHERE fund = ANY (ARRAY(SELECT fund_number FROM active)) AND project_number = ANY (ARRAY(SELECT project_key FROM active))
  GROUP BY project_number)
SELECT a.project_key, a.display_name, a.faculty_name, d.sponsor, d.award_total, d.gmas_award_total, d.spent_to_date,
       d.award_total - d.spent_to_date AS remaining,
       ROUND(100 * d.spent_to_date / NULLIF(d.award_total, 0), 1) AS pct_spent,
       ROUND(100.0 * (CURRENT_DATE - d.start_date) / NULLIF(d.end_date - d.start_date, 0), 1) AS pct_time_elapsed, d.end_date
FROM active a LEFT JOIN to_date d ON d.project_number = a.project_key
ORDER BY pct_spent DESC NULLS LAST
```

**6. Payroll vs non-payroll** (direct spend), and people paid without names.

```sql
SELECT CASE giga_object WHEN 'G601' THEN 'Payroll: salaries and wages' WHEN 'G624' THEN 'Payroll: employee benefits'
                        ELSE 'Non-payroll' END AS category,
       SUM(transaction_amount) FILTER (WHERE sponsored = 'S') AS sponsored,
       SUM(transaction_amount) FILTER (WHERE sponsored IS NULL) AS non_sponsored,
       SUM(transaction_amount) AS total,
       COUNT(DISTINCT univ_id) FILTER (WHERE giga_object = 'G601') AS people_paid
FROM wyss_apps_transaction_details WHERE fiscal_year = 2026 AND expense_type IS DISTINCT FROM 'IDC'
GROUP BY 1 ORDER BY 1
```

**7. Month by month.** By category: add `giga_object_name` to the select and group.

```sql
SELECT fiscal_period_order % 100 AS period, period_name AS month,
       SUM(transaction_amount) FILTER (WHERE expense_type IS DISTINCT FROM 'IDC') AS direct_spend,
       SUM(transaction_amount) FILTER (WHERE sponsored = 'S') AS sponsored_incl_idc,
       MAX(posted_date) AS last_posted
FROM wyss_apps_transaction_details WHERE fiscal_year = 2026 GROUP BY 1, 2 ORDER BY 1
```

**8. Year to date vs the same closed months last year** (here periods 1 to 2: set the last closed
period from query F). Five-year trend: `fiscal_year BETWEEN 2022 AND 2026`, no period filter.

```sql
SELECT fiscal_year,
       SUM(transaction_amount) FILTER (WHERE expense_type IS DISTINCT FROM 'IDC') AS direct_spend,
       SUM(transaction_amount) FILTER (WHERE sponsored = 'S') AS sponsored_incl_idc,
       SUM(transaction_amount) FILTER (WHERE giga_object IN ('G601', 'G624')) AS payroll
FROM wyss_apps_transaction_details
WHERE fiscal_year IN (2026, 2027) AND fiscal_period_order % 100 <= 2
GROUP BY fiscal_year ORDER BY fiscal_year
```

**11. Direct spend by area** (`TRIM(org_name)`), by category (`giga_object_name`) or top vendors
(`vendor_name`, add `AND giga_object <> 'G709'` to leave out rent): the same shape as query 1,
grouped by that column.

**P2. Pending proposals, federal vs non-federal.** [87 pending on 2026-09-28: 41 federal, 46
non-federal; 27 with no funder type, 10 of them federal by sponsor name; 17 not yet submitted;
10 submitted over a year ago.] For the list itself, select the proposal columns with the
project list's `faculty_name` instead of grouping, largest first.

```sql
WITH p AS (
  SELECT w.date_submitted, fs.name AS funder_type,
         CASE WHEN w.use_wyss_proposed_amounts THEN w.wyss_proposed_total ELSE w.wigt_proposed_total END AS proposed_total,
         CASE WHEN w.use_wyss_proposed_amounts THEN w.wyss_proposed_indirect ELSE w.wigt_proposed_indirect END AS proposed_idc,
         <the federal expression above>
  FROM wigt_projects w
  LEFT JOIN funding_sources_wigt_projects j ON j.wigt_project_id = w.id
  LEFT JOIN funding_sources fs ON fs.id = j.funding_source_id
  WHERE w.success_status = 2)
SELECT CASE WHEN federal THEN 'Federal' ELSE 'Non-federal' END AS funder,
       COUNT(*) AS pending, SUM(proposed_total) AS proposed_total, SUM(proposed_idc) AS proposed_idc,
       COUNT(*) FILTER (WHERE funder_type IS NULL) AS no_funder_type,
       COUNT(*) FILTER (WHERE funder_type IS NULL AND federal) AS no_funder_type_but_federal,
       COUNT(*) FILTER (WHERE date_submitted IS NULL) AS not_yet_submitted,
       COUNT(*) FILTER (WHERE date_submitted < CURRENT_DATE - INTERVAL '12 months') AS submitted_over_a_year_ago
FROM p GROUP BY 1 ORDER BY 1
```

**P4. Success rate by faculty member**, submitted FY2022 to FY2026, with the expected rate and
all years. [Institute 32.1%; Donald Ingber 51 of 136 = 37.5% (2026-09-28).] Drop the `HAVING`
for everyone.

```sql
WITH decided AS (
  SELECT NULLIF(TRIM(a.faculty_name), '') AS faculty, w.success_status, w.fiscal_year BETWEEN 2022 AND 2026 AS recent
  FROM wigt_projects w JOIN wyss_apps_all_projects a ON a.source = 'sponsored' AND a.project_key = w.project_number
  WHERE w.success_status IN (0, 1)),
overall AS (SELECT AVG(success_status::numeric) AS rate FROM decided WHERE recent)
SELECT COALESCE(d.faculty, '(no faculty listed)') AS faculty,
       COUNT(*) FILTER (WHERE recent) AS decided, SUM(d.success_status) FILTER (WHERE recent) AS awarded,
       ROUND(100.0 * SUM(d.success_status) FILTER (WHERE recent) / NULLIF(COUNT(*) FILTER (WHERE recent), 0), 1) AS historical_pct,
       ROUND(100.0 * (COALESCE(SUM(d.success_status) FILTER (WHERE recent), 0) + 5 * o.rate) / (COUNT(*) FILTER (WHERE recent) + 5), 1) AS expected_pct,
       COUNT(*) AS decided_all_years, ROUND(100.0 * SUM(d.success_status) / COUNT(*), 1) AS all_years_pct,
       ROUND(100 * o.rate, 1) AS institute_pct
FROM decided d CROSS JOIN overall o
GROUP BY 1, o.rate HAVING COUNT(*) FILTER (WHERE recent) >= 10 ORDER BY decided DESC
```

**P5. Success rate by funder type**, same window. [Foundation 34.6% of 153, NIH 25.0% of 104,
Industry 55.8% of 52.] Named sponsors: group by `w.primary_sponsor_name`, `HAVING COUNT(*) >= 5`.

```sql
SELECT COALESCE(fs.name, '(no funder type)') AS funder_type, COUNT(*) AS decided, SUM(w.success_status) AS awarded,
       ROUND(100.0 * SUM(w.success_status) / COUNT(*), 1) AS success_pct
FROM wigt_projects w
LEFT JOIN funding_sources_wigt_projects j ON j.wigt_project_id = w.id
LEFT JOIN funding_sources fs ON fs.id = j.funding_source_id
WHERE w.success_status IN (0, 1) AND w.fiscal_year BETWEEN 2022 AND 2026
GROUP BY 1 ORDER BY decided DESC
```

**P6. Expected IDC from pending proposals**: proposed IDC × the expected rate for its funder type.

```sql
WITH decided AS (
  SELECT COALESCE(fs.name, '(no funder type)') AS funder_type, w.success_status
  FROM wigt_projects w LEFT JOIN funding_sources_wigt_projects j ON j.wigt_project_id = w.id
  LEFT JOIN funding_sources fs ON fs.id = j.funding_source_id
  WHERE w.success_status IN (0, 1) AND w.fiscal_year BETWEEN 2022 AND 2026),
overall AS (SELECT AVG(success_status::numeric) AS rate FROM decided),
hist AS (SELECT funder_type, COUNT(*) AS n, SUM(success_status) AS wins FROM decided GROUP BY 1),
pending AS (
  SELECT COALESCE(fs.name, '(no funder type)') AS funder_type,
         CASE WHEN w.use_wyss_proposed_amounts THEN w.wyss_proposed_indirect ELSE w.wigt_proposed_indirect END AS proposed_idc
  FROM wigt_projects w LEFT JOIN funding_sources_wigt_projects j ON j.wigt_project_id = w.id
  LEFT JOIN funding_sources fs ON fs.id = j.funding_source_id WHERE w.success_status = 2)
SELECT p.funder_type, COUNT(*) AS pending, SUM(p.proposed_idc) AS proposed_idc,
       ROUND(100 * (COALESCE(h.wins, 0) + 5 * o.rate) / (COALESCE(h.n, 0) + 5), 1) AS expected_success_pct,
       ROUND(SUM(p.proposed_idc) * (COALESCE(h.wins, 0) + 5 * o.rate) / (COALESCE(h.n, 0) + 5)) AS expected_idc
FROM pending p CROSS JOIN overall o
LEFT JOIN hist h ON h.funder_type = p.funder_type AND p.funder_type <> '(no funder type)'
GROUP BY p.funder_type, h.n, h.wins, o.rate ORDER BY proposed_idc DESC NULLS LAST
```

**P7. One person's projects** (after asking WIGT, Wyss or both).

```sql
SELECT a.source, a.project_key, a.display_name, a.status, a.is_active, a.funding_source,
       w.fiscal_year AS submitted_fy, fs.name AS funder_type,
       CASE WHEN w.use_wyss_proposed_amounts THEN w.wyss_proposed_total ELSE w.wigt_proposed_total END AS proposed_total,
       CASE WHEN w.use_wyss_anticipated_amounts THEN w.wyss_anticipated_total ELSE w.wigt_anticipated_total END AS award_total
FROM wyss_apps_all_projects a
LEFT JOIN wigt_projects w ON a.source = 'sponsored' AND w.project_number = a.project_key
LEFT JOIN funding_sources_wigt_projects j ON j.wigt_project_id = w.id
LEFT JOIN funding_sources fs ON fs.id = j.funding_source_id
WHERE a.faculty_name ILIKE '%artzi%'
ORDER BY a.source, a.is_active DESC, w.fiscal_year DESC NULLS LAST, a.display_name
```

**R1. Requests of one type sent in a fiscal year** (here supplements, FY2026), with the segment
PI and fund. New money overall: `request_type_cd IN ('IR', 'S', 'R')`.

```sql
SELECT r.request_type_cd, r.request_status_group, w.project_number, w.wigt_pi AS segment_pi, w.fund,
       r.request_sent_date, r.total_proposed_direct_amt + r.total_proposed_indirect_amt AS asked_for
FROM wigt_requests r JOIN wigt_projects w ON w.dw_segment_key = r.dw_segment_key
WHERE r.request_type_cd = 'S'
  AND EXTRACT(YEAR FROM COALESCE(r.request_sent_date, r.req_create_date) + INTERVAL '6 months') = 2026
ORDER BY asked_for DESC
```

**O1. Obligated vs awarded**, active awards and all time.

```sql
SELECT CASE WHEN a.is_active THEN 'Active awards' ELSE 'Not active' END AS awards, COUNT(*) AS n,
       SUM(w.wigt_obligated_total) AS obligated, SUM(w.wigt_anticipated_total) AS awarded_gmas,
       ROUND(100 * SUM(w.wigt_obligated_total) / NULLIF(SUM(w.wigt_anticipated_total), 0), 1) AS pct_obligated
FROM wigt_projects w JOIN wyss_apps_all_projects a ON a.source = 'sponsored' AND a.project_key = w.project_number
WHERE w.success_status = 1 GROUP BY 1 ORDER BY 1
```

## Charts, tables and spreadsheets

Only when the person asks for a chart, table, report or spreadsheet; a plain question gets a
plain answer. Build it **from the rows the query returned**, never retyped or estimated; if the
answer needs more than 500 rows, aggregate further. Read `wyss_guide` (topic style) for the house
style; the finance specifics:

- **What to chart**: one message per chart. Categories (sponsor, faculty, funder type,
  category) as horizontal bars, largest first, top 10 to 15 plus "All other"; months or years as
  columns or a line, in fiscal order (July first); direct vs IDC as stacked bars. No pie with more
  than five slices. Success rates as bars with the decided count on each.
- **Label every amount with its kind**: direct spend, IDC, total incl. IDC, proposed (whole
  period), awarded, obligated. Titles name the fiscal year ("Sponsored spend by sponsor, FY2026
  (Jul 2025 to Jun 2026)"); money as $ with M or K on axes; a source line: "Source: Harvard
  general ledger and GMAS via Wyss Apps, refreshed <date>; posted through <date>".
- **Colours**: single series Wyss Midnight `#000032`, Wyss Arctic `#1EAFEC` for the one bar to
  call out. Categorical order: Midnight `#000032`, Arctic `#1EAFEC`, Raspberry `#A62259`,
  Sunshine `#FCB83A`, Seaweed `#336252`, Violet `#8B1BBA`, Cornflower `#7192EB`, Coral `#F96366`,
  Terracotta `#9B391E`, Sea Urchin `#564785`. Raspberry for negatives and over-budget callouts.
  Grand Challenges keep their own colours (wyss-style).
- **Output**: a chart, dashboard or page is an artifact (one self-contained HTML page, inline
  SVG, no external scripts or fonts beyond the fallbacks). A spreadsheet is an `.xlsx`: one sheet
  per table, Midnight header row with white text, frozen header, `$#,##0` for dollars, `0.0%`
  for rates, totals in bold, and a "Notes" sheet with the fiscal year, the definitions used, the
  data freshness and the source line. Name the file for its content
  (`FY2026 sponsored spend by sponsor.xlsx`).

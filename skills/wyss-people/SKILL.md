---
name: wyss-people
description: Look up one Wyss person and get everything Wyss Apps knows about them - "who is Jane Doe", "look up Don Ingber", "what's Aliz Lewis's title", "how is Rebecca Perelman costed", "which grants pay for her", "when does his appointment end", "has her costing changed", "what is Christina Lewis working on", "what's the HUID for ...". Joins the directory (title, Wyss role, email, skills), their jobs and appointment end dates, current payroll costing line by line with the project each line pays from, the costing and title history, their projects and any costing-change requests, and presents it as one person card. Use whenever someone asks about a specific person at the Wyss; for "who works on <topic>" use wyss-projects (search_people) instead.
---

# Wyss people (one person, everything)

The person asks about someone; they get a person card: who the person is, what they do, how they
are paid for (which grants and funds, never how much), what changed and what is in flight. One
call does the work: `person_lookup`. The card is written, not dumped: lead with what matters
about this person today, then the detail.

## If a tool fails (no check before the first answer)

Go straight to the lookup; do not call `whoami` first. A failed Wyss Apps call already says the
one thing to do (missing or expired token, not on the VPN, no access): repeat that sentence and
stop. If the Wyss Apps tools are missing altogether, the `wyss-setup` skill (or `wyss_guide`
topic setup) has the two causes. A result carrying `plugin_update` means the plugin is behind:
add that one line and go on. The person does not need to know Wyss Apps: no tool names, no
permission talk beyond "you do not have access to <thing>; ask Matthew Laubach".

## Which tool

| Ask | Tool |
|---|---|
| Anything about one named person: title, job, department, email, appointment, costing, effort, history, projects, costing requests, HUID | `person_lookup` with `query` = the name, work email or HUID |
| "Who works on / knows about <topic>", "who is in the Ingber lab" | `search_people` (the `wyss-projects` skill) |
| How a PI's grants are doing (submitted, awarded, success rate, pipeline) | `faculty_view` after the card, if asked |
| Everyone costed to one grant | `sponsored_project_lookup` (its `effort` section) |
| The costing-change queue itself, or keying a change | the `wyss-costing-changes` skill |

## Finding the person

- Pass the name as the person wrote it ("Don Ingber", "Lewis", "jalewis@seas.harvard.edu",
  "90270915"). Nicknames work ("Don" finds Donald); titles ("Dr.") are ignored.
- Several matches come back as `candidates` (name, directory title, payroll title, department,
  `in_payroll_now` or `last_in_payroll`). If one is plainly meant (the only current one, or the
  one whose department fits the conversation), call again with its `huid` or `profile_id` and say
  which one you picked in a few words ("the Jennifer Lewis in SEAS Bioengineering"). Otherwise
  ask one short question listing two or three of them; never build a card on a guess.
- A candidate with only a `huid` has no directory profile; one with only a `profile_id` has no
  Wyss payroll record. Both are normal (visiting staff, faculty paid elsewhere, alumni).
- Not found: say so, suggest the last name alone, and stop. Do not fall back to memory.

## The person card

Write it in this order and keep it to one screen. Use the Wyss style (`wyss_guide` topic style
once per session): dates as "Jun 30, 2027", percentages to one decimal, project names linked to
their `url`.

1. **Header.** Bold full name, then one line: title (primary job's title, else the directory
   title), department, Wyss role, email, location. A second line only when it applies: "On leave
   (Leave With Pay)", "Left the Wyss in 2021 for <title> at <institution>", "No longer in the
   payroll feed since <date>".
2. **At a glance.** Three to five bullets from `highlights`, flags first, in plain words:
   - appointment ending within four months, or an end date already past;
   - a job whose `costed_percent` is under 100 (part of the job is not costed in the feed);
   - any line in payroll suspense ("100% of the Surgery professorship sits in Payroll Suspense,
     invalid payroll coding");
   - open costing-change requests (status and effective date);
   - the sponsored share and the main grant ("60% of costed FTE is sponsored, mostly DARPA ABC").
3. **Jobs.** Only when there are two or more: a small table (job title, department, FTE,
   appointment end). One job goes in the header.
4. **How they are paid for now** (as of `costing.as_of`). A table, largest first:

   | Pays from | Share of job | FTE | Sponsored | Since |
   |---|---|---|---|---|
   | [DARPA ABC](url) | 60.0% | 0.600 | Yes | Jul 5, 2026 |
   | Faculty Support / Professorship 1 | 39.6% | 0.396 | No | Jul 5, 2026 |

   "Pays from" is the project name (linked) when there is one, else `account_name`, else the
   account string. Merge lines of the same project (the `by_project` rollup has the sums). Put
   the account string in the row only when the person works with account strings (finance,
   payroll, costing) or asks. More than eight lines: show the eight largest and say "and N
   smaller lines (M% together)". With two jobs, one table per job, primary first.
5. **How it changed.** From `costing_history`: title or department changes with the month,
   then the costing changes, newest first, one line each ("Jul 2026: DARPA ABC added at 60%;
   Wyss fund down from 100% to 40%"). Five lines at most; say how many more. Leave the section out
   when nothing changed.
6. **Projects.** Active first, up to eight, each with the role ("PI", "Project Lead",
   "Maintainer") and linked. Then the counts ("and 271 more: 87 Not Funded, 54 Closed, …").
   For a PI with many grants, offer the faculty record rather than listing them.
7. **In flight.** Costing-change requests that are not finished: status, effective date, link.
8. **Links.** The Effort History page (`effort_history_url`) for the month-by-month chart.

Then stop and offer one or two next steps that fit: the PI's grant record, one grant in full,
a brief before a meeting with them (the `wyss-briefs` skill), or the costing-change request.

## Reading the numbers right

- **Share of job** (`percent`) is the line's share of that job's pay distribution; a job's lines
  normally add to 100 (`costed_percent` on the job says what they add to). **FTE** is the FTE
  that line pays (share × the job's FTE). **Sponsored share** is sponsored FTE over all costed
  FTE across jobs. Name which one you quote.
- A 0-FTE job (a named professorship held alongside the main job, a stipend) has lines with
  FTE 0: say "no FTE" rather than "0%".
- The daily feed date is `costing.as_of`; the monthly history (`costing_history`) is taken
  around the 17th of each month. Quote the date when timing matters ("as of Jul 30, 2026").
- `days_to_appointment_end` counts from today; an appointment end in the past usually means a
  renewal that is not yet in the feed, so say "end date passed; renewal may be pending", not
  "has left".
- A project is named on a costing line only when its fund and activity match a project the
  person may see. A grant they cannot see shows as its account name: do not guess the grant.
- The directory and payroll are joined by name; GMAS and costing requests by HUID. If the
  directory title and the payroll title differ, give the payroll title for the job and the
  directory one as the Wyss role.

## Rules

- Never pay: no salary, rate, grade or dollar amount for a person. The tool returns none; do not
  estimate one from FTE, grant budgets or anything else, even when asked. Say it is not
  available here.
- The HUID appears in the card only when the person asks for it or the work is payroll or a
  costing change.
- One person per call. "Everyone on grant X" is the grant's effort section; "everyone in the lab"
  is a directory search. Do not loop `person_lookup` over a list of people to build a costing
  roster unless the person asking works payroll or costing and asked for exactly that.
- Parts in `sections_hidden_for_you` are access, not missing data: say once that their account
  does not show <jobs and costing / the directory / costing requests> and go on with the rest.
- The card is for the person asking. It is not sent to anyone unless they ask, and then as a
  draft they send themselves.

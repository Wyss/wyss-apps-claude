---
name: wyss-people
description: Look up one Wyss person and get everything Wyss Apps knows about them, read the way the asker works - HR (appointment, job, union, who they report to, costing and the grants it pays from, funding that runs out before the appointment, costing-change requests) or sponsored research (the grants they are named on vs the grants charged, effort, related projects). "who is Jane Doe", "look up Don Ingber", "when does his appointment end", "who does she report to", "is he a supervisor", "what union is she in", "how is Rebecca Perelman costed", "which grants pay for her", "when does her funding run out", "does her costing need to move", "has her costing changed", "what effort does he have on the R01", "is she charged to the grants she is named on", "what is Christina Lewis working on", "what's the HUID for ...". Presents it as one person card. Use whenever someone asks about a specific person at the Wyss; for "who works on <topic>" use wyss-projects (search_people) instead.
---

# Wyss people (one person, everything)

The person asks about someone; they get a person card: who the person is, what they do, how they
are paid for (which grants and funds, never how much), what is about to change and what is in
flight. One call does the work: `person_lookup`. The card is written, not dumped: lead with what
matters about this person today for the one asking, then the detail.

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
| Anything about one named person: title, job, appointment, reports to, union, supervision, costing, funding end dates, effort on grants, history, projects, costing requests, HUID | `person_lookup` with `query` = the name, work email or HUID |
| "Who works on / knows about <topic>", "who is in the Ingber lab" | `search_people` (the `wyss-projects` skill) |
| How a PI's grants are doing (submitted, awarded, success rate, pipeline) | `faculty_view` after the card, if asked |
| Everyone costed to one grant | `sponsored_project_lookup` (its `effort` section) |
| The costing-change queue itself, or keying a change | the `wyss-costing-changes` skill |

## Two readers: the lens

Every result says `lens`: **hr** or **research**. It comes from the asker's account (HR staff get
`hr`; everyone else `research`) and orders `highlights` for them. Write the card for that lens.
The question can override it: pass `lens` yourself when it plainly belongs to the other reader
("what effort does she have on her grants" from HR = `research`; "when does his appointment end and
who does he report to" = `hr`). The lens never adds data: what the account cannot see stays out
either way (see `sections_hidden_for_you`).

- **HR** (the HR team: appointments, payroll costing, the costing queue, supervision and union
  codes) asks: is the appointment in order, is the job fully costed to accounts that last as long as
  the appointment, what has to change and when, who supervises whom, is a costing change already
  in flight.
- **Research** (sponsored research administration, PIs, project leads) asks: which grants is this
  person on and in what role, are they charged where they are named, what do they work on, who
  else is on it.

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

## The card, HR lens

Keep it to one screen; use the Wyss style (`wyss_guide` topic style once per session): dates as
"Jun 30, 2027", percentages to one decimal, project names linked to their `url`. HR works with
account strings, so show the `coa` in the costing table.

1. **Header.** Bold full name, then one line: payroll title, department, employee class, FTE,
   "reports to <name>" (`hr.reports_to`). A second line only when it applies: not Active ("On
   leave (Leave With Pay)"), "No longer in the payroll feed since <date>", "Left the Wyss in 2021".
2. **Needs attention.** The flags, most urgent first, each with the date and what to do. Take them
   from `highlights` (already in HR order) and the sections:
   - a sponsored line whose account has **ended** but still carries pay (`funding.lines` with
     negative `days_left`): "R01 ABC still carries 75.0% of the postdoc job; the account ended
     Jul 31, 2026. The costing should move unless an extension is coming in GMAS.";
   - a line whose account ends **before the appointment** (`ends_before_appointment`): "needs new
     costing by <account_end>";
   - an appointment ending within four months, or already past ("end date passed; renewal may be
     pending", never "has left");
   - a job whose `costed_percent` is under 100, any line in payroll suspense;
   - supervision: `hr.supervisor_watch.needs_attention` (Needs supervisor code, No reports,
     Reports ending soon) with `attention_since`, and a recent union-code change;
   - an open costing-change request (status, effective date, link): it may already fix a flag
     above, so say so ("a request effective Dec 1 is already in the queue").

   Nothing to flag: one line, "Nothing needs attention: fully costed, accounts outlast the
   appointment, no open requests."
3. **Appointment.** One row per job (primary first): title, job, employee class, union, FLSA,
   FTE and hours, position number, in position since, appointment end. One job: a short
   two-line block instead of a table.
4. **How they are paid for now** (as of `costing.as_of`). Largest first; join `funding.lines` on
   the account string for the end dates:

   | Pays from | Account string | Share of job | FTE | Sponsored | Since | Account ends |
   |---|---|---|---|---|---|---|
   | [DARPA ABC](url) | 635.67116.6030.168071.435927.0001.66621 | 60.0% | 0.600 | Yes | Jul 5, 2026 | Jan 31, 2027 |
   | Faculty Support / Professorship 1 | 635.67116.6030.634001.815055.0001.66621 | 39.6% | 0.396 | No | Jul 5, 2026 | — |

   "Pays from" is the project name (linked) when there is one, else `account_name`, else the
   account string. Put an account end that falls before the appointment end in bold. More than
   eight lines: the eight largest and "and N smaller lines (M% together)". Two jobs: one table
   per job, primary first.
5. **Supervision.** When `hr.supervisor_watch` is present: status, union, and the direct reports
   (name, title, appointment end), soonest end first; link the watch-list entry (`url`). When the
   person is a report, "reports to" is already in the header. A blank `reports_to` means the
   person is outside the supervisor check's scope (the HAW unit and the supervisor code), not
   that they have no supervisor: say "supervisor not on file here" only if asked.
6. **Requests and history.** Open costing-change requests first (status, effective date, who
   asked, the other school when routed there, `last_error` if any, link), then the last few
   finished. Then one dated list, newest first, of costing changes (`costing_history`),
   union-code changes (`hr.union_code_changes`) and title changes; six lines at most.
7. **Projects.** Two or three lines at most: the active ones they lead or are named on.
8. **Links.** The Effort History page (`effort_history_url`).

Offer next steps that fit: start or check the costing change (the `wyss-costing-changes`
skill), the supervisor's other reports, or everyone on the grant that is ending.

## The card, research lens

1. **Header.** Bold full name, then: title, department, Wyss role, email, location; a second line
   only when it applies (on leave, left the Wyss, not in the payroll feed).
2. **At a glance.** Three to five bullets from `highlights` (research order), flags first:
   named on an active grant with no salary charged there (`effort.named_not_charged`), a charged
   account that has ended or ends soon, an appointment ending within four months, open costing
   requests, the sponsored share and the main grant.
3. **Effort on grants** (`effort.grants`, as of `effort.as_of`):

   | Grant | GMAS role | Charged (share of job) | FTE | Note |
   |---|---|---|---|---|
   | [DARPA ABC](url) | PI | 60.0% | 0.600 | |
   | [NIH R01 XYZ](url) | Co-Investigator | 0.0% | 0.000 | Named, not charged |
   | [Gates Foundation 123](url) | — | 25.0% | 0.250 | Charged, not named |

   "Named, not charged" matters for key personnel. "Charged, not named" is normal for postdocs and
   staff: say so once and do not flag it as a problem. GMAS carries no committed-effort percentage
   here, so do not compare to a commitment; say "named vs charged".
4. **How they are paid for now.** The HR table without the account string (add it when asked),
   with "Account ends" only where a grant ends within a year.
5. **How it changed.** From `costing_history`: title or department changes with the month, then
   costing changes newest first, five lines at most; leave it out when nothing changed.
6. **Projects.** Active first, up to eight, each with the role ("PI", "Project Lead",
   "Maintainer") and linked, then the counts ("and 271 more: 87 Not Funded, 54 Closed, …"). For a
   PI with many grants, offer the faculty record rather than listing them.
7. **In flight.** Costing-change requests not finished: status, effective date, link.

Offer next steps that fit: one grant in full with everyone on it (`sponsored_project_lookup`),
the PI's grant record (`faculty_view`), or a brief before a meeting (the `wyss-briefs` skill).

## Reading the numbers right

- **Share of job** (`percent`) is the line's share of that job's pay distribution; a job's lines
  normally add to 100 (`costed_percent` on the job says what they add to). **FTE** is the FTE
  that line pays (share × the job's FTE). **Sponsored share** is sponsored FTE over all costed
  FTE across jobs. Name which one you quote.
- **Account ends** (`funding.lines[].account_end`) is the GMAS account's end date (its at-risk end
  when there is no end date yet). GMAS records extensions late, so an ended account still charged
  is "should move, unless an extension is coming", never "is wrong".
- A 0-FTE job (a named professorship held alongside the main job, a stipend) has lines with
  FTE 0: say "no FTE" rather than "0%".
- The daily feed date is `costing.as_of`; the monthly history (`costing_history`) is taken
  around the 17th of each month. Quote the date when timing matters ("as of Jul 30, 2026").
- `days_to_appointment_end` and `days_left` count from today.
- A project is named on a costing line only when its fund and activity match a project the
  person may see. A grant they cannot see shows as its account name: do not guess the grant.
- The directory and payroll are joined by name; GMAS, the supervisor check and costing requests
  by HUID. If the directory title and the payroll title differ, give the payroll title for the
  job and the directory one as the Wyss role.

## Rules

- Never pay: no salary, rate, grade or dollar amount for a person. The tool returns none; do not
  estimate one from FTE, grant budgets or anything else, even when asked. Say it is not
  available here.
- The HUID goes in the HR card (HR keys on it); in the research card only when asked.
- One person per call. "Everyone on grant X" is the grant's effort section; "everyone in the lab"
  is a directory search; "everyone whose funding ends this quarter" is not something this tool
  answers in one go: say so and offer to check the people the asker names. Do not loop
  `person_lookup` over a list unless the asker works payroll, costing or HR and asked for exactly
  that.
- Parts in `sections_hidden_for_you` are access, not missing data: say once that their account
  does not show <jobs and costing / the directory / costing requests / supervision> and go on.
- The card is for the person asking. It is not sent to anyone unless they ask, and then as a
  draft they send themselves.

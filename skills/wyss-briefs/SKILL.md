---
name: wyss-briefs
description: One-page briefs from Wyss Apps for a meeting, a faculty member, a project or a grant - "brief me on Jennifer Lewis before 2pm", "prep me for my meeting with the Ingber lab", "where does the organ-on-chip grant stand", "what should I know before the finance check-in". Pulls the portfolio, pipeline, money and people from the Wyss Apps tools (and the calendar through Microsoft 365 when connected) and writes it in the Wyss house style. Use whenever someone asks to be briefed, prepped, caught up or given the one-pager.
---

# Wyss briefs

A brief answers "what do I need to know, in two minutes, before I walk in". It is written, not
dumped: short sections, the numbers that matter, the open questions, nothing the person cannot
see in Wyss Apps. Read `wyss_guide(topic: "style")` once per session before writing, and
`wyss_guide(topic: "metrics")` before quoting dollars or rates.

## Before anything (silent when it passes)

Call `whoami` once per session before the first answer. If it answers, say nothing about setup
and do the work. If `whoami` answers with `plugin.update_available` true, add one line, its `plugin.update` text, and go on. If it fails, its message already says the one thing to do (missing token,
expired token, not on the VPN, account without access): repeat that sentence and stop. If the
Wyss Apps tools are missing altogether, say both causes and stop: this Cowork session may be
running in the cloud, where the plugin cannot run (Settings, Cowork, turn off "Run new tasks in
the cloud", then start a new session), or the plugin is not enabled for this chat (Customize,
Plugins, add `https://github.com/Wyss/wyss-apps-claude` and enable it). If the Microsoft
365 connector (calendar search) is missing, say one line ("Connect Microsoft 365 in Claude,
Settings, Connectors, so I can read the meeting from your calendar") and write the brief
without it.
The person does not need to know Wyss Apps: no tool names, no permission talk beyond "you do
not have access to <thing>; ask Matthew Laubach". Lead with the result.

## Which brief

| Ask | Shape | Tools |
|---|---|---|
| "Brief me on <faculty>" | Faculty brief | `faculty_view` (current fiscal year and the previous one), `search_projects` for the active Wyss projects, `sponsored_project_lookup` for the two or three biggest active awards |
| "Prep me for my meeting with <person or lab>" | Meeting prep | The calendar search (Microsoft 365 connector: the meeting, its attendees and any agenda in the invite), then the faculty brief for each PI involved, then `search_people` for anyone else named |
| "Where does <project or grant> stand" | Project brief | `sponsored_project_lookup` (funding timeline, accounts, burn and runway, effort) or `get_project` for a Wyss project; `search_science` for what the work is about |
| "What should I know before the finance check-in / quarterly" | Portfolio brief | `faculty_view` for each PI in scope, sorted by what changed; `list_costing_changes` if payroll is in scope |

If the ask names nobody, ask one question: "Whose brief, and for what?" Do not guess a person.

## Layout (keep to one screen)

1. **One line.** Who or what, and the single most important thing (a large award ending, a
   proposal pending, runway under six months, a new award).
2. **Portfolio now.** Active sponsored awards (sponsor, title, end date, remaining and runway
   where visible) and active Wyss projects (status, platform). Three to six lines, most money
   first.
3. **Pipeline.** Submitted and pending proposals, selected-for-funding items, anything declined
   this year that matters.
4. **People.** Key personnel and maintainers named in Wyss Apps; who to ask about what.
5. **Watch.** Dates in the next 90 days (award ends, reporting due, effort certification),
   costing changes in flight, anything flagged `needs_review`.
6. **Questions to ask.** Three at most, each one answerable in the meeting.

Then stop. Offer to go deeper on one section, draft the follow-up email (house style), or turn
the brief into a document.

## Rules

- Every number carries its fiscal year and its kind (proposed, anticipated, obligated, spent);
  never mix them in one sentence. Dollars appear only when the tools return them (financial
  access); otherwise say "amounts not visible to you" once and move on.
- Dates as "Jun 30, 2027", not "6/30/27". Faculty by full name on first mention.
- Prefer what Wyss Apps shows over memory; if two tools disagree, say so and show both.
- Nothing from pay, salary or effort certification detail: those are not in the tools and must
  not be inferred.
- A brief is for the person asking; it is not sent to anyone unless they ask, and then as a
  draft they send themselves.

---
name: wyss-apps
description: Look up Wyss Institute projects (sponsored grants from GMAS and internal Wyss projects), who maintains them, their status, sponsors, timelines and, where the person is allowed, dollar amounts, plus the payroll costing-change queue, through the Wyss Apps MCP server. Use whenever someone asks about a Wyss project, grant, PI, fund number, GMAS id, Director's Fund project, or costing change, or asks what they can see in Wyss Apps.
---

# Wyss Apps

Wyss Apps (`https://wigt.med.harvard.edu`) is the Wyss Institute's internal record of projects,
accounts and people. The `wyss-apps` MCP server exposes a read-only slice of it, **as the person
whose token is connected**: tool access and per-project permissions are the same as on the website.
A "no access" answer is a permission, not a bug; tell the person which tool they lack and that a
super user can grant it on their Wyss Apps account.

## Tools

| Tool | Use it for |
|---|---|
| `whoami` | Who the connection is authenticated as, their role, flags (`financial_access`, `maintainer_on_all_projects`, `restricted_to_own_projects`) and which Wyss Apps tools they have. Call first when unsure what they can see. |
| `search_projects` | Find projects by name, nickname, faculty or PI name, sponsor fund number, GMAS project id or segment key. `type` = `all` (default), `sponsored` or `wyss`; optional `status`; `limit` up to 50 per type. Returns ids for `get_project` and a `url` for each hit. |
| `get_project` | Everything the person may see about one project: `type` + `id` from a search. Sections the policy hides are listed in `sections_hidden_for_you`, never silently dropped. |
| `search_science` | Questions about *the science*: topics, methods, diseases, organisms, materials, techniques, sponsors. Full-text over summaries, abstracts, problem statements, applications, status narratives and publications, ranked with a highlighted snippet. Quoted phrases, OR, -exclusions; filters `grand_challenge`, `platform`, `faculty`, `status`, `tag`. |
| `list_science_themes` | The science map: the six Grand Challenges, the platform initiatives, tags, funding sources and the faculty with the most projects, with counts of what this person can see. Use it to choose filters and to explain how the Institute organises its work. |
| `search_people` | The Wyss directory (needs the Involvement tool): name, title, Wyss role, email, profile text, skills, and the projects they are on that the person can see. No HR, pay or effort data. |
| `faculty_view` | A faculty member's or PI's sponsored-project record by fiscal year: submitted / awarded / declined counts and dollars, success rate per year, time to award, by sponsor, funding source, Grand Challenge and platform, active portfolio, pipeline, new-money requests. Definitions in the `wyss-metrics` skill. |
| `sponsored_project_lookup` | One grant, everything: GMAS record and classification, funding timeline (requests, award revisions), accounts, spend by fiscal year, burndown with burn and runway, who is costed to it, and ready-made highlights. By id, fund number, GMAS id or name. |
| `wyss_guide` | The guides, one topic per call: `intranet` (how-do-I and policy questions, answered from the Wyss SharePoint through the person's Microsoft 365 connector), `style` (vocabulary and document style; **call before writing any report, summary, email or slide**), `metrics` (what every metric means; call before quoting numbers), `costing_changes`, `using_wyss_apps`. They are the same text as this plugin's skills, so Claude gets them without the plugin. |
| `list_costing_changes` | The payroll costing-change queue (needs the Costing Changes tool). Filter by `status` list and `search` (employee, HUID, requester, id). No salary or pay-rate data exists in these payloads. |

## Vocabulary

- **Sponsored project** (`type: sponsored`): a GMAS segment, i.e. a grant or sponsored award. Has a
  `fund` (6-digit Harvard fund), `project_id`, `segment_key`, a GMAS `status` (Pending, Active,
  Not Funded, Closed, Completed, Cancelled, Terminated) which a Wyss override can replace
  (`status` is the effective one; `gmas_status` the raw one), and proposed / anticipated /
  obligated amounts split direct / indirect.
- **Wyss project** (`type: wyss`): an internal project (Director's Fund, validation, SAB, retreat
  lists). Statuses: Not Started, Active, Closed. Dollars come from its funding rows.
- **Faculty / PI**: `faculty` is the Wyss faculty member linked to the project; `pi` is the GMAS
  principal investigator in "First Last" form. GMAS stores "Last, First" and abbreviates first
  names ("Don" for Donald); search by last name when a first name fails.
- **Maintainers**: the people who may edit the project. Viewers see a reduced set of sections.
- **Costing change**: a request to re-cost someone's payroll across chart-of-account strings
  (33-digit COA, percentages summing to 100). Status flow: new → validated → ready → claimed →
  staged → submitted → backup_filed; side states needs_review, error, cancelled.

## Answering questions about the science

1. `list_science_themes` once per conversation if the question is broad ("what does the Wyss do
   in cancer?"), so you know the Grand Challenge and platform names and who the faculty are.
2. `search_science` with the topic, then again with synonyms or the faculty name if the first
   pass is thin (the record uses the words the proposal used: "organ chip" and "organ-on-a-chip"
   are both in use). Narrow with `grand_challenge`/`platform` when the person names one.
3. `get_project` on the top hits for the full abstract, problem statement, current status and
   publications. Quote the project's own words for claims about the science; label them as
   proposal text (summary, abstract) or reported progress (current status), and give the date.
4. Answer in the Wyss vocabulary (`wyss_guide` (topic style)): Wyss name first, faculty, status, which
   Grand Challenge and platform, the `url`. Group by platform or Grand Challenge for overviews;
   by faculty for "who works on". Say plainly when the record has no science text (many
   sponsored projects carry only a title and sponsor).
5. For "who should I talk to", combine the project's faculty and team with `search_people`.

## How to answer

1. Search first, then fetch. Prefer `search_projects` with a distinctive word; widen with the
   faculty last name if nothing matches. Do not guess ids.
2. Quote amounts exactly as returned (strings in USD, two decimals) and say which amount it is
   (proposed vs anticipated vs obligated; direct vs indirect vs total).
3. Link people to the `url` of each project so they can open it in Wyss Apps.
4. When a section is in `sections_hidden_for_you`, say so plainly ("your account doesn't have
   financial access, so I can't see the dollars") rather than inferring values.
5. Nothing here writes. If someone asks to change a project, point them to the project's `url`
   (Edit button) or to the maintainer listed on it.
6. Every call is logged on the person's Claude access page in Wyss Apps; there is nothing to hide
   and nothing to work around.

## Connection problems

- 401 / "invalid_token": the token is wrong, expired or revoked. Make a new one at
  `https://wigt.med.harvard.edu/tools/claude_access` and reconnect.
- 403 / "insufficient_scope": the Wyss Apps account lacks the **Claude access** tool. A super
  user grants it under Super User → Users.
- Connection refused / timeout: Wyss Apps is reachable only on the Wyss/HMS network or VPN.
- 429: more than 120 calls a minute on one token; wait a minute.

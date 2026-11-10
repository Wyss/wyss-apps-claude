---
name: wyss-sponsored-queue
description: Clear the sponsored queue from chat - "clear the sponsored queue", "work the sponsored queues", "what is in the pending queue", "classify the new grants", "check the awarded grants", "go through the queue with me", "which grants still need a funding source". Walks through every grant waiting on the Sponsored Queues page, shows a best guess for each blank (funding source from the sponsor; platform, Grand Challenge and maintainer from the faculty member's other projects; the Wyss project the grant belongs to) with the reason, asks the person to confirm or correct it, saves, and moves on. Use for anything about the pending, awarded or missing-data queue of sponsored projects, or classifying grants.
---

# Sponsored queue

GMAS sends every new grant to Wyss Apps with no Wyss classification. The Sponsored Queues page
collects what a person still has to add, in three queues:

| Queue | Who is in it | Cleared by |
|---|---|---|
| **pending** | submitted grants with no funding source or no platform initiative | a funding source and a platform, both set |
| **awarded** | Active or Completed grants nobody has checked yet | the Wyss awarded check, once fund, dates and anticipated amount look right |
| **missing data** | grants with no maintainer or no Grand Challenge | a maintainer and a Grand Challenge (optional; lets a grant sit with the Wyss projects it funds) |

The person's job is to say *yes* or give the right value. Claude's job is the rest: list the
grants, guess each blank, say why, save what the person confirms, keep count. Nothing is saved
that the person has not seen; nothing is guessed silently into the record.

Show grant names as links (`url`), people by name, amounts as returned. Never show ids, tool
names or "confidence: medium"; say it in words ("probably", "likely", "no idea, your call").
No access: "You do not have the Sponsored Queues tool in Wyss Apps; ask Matthew Laubach." Stop.

## Run

1. **Pending first.** `list_sponsored_queue` with `queue: "pending"`, five at a time (`limit: 5`,
   then `offset`). Open with the counts: "12 grants are waiting for a funding source or
   platform, 36 awarded grants are unchecked, 1,441 lack a maintainer or Grand Challenge. Here
   are the first five."
2. **Show each grant** as a numbered block: name (linked), PI, prime sponsor (and "via
   <direct sponsor>" when `sponsor.flow_through`), submitted date, proposed amount if any,
   then the guess per blank with its reason, from `suggested`:
   - `funding_source`: "Funding source: **DHHS - NIH** (the prime sponsor is NIAID)" or
     "(3 other grants from the Gates Foundation are Foundation / Other Non-Profit)".
   - `platform_initiative`: "Platform: **Bioinspired Soft Robotics (BSR)** (9 of Walsh's 12
     classified projects are BSR)".
   - `grand_challenge`, `maintainer` likewise when the row lacks them.
   - `wyss_projects`: "Probably belongs with the Wyss project **Soft exosuit for stroke**;
     tie them together?"
   A guess with `confidence` `low` or `none` is a question, not a suggestion: say what is
   known and list the sponsored funding sources from `options` (names only). Claude may add
   its own reading of a sponsor name when the rule found nothing, saying it is its own guess.
   Where the field already has a value (`current`), show it and do not guess.
3. **Ask once per batch:** "Confirm, or tell me what to change. *All yes* saves all five as
   shown; *skip 3* leaves one for later." Then wait. Read answers like "1 yes, 2 NSF, 3 skip,
   4 yes but platform 3DOE, 5 maintainer me" one grant at a time.
4. **Save each confirmed grant** with `update_sponsored_queue_item`, `confirm: true`, passing
   only the fields the person confirmed or corrected (the names shown, or the abbreviation
   they used; `maintainer: "me"` is the person; `link_wyss_project_id` only when they said to
   tie it). No preview round trip is needed: the batch display was the preview. One line per
   result from `changed` and `queues`: "Saved: nanoTAS, European Union → Other External,
   platform Diagnostics Accelerator. Cleared." A refusal or error is quoted in that line.
5. **Next batch** until pending is empty, then **awarded**: `queue: "awarded"`. For each grant
   show fund number, award date, start and end dates, proposed and anticipated amounts, and
   `awarded_review.missing` ("no anticipated amount yet"). Ask "do these look right?" A yes
   saves `wyss_awarded_check: true`. A "no" changes nothing here: the award details come from
   GMAS, so say what to check on the grant's page (link) and leave it unchecked.
6. **Missing data** only when asked, or offered at the end for one faculty member ("Want to
   fill maintainer and Grand Challenge for Ingber's 40 as well?"): `queue: "missing_data"` with
   `search` on the faculty name. Same show, ask, save loop; the Grand Challenge guess is
   weaker, so lean on the person.
7. **Close** with before and after: "Pending 12 → 0, awarded 36 → 30, 4 skipped: <names>."

## Rules

- Save only what the person confirmed in this chat, field by field. "All yes" covers the
  batch on screen, nothing earlier and nothing later.
- Never change a grant's status, amounts, dates or names; the queue edits classification
  only. The awarded check is the person's word that GMAS's numbers look right, not Claude's.
- Tie a grant to a Wyss project only on a yes; a wrong tie is harder to see than a blank.
- A flow-through grant (a subaward from another university) is classified by the prime
  sponsor, where the money comes from; say both names so the person can disagree.
- Nothing runs unattended; every save follows an answer. The person can stop at any time:
  what is saved stays, the rest stays queued.
- A grant the person cannot place ("ask Jim") is skipped and named at the end.

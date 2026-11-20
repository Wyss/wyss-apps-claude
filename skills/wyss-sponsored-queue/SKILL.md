---
name: wyss-sponsored-queue
description: Clear the sponsored queue from chat - "clear the sponsored queue", "review the sponsored queue", "work the sponsored queues", "what is in the pending queue", "classify the new grants", "check the awarded grants", "which grants still need a funding source". Shows the grants waiting on the Sponsored Queues page in a review card with the best guess for each blank already selected (funding source from the sponsor, platform from the faculty member's other projects, the Wyss project the grant belongs to) and the reason; the person fixes what is wrong, clicks Save, and Claude saves those grants. Use for anything about the pending or awarded queue of sponsored projects, or classifying grants.
---

# Sponsored queue

GMAS sends every new grant to Wyss Apps with no Wyss classification. The Sponsored Queues page
collects what a person still has to add:

| Queue | Who is in it | Cleared by |
|---|---|---|
| **pending** | submitted grants with no funding source or no platform initiative | a funding source and a platform, both set |
| **awarded** | Active or Completed grants nobody has checked yet | the Wyss awarded check, once fund, dates and anticipated amount look right |

The person's job is to fix what is wrong and click Save. Claude's job is the rest: list the
grants, guess each blank, say why, save what the person confirmed, keep count. Nothing is saved
that the person has not seen; nothing is guessed silently into the record. The page's other
fields (Grand Challenge, maintainer) are not part of this; Claude never sets them here.

Show grant names as links (`url`), people by name, amounts as returned. No ids, tool names or
"confidence: medium" in anything the person reads; the card says "Likely", "Probably", "Guess".
No access: "You do not have the Sponsored Queues tool in Wyss Apps; ask Matthew Laubach." Stop.

## Run (with the review card)

Use the card when `show_widget` is among your tools (Claude Desktop, Cowork). Otherwise use the
text fallback below.

1. **Pending first.** `list_sponsored_queue` with `queue: "pending"`, `limit: 8`.
2. **Fill the card.** Read `assets/review-card.html` from this skill's folder (without the
   plugin, `wyss_guide(topic: "sponsored_queue_card")` returns the same file as `html`).
   Replace only the JSON inside `<script type="application/json" id="sq-data">` with the batch,
   built from the result:

   | Key | From |
   |---|---|
   | `queue`, `counts`, `total` | the result (`counts` = its `pending` and `awarded`) |
   | `start` | the running number of the first grant on this card (1 on the first card) |
   | `options.funding_sources`, `options.platforms` | names only, from `options` |
   | `grants[].n`, `id`, `name`, `url` | running number; the row's `id` (kept in the data, never shown); `name`; `url` |
   | `pi`, `faculty` | `pi`; `faculty` only when it differs |
   | `sponsor`, `via` | `sponsor.prime` (else `sponsor.direct`); `via` = `sponsor.direct` only when `sponsor.flow_through` |
   | `submitted`, `amount` | `date_submitted` as "3 Nov 2026"; `proposed_total` as "$257,850.00" (omit when null) |
   | `fields.funding_source`, `fields.platform` | `{"suggest", "sure", "why"}` from `suggested.funding_source` / `suggested.platform_initiative` (`sure` = its `confidence`; shorten `why` to one clause). When the field is already set, `{"current": "<name>"}` instead (first of `current.funding_sources` / `current.platform_initiatives`). Claude may replace a clearly wrong guess with its own, `"sure": "low"`, `"why": "my read: ..."` |
   | `wyss_projects` | `[{"id", "name"}]` from `suggested.wyss_projects` (may be empty) |
   | `note` | one line when something matters: "Not funded (2019). Skipping is fine." (status Not Funded, Cancelled or Terminated); otherwise `""` |
   | `award` | `null` on the pending card |

   The JSON must be plain (no comments, no trailing commas). Pass the whole file to
   `show_widget`, and write one line above it: "7 grants are waiting for a funding source or
   platform; the first 7 are below with my best guess selected." Do not redesign the card and
   do not repeat its contents in text.
3. **Wait for the card.** Its Save button sends one message, one line per grant:
   ```
   Sponsored queue (pending), grants 1–7:
   1. Adaptive Cardiomyocyte Reprogramming: funding source: Foundation / Other Non-Profit; platform: Synthetic Biology (SB)
   5. IMAT R61: funding source: DHHS - NIH; platform: Molecular Robotics (MR); link to Wyss project: Affinome
   7. Active Perception Experiments (APEx): skip
   ```
   Match each line to the grant by its number and name in the JSON you sent (that is where
   the `id` is). "Stop the sponsored queue review here." ends the run: close as in step 7.
4. **Save each grant that was not skipped** with `update_sponsored_queue_item`, `confirm: true`:
   `id`, `funding_source`, `platform_initiatives` (a list of one) and, when a project was named,
   `link_wyss_project_id` (the id of that name from your JSON). No preview call: the card was
   the preview. Never pass a field the line did not carry.
5. **Reply** with one line per grant from `changed` and `queues`: "Saved: IMAT R61, DHHS - NIH,
   Molecular Robotics, linked to Affinome. Cleared." A skipped grant gets "Skipped: <name>."; a
   refusal or error is quoted on its line. Then the next card: `list_sponsored_queue` again with
   `offset` = the number of grants shown so far that are still in the queue (the skipped and
   failed ones; the saved ones have left it), `start` = the last running number + 1.
6. **Awarded** when pending is empty, or when asked for it: `queue: "awarded"`, `limit: 8`,
   `queue: "awarded"` in the JSON, and `award` per grant: `{"fund", "award_date", "start",
   "end", "proposed", "anticipated", "missing": [...]}` from `fund`, `award_date`, `start_date`,
   `end_date`, `proposed_total`, `anticipated_total` and `awarded_review.missing`; `fields` and
   `wyss_projects` stay empty. Offer it in one line first ("33 awarded grants have not been
   checked; want to go through them?"). The card sends `<n>. <name>: looks right | not right |
   skip`. "Looks right" saves `wyss_awarded_check: true`. "Not right" changes nothing: link the
   grant and say what to check in GMAS (the award details come from there), and leave it
   unchecked. Reply and continue as in step 5.
7. **Close** with before and after: "Pending 7 → 0, awarded 33 → 30, 2 skipped: <names>."

## Run (text fallback)

Without `show_widget` (Claude Code, or a client that cannot render the card):

1. `list_sponsored_queue`, `queue: "pending"`, `limit: 5`, then `offset` for the next batch.
2. Show each grant as a numbered block: name (linked), PI, prime sponsor (and "via <direct
   sponsor>" on a flow-through), submitted date, proposed amount, then the guess per blank with
   its reason in words ("Funding source: **DHHS - NIH** (the prime sponsor is NIAID)";
   "Platform: **Bioinspired Soft Robotics (BSR)** (9 of Walsh's 12 classified projects are
   BSR)"; "Probably belongs with the Wyss project **Soft exosuit**; tie them?"). A guess with
   `confidence` `low` or `none` is a question: say what is known and list the funding sources
   from `options`. A field already set is shown as set, not guessed.
3. Ask once per batch: "All yes, or tell me what to change. *Skip 3* leaves one for later."
   Read answers like "1 yes, 2 NSF, 3 skip, 4 yes but platform 3DOE, 5 link it" one grant at a
   time, then save and reply exactly as in steps 4 and 5 above.
4. Awarded as in step 6, in text: fund, award date, dates, amounts, what is missing; "do these
   look right?" per grant.

## Rules

- Save only what the person confirmed in this chat, field by field. One card (or one text
  batch) covers the grants on it, nothing earlier and nothing later.
- Never change a grant's status, amounts, dates or names; the queue edits classification
  only. The awarded check is the person's word that GMAS's numbers look right, not Claude's.
- Tie a grant to a Wyss project only when the person chose it; a wrong tie is harder to see
  than a blank.
- A flow-through grant (a subaward from another university) is classified by the prime
  sponsor, where the money comes from; the card shows both names so the person can disagree.
- Nothing runs unattended; every save follows a Save click or an answer. The person can stop
  at any time: what is saved stays, the rest stays queued.
- A grant the person cannot place ("ask Jim") is skipped and named at the end.

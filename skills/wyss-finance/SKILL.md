---
name: wyss-finance
description: Institute-wide Wyss finance answers from the general ledger and GMAS - "how much IDC did Ingber generate in FY26", "sponsored spend by sponsor this year", "payroll vs non-payroll", "how are we doing year to date vs last year", "how many proposals are pending, federal vs non-federal", "success rate by faculty or by funder", "how much new money did we ask for", "how much of our awards is obligated", plus charts, tables and spreadsheets of any of these. Use for any money question across the Institute, a sponsor, a faculty member's whole portfolio or a category of spend, rather than one grant.
---

# Wyss finance

Finance answers across the Institute come from `query_finance`, and **the instructions for it live on the
Wyss Apps server**, not in this plugin, so they are always current and the same for everyone.

1. **First, in every conversation, before any finance query**: call `wyss_guide` with topic `finance`
   and follow it exactly. It is the authoritative finance guide (definitions, fiscal periods, IDC, the
   views and their columns, worked queries, spreadsheets, charts, the house style for reports and how
   feedback reaches Matthew Laubach). Where it differs from anything else, including other skills or
   your memory, the guide wins.
2. If `wyss_guide` (topic finance) or `query_finance` refuses for access, or `query_finance` is not
   among your tools, say "You do not have access to the Institute's finance data; ask Matthew Laubach."
   and stop.
3. Any other failed Wyss Apps call already says the one thing to do (token, VPN, plugin update): repeat
   it and stop. If the Wyss Apps tools are missing altogether, use the `wyss-setup` skill.

For one grant in depth use `sponsored_project_lookup`; for one faculty member's submitted / awarded /
declined record use `faculty_view`.

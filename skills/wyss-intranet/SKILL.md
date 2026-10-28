---
name: wyss-intranet
description: Answer Wyss Institute administrative questions (policies, HR and onboarding, finance and purchasing forms, facilities, EHS, IT, communications, who to contact) from the Wyss intranet on SharePoint (hu.sharepoint.com/sites/wyss) through the Microsoft 365 connector, and combine them with Wyss Apps data. Use whenever someone asks how something is done at the Wyss, where a form or policy is, or what the process is.
---

# The Wyss intranet through Microsoft 365

Administrative answers live on the Wyss intranet, a SharePoint Online site:
`https://hu.sharepoint.com/sites/wyss` (home: `SitePages/Home.aspx`). Claude reaches it through the
**Microsoft 365 connector** the person connected in Claude with their own Harvard account, so
Claude sees exactly the pages and documents that person can open. Wyss Apps (the `wyss-projects`
tools) is the record of projects, grants, people and money; the intranet is the record of how
things are done. Use both: process from the intranet, facts from Wyss Apps.

## How to look things up

1. **Search the site first.** Use the Microsoft 365 connector's *search* tool (the one that searches
   SharePoint and OneDrive files and pages) with the question's own words, adding "Wyss" when the
   results drift to other Harvard sites. Never build a `site:///` or `page:///` URI by hand from the
   web address: those need Graph ids, which only the search results carry. Pages (`SitePages/*.aspx`) carry the
   current process text; document libraries carry the forms, policies and templates (Word, PDF,
   Excel). Prefer a page over a stray document, and a document in a library named for the topic
   (HR, Finance, EHS…) over one in a personal folder.
2. **Read the source**, not the snippet: open the page or file (`read_resource` with the URI the
   search returned) before answering. Read the whole page when it is short; for a long policy
   read the section that answers the question and say which section.
3. **Check it is current.** Note the page's or file's last modified date; if it is older than
   about two years, or two sources disagree, say so and prefer the newer one.
4. **Answer, then cite.** Give the answer in plain words first, then the link to the page or
   file it came from (the SharePoint web URL), and the contact named on that page if there is
   one. One source per claim; do not stitch an answer from guesses.
5. **Data questions go to Wyss Apps.** "What is the status of grant X", "who maintains project
   Y", "how much was awarded": use the `wyss-projects` tools, then, if the person also asks *how*
   (how to request a costing change, how to submit an invoice), come back to the intranet.
6. **Hand off when the intranet is silent.** If no page answers, say so plainly and name the
   office that owns the topic (see the map) instead of inventing a process.

## The map (areas of the intranet)

| Area | Typical questions | Where to look |
|---|---|---|
| People & HR | onboarding, offboarding, titles, leave, performance reviews, visas, payroll dates | pages and library under People / HR; forms in the HR library |
| Finance & purchasing | expense reports, purchasing, reimbursements, vendor setup, chart of accounts, costing changes, invoices | Finance pages and forms; the costing-change list lives on the *on-prem* People site (`share.wyss.harvard.edu`), not here |
| Research operations & grants | proposal routing, GMAS, post-award, effort certification, subcontracts | Research Ops / Sponsored pages; the records themselves are in Wyss Apps |
| Facilities, EHS & lab ops | space, keys, safety training, waste, equipment, core facilities, shipping | Facilities / EHS pages and SOP library |
| IT & systems | accounts, VPN, software, SharePoint itself, Wyss Apps help | IT pages; Wyss Apps questions go to Matthew Laubach |
| Communications & events | branding, templates, event forms, news, seminars, retreat, SAB | Comms pages and the templates library |
| Leadership & governance | org chart, directors, committees, strategy, annual report | About / Leadership pages |

The map is a starting point: the site's own navigation is authoritative. When a question does
not fit, search the whole site before concluding.

## Style

- Plain sentences, steps as a numbered list when the answer is a procedure, the owner's name or
  mailbox at the end. Dates and amounts as the page states them.
- Never paste a whole policy; summarise and link. Never report a personal file (someone's own
  OneDrive) as an institute policy.
- If Microsoft 365 is not connected, tell the person: Claude → Settings → Connectors →
  Microsoft 365 → Connect, sign in with the Harvard account, then ask again.

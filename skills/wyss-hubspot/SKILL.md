---
name: wyss-hubspot
description: Work in the Wyss HubSpot account through Wyss Apps - "log a note on Jane Doe's contact about today's call", "find everyone at Moderna in HubSpot", "create a deal for the Ingber licensing talk", "which BD deals have gone quiet", "add these 12 people to the Gala list", "make me a follow-up task for Friday", "update the company's industry". Reads and changes contacts, companies, deals, tickets, notes, calls, meetings, tasks, lists, properties and marketing through the hubspot_read and hubspot_write tools, with Wyss Apps' own HubSpot key. Use for anything in HubSpot.
---

# HubSpot

The person asks for something in HubSpot and it gets done. They never handle a HubSpot key:
Wyss Apps makes each call with its own, and what that key's scopes allow is what can be done.
Every call is logged in Wyss Apps under the person's name.

## Before anything (silent when it passes)

- No `hubspot_read` / `hubspot_write` among your tools: the person does not have the
  **HubSpot for Claude** tool. Say: "HubSpot through Claude needs the HubSpot for Claude tool in
  Wyss Apps; ask Matthew Laubach for it." Stop.
- A call answering "HubSpot is not connected in Wyss Apps yet": repeat that line. Stop.

## The two tools

- `hubspot_read(method, path, query, body)`: GET, or POST to a path ending `/search` or
  `/batch/read`. Path under `https://api.hubapi.com`, no query string in it; parameters go in
  `query`.
- `hubspot_write(method, path, query, body, confirm)`: POST, PUT, PATCH, DELETE. Without
  `confirm: true` nothing is sent and the exact request comes back.
- HubSpot's answer comes back as `{request, status, ok, body}`, errors included. Answers over
  60,000 characters are cut (`truncated: true`): ask again for fewer `properties`, a smaller
  `limit`, or the next page with `after`.

## Changes: show, then do

1. Find the records first (search), so the change names real records: "Jane Doe
   (jane@acme.com, Acme Corp)", not an id.
2. Show the change in plain words: which records, which fields, old value to new value, or the
   note text as it will appear. For many records, the count and a short sample.
3. Call `hubspot_write` with `confirm: true` only after the person says yes. One yes covers the
   list they saw, not later additions.
4. Report what was done with a link to each record.

Never send a marketing email, enrol anyone in a sequence or workflow, or delete records unless
the person asked for exactly that. A CRM `DELETE` archives the record (HubSpot keeps it
restorable for 90 days); say so when deleting.

## Whose name is on it

HubSpot records every change as made by the Wyss Apps app. To put an activity or record under
the person, set its owner: find their owner id once with
`hubspot_read GET /crm/v3/owners` and `query: {"email": "<their email>"}` (their email is in
`whoami`), then pass `hubspot_owner_id` on notes, calls, meetings, tasks, deals and contacts they
create. If they are not a HubSpot user, leave the owner off and say so.

## Common calls

Object types: `contacts`, `companies`, `deals`, `tickets`, `notes`, `calls`, `meetings`,
`tasks`, `emails`. Record links: `https://app.hubspot.com/contacts/<portalId>/record/<type id>/<id>`
with type id `0-1` contact, `0-2` company, `0-3` deal, `0-5` ticket; the portal id is in
`GET /account-info/v3/details` (`portalId`).

- **Search**: `POST /crm/v3/objects/contacts/search` with
  `{"filterGroups":[{"filters":[{"propertyName":"email","operator":"EQ","value":"jane@acme.com"}]}],"properties":["firstname","lastname","email","company"],"limit":10}`.
  Free text: `{"query":"moderna","limit":10}`. Operators: `EQ`, `NEQ`, `CONTAINS_TOKEN`, `GT`,
  `LT`, `BETWEEN`, `HAS_PROPERTY`, `NOT_HAS_PROPERTY`, `IN`. Filters in one group are AND, groups
  are OR. Sort: `"sorts":[{"propertyName":"lastmodifieddate","direction":"DESCENDING"}]`.
  Search allows 200 per page and lags writes by a few seconds.
- **One record**: `GET /crm/v3/objects/contacts/<id>` with
  `query: {"properties":"email,firstname,lastname,jobtitle","associations":"companies,deals"}`.
- **Property names and options**: `GET /crm/v3/properties/<type>`; check before writing a
  dropdown, which takes the option's internal `value`, not its label.
- **Pipelines and stages**: `GET /crm/v3/pipelines/deals` (stage ids, not labels, go in `dealstage`).
- **Create or update**: `POST /crm/v3/objects/<type>` with `{"properties":{...}}`;
  `PATCH /crm/v3/objects/<type>/<id>` with only the fields that change. A contact is matched by
  email: search first so a duplicate is not created.
- **Log an activity**: `POST /crm/v3/objects/notes` with
  `{"properties":{"hs_timestamp":"2026-11-09T15:00:00Z","hs_note_body":"...","hubspot_owner_id":"123"},"associations":[{"to":{"id":"<contact id>"},"types":[{"associationCategory":"HUBSPOT_DEFINED","associationTypeId":202}]}]}`.
  Calls (`hs_call_title`, `hs_call_body`, `hs_call_direction`, `hs_call_status`), meetings
  (`hs_meeting_title`, `hs_meeting_body`, `hs_meeting_start_time`, `hs_meeting_end_time`) and
  tasks (`hs_task_subject`, `hs_task_body`, `hs_task_status` NOT_STARTED, `hs_task_priority`,
  `hs_timestamp` = due date) work the same way.
- **Association type ids** (activity to record): notes 202 contact, 190 company, 214 deal;
  calls 194, 182, 206; meetings 200, 188, 212; tasks 204, 192, 216; emails 198, 186, 210. For
  any other pair, `GET /crm/v4/associations/<from>/<to>/labels`. Link two existing records with
  `PUT /crm/v4/objects/<from>/<id>/associations/default/<to>/<id>`.
- **Many at once**: `POST /crm/v3/objects/<type>/batch/create|update|read` with up to 100
  `inputs`. Prefer one batch to a hundred calls.
- **Lists**: `POST /crm/v3/lists/search` with `{"query":"gala"}`; add contacts to a static list
  with `PUT /crm/v3/lists/<listId>/memberships/add` and a JSON array of record ids.
- **Recent activity on a record**: `GET /crm/v4/objects/contacts/<id>/associations/notes` (or
  calls, meetings, emails, tasks), then a batch read of those ids with the fields wanted.

## When HubSpot says no

- `403` with `MISSING_SCOPES`: "The Wyss Apps HubSpot key does not allow that (it needs the
  `<scope>` scope). Matthew Laubach can add it." Do not retry.
- `400`: read HubSpot's message (usually a property name or option value), fix the call once,
  and try again; if it fails again, show the message.
- `404`: the record or path does not exist; search again rather than guess an id.
- `429`: Wyss Apps already waited and retried; tell the person HubSpot is busy and to try in a
  minute.

## Writing it up

Contact details are personal information: show what the person asked for, not whole exports,
and do not paste contact lists outside the conversation unless asked. Follow `wyss-style` for any
report or email made from HubSpot data.

# Changes

## 0.5.2 (2026-10-28)
- Results first. Every skill now checks the setup silently before its first answer (`whoami`;
  Claude in Chrome for costing changes; Microsoft 365 for intranet and calendar) and, when
  something is missing, says the one thing to fix and stops. New `wyss-setup` skill ("check my
  setup", "is this working") reports the three checks and what the person can ask.
- Costing changes speak in work words only (waiting to be keyed, filled and waiting for your
  Save, saved, done and filed, skipped because): no statuses, tool names or ids. A run resumes
  the person's own unfinished work (filled but unsaved, or started) instead of answering
  "nothing ready", re-queues a filled row whose tab was lost, and after Save files the backup
  itself: a screenshot of the saved page uploaded to the request (PDF by Ctrl+P only as the
  fallback). The person signs in and clicks Save; nothing else.

## 0.5.1 (2026-10-28)
- `wyss-costing-changes` is now a run, not a tour: "run the costing changes" claims every ready
  request, opens each Department Budget Earnings page by direct URL in the person's own Chrome
  (Claude in Chrome only; Duo cannot complete in Cowork's built-in browser), checks the before,
  keys the new row field by field (page ids from Beth's page map), stages it, and speaks only to
  hand over for Save and to report. After "done" it records the submissions, asks for the
  Ctrl+P PDFs, attaches them on the request pages and closes the requests.

## 0.5.0 (2026-10-28)
- The backup of a costing change is the saved PeopleSoft page printed to PDF, attached on the
  request page in Wyss Apps ("Attach backup and complete"), which closes the request; the queue
  shows a "backup PDF" link on the row. `file_costing_change_backup` is only for a backup kept
  elsewhere. The skill opens the Costing Changes tool in the person's browser first and keeps
  it beside the chat.
- New skill `wyss-briefs`: one-page briefs for a meeting, a faculty member, a project or a grant
  (`wyss_guide(topic: "briefs")`).

## 0.4.1 (2026-10-28)
- Windows bridge hardened for Windows PowerShell 5.1: no progress bar on the output pipe, TLS 1.2
  forced on, UTF-8 without a byte-order mark on stdin/stdout. Exercised end to end under
  PowerShell 7 (initialize, tools/list, whoami, parse error, CRLF token and URL files, 401/403/
  unreachable mapping); 5.1 itself still awaits a first Windows user.
- README: what the expected failed sibling server looks like, the "running scripts is disabled"
  fix, and how to check the token file on Windows.

## 0.4.0 (2026-10-27)
- Costing-change actions as the person: `claim_costing_change`, `mark_costing_change_staged`
  (readback checked against the fill spec), `mark_costing_change_submitted` (after Save),
  `file_costing_change_backup`, `report_costing_change_error`, `review_costing_change`
  (mark ready / send back / cancel with the review page's rules). All preview unless
  `confirm: true`; none writes to PeopleSoft. The `wyss-costing-changes` skill carries the
  end-to-end flow with Claude in Chrome.

## 0.3.2 (2026-10-27)
- Windows: a second server, `wyss-apps-win`, runs `bridge/wyss-apps-bridge.ps1` with PowerShell
  (token and URL read per request, like the bash bridge). Plugin manifests cannot choose a command
  per platform, so each machine starts the one that fits and the other fails quietly.

## 0.3.1 (2026-10-27)
- Skill names say what they cover: `wyss-projects` (was `wyss-apps`: projects, grants, science,
  people), `wyss-costing-changes` (was `costing-changes`), alongside `wyss-metrics`, `wyss-style`,
  `wyss-intranet`. Guide topic `using_wyss_apps` is now `projects`.

## 0.3.0 (2026-10-27)
- One server everywhere: `.mcp.json` now declares only `wyss-apps`, the local bash bridge. The
  http entry with `${user_config.wyss_apps_token}` is gone: Cowork never asked for the value and
  sent an empty bearer, a 401 on every start.
- The bridge reads the token (`$WYSS_APPS_TOKEN`, `$WYSS_APPS_TOKEN_FILE`, `~/.wyss-apps/token`)
  and the URL (`$WYSS_APPS_URL`, `~/.wyss-apps/url`, the prod URL) on every request: a new token
  works without a restart. 401/403 messages say what to do; a token file readable by other
  accounts is flagged.
- Tool names are now `mcp__plugin_wyss-apps_wyss-apps__*`.

## 0.2.1
- `userConfig` titles (the plugin refused to load without them); intranet skill uses the
  Microsoft 365 search tool.

## 0.2.0
- Local bridge for the extension allow-list case; marketplace install.

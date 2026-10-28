# Changes

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

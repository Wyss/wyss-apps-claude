# Wyss Apps extension for Claude Desktop and Cowork

This folder is packed into `wyss-apps.mcpb` (download it from the Claude access page in Wyss Apps,
or build it with `zip -r wyss-apps.mcpb manifest.json server README.md` from this folder).

- `manifest.json`: the MCPB manifest. `user_config.wyss_apps_token` is `sensitive`, so Claude
  Desktop stores it in the OS keychain and passes it to the server as `WYSS_APPS_TOKEN`.
- `server/index.mjs`: a dependency-free Node script (Claude Desktop's built-in Node runs it) that
  turns the local stdio MCP connection into HTTPS calls to `https://wigt.med.harvard.edu/mcp`
  with `Authorization: Bearer <token>`. The connection is made from the person's own computer,
  on the Wyss network or VPN, never from Anthropic's cloud.

Install: double-click the `.mcpb` (or Claude Desktop → Settings → Extensions → Advanced →
Install Extension…), paste the token when asked, and in Cowork choose the **computer**
environment for the session (local MCP servers do not run in cloud sessions).

# Wyss Apps for Claude

Connect Claude to Wyss Apps so it can look up Wyss projects, grants, maintainers and the
costing-change queue **as you**. Claude sees exactly what you can see on
https://wigt.med.harvard.edu, nothing more, and every question it asks is listed on your
Claude access page there. Nothing in this connection can change data.

You need a Wyss Apps account (members have the **Claude access** tool by default), a computer on
the Wyss/HMS network or VPN, and Claude Desktop (Cowork) or Claude Code. Nothing here needs
approval from a Claude organisation owner or from HUIT: everything is downloaded from Wyss Apps
itself.

## The easy way: let Claude walk you through it

Open **AI Assistant (Claude)** in Wyss Apps (https://wigt.med.harvard.edu/tools/claude_access),
click **Copy the setup prompt**, and paste it into Claude (Desktop chat, or a Cowork task running on
your computer). Claude explains each step and waits for you:

1. Create a token on that page (name it after your computer; it starts with `wyss_`, is shown once;
   treat it like a password).
2. Save it in a file with one line in Terminal (the token is still in your clipboard):
   `mkdir -p ~/.wyss-apps && pbpaste > ~/.wyss-apps/token && chmod 600 ~/.wyss-apps/token`
3. Add this plugin: Customize → Plugins → Add → **Add marketplace**, paste
   `https://github.com/Wyss/wyss-apps-claude`, install **wyss-apps**, enable it.
4. Ask Claude to call `whoami`. It reports who Wyss Apps thinks you are.
5. Connect **Microsoft 365** in Claude (Customize → Connectors) so Claude can also answer "how do I"
   questions from the Wyss intranet.

In **Cowork**, start the task on **your computer** (not in the cloud): the plugin's connection runs
there and reads your token from the file.

## Claude Code (terminal)

Paste the one-line command shown on the Claude access page (it already has your token in it):

```bash
claude mcp add --transport http wyss-apps https://wigt.med.harvard.edu/mcp --header "Authorization: Bearer wyss_…"
```

Then type `/mcp` in Claude Code to check the connection. Add `--scope user` to make it available in
every folder on that computer.

## The skills (optional, recommended for regular users)

This plugin's `skills/` teach Claude the Wyss vocabulary and how to work the tools:
`wyss-apps` (projects, the science search, people), `wyss-style` (the shared Wyss language and
document style for every report, email or slide), and `costing-changes` (the payroll
costing-change queue, for Beth and the finance managers). The style guide is also served by the
`wyss_guide` (topic style) tool, so Claude gets it even without the plugin.

- Claude Desktop / claude.ai / Cowork: download **the Wyss Apps skills** (`wyss-apps-plugin.zip`)
  from the Claude access page and add them under **Customize → Plugins → Add → upload**.
  The data connection still comes from the extension above.
- Claude Code: unzip and run `claude --plugin-dir <folder>`, or install from a marketplace that
  has this folder. Claude Code prompts for your token when it enables the plugin
  (`.mcp.json` here uses a secure `userConfig` field).

## If something fails

| Symptom | Cause | Fix |
|---|---|---|
| Claude Desktop refuses to install the `.mcpb` | Your Claude organisation turned on the extension allow-list | Tell Matthew. Fallback: Claude Code, or a `claude_desktop_config.json` entry running `bridge/wyss-apps-bridge.mjs` with `WYSS_APPS_TOKEN` |
| Extension installed, but Claude sees no Wyss Apps tools | Claude Desktop not restarted; Cowork task running in the cloud; off the VPN | Restart Claude Desktop; start the Cowork task on your computer; connect to the VPN |
| Claude says "invalid_token" | Token expired or revoked | Create a new one and paste it into the extension's settings (or `claude mcp remove wyss-apps` and add again) |
| Claude says the account lacks the Claude access tool | A super user turned the tool off for you | Ask Matthew or a super user |
| Claude says it can't see financials | Your account has no financial access | That is the permission model working; ask a super user if you need it |
| "No sponsored project with id …" | Outside your scope (restricted accounts) or wrong id | Search again by name |

Questions: matthew.laubach@wyss.harvard.edu

## If Claude Desktop refuses the extension ("cannot be installed, contact your organization owner")

Your Claude organisation has an extension allow-list on. Use the plugin instead; it carries the
same connection as a local server that Cowork runs on your Mac:

1. On the Claude access page, create a token, then download **the Wyss Apps skills**
   (`wyss-apps-plugin.zip`).
2. Save the token in a file: open Terminal (Spotlight → "Terminal"), paste this and press
   Return (your token is still in the clipboard from step 1):

   ```bash
   mkdir -p ~/.wyss-apps && pbpaste > ~/.wyss-apps/token && chmod 600 ~/.wyss-apps/token
   ```

3. In Claude: **Customize → Plugins → Add → upload** the zip, and enable it.
4. Start a Cowork task **on your computer** and ask Claude to call `whoami`.

The bridge is `bridge/wyss-apps-bridge.sh` (bash + curl, nothing to install). The same file works
in `claude_desktop_config.json` for Claude Desktop chat:

```json
{ "mcpServers": { "wyss-apps": { "command": "bash", "args": ["/path/to/claude-plugin/bridge/wyss-apps-bridge.sh"] } } }
```

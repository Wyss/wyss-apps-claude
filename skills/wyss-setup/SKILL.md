---
name: wyss-setup
description: Check that Wyss Apps is set up in this assistant (Claude or Codex) for this person and fix what is not - "check my setup", "am I connected to Wyss Apps", "is this working", "what can I do here", the first message after installing the plugin, or any time a Wyss Apps tool fails with a token, VPN or access message. Verifies that the session runs on the computer, the token and the person's tool access, the browser tool for PeopleSoft (Claude in Chrome: costing changes and time off) and the Microsoft 365 connector (calendar, for meeting prep), tells them the one thing to fix, then shows what they can ask.
---

# Setup check

Three checks, each with one fix. Run them in order, say only what failed and how to fix it, and
end with what the person can do now. Never paste the whole setup guide; the setup page already
holds it: `https://wigt.med.harvard.edu/tools/claude_access`.

**Which assistant.** These steps name Claude's menus. In **Codex** (the ChatGPT desktop app,
the Codex command line or the IDE extension) there is no plugin: the connection is one block in
the Codex settings file (`~/.codex/config.toml`; on Windows `%USERPROFILE%\.codex\config.toml`)
that the setup page shows under **Codex**, with the token inside it. There, every token fix is
"create a token on <setup page>, replace the `Bearer` value in that file with it, and restart
Codex", a missing tool list is "add the Codex block from <setup page> and restart Codex", and
checks 2 and 3 are skipped (see check 2).

## 1. Wyss Apps connection

Call `whoami`.

| Result | Say |
|---|---|
| Answers with a name and tools | "Connected to Wyss Apps as <name>." (one line; then go on). If `plugin.update_available` is true, add its `plugin.update` line: the plugin is behind and the person should update it (Cowork: Customize, Plugins, Wyss Apps, Update). |
| Error "No Wyss Apps token" | "The token file is missing. Open <setup page>, create a token and click Download token file; it lands in your Downloads folder and the plugin moves it into place by itself. Then say check again." (A download older than a day is ignored: ask them to download a fresh one. If downloads are blocked, the page shows a one-line command for their computer under the new token.) |
| Error "refused the token (401)" | "The token has expired or was revoked. Open <setup page>, create a new token and click Download token file. Then say check again." The plugin replaces the old token with the fresh download on that next call. |
| Error "refused this account (403)" | "Your Wyss Apps account does not have the AI Assistant tool yet. Ask Matthew Laubach (matthew.laubach@wyss.harvard.edu) to add it." |
| Error "Cannot reach Wyss Apps" or "Wyss Apps is not reachable from this computer right now" | "Wyss Apps is only reachable on the Harvard network or VPN. Connect to the VPN, then say check again." No restart is needed. |
| The only Wyss Apps tool is `wyss_apps_status` | The chat started off the VPN on a computer that had never connected. "Connect to the VPN, then say check again." Call `wyss_apps_status`; once it answers, the full tool list loads (if it does not, start a new chat). |
| Error "This Wyss Apps plugin is too old" | Give the update steps from the message, then "start a new chat". |
| The `wyss-apps` tools are not there at all | Two causes; say both. (a) This Cowork session is running in the cloud, where the plugin cannot run, and there is no personal setting for that any more (the Claude organisation decides where Cowork runs): "This task is running in the cloud, where Wyss Apps cannot be reached. Use the Code tab of the Claude desktop app, which always runs on your computer, and ask again there." (b) The plugin is not installed or enabled: "In Cowork, open Customize, then Plugins, add `https://github.com/Wyss/wyss-apps-claude`, install wyss-apps and enable it for this chat." On Windows, "Add marketplace" is only offered when Git for Windows is installed: if it is missing, "open PowerShell, run `winget install --id Git.Git -e --source winget`, accept the prompts, restart Claude; if Windows asks for admin rights you do not have, ask Wyss IT to install Git for Windows." On a Mac the server is `wyss-apps`; on Windows `wyss-apps-win`; the other one shows as failed, which is expected. |

Stop after a failed check; the person fixes it and asks again.

## 2. Claude in Chrome

Anything in PeopleSoft (costing changes, time off) is read in the person's own Chrome, signed in
with HarvardKey and Duo, so the Claude in Chrome extension must be installed, signed in, and
enabled for this chat. If the Claude in Chrome tools (tabs, navigate, read page) are not among your tools, say:
"Install Claude in Chrome from the Chrome Web Store, sign in to it with the same account as this
chat, and turn it on for this chat. Then say check again." If they are present, say "Claude in
Chrome is on." and nothing more. Stop for this only when `whoami` lists the Costing Changes tool.
In Codex, skip this check and say one line only if they ask about time off or costing changes:
"Time off and costing changes in PeopleSoft work in Claude only for now."

## 3. Microsoft 365 (optional)

Meeting prep uses the Microsoft 365 connector for the person's calendar. If its calendar
search is not among your tools, say one line: "For meeting prep, connect Microsoft 365 in
Claude (Settings, Connectors) with your Harvard account."
Do not stop for this; everything else works without it.

## Then: what they can do

Three examples, chosen from the tools `whoami` lists, in the person's own domain:

- Everyone: "What is the status of the <sponsor> grant for <faculty>?", "Who works on
  organ-on-chip?", "Brief me on <faculty> before my 2pm.", "Check my time off."
- With Costing Changes: "Run the costing changes." (keys every ready request into PeopleSoft and
  stops at Save for them.)
- With Sponsored Queues: "Clear the sponsored queue." (shows each waiting grant with a guessed
  classification and saves what they confirm.)
- With Involvement: "Who at the Wyss knows about microfluidics?"
- With financial access: "How much runway does fund 377514 have?", "How much IDC did <faculty>
  generate this fiscal year?", "Chart sponsored spend by sponsor for FY2026."

Keep the whole answer under ten lines when everything passes.

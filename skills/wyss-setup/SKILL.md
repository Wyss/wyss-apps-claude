---
name: wyss-setup
description: Check that Wyss Apps for Claude is set up for this person and fix what is not - "check my setup", "am I connected to Wyss Apps", "is this working", "what can I do here", the first message after installing the plugin, or any time a Wyss Apps tool fails with a token, VPN or access message. Verifies that the session runs on the computer, the token and the person's tool access, Claude in Chrome (PeopleSoft: costing changes and time off) and the Microsoft 365 connector (calendar, for meeting prep), tells them the one thing to fix, then shows what they can ask.
---

# Setup check

Three checks, each with one fix. Run them in order, say only what failed and how to fix it, and
end with what the person can do now. Never paste the whole setup guide; the setup page already
holds it: `https://wigt.med.harvard.edu/tools/claude_access`.

## 1. Wyss Apps connection

Call `whoami`.

| Result | Say |
|---|---|
| Answers with a name and tools | "Connected to Wyss Apps as <name>." (one line; then go on). If `plugin.update_available` is true, add its `plugin.update` line: the plugin is behind and the person should update it (Cowork: Customize, Plugins, Wyss Apps, Update). |
| Error "No Wyss Apps token" | "The token file is missing. Open <setup page>, create a token, and run the one-line command the page shows for your computer. Then say check again." |
| Error "refused the token (401)" | "The token has expired or was revoked. Open <setup page>, create a new token and save it with the page's command. Then say check again." |
| Error "refused this account (403)" | "Your Wyss Apps account does not have the AI Assistant tool yet. Ask Matthew Laubach (matthew.laubach@wyss.harvard.edu) to add it." |
| Error "Cannot reach Wyss Apps" | "Wyss Apps is only reachable on the Harvard network or VPN. Connect to the VPN, then say check again." |
| The `wyss-apps` tools are not there at all | Two causes; say both. (a) This Cowork session is running in the cloud, where the plugin cannot run: "In Claude, open Settings, Cowork, and turn off *Run new tasks in the cloud*; then start a new session and ask again" (a session cannot switch; it has to be a new one). (b) The plugin is not installed or enabled: "In Cowork, open Customize, then Plugins, add `https://github.com/Wyss/wyss-apps-claude`, install wyss-apps and enable it for this chat." On a Mac the server is `wyss-apps`; on Windows `wyss-apps-win`; the other one shows as failed, which is expected. |

Stop after a failed check; the person fixes it and asks again.

## 2. Claude in Chrome

Anything in PeopleSoft (costing changes, time off) is read in the person's own Chrome, signed in
with HarvardKey and Duo, so the Claude in Chrome extension must be installed, signed in, and
enabled for this chat. If the Claude in Chrome tools (tabs, navigate, read page) are not among your tools, say:
"Install Claude in Chrome from the Chrome Web Store, sign in to it with the same account as this
chat, and turn it on for this chat. Then say check again." If they are present, say "Claude in
Chrome is on." and nothing more. Stop for this only when `whoami` lists the Costing Changes tool.

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
- With Involvement: "Who at the Wyss knows about microfluidics?"
- With financial access: "How much runway does fund 377514 have?"

Keep the whole answer under ten lines when everything passes.

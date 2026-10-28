#!/usr/bin/env node
// Stdio ⇄ Streamable HTTP bridge for the Wyss Apps MCP server.
//
// Claude Desktop / Cowork run local MCP servers over stdio. This script turns
// that into plain HTTPS calls to https://wigt.med.harvard.edu/mcp with the
// person's own access token, so the connection is made from the laptop (on
// the Wyss network or VPN), not from Anthropic's cloud. It needs Node 18+
// (built-in fetch) and no npm packages.
//
//   WYSS_APPS_TOKEN=wyss_…  [WYSS_APPS_URL=https://wigt.med.harvard.edu/mcp]  node wyss-apps-bridge.mjs
//
// Protocol: one JSON-RPC message per line on stdin; each request is POSTed
// and its JSON reply written to stdout. The server is stateless (no session
// id, no SSE), so every message is an independent exchange. Notifications
// (no id) are forwarded and produce no output.

import { createInterface } from "node:readline";

const url = process.env.WYSS_APPS_URL || "https://wigt.med.harvard.edu/mcp";
const CLIENT = "wyss-apps-extension/0.1.0";
const TIMEOUT_MS = 90_000;

// Claude Desktop closing the pipe must not leave a zombie or a stack trace.
process.stdout.on("error", (e) => { if (e.code === "EPIPE") process.exit(0); });
process.on("SIGTERM", () => process.exit(0));
const token = (process.env.WYSS_APPS_TOKEN || "").trim();

function write(obj) {
  process.stdout.write(JSON.stringify(obj) + "\n");
}

function errorReply(id, code, message, data) {
  write({ jsonrpc: "2.0", id, error: { code, message, ...(data ? { data } : {}) } });
}

async function forward(msg) {
  const id = msg.id;
  if (!token) {
    if (id !== undefined) errorReply(id, -32001, "No Wyss Apps token. Create one at https://wigt.med.harvard.edu/tools/claude_access and put it in WYSS_APPS_TOKEN.");
    return;
  }
  let res;
  const abort = new AbortController();
  const timer = setTimeout(() => abort.abort(), TIMEOUT_MS);
  try {
    res = await fetch(url, {
      method: "POST",
      signal: abort.signal,
      headers: {
        "content-type": "application/json",
        accept: "application/json, text/event-stream",
        authorization: `Bearer ${token}`,
        "x-wyss-apps-client": CLIENT,
      },
      body: JSON.stringify(msg),
    });
  } catch (e) {
    clearTimeout(timer);
    const why = e.name === "AbortError" ? `no answer within ${TIMEOUT_MS / 1000}s` : e.message;
    if (id !== undefined) errorReply(id, -32002, `Cannot reach Wyss Apps at ${url}: ${why}. Are you on the Wyss network or VPN?`);
    return;
  }
  clearTimeout(timer);
  if (res.status === 202 || res.status === 204) return; // notification accepted
  const text = await res.text();
  if (res.status === 401 || res.status === 403) {
    if (id !== undefined) errorReply(id, -32003, `Wyss Apps refused the token (${res.status}): ${text.slice(0, 300)}. Make a new token at https://wigt.med.harvard.edu/tools/claude_access.`);
    return;
  }
  if (res.status === 429) {
    if (id !== undefined) errorReply(id, -32004, "Wyss Apps rate limit: more than 120 requests a minute on this token. Wait a minute.");
    return;
  }
  // Streamable HTTP may answer as SSE even for a single reply; take the data lines.
  const ctype = res.headers.get("content-type") || "";
  let payload = text;
  if (ctype.includes("text/event-stream")) {
    payload = text.split("\n").filter((l) => l.startsWith("data:")).map((l) => l.slice(5).trim()).join("\n");
  }
  if (!payload.trim()) {
    if (id !== undefined) errorReply(id, -32005, `Empty reply from Wyss Apps (HTTP ${res.status}).`);
    return;
  }
  for (const line of payload.split("\n")) {
    if (!line.trim()) continue;
    try {
      process.stdout.write(JSON.stringify(JSON.parse(line)) + "\n");
    } catch {
      if (id !== undefined) errorReply(id, -32006, `Unreadable reply from Wyss Apps (HTTP ${res.status}): ${line.slice(0, 200)}`);
    }
  }
}

const rl = createInterface({ input: process.stdin, crlfDelay: Infinity });
let chain = Promise.resolve();
rl.on("line", (line) => {
  if (!line.trim()) return;
  let msg;
  try {
    msg = JSON.parse(line);
  } catch {
    errorReply(null, -32700, "Parse error");
    return;
  }
  const messages = Array.isArray(msg) ? msg : [msg];
  for (const m of messages) chain = chain.then(() => forward(m));
});
rl.on("close", () => chain.then(() => process.exit(0)));

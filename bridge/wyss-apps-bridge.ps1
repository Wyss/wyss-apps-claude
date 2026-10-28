# Stdio <-> HTTPS bridge for the Wyss Apps MCP server, PowerShell edition
# (Windows). Same contract as wyss-apps-bridge.sh: one JSON-RPC line in,
# one out; token from $env:WYSS_APPS_TOKEN or $HOME\.wyss-apps\token.
# Not wired into .mcp.json (plugin manifests cannot branch by platform);
# use it from claude_desktop_config.json:
#   { "mcpServers": { "wyss-apps": { "command": "powershell", "args": ["-NoProfile", "-File", "C:\\path\\wyss-apps-bridge.ps1"] } } }
$Url = if ($env:WYSS_APPS_URL) { $env:WYSS_APPS_URL } else { "https://wigt.med.harvard.edu/mcp" }
$Token = $env:WYSS_APPS_TOKEN
if (-not $Token) {
  $File = Join-Path $HOME ".wyss-apps\token"
  if (Test-Path $File) { $Token = (Get-Content $File -Raw).Trim() }
}
function Reply-Error($id, $code, $message) {
  $idJson = if ($id -is [string]) { '"' + $id + '"' } else { "$id" }
  Write-Output ('{"jsonrpc":"2.0","id":' + $idJson + ',"error":{"code":' + $code + ',"message":' + (ConvertTo-Json $message) + '}}')
}
while ($line = [Console]::In.ReadLine()) {
  if ([string]::IsNullOrWhiteSpace($line)) { continue }
  try { $msg = $line | ConvertFrom-Json } catch { Reply-Error $null -32700 "Parse error"; continue }
  $id = $msg.id
  if (-not $Token) { if ($null -ne $id) { Reply-Error $id -32001 "No Wyss Apps token. Create one at https://wigt.med.harvard.edu/tools/claude_access and save it in ~/.wyss-apps/token" }; continue }
  try {
    $resp = Invoke-WebRequest -Uri $Url -Method Post -ContentType "application/json" -Body $line -TimeoutSec 90 -UseBasicParsing `
      -Headers @{ "Authorization" = "Bearer $Token"; "Accept" = "application/json, text/event-stream"; "X-Wyss-Apps-Client" = "wyss-apps-plugin-bridge-ps/0.1.0" }
    if ($resp.StatusCode -eq 202 -or $resp.StatusCode -eq 204) { continue }
    $body = $resp.Content
    if ($body -match '^data:') { $body = ($body -split "`n" | Where-Object { $_ -like 'data:*' } | ForEach-Object { $_.Substring(5).Trim() }) -join "`n" }
    Write-Output $body
  } catch {
    $status = $_.Exception.Response.StatusCode.value__
    if ($null -eq $id) { continue }
    switch ($status) {
      401 { Reply-Error $id -32003 "Wyss Apps refused the token (401). Make a new token at https://wigt.med.harvard.edu/tools/claude_access and save it in ~/.wyss-apps/token" }
      403 { Reply-Error $id -32003 "Wyss Apps refused this account (403): it lacks the AI Assistant (Claude) tool. Ask Matthew Laubach." }
      429 { Reply-Error $id -32004 "Wyss Apps rate limit: more than 120 requests a minute. Wait a minute." }
      default { Reply-Error $id -32002 "Cannot reach Wyss Apps at $Url ($status). Are you on the Wyss network or VPN?" }
    }
  }
}

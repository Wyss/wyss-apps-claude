# Stdio <-> HTTPS bridge for the Wyss Apps MCP server, PowerShell edition
# (Windows; the plugin's wyss-apps-win server). Same contract as
# wyss-apps-bridge.sh: one JSON-RPC line in, one out. The token and URL are
# read on every request, so a new token in the file works without a restart.
#   token: $env:WYSS_APPS_TOKEN, then $env:WYSS_APPS_TOKEN_FILE, then $HOME\.wyss-apps\token
#   url:   $env:WYSS_APPS_URL, then $HOME\.wyss-apps\url, then https://wigt.med.harvard.edu/mcp
$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
$Client = "wyss-apps-plugin-bridge-ps/0.3.2"
$DefaultUrl = "https://wigt.med.harvard.edu/mcp"
$TokenHelp = "Create a token at https://wigt.med.harvard.edu/tools/claude_access and save it in $HOME\.wyss-apps\token (no restart needed)."

function Get-WyssToken {
  if ($env:WYSS_APPS_TOKEN) { return $env:WYSS_APPS_TOKEN.Trim() }
  $file = if ($env:WYSS_APPS_TOKEN_FILE) { $env:WYSS_APPS_TOKEN_FILE } else { Join-Path $HOME ".wyss-apps\token" }
  if (Test-Path $file) { return (Get-Content $file -Raw).Trim() }
  return $null
}
function Get-WyssUrl {
  if ($env:WYSS_APPS_URL) { return $env:WYSS_APPS_URL.Trim() }
  $file = Join-Path $HOME ".wyss-apps\url"
  if (Test-Path $file) { return (Get-Content $file -Raw).Trim() }
  return $DefaultUrl
}
function Write-Reply([string]$text) { [Console]::Out.WriteLine($text); [Console]::Out.Flush() }
function Write-RpcError($id, [int]$code, [string]$message) {
  $idJson = if ($null -eq $id) { "null" } elseif ($id -is [string]) { ConvertTo-Json $id -Compress } else { "$id" }
  Write-Reply ('{"jsonrpc":"2.0","id":' + $idJson + ',"error":{"code":' + $code + ',"message":' + (ConvertTo-Json $message -Compress) + '}}')
}

while ($null -ne ($line = [Console]::In.ReadLine())) {
  if ([string]::IsNullOrWhiteSpace($line)) { continue }
  $id = $null
  try { $msg = $line | ConvertFrom-Json; if ($msg.PSObject.Properties.Name -contains "id") { $id = $msg.id } }
  catch { Write-RpcError $null -32700 "Parse error"; continue }
  $token = Get-WyssToken
  $url = Get-WyssUrl
  if (-not $token) { if ($null -ne $id) { Write-RpcError $id -32001 "No Wyss Apps token. $TokenHelp" }; continue }
  try {
    $resp = Invoke-WebRequest -Uri $url -Method Post -ContentType "application/json" -Body ([System.Text.Encoding]::UTF8.GetBytes($line)) -TimeoutSec 90 -UseBasicParsing `
      -Headers @{ "Authorization" = "Bearer $token"; "Accept" = "application/json, text/event-stream"; "X-Wyss-Apps-Client" = $Client }
    if ($resp.StatusCode -eq 202 -or $resp.StatusCode -eq 204) { continue }
    $body = [System.Text.Encoding]::UTF8.GetString($resp.RawContentStream.ToArray())
    if ($body -match '^data:') { $body = (($body -split "`n") | Where-Object { $_ -like 'data:*' } | ForEach-Object { $_.Substring(5).Trim() }) -join "`n" }
    if ($null -ne $id -or $body.Trim().Length -gt 0) { Write-Reply $body.Trim() }
  } catch {
    $status = 0
    try { $status = [int]$_.Exception.Response.StatusCode } catch {}
    if ($null -eq $id) { continue }
    switch ($status) {
      401 { Write-RpcError $id -32003 "Wyss Apps refused the token (401: expired, revoked or wrong). $TokenHelp" }
      403 { Write-RpcError $id -32003 "Wyss Apps refused this account (403): it does not have the AI Assistant (Claude) tool. Ask Matthew Laubach (matthew.laubach@wyss.harvard.edu)." }
      429 { Write-RpcError $id -32004 "Wyss Apps rate limit: more than 120 requests a minute on this token. Wait a minute." }
      default { Write-RpcError $id -32002 "Cannot reach Wyss Apps at $url ($status). Are you on the Wyss network or VPN? ($($_.Exception.Message))" }
    }
  }
}

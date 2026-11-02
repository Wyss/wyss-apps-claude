# Stdio <-> HTTPS bridge for the Wyss Apps MCP server, PowerShell edition
# (Windows; the plugin's wyss-apps-win server). Same contract as
# wyss-apps-bridge.sh: one JSON-RPC line in, one out. The token and URL are
# read on every request, so a new token in the file works without a restart.
# When Wyss Apps cannot answer (off the VPN, no or expired token), Claude
# still connects: initialize and tools/list come from the last good replies
# in $HOME\.wyss-apps\cache (or a one-tool stub on a first run), and each tool
# call returns the reason as a tool error. A connection gives up after 4s.
#   token: $env:WYSS_APPS_TOKEN, then $env:WYSS_APPS_TOKEN_FILE, then $HOME\.wyss-apps\token
#   url:   $env:WYSS_APPS_URL, then $HOME\.wyss-apps\url, then https://wigt.med.harvard.edu/mcp
# No token, or a refused one: the Claude access page's "Download token file" saves
# the token as Downloads\wyss-apps-token (under $env:USERPROFILE), and the bridge
# moves that file into $HOME\.wyss-apps\token and removes it from Downloads, so the
# first call after the download simply works, with nothing typed. A download older
# than a day is ignored.
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"   # Windows PowerShell 5.1 would otherwise draw a progress bar per request
# Windows PowerShell 5.1 on an older Windows build may still default to TLS 1.0; make sure 1.2 is on.
try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch {}
# UTF-8 without a byte-order mark on both pipes: a BOM in front of the first reply breaks the client's JSON parse.
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[Console]::OutputEncoding = $Utf8NoBom
[Console]::InputEncoding = $Utf8NoBom
# The version reported to Wyss Apps is the plugin's (.claude-plugin/plugin.json next to
# this bridge's folder), so the server can tell the person when the plugin is behind.
$PluginVersion = "unknown"
try {
  $PluginJson = Join-Path (Split-Path -Parent $PSScriptRoot) ".claude-plugin\plugin.json"
  if (Test-Path $PluginJson) { $v = (Get-Content -Raw $PluginJson | ConvertFrom-Json).version; if ($v) { $PluginVersion = "$v" } }
} catch {}
$Client = "wyss-apps-plugin-bridge-ps/$PluginVersion"
$DefaultUrl = "https://wigt.med.harvard.edu/mcp"
$TokenHelp = "Create a token at https://wigt.med.harvard.edu/tools/claude_access, click `"Download token file`" and ask again: the plugin moves the downloaded file into $HOME\.wyss-apps\token by itself (no restart needed; a download older than a day is ignored)."
$WyssDir = Join-Path $HOME ".wyss-apps"
$CacheDir = Join-Path $WyssDir "cache"
$DownloadsDir = Join-Path $(if ($env:USERPROFILE) { $env:USERPROFILE } else { $HOME }) "Downloads"
$DownloadName = "wyss-apps-token"
$DownloadMaxAgeHours = 24
$OfflineHelp = "Wyss Apps is not reachable from this computer right now. Connect to the Wyss VPN (or the Harvard network) and ask again; nothing needs restarting."
$StatusTool = "wyss_apps_status"
$StubTools = $false                  # tools/list was answered with the stub: the next good reply asks Claude to reload the list
$OfflineUntil = [DateTime]::MinValue # after a failed connection, skip the network for 15s except on tool calls
$LastOk = [DateTime]::MinValue       # a TCP check (4s) runs first when nothing has answered for a minute

function Get-WyssToken {
  if ($env:WYSS_APPS_TOKEN) { return $env:WYSS_APPS_TOKEN.Trim() }
  $file = if ($env:WYSS_APPS_TOKEN_FILE) { $env:WYSS_APPS_TOKEN_FILE } else { Join-Path $WyssDir "token" }
  if (Test-Path $file) { return (Get-Content $file -Raw).Trim() }
  return $null
}
# Move a fresh Downloads\wyss-apps-token into place as the token file. $true when a
# token was adopted (the caller re-reads it). Nothing happens while $env:WYSS_APPS_TOKEN is set.
function Import-DownloadedToken {
  if ($env:WYSS_APPS_TOKEN) { return $false }
  $dest = if ($env:WYSS_APPS_TOKEN_FILE) { $env:WYSS_APPS_TOKEN_FILE } else { Join-Path $WyssDir "token" }
  foreach ($name in @($DownloadName, "$DownloadName.txt")) {
    $f = Join-Path $DownloadsDir $name
    if (-not (Test-Path $f -PathType Leaf)) { continue }
    try {
      $item = Get-Item $f
      if (([DateTime]::UtcNow - $item.LastWriteTimeUtc).TotalHours -gt $DownloadMaxAgeHours) { continue }
      if (-not ([System.IO.File]::ReadAllText($f)).Trim()) { continue }
      New-Item -ItemType Directory -Force (Split-Path -Parent $dest) | Out-Null
      Move-Item -Force $f $dest
      return $true
    } catch { continue }
  }
  return $false
}
function Get-WyssUrl {
  if ($env:WYSS_APPS_URL) { return $env:WYSS_APPS_URL.Trim() }
  $file = Join-Path $WyssDir "url"
  if (Test-Path $file) { return (Get-Content $file -Raw).Trim() }
  return $DefaultUrl
}
function Write-Reply([string]$text) { [Console]::Out.WriteLine($text); [Console]::Out.Flush() }
function ConvertTo-IdJson($id) {
  if ($null -eq $id) { return "null" }
  if ($id -is [string]) { return (ConvertTo-Json $id -Compress) }
  return "$id"
}
function Write-RpcError($id, [int]$code, [string]$message) {
  Write-Reply ('{"jsonrpc":"2.0","id":' + (ConvertTo-IdJson $id) + ',"error":{"code":' + $code + ',"message":' + (ConvertTo-Json $message -Compress) + '}}')
}
function Write-RpcResult($id, [string]$resultJson) {
  Write-Reply ('{"jsonrpc":"2.0","id":' + (ConvertTo-IdJson $id) + ',"result":' + $resultJson + '}')
}
# The `result` member of a compact success reply ({"jsonrpc":"2.0","id":N,"result":{...}}), or $null.
function Get-ResultJson([string]$body) {
  if (-not $body.StartsWith('{"jsonrpc":"2.0","id":')) { return $null }
  $at = $body.IndexOf('"result":')
  if ($at -lt 0) { return $null }
  $r = $body.Substring($at + 9).TrimEnd()
  return $r.Substring(0, $r.Length - 1)
}
function Save-CachedResult([string]$name, [string]$body) {
  $r = Get-ResultJson $body
  if (-not $r) { return }
  try {
    New-Item -ItemType Directory -Force $CacheDir | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $CacheDir "$name.json"), $r, $Utf8NoBom)
  } catch {}
}
function Get-CachedResult([string]$name) {
  $file = Join-Path $CacheDir "$name.json"
  if (Test-Path $file) { $r = [System.IO.File]::ReadAllText($file, $Utf8NoBom); if ($r.Trim().Length -gt 0) { return $r } }
  return $null
}
function Test-WyssReachable([string]$url) {
  try {
    $u = [Uri]$url
    $port = if ($u.Port -gt 0) { $u.Port } elseif ($u.Scheme -eq "http") { 80 } else { 443 }
    $client = New-Object System.Net.Sockets.TcpClient
    try { return ($client.ConnectAsync($u.Host, $port).Wait(4000) -and $client.Connected) } finally { $client.Close() }
  } catch { return $false }
}
# Wyss Apps could not answer: keep Claude connected and say why on each tool call.
function Send-OfflineAnswer($msg, $id, [int]$code, [string]$message) {
  if ($null -eq $id) { return }
  $text = ConvertTo-Json $message -Compress
  switch ($msg.method) {
    "initialize" {
      $cached = Get-CachedResult "initialize"
      if ($cached) { Write-RpcResult $id $cached; return }
      $pv = "2025-06-18"
      if ($msg.params -and $msg.params.protocolVersion) { $pv = "$($msg.params.protocolVersion)" }
      Write-RpcResult $id ('{"protocolVersion":' + (ConvertTo-Json $pv -Compress) + ',"capabilities":{"tools":{"listChanged":true}},"serverInfo":{"name":"wyss-apps","title":"Wyss Apps","version":"offline"},"instructions":' + $text + '}')
    }
    "tools/list" {
      $cached = Get-CachedResult "tools"
      if ($cached) { Write-RpcResult $id $cached; return }
      $script:StubTools = $true
      Write-RpcResult $id ('{"tools":[{"name":"' + $StatusTool + '","title":"Wyss Apps connection","description":"Wyss Apps could not be reached when this chat started. Call this whenever the person asks about Wyss projects, grants, people, finance or costing changes: it retries and says what to fix.","inputSchema":{"type":"object","properties":{}}}]}')
    }
    "tools/call" { Write-RpcResult $id ('{"content":[{"type":"text","text":' + $text + '}],"isError":true}') }
    default { Write-RpcError $id $code $message }
  }
}

while ($null -ne ($line = [Console]::In.ReadLine())) {
  if ([string]::IsNullOrWhiteSpace($line)) { continue }
  $id = $null
  try { $msg = $line | ConvertFrom-Json; if ($msg.PSObject.Properties.Name -contains "id") { $id = $msg.id } }
  catch { Write-RpcError $null -32700 "Parse error"; continue }
  $token = Get-WyssToken
  if (-not $token -and (Import-DownloadedToken)) { $token = Get-WyssToken }
  $url = Get-WyssUrl
  if (-not $token) { Send-OfflineAnswer $msg $id -32001 "No Wyss Apps token on this computer. $TokenHelp"; continue }
  $isCall = $msg.method -eq "tools/call"
  if (-not $isCall -and [DateTime]::UtcNow -lt $OfflineUntil) { Send-OfflineAnswer $msg $id -32002 $OfflineHelp; continue }
  if (([DateTime]::UtcNow - $LastOk).TotalSeconds -gt 60 -and -not (Test-WyssReachable $url)) {
    $OfflineUntil = [DateTime]::UtcNow.AddSeconds(15)
    Send-OfflineAnswer $msg $id -32002 $OfflineHelp
    continue
  }
  # The stub tool is whoami under another name: once Wyss Apps answers, it proves the connection.
  if ($isCall -and $msg.params -and $msg.params.name -eq $StatusTool) { $line = $line.Replace('"name":"' + $StatusTool + '"', '"name":"whoami"') }
  $attempt = 0
  while ($true) {   # one request; a second only when a refused token was replaced by a fresh download
    $attempt++
    try {
      $resp = Invoke-WebRequest -Uri $url -Method Post -ContentType "application/json" -Body ([System.Text.Encoding]::UTF8.GetBytes($line)) -TimeoutSec 90 -UseBasicParsing `
        -Headers @{ "Authorization" = "Bearer $token"; "Accept" = "application/json, text/event-stream"; "X-Wyss-Apps-Client" = $Client }
      $LastOk = [DateTime]::UtcNow
      $OfflineUntil = [DateTime]::MinValue
      if ($resp.StatusCode -eq 202 -or $resp.StatusCode -eq 204) { break }
      $body = [System.Text.Encoding]::UTF8.GetString($resp.RawContentStream.ToArray())
      if ($body -match '^data:') { $body = (($body -split "`n") | Where-Object { $_ -like 'data:*' } | ForEach-Object { $_.Substring(5).Trim() }) -join "`n" }
      $body = $body.Trim()
      if ($null -ne $id -or $body.Length -gt 0) { Write-Reply $body }
      if ($msg.method -eq "initialize") { Save-CachedResult "initialize" $body }
      if ($msg.method -eq "tools/list") { Save-CachedResult "tools" $body; $StubTools = $false }
      if ($StubTools) { $StubTools = $false; Write-Reply '{"jsonrpc":"2.0","method":"notifications/tools/list_changed"}' }
    } catch {
      $err = $_
      $status = 0
      try { $status = [int]$err.Exception.Response.StatusCode } catch {}
      if ($status -ne 0) { $LastOk = [DateTime]::UtcNow; $OfflineUntil = [DateTime]::MinValue }
      if ($status -eq 401 -and $attempt -eq 1 -and (Import-DownloadedToken)) { $token = Get-WyssToken; continue }
      switch ($status) {
        0 { $OfflineUntil = [DateTime]::UtcNow.AddSeconds(15); Send-OfflineAnswer $msg $id -32002 $OfflineHelp }
        401 { Send-OfflineAnswer $msg $id -32003 "Wyss Apps refused the token (expired, revoked or wrong). $TokenHelp" }
        403 { Send-OfflineAnswer $msg $id -32003 "Wyss Apps refused this account: it does not have the AI Assistant (Claude) tool. Ask Matthew Laubach (matthew.laubach@wyss.harvard.edu)." }
        429 { if ($null -ne $id) { Write-RpcError $id -32004 "Wyss Apps rate limit: more than 120 requests a minute on this token. Wait a minute." } }
        default { Send-OfflineAnswer $msg $id -32005 "Wyss Apps answered HTTP $status. ($($err.Exception.Message))" }
      }
    }
    break
  }
}

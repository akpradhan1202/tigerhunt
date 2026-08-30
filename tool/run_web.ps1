#Requires -Version 5.1
<#
.SYNOPSIS
    Run TigerHunt on the web (Chrome by default) for manual testing.

.DESCRIPTION
    Locates the Flutter SDK (PATH, or flutter.sdk in android/local.properties), then
    runs the app in Chrome via 'flutter run -d chrome' (interactive: r = reload, q = quit).

.PARAMETER Server
    Use the headless 'web-server' device (prints a localhost URL you open yourself)
    instead of launching Chrome.

.PARAMETER Build
    Build a web bundle ('flutter build web') instead of running. Output goes to
    build/web and is captured to tool/web-output.txt.

.PARAMETER Release
    Release mode instead of debug.

.PARAMETER Port
    Fixed web port for the dev server (0 = let Flutter pick one).

.PARAMETER NoDds
    Pass --no-dds. Workaround for a DartDevelopmentServiceException / websocket-upgrade
    error seen on some setups (notably with -Server / web-server).

.EXAMPLE
    .\tool\run_web.ps1

.EXAMPLE
    .\tool\run_web.ps1 -Port 8080

.EXAMPLE
    .\tool\run_web.ps1 -Server -NoDds

.EXAMPLE
    .\tool\run_web.ps1 -Build -Release
#>
[CmdletBinding()]
param(
    [switch]$Server,
    [switch]$Build,
    [switch]$Release,
    [int]$Port = 0,
    [switch]$NoDds
)

$ErrorActionPreference = 'Stop'

# --- Paths -----------------------------------------------------------------
$RepoRoot = Split-Path -Parent $PSScriptRoot
$LogFile  = Join-Path $PSScriptRoot 'web-output.txt'
Set-Location $RepoRoot

"TigerHunt web run - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Set-Content -Path $LogFile -Encoding UTF8

function Log {
    param([string]$Text = '')
    Write-Host $Text
    Add-Content -Path $LogFile -Value $Text -Encoding UTF8
}

# --- Locate Flutter --------------------------------------------------------
$FlutterCmd = $null
$onPath = Get-Command flutter -ErrorAction SilentlyContinue
if ($onPath) {
    $FlutterCmd = $onPath.Source
} else {
    $localProps = Join-Path $RepoRoot 'android\local.properties'
    if (Test-Path $localProps) {
        $m = Select-String -Path $localProps -Pattern '^\s*flutter\.sdk\s*=\s*(.+)$' | Select-Object -First 1
        if ($m) {
            $sdk = ($m.Matches[0].Groups[1].Value.Trim()) -replace '\\\\', '\'
            $candidate = Join-Path $sdk 'bin\flutter.bat'
            if (Test-Path $candidate) { $FlutterCmd = $candidate }
        }
    }
}
if (-not $FlutterCmd) {
    Log "ERROR: Could not find 'flutter'. Put it on PATH, or set flutter.sdk in android/local.properties."
    exit 1
}
Log "Using Flutter: $FlutterCmd"

# --- Build-only path -------------------------------------------------------
if ($Build) {
    $buildArgs = @('build', 'web')
    if ($Release) { $buildArgs += '--release' }
    Log ''
    Log "=== flutter $($buildArgs -join ' ') ==="
    & $FlutterCmd @buildArgs 2>&1 | Tee-Object -FilePath $LogFile -Append
    exit $LASTEXITCODE
}

# --- Run -------------------------------------------------------------------
$device = if ($Server) { 'web-server' } else { 'chrome' }
$runArgs = @('run', '-d', $device)
if ($Release) { $runArgs += '--release' }
if ($Port -gt 0) { $runArgs += @('--web-port', "$Port") }
if ($NoDds)      { $runArgs += '--no-dds' }

Log ''
Log "=== flutter $($runArgs -join ' ') ==="
if ($Server) {
    Log 'web-server mode: open the http://localhost URL it prints in your browser.'
}
Log '(interactive: press r = hot reload, R = hot restart, q = quit)'
& $FlutterCmd @runArgs
exit $LASTEXITCODE

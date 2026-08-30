#Requires -Version 5.1
<#
.SYNOPSIS
    Build and launch TigerHunt on an Android emulator for manual testing.

.DESCRIPTION
    1. Locates the Flutter SDK (PATH, or flutter.sdk in android/local.properties).
    2. Runs 'flutter doctor -v' plus an emulator/device inventory (saved to
       tool/android-output.txt) so setup problems are easy to spot.
    3. If no Android device is attached, boots an AVD and waits for it to come online.
    4. Runs the app on that device ('flutter run', interactive: r = reload, q = quit).

.PARAMETER Doctor
    Only run diagnostics (doctor + emulators + devices), then stop.

.PARAMETER SkipDoctor
    Skip 'flutter doctor -v' (faster on repeat runs).

.PARAMETER Release
    Run/build in release mode instead of debug.

.PARAMETER Apk
    Build an APK ('flutter build apk') instead of running interactively.
    Full build output is captured to the log file - handy for diagnosing build failures.

.PARAMETER Emulator
    AVD id to launch (see 'flutter emulators'). Defaults to the first one listed.

.PARAMETER WaitSeconds
    Seconds to wait for the emulator to come online (default 120).

.EXAMPLE
    .\tool\run_android.ps1

.EXAMPLE
    .\tool\run_android.ps1 -Emulator Pixel_7_API_34 -WaitSeconds 180

.EXAMPLE
    .\tool\run_android.ps1 -Doctor
#>
[CmdletBinding()]
param(
    [switch]$Doctor,
    [switch]$SkipDoctor,
    [switch]$Release,
    [switch]$Apk,
    [string]$Emulator,
    [int]$WaitSeconds = 120
)

$ErrorActionPreference = 'Stop'

# --- Paths -----------------------------------------------------------------
$RepoRoot = Split-Path -Parent $PSScriptRoot
$LogFile  = Join-Path $PSScriptRoot 'android-output.txt'
Set-Location $RepoRoot

"TigerHunt Android run - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Set-Content -Path $LogFile -Encoding UTF8

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

# --- Diagnostics -----------------------------------------------------------
if (-not $SkipDoctor) {
    Log ''
    Log '=== flutter doctor -v ==='
    & $FlutterCmd doctor -v 2>&1 | Tee-Object -FilePath $LogFile -Append
}

Log ''
Log '=== flutter emulators ==='
$emulatorsRaw = & $FlutterCmd emulators 2>&1
$emulatorsRaw | Tee-Object -FilePath $LogFile -Append

Log ''
Log '=== flutter devices ==='
& $FlutterCmd devices 2>&1 | Tee-Object -FilePath $LogFile -Append

if ($Doctor) {
    Log ''
    Log "-Doctor set: stopping after diagnostics. Log: $LogFile"
    exit 0
}

# --- Ensure an Android device is online ------------------------------------
function Get-AndroidDevices {
    # --machine emits pretty-printed (multi-line) JSON; join to one string before parsing,
    # otherwise ConvertFrom-Json on a string[] throws on PowerShell 5.1.
    $json = (& $FlutterCmd devices --machine 2>$null) -join "`n"
    if ([string]::IsNullOrWhiteSpace($json)) { return @() }
    try { $parsed = $json | ConvertFrom-Json } catch { return @() }
    return @($parsed | Where-Object { $_.platformType -eq 'android' })
}

$android = Get-AndroidDevices
if (-not $android -or $android.Count -eq 0) {
    Log ''
    Log 'No Android device attached; booting an emulator...'

    $avdId = $Emulator
    if (-not $avdId) {
        # 'flutter emulators' separates columns with a bullet (U+2022). Build it from its
        # code point (pure-ASCII source) so parsing works no matter how PowerShell decodes
        # this .ps1 file - avoids a mangled literal bullet under Windows PowerShell 5.1.
        $bullet = [char]0x2022
        foreach ($line in $emulatorsRaw) {
            # AVD line: "<id> <bullet> <name> <bullet> <manufacturer> <bullet> <platform>".
            # Flutter 3.47+ prints a header row "Id <bullet> Name <bullet> ..." first - skip it.
            if ("$line" -match "^\s*(\S[^$bullet]*?)\s*$bullet") {
                $candidate = $matches[1].Trim()
                if ($candidate -and $candidate -ne 'Id') { $avdId = $candidate; break }
            }
        }
    }
    if (-not $avdId) {
        Log "ERROR: No AVDs found. Create one in Android Studio > Device Manager (or 'flutter emulators --create'), then re-run."
        exit 1
    }

    Log "Launching emulator: $avdId"
    & $FlutterCmd emulators --launch $avdId 2>&1 | Tee-Object -FilePath $LogFile -Append

    Log "Waiting up to $WaitSeconds s for it to come online..."
    $deadline = (Get-Date).AddSeconds($WaitSeconds)
    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Seconds 3
        $android = Get-AndroidDevices
        if ($android.Count -gt 0) { break }
        Write-Host '  ...still booting'
    }
}

if (-not $android -or $android.Count -eq 0) {
    Log "ERROR: No Android device came online within $WaitSeconds s. Check the emulator window / 'flutter devices'."
    exit 1
}

$target = $android | Where-Object { $_.emulator -eq $true } | Select-Object -First 1
if (-not $target) { $target = $android | Select-Object -First 1 }
$deviceId = $target.id
Log ''
Log "Target: $($target.name) [$deviceId]"

# --- Build / run -----------------------------------------------------------
if ($Apk) {
    $mode = if ($Release) { '--release' } else { '--debug' }
    Log ''
    Log "=== flutter build apk $mode ==="
    & $FlutterCmd build apk $mode 2>&1 | Tee-Object -FilePath $LogFile -Append
    exit $LASTEXITCODE
}

$runArgs = @('run', '-d', $deviceId)
if ($Release) { $runArgs += '--release' }
Log ''
Log "=== flutter $($runArgs -join ' ') ==="
Log "(interactive: press r = hot reload, R = hot restart, q = quit)"
& $FlutterCmd @runArgs
exit $LASTEXITCODE

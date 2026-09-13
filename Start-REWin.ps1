# ============================================================
# REWin
# Windows IT Diagnostics Toolkit
# Main Launcher V3
# ============================================================

$REWinRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"
$InformationPreference = "SilentlyContinue"
$VerbosePreference = "SilentlyContinue"
$DebugPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"


# ============================================================
# LOAD MODULES
# ============================================================

$ModulePaths = @(
    "$REWinRoot\src\Core\Logger.psm1",
    "$REWinRoot\src\Core\Privilege.psm1",
    "$REWinRoot\src\Core\Backup.psm1",
    "$REWinRoot\src\Core\HealthReport.psm1",
    "$REWinRoot\src\Core\HealthReportHtml.psm1",
    "$REWinRoot\src\Diagnostics\SystemDiagnostics.psm1",
    "$REWinRoot\src\Diagnostics\DiskDiagnostics.psm1",
    "$REWinRoot\src\Diagnostics\NetworkDiagnostics.psm1",
    "$REWinRoot\src\Diagnostics\WindowsUpdateDiagnostics.psm1",
    "$REWinRoot\src\Diagnostics\EventLogDiagnostics.psm1",
    "$REWinRoot\src\Diagnostics\CrashDiagnostics.psm1",
    "$REWinRoot\src\Diagnostics\HardwareDiagnostics.psm1",
    "$REWinRoot\src\Security\SecurityDiagnostics.psm1"
)


foreach ($ModulePath in $ModulePaths) {

    if (Test-Path $ModulePath) {

        Import-Module $ModulePath `
            -Force `
            -ErrorAction SilentlyContinue `
            2>$null `
            3>$null `
            4>$null `
            5>$null `
            6>$null
    }
}


# ============================================================
# GLOBAL REPORT
# ============================================================

$Global:REWinHealthReport = $null


# ============================================================
# TITLE
# ============================================================

function Show-REWinTitle {

    Clear-Host

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "                         REWin" -ForegroundColor White
    Write-Host "              Windows IT Diagnostics Toolkit" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
}


# ============================================================
# HEALTH CHECK
# ============================================================

function Get-REWinCurrentHealth {

    try {

        $Global:REWinHealthReport = Get-REWinHealthReport `
            -ErrorAction Stop `
            2>$null `
            3>$null `
            4>$null `
            5>$null `
            6>$null

        return $true
    }
    catch {

        $Global:REWinHealthReport = $null

        return $false
    }
}


# ============================================================
# HEALTH SUMMARY
# ============================================================

function Show-REWinHealth {

    Write-Host " SYSTEM HEALTH" -ForegroundColor Cyan
    Write-Host " ----------------------------------------------------------"

    if ($null -eq $Global:REWinHealthReport) {

        Write-Host " Status           : NOT SCANNED" -ForegroundColor Yellow
        Write-Host ""

        return
    }


    $Report = $Global:REWinHealthReport
    $Score = [int]$Report.OverallScore


    if ($Score -ge 90) {
        $Color = "Green"
    }
    elseif ($Score -ge 75) {
        $Color = "Cyan"
    }
    elseif ($Score -ge 50) {
        $Color = "Yellow"
    }
    else {
        $Color = "Red"
    }


    Write-Host " Overall Score    : " -NoNewline
    Write-Host "$Score / 100" -ForegroundColor $Color

    Write-Host " Overall Status   : " -NoNewline
    Write-Host "$($Report.OverallStatus)" -ForegroundColor $Color

    Write-Host " Issues           : $($Report.IssueCount)"

    Write-Host " Critical         : $($Report.CriticalCount)"

    Write-Host " Warnings         : $($Report.WarningCount)"

    Write-Host ""
}


# ============================================================
# ADMINISTRATOR
# ============================================================

function Show-REWinAdministrator {

    Write-Host " ADMINISTRATOR" -ForegroundColor Cyan
    Write-Host " ----------------------------------------------------------"

    try {

        $Privilege = Get-REWinPrivilegeStatus `
            -ErrorAction Stop `
            2>$null `
            3>$null `
            4>$null `
            5>$null `
            6>$null

        if ($Privilege.IsAdministrator) {

            Write-Host " Status           : " -NoNewline
            Write-Host "YES" -ForegroundColor Green
        }
        else {

            Write-Host " Status           : " -NoNewline
            Write-Host "NO" -ForegroundColor Yellow
        }
    }
    catch {

        Write-Host " Status           : UNKNOWN" -ForegroundColor Yellow
    }

    Write-Host ""
}


# ============================================================
# WAIT
# ============================================================

function Wait-REWin {

    Write-Host ""

    Read-Host "Press ENTER to continue"
}


# ============================================================
# QUICK HEALTH
# ============================================================

function Invoke-REWinQuickHealth {

    Show-REWinTitle

    Write-Host " QUICK HEALTH CHECK" -ForegroundColor Cyan
    Write-Host " ----------------------------------------------------------"
    Write-Host ""

    if (Get-REWinCurrentHealth) {

        Show-REWinHealth

        if ($Global:REWinHealthReport.Recommendations) {

            Write-Host " RECOMMENDATIONS" -ForegroundColor Yellow
            Write-Host " ----------------------------------------------------------"

            foreach ($Recommendation in $Global:REWinHealthReport.Recommendations) {

                Write-Host "[!] " -ForegroundColor Yellow -NoNewline

                Write-Host "$($Recommendation.Area): $($Recommendation.Message)"
            }
        }
    }
    else {

        Write-Host "Health check failed." -ForegroundColor Red
    }

    Wait-REWin
}


# ============================================================
# SYSTEM
# ============================================================

function Invoke-REWinSystem {

    Show-REWinTitle

    Write-Host " SYSTEM DIAGNOSTICS" -ForegroundColor Cyan
    Write-Host ""

    try {

        Get-REWinSystemDiagnostics `
            -ErrorAction Stop `
            2>$null |
            Format-List
    }
    catch {

        Write-Host $_.Exception.Message -ForegroundColor Red
    }

    Wait-REWin
}


# ============================================================
# DISK
# ============================================================

function Invoke-REWinDisk {

    Show-REWinTitle

    Write-Host " DISK DIAGNOSTICS" -ForegroundColor Cyan
    Write-Host ""

    try {

        Get-REWinDiskDiagnostics `
            -ErrorAction Stop `
            2>$null |
            Format-Table -AutoSize
    }
    catch {

        Write-Host $_.Exception.Message -ForegroundColor Red
    }

    Wait-REWin
}


# ============================================================
# NETWORK
# ============================================================

function Invoke-REWinNetwork {

    Show-REWinTitle

    Write-Host " NETWORK DIAGNOSTICS" -ForegroundColor Cyan
    Write-Host ""

    try {

        Get-REWinNetworkDiagnostics `
            -ErrorAction Stop `
            2>$null |
            Format-List
    }
    catch {

        Write-Host $_.Exception.Message -ForegroundColor Red
    }

    Wait-REWin
}


# ============================================================
# WINDOWS UPDATE
# ============================================================

function Invoke-REWinWindowsUpdate {

    Show-REWinTitle

    Write-Host " WINDOWS UPDATE DIAGNOSTICS" -ForegroundColor Cyan
    Write-Host ""

    try {

        Get-REWinWindowsUpdateDiagnostics `
            -ErrorAction Stop `
            2>$null |
            Format-List
    }
    catch {

        Write-Host $_.Exception.Message -ForegroundColor Red
    }

    Wait-REWin
}


# ============================================================
# EVENT LOG
# ============================================================

function Invoke-REWinEventLog {

    Show-REWinTitle

    Write-Host " EVENT LOG DIAGNOSTICS" -ForegroundColor Cyan
    Write-Host ""

    try {

        Get-REWinEventLogDiagnostics `
            -ErrorAction Stop `
            2>$null |
            Format-List
    }
    catch {

        Write-Host $_.Exception.Message -ForegroundColor Red
    }

    Wait-REWin
}


# ============================================================
# CRASH
# ============================================================

function Invoke-REWinCrash {

    Show-REWinTitle

    Write-Host " CRASH DIAGNOSTICS" -ForegroundColor Cyan
    Write-Host ""

    try {

        Get-REWinCrashDiagnostics `
            -ErrorAction Stop `
            2>$null |
            Format-List
    }
    catch {

        Write-Host $_.Exception.Message -ForegroundColor Red
    }

    Wait-REWin
}


# ============================================================
# HARDWARE
# ============================================================

function Invoke-REWinHardware {

    Show-REWinTitle

    Write-Host " HARDWARE DIAGNOSTICS" -ForegroundColor Cyan
    Write-Host ""

    try {

        Get-REWinHardwareDiagnostics `
            -ErrorAction Stop `
            2>$null |
            Format-List
    }
    catch {

        Write-Host $_.Exception.Message -ForegroundColor Red
    }

    Wait-REWin
}


# ============================================================
# SECURITY
# ============================================================

function Invoke-REWinSecurity {

    Show-REWinTitle

    Write-Host " SECURITY DIAGNOSTICS" -ForegroundColor Cyan
    Write-Host ""

    try {

        Get-REWinSecurityDiagnostics `
            -ErrorAction Stop `
            2>$null |
            Format-List
    }
    catch {

        Write-Host $_.Exception.Message -ForegroundColor Red
    }

    Wait-REWin
}


# ============================================================
# HTML REPORT
# ============================================================

function Invoke-REWinHtmlReport {

    Show-REWinTitle

    Write-Host " GENERATING HTML HEALTH REPORT" -ForegroundColor Cyan
    Write-Host ""

    try {

        $Report = Get-REWinHealthReport `
            -ErrorAction Stop `
            2>$null `
            3>$null `
            4>$null `
            5>$null `
            6>$null


        $ReportPath = Join-Path `
            $env:USERPROFILE `
            "Desktop\REWin-HealthReport.html"


        Export-REWinHealthReport `
            -Report $Report `
            -Path $ReportPath `
            -Language EN `
            -ErrorAction Stop `
            2>$null `
            3>$null `
            4>$null `
            5>$null `
            6>$null


        Write-Host ""
        Write-Host "Report created successfully." -ForegroundColor Green
        Write-Host ""
        Write-Host $ReportPath -ForegroundColor Cyan


        Start-Process $ReportPath
    }
    catch {

        Write-Host ""
        Write-Host "Report generation failed." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }

    Wait-REWin
}


# ============================================================
# MAIN MENU
# ============================================================

do {

    Show-REWinTitle

    Show-REWinHealth

    Show-REWinAdministrator


    Write-Host " DIAGNOSTICS" -ForegroundColor Cyan
    Write-Host " ----------------------------------------------------------"

    Write-Host " [1] Quick Health Check"
    Write-Host " [2] System Diagnostics"
    Write-Host " [3] Disk Diagnostics"
    Write-Host " [4] Network Diagnostics"
    Write-Host " [5] Windows Update"
    Write-Host " [6] Event Log Diagnostics"
    Write-Host " [7] Crash Diagnostics"
    Write-Host " [8] Hardware Diagnostics"
    Write-Host " [9] Security Diagnostics"

    Write-Host ""

    Write-Host " REPORTS" -ForegroundColor Cyan
    Write-Host " ----------------------------------------------------------"

    Write-Host " [10] Generate HTML Health Report"

    Write-Host ""
    Write-Host " [0] Exit"

    Write-Host ""

    $Choice = Read-Host "Select an option"


    switch ($Choice) {

        "1" {
            Invoke-REWinQuickHealth
        }

        "2" {
            Invoke-REWinSystem
        }

        "3" {
            Invoke-REWinDisk
        }

        "4" {
            Invoke-REWinNetwork
        }

        "5" {
            Invoke-REWinWindowsUpdate
        }

        "6" {
            Invoke-REWinEventLog
        }

        "7" {
            Invoke-REWinCrash
        }

        "8" {
            Invoke-REWinHardware
        }

        "9" {
            Invoke-REWinSecurity
        }

        "10" {
            Invoke-REWinHtmlReport
        }

        "0" {
            Write-Host ""
            Write-Host "Exiting REWin..." -ForegroundColor Cyan
        }

        default {
            Write-Host ""
            Write-Host "Invalid option." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }

}
while ($Choice -ne "0")
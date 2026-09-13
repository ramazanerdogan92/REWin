# ============================================================
# REWin - Main Launcher
# Windows IT Diagnostics & Health Toolkit
# ============================================================

$REWinRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# ============================================================
# MODULE PATHS
# ============================================================

$LoggerPath       = Join-Path $REWinRoot "src\Core\Logger.psm1"
$PrivilegePath    = Join-Path $REWinRoot "src\Core\Privilege.psm1"
$SystemPath       = Join-Path $REWinRoot "src\Diagnostics\SystemDiagnostics.psm1"
$DiskPath         = Join-Path $REWinRoot "src\Diagnostics\DiskDiagnostics.psm1"
$NetworkPath      = Join-Path $REWinRoot "src\Diagnostics\NetworkDiagnostics.psm1"
$UpdatePath       = Join-Path $REWinRoot "src\Diagnostics\WindowsUpdateDiagnostics.psm1"
$EventLogPath     = Join-Path $REWinRoot "src\Diagnostics\EventLogDiagnostics.psm1"
$CrashPath        = Join-Path $REWinRoot "src\Diagnostics\CrashDiagnostics.psm1"
$HardwarePath     = Join-Path $REWinRoot "src\Diagnostics\HardwareDiagnostics.psm1"
$SecurityPath     = Join-Path $REWinRoot "src\Security\SecurityDiagnostics.psm1"
$HealthPath       = Join-Path $REWinRoot "src\Core\HealthReport.psm1"
$HtmlReportPath   = Join-Path $REWinRoot "src\Core\HealthReportHtml.psm1"


# ============================================================
# LOAD MODULES
# ============================================================

$Modules = @(
    $LoggerPath,
    $PrivilegePath,
    $SystemPath,
    $DiskPath,
    $NetworkPath,
    $UpdatePath,
    $EventLogPath,
    $CrashPath,
    $HardwarePath,
    $SecurityPath,
    $HealthPath,
    $HtmlReportPath
)

foreach ($Module in $Modules) {

    if (Test-Path $Module) {

        Import-Module $Module -Force -ErrorAction SilentlyContinue

    }
}


# ============================================================
# LOGGING
# ============================================================

if (Get-Command Initialize-REWinLogging -ErrorAction SilentlyContinue) {

    Initialize-REWinLogging

}


# ============================================================
# COLORS
# ============================================================

function Write-REWinTitle {

    Clear-Host

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "                         REWin" -ForegroundColor White
    Write-Host "             Windows IT Diagnostics Toolkit" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Cyan
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
# PRIVILEGE CHECK
# ============================================================

function Show-REWinPrivilege {

    if (Get-Command Get-REWinPrivilegeStatus -ErrorAction SilentlyContinue) {

        $Privilege = Get-REWinPrivilegeStatus

        if ($Privilege.IsAdministrator) {

            Write-Host "Administrator : YES" -ForegroundColor Green

        }
        else {

            Write-Host "Administrator : NO" -ForegroundColor Yellow

        }
    }
}


# ============================================================
# QUICK HEALTH CHECK
# ============================================================

function Invoke-REWinQuickHealth {

    Write-REWinTitle

    Write-Host "Running REWin Health Check..." -ForegroundColor Cyan
    Write-Host ""

    try {

        $Report = Get-REWinHealthReport -ErrorAction Stop

        Write-Host "Overall Score  : " -NoNewline
        Write-Host "$($Report.OverallScore) / 100" -ForegroundColor Green

        Write-Host "Overall Status : " -NoNewline
        Write-Host "$($Report.OverallStatus)" -ForegroundColor Green

        Write-Host ""

        Write-Host "Issues         : $($Report.IssueCount)"
        Write-Host "Critical       : $($Report.CriticalCount)"
        Write-Host "Warnings       : $($Report.WarningCount)"

        Write-Host ""

        Write-Host "Module Scores" -ForegroundColor Cyan
        Write-Host "-------------"

        foreach ($Module in $Report.ModuleScores.PSObject.Properties) {

            $Score = $Module.Value

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

            Write-Host ("{0,-18}" -f $Module.Name) -NoNewline
            Write-Host $Score -ForegroundColor $Color
        }

        Write-Host ""

        if ($Report.Recommendations) {

            Write-Host "Recommendations" -ForegroundColor Yellow
            Write-Host "---------------"

            foreach ($Recommendation in $Report.Recommendations) {

                Write-Host "[!] " -ForegroundColor Yellow -NoNewline
                Write-Host "$($Recommendation.Area): $($Recommendation.Message)"
            }
        }

    }
    catch {

        Write-Host ""
        Write-Host "Health check failed." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }

    Wait-REWin
}


# ============================================================
# SYSTEM
# ============================================================

function Invoke-REWinSystem {

    Write-REWinTitle

    Write-Host "System Diagnostics" -ForegroundColor Cyan
    Write-Host ""

    $Result = Get-REWinSystemDiagnostics

    $Result | Format-List

    Wait-REWin
}


# ============================================================
# DISK
# ============================================================

function Invoke-REWinDisk {

    Write-REWinTitle

    Write-Host "Disk Diagnostics" -ForegroundColor Cyan
    Write-Host ""

    $Result = Get-REWinDiskDiagnostics

    $Result | Format-Table -AutoSize

    Wait-REWin
}


# ============================================================
# NETWORK
# ============================================================

function Invoke-REWinNetwork {

    Write-REWinTitle

    Write-Host "Network Diagnostics" -ForegroundColor Cyan
    Write-Host ""

    $Result = Get-REWinNetworkDiagnostics

    $Result | Format-List

    Wait-REWin
}


# ============================================================
# WINDOWS UPDATE
# ============================================================

function Invoke-REWinWindowsUpdate {

    Write-REWinTitle

    Write-Host "Windows Update Diagnostics" -ForegroundColor Cyan
    Write-Host ""

    $Result = Get-REWinWindowsUpdateDiagnostics

    $Result | Format-List

    Wait-REWin
}


# ============================================================
# EVENT LOG
# ============================================================

function Invoke-REWinEventLog {

    Write-REWinTitle

    Write-Host "Event Log Diagnostics" -ForegroundColor Cyan
    Write-Host ""

    $Result = Get-REWinEventLogDiagnostics

    $Result | Format-List

    Wait-REWin
}


# ============================================================
# CRASH
# ============================================================

function Invoke-REWinCrash {

    Write-REWinTitle

    Write-Host "Crash Diagnostics" -ForegroundColor Cyan
    Write-Host ""

    $Result = Get-REWinCrashDiagnostics

    $Result | Format-List

    Wait-REWin
}


# ============================================================
# HARDWARE
# ============================================================

function Invoke-REWinHardware {

    Write-REWinTitle

    Write-Host "Hardware Diagnostics" -ForegroundColor Cyan
    Write-Host ""

    $Result = Get-REWinHardwareDiagnostics

    $Result | Format-List

    Wait-REWin
}


# ============================================================
# SECURITY
# ============================================================

function Invoke-REWinSecurity {

    Write-REWinTitle

    Write-Host "Security Diagnostics" -ForegroundColor Cyan
    Write-Host ""

    $Result = Get-REWinSecurityDiagnostics

    $Result | Format-List

    Wait-REWin
}


# ============================================================
# HTML REPORT
# ============================================================

function Invoke-REWinHtmlReport {

    Write-REWinTitle

    Write-Host "Generating HTML Health Report..." -ForegroundColor Cyan
    Write-Host ""

    try {

        $Report = Get-REWinHealthReport -ErrorAction Stop

        $ReportPath = Join-Path `
            $env:USERPROFILE `
            "Desktop\REWin-HealthReport.html"

        Export-REWinHealthReport `
            -Report $Report `
            -Path $ReportPath `
            -Language EN

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

    Write-REWinTitle

    Show-REWinPrivilege

    Write-Host ""

    Write-Host "[1] Quick Health Check"
    Write-Host "[2] System Diagnostics"
    Write-Host "[3] Disk Diagnostics"
    Write-Host "[4] Network Diagnostics"
    Write-Host "[5] Windows Update"
    Write-Host "[6] Event Log Diagnostics"
    Write-Host "[7] Crash Diagnostics"
    Write-Host "[8] Hardware Diagnostics"
    Write-Host "[9] Security Diagnostics"
    Write-Host "[10] Generate HTML Health Report"
    Write-Host "[0] Exit"

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
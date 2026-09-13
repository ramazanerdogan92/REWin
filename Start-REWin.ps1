# ============================================================
# REWin - Windows IT Toolkit
# Main Launcher
# ============================================================

$ErrorActionPreference = "SilentlyContinue"

$ProgressPreference = "SilentlyContinue"
$InformationPreference = "SilentlyContinue"
$VerbosePreference = "SilentlyContinue"
$DebugPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"

# ============================================================
# PATHS
# ============================================================

$REWinRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

$CorePath = Join-Path $REWinRoot "src\Core"
$DiagnosticsPath = Join-Path $REWinRoot "src\Diagnostics"
$SecurityPath = Join-Path $REWinRoot "src\Security"
$RepairPath = Join-Path $REWinRoot "src\Repair"

# ============================================================
# MODULES
# ============================================================

$Modules = @(
    (Join-Path $CorePath "Logger.psm1"),
    (Join-Path $CorePath "Privilege.psm1"),
    (Join-Path $CorePath "Backup.psm1"),
    (Join-Path $CorePath "HealthEngine.psm1"),
    (Join-Path $CorePath "HealthReport.psm1"),
    (Join-Path $CorePath "HealthReportHtml.psm1"),

    (Join-Path $DiagnosticsPath "SystemDiagnostics.psm1"),
    (Join-Path $DiagnosticsPath "DiskDiagnostics.psm1"),
    (Join-Path $DiagnosticsPath "NetworkDiagnostics.psm1"),
    (Join-Path $DiagnosticsPath "WindowsUpdateDiagnostics.psm1"),
    (Join-Path $DiagnosticsPath "EventLogDiagnostics.psm1"),
    (Join-Path $DiagnosticsPath "CrashDiagnostics.psm1"),
    (Join-Path $DiagnosticsPath "HardwareDiagnostics.psm1"),

    (Join-Path $SecurityPath "SecurityDiagnostics.psm1"),

    (Join-Path $RepairPath "RepairEngine.psm1")
)

foreach ($Module in $Modules) {

    if (Test-Path $Module) {

        try {
            Import-Module $Module -Force -ErrorAction Stop
        }
        catch {
            Write-Host ""
            Write-Host "Module load error:" -ForegroundColor Red
            Write-Host $Module -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
            Write-Host ""
        }
    }
}

# ============================================================
# GLOBAL HEALTH REPORT
# ============================================================

$Global:REWinHealthReport = $null

# ============================================================
# TITLE
# ============================================================

function Show-REWinTitle {

    Clear-Host

    Write-Host ""
    Write-Host " ==========================================================" -ForegroundColor Cyan
    Write-Host "                         REWin" -ForegroundColor Cyan
    Write-Host "                 Windows IT Toolkit" -ForegroundColor Gray
    Write-Host " ==========================================================" -ForegroundColor Cyan
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
# ADMINISTRATOR
# ============================================================

function Show-REWinAdministrator {

    try {

        if (Test-REWinAdministrator) {

            Write-Host "Administrator    : YES" -ForegroundColor Green

        }
        else {

            Write-Host "Administrator    : NO" -ForegroundColor Red
        }

    }
    catch {

        Write-Host "Administrator    : UNKNOWN" -ForegroundColor Yellow
    }
}

# ============================================================
# CURRENT HEALTH
# ============================================================

function Get-REWinCurrentHealth {

    if ($null -eq $Global:REWinHealthReport) {

        try {

            $Global:REWinHealthReport = Get-REWinHealthReport

        }
        catch {

            return $null
        }
    }

    return $Global:REWinHealthReport
}

# ============================================================
# HEALTH DISPLAY
# ============================================================

function Show-REWinHealth {

    Show-REWinTitle

    Write-Host " SYSTEM HEALTH" -ForegroundColor Cyan
    Write-Host " ----------------------------------------------------------"
    Write-Host ""

    $Report = Get-REWinCurrentHealth

    if ($null -eq $Report) {

        Write-Host "System Health    : NOT SCANNED" -ForegroundColor Yellow
        Write-Host ""

        Wait-REWin
        return
    }

    Write-Host "Overall Score    : " -NoNewline

    if ($Report.OverallScore -ge 90) {
        Write-Host "$($Report.OverallScore)/100" -ForegroundColor Green
    }
    elseif ($Report.OverallScore -ge 70) {
        Write-Host "$($Report.OverallScore)/100" -ForegroundColor Yellow
    }
    else {
        Write-Host "$($Report.OverallScore)/100" -ForegroundColor Red
    }

    Write-Host "Overall Status   : $($Report.OverallStatus)"
    Write-Host ""

    Write-Host "Attention        : " -NoNewline

    if ($Report.AttentionRequired) {
        Write-Host "REQUIRED" -ForegroundColor Yellow
    }
    else {
        Write-Host "NONE" -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "Issues           : $($Report.IssueCount)"
    Write-Host "Critical         : $($Report.CriticalCount)"
    Write-Host "Warnings         : $($Report.WarningCount)"
    Write-Host ""

    Write-Host "MODULE SCORES"
    Write-Host " ----------------------------------------------------------"

    foreach ($ModuleScore in $Report.ModuleScores) {

        Write-Host ""

        Write-Host ("{0,-18}" -f $ModuleScore.Name) -NoNewline
        Write-Host "$($ModuleScore.Score)/100" -NoNewline

        if ($ModuleScore.Score -ge 90) {

            Write-Host "  EXCELLENT" -ForegroundColor Green

        }
        elseif ($ModuleScore.Score -ge 70) {

            Write-Host "  GOOD" -ForegroundColor Cyan

        }
        elseif ($ModuleScore.Score -ge 50) {

            Write-Host "  WARNING" -ForegroundColor Yellow

        }
        else {

            Write-Host "  CRITICAL" -ForegroundColor Red
        }
    }

    if ($Report.Recommendations) {

        Write-Host ""
        Write-Host "RECOMMENDATIONS"
        Write-Host " ----------------------------------------------------------"

        foreach ($Recommendation in $Report.Recommendations) {

            Write-Host ""
            Write-Host " - $Recommendation" -ForegroundColor Yellow
        }
    }

    Write-Host ""

    Wait-REWin
}

# ============================================================
# QUICK HEALTH CHECK
# ============================================================

function Invoke-REWinQuickHealthCheck {

    Show-REWinTitle

    Write-Host " QUICK HEALTH CHECK" -ForegroundColor Cyan
    Write-Host " ----------------------------------------------------------"
    Write-Host ""

    Write-Host "Running system health analysis..." -ForegroundColor Yellow
    Write-Host ""

    try {

        $Global:REWinHealthReport = Get-REWinHealthReport

    }
    catch {

        Write-Host "Health scan failed." -ForegroundColor Red
        Write-Host ""
        Write-Host $_.Exception.Message -ForegroundColor Red

        Wait-REWin
        return
    }

    Write-Host "Health Score     : " -NoNewline

    if ($Global:REWinHealthReport.OverallScore -ge 90) {

        Write-Host "$($Global:REWinHealthReport.OverallScore)/100" -ForegroundColor Green

    }
    elseif ($Global:REWinHealthReport.OverallScore -ge 70) {

        Write-Host "$($Global:REWinHealthReport.OverallScore)/100" -ForegroundColor Cyan

    }
    elseif ($Global:REWinHealthReport.OverallScore -ge 50) {

        Write-Host "$($Global:REWinHealthReport.OverallScore)/100" -ForegroundColor Yellow

    }
    else {

        Write-Host "$($Global:REWinHealthReport.OverallScore)/100" -ForegroundColor Red
    }

    Write-Host "Health Status    : $($Global:REWinHealthReport.OverallStatus)"
    Write-Host ""

    Write-Host "Issues           : $($Global:REWinHealthReport.IssueCount)"
    Write-Host "Critical         : $($Global:REWinHealthReport.CriticalCount)"
    Write-Host "Warnings         : $($Global:REWinHealthReport.WarningCount)"
    Write-Host ""

    if ($Global:REWinHealthReport.Recommendations) {

        Write-Host "Recommendations  : $($Global:REWinHealthReport.Recommendations.Count)"

        foreach ($Recommendation in $Global:REWinHealthReport.Recommendations) {

            Write-Host " - $Recommendation" -ForegroundColor Yellow
        }
    }

    Write-Host ""

    Wait-REWin
}

# ============================================================
# SYSTEM DIAGNOSTICS
# ============================================================

function Invoke-REWinSystemDiagnostics {

    Show-REWinTitle

    Write-Host " SYSTEM DIAGNOSTICS" -ForegroundColor Cyan
    Write-Host " ----------------------------------------------------------"
    Write-Host ""

    try {

        $Result = Get-REWinSystemDiagnostics

        $Result | Format-List

    }
    catch {

        Write-Host "System diagnostics failed." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }

    Wait-REWin
}

# ============================================================
# DISK DIAGNOSTICS
# ============================================================

function Invoke-REWinDiskDiagnostics {

    Show-REWinTitle

    Write-Host " DISK DIAGNOSTICS" -ForegroundColor Cyan
    Write-Host " ----------------------------------------------------------"
    Write-Host ""

    try {

        $Result = Get-REWinDiskDiagnostics

        $Result | Format-List

    }
    catch {

        Write-Host "Disk diagnostics failed." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }

    Wait-REWin
}

# ============================================================
# NETWORK DIAGNOSTICS
# ============================================================

function Invoke-REWinNetworkDiagnostics {

    Show-REWinTitle

    Write-Host " NETWORK DIAGNOSTICS" -ForegroundColor Cyan
    Write-Host " ----------------------------------------------------------"
    Write-Host ""

    try {

        $Result = Get-REWinNetworkDiagnostics

        $Result | Format-List

    }
    catch {

        Write-Host "Network diagnostics failed." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }

    Wait-REWin
}

# ============================================================
# WINDOWS UPDATE
# ============================================================

function Invoke-REWinWindowsUpdateDiagnostics {

    Show-REWinTitle

    Write-Host " WINDOWS UPDATE DIAGNOSTICS" -ForegroundColor Cyan
    Write-Host " ----------------------------------------------------------"
    Write-Host ""

    try {

        $Result = Get-REWinWindowsUpdateDiagnostics

        $Result | Format-List

    }
    catch {

        Write-Host "Windows Update diagnostics failed." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }

    Wait-REWin
}

# ============================================================
# EVENT LOG
# ============================================================

function Invoke-REWinEventLogDiagnostics {

    Show-REWinTitle

    Write-Host " EVENT LOG DIAGNOSTICS" -ForegroundColor Cyan
    Write-Host " ----------------------------------------------------------"
    Write-Host ""

    try {

        $Result = Get-REWinEventLogDiagnostics

        $Result | Format-List

    }
    catch {

        Write-Host "Event Log diagnostics failed." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }

    Wait-REWin
}

# ============================================================
# CRASH DIAGNOSTICS
# ============================================================

function Invoke-REWinCrashDiagnostics {

    Show-REWinTitle

    Write-Host " CRASH DIAGNOSTICS" -ForegroundColor Cyan
    Write-Host " ----------------------------------------------------------"
    Write-Host ""

    try {

        $Result = Get-REWinCrashDiagnostics

        $Result | Format-List

    }
    catch {

        Write-Host "Crash diagnostics failed." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }

    Wait-REWin
}

# ============================================================
# HARDWARE DIAGNOSTICS
# ============================================================

function Invoke-REWinHardwareDiagnostics {

    Show-REWinTitle

    Write-Host " HARDWARE DIAGNOSTICS" -ForegroundColor Cyan
    Write-Host " ----------------------------------------------------------"
    Write-Host ""

    try {

        $Result = Get-REWinHardwareDiagnostics

        $Result | Format-List

    }
    catch {

        Write-Host "Hardware diagnostics failed." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }

    Wait-REWin
}

# ============================================================
# SECURITY DIAGNOSTICS
# ============================================================

function Invoke-REWinSecurityDiagnostics {

    Show-REWinTitle

    Write-Host " SECURITY DIAGNOSTICS" -ForegroundColor Cyan
    Write-Host " ----------------------------------------------------------"
    Write-Host ""

    try {

        $Result = Get-REWinSecurityDiagnostics

        $Result | Format-List

    }
    catch {

        Write-Host "Security diagnostics failed." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }

    Wait-REWin
}

# ============================================================
# HTML HEALTH REPORT
# ============================================================

function Invoke-REWinHtmlReport {

    Show-REWinTitle

    Write-Host " HTML HEALTH REPORT" -ForegroundColor Cyan
    Write-Host " ----------------------------------------------------------"
    Write-Host ""

    try {

        if ($null -eq $Global:REWinHealthReport) {

            Write-Host "Health report not scanned yet." -ForegroundColor Yellow
            Write-Host ""
            Write-Host "Running health scan..." -ForegroundColor Yellow
            Write-Host ""

            $Global:REWinHealthReport = Get-REWinHealthReport
        }

        $ReportPath = Export-REWinHealthReport `
            -Report $Global:REWinHealthReport

        Write-Host ""
        Write-Host "HTML report created successfully." -ForegroundColor Green
        Write-Host ""
        Write-Host "Report Path:"
        Write-Host $ReportPath -ForegroundColor Cyan

        if ($ReportPath -and (Test-Path $ReportPath)) {

            Write-Host ""
            Write-Host "Opening report..." -ForegroundColor Yellow

            Start-Process $ReportPath
        }

    }
    catch {

        Write-Host "HTML report generation failed." -ForegroundColor Red
        Write-Host ""
        Write-Host $_.Exception.Message -ForegroundColor Red
    }

    Wait-REWin
}

# ============================================================
# REPAIR CENTER
# ============================================================

function Invoke-REWinRepairCenter {

    do {

        Show-REWinTitle

        Write-Host " REPAIR CENTER" -ForegroundColor Cyan
        Write-Host " ----------------------------------------------------------"
        Write-Host ""

        $Options = Get-REWinRepairOptions

        foreach ($Option in $Options) {

            $RiskColor = switch ($Option.Risk) {

                "LOW" {
                    "Green"
                }

                "MEDIUM" {
                    "Yellow"
                }

                "HIGH" {
                    "Red"
                }

                default {
                    "White"
                }
            }

            Write-Host " [$($Option.Id)] " -NoNewline
            Write-Host "$($Option.Name)" -NoNewline
            Write-Host " [$($Option.Risk)]" -ForegroundColor $RiskColor
        }

        Write-Host ""
        Write-Host " [0] Back"
        Write-Host ""

        $RepairChoice = Read-Host "Select repair"

        if ($RepairChoice -eq "0") {
            break
        }

        $Selected = $Options |
            Where-Object {
                $_.Id -eq [int]$RepairChoice
            } |
            Select-Object -First 1

        if (-not $Selected) {

            Write-Host ""
            Write-Host "Invalid repair option." -ForegroundColor Red

            Start-Sleep -Seconds 1
            continue
        }

        Show-REWinTitle

        Write-Host " REPAIR CONFIRMATION" -ForegroundColor Cyan
        Write-Host " ----------------------------------------------------------"
        Write-Host ""

        Write-Host "Repair          : $($Selected.Name)"

        Write-Host "Risk            : " -NoNewline

        $RiskColor = switch ($Selected.Risk) {

            "LOW" {
                "Green"
            }

            "MEDIUM" {
                "Yellow"
            }

            "HIGH" {
                "Red"
            }

            default {
                "White"
            }
        }

        Write-Host "$($Selected.Risk)" -ForegroundColor $RiskColor

        Write-Host ""

        Write-Host "Description     : $($Selected.Description)"

        Write-Host ""

        if ($Selected.Command) {

            Write-Host "Command:"
            Write-Host "  $($Selected.Command)" -ForegroundColor Yellow
            Write-Host ""
        }

        if ($Selected.Commands) {

            Write-Host "Commands:"

            foreach ($Command in $Selected.Commands) {

                Write-Host "  $Command" -ForegroundColor Yellow
            }

            Write-Host ""
        }

        Write-Host "WARNING: This operation will modify the system." -ForegroundColor Red
        Write-Host ""

        Write-Host "The repair engine will:"
        Write-Host ""
        Write-Host "  1. Create backup"
        Write-Host "  2. Check System Restore"
        Write-Host "  3. Capture BEFORE health"
        Write-Host "  4. Execute repair"
        Write-Host "  5. Capture AFTER health"
        Write-Host "  6. Compare health score"
        Write-Host ""

        $Confirm = Read-Host "Continue? [Y/N]"

        if ($Confirm -notmatch "^[Yy]$") {

            Write-Host ""
            Write-Host "Repair cancelled." -ForegroundColor Yellow

            Start-Sleep -Seconds 1
            continue
        }

        Show-REWinTitle

        Write-Host " REPAIR IN PROGRESS" -ForegroundColor Cyan
        Write-Host " ----------------------------------------------------------"
        Write-Host ""

        Write-Host "Repair          : $($Selected.Name)"
        Write-Host "Risk            : $($Selected.Risk)"
        Write-Host ""

        Write-Host "Starting RepairEngine..." -ForegroundColor Yellow
        Write-Host ""

        try {

            $Result = Invoke-REWinRepair -Id $Selected.Id

        }
        catch {

            Write-Host ""
            Write-Host "Repair engine error." -ForegroundColor Red
            Write-Host ""
            Write-Host $_.Exception.Message -ForegroundColor Red

            Wait-REWin
            continue
        }

        Show-REWinTitle

        Write-Host " REPAIR RESULT" -ForegroundColor Cyan
        Write-Host " ----------------------------------------------------------"
        Write-Host ""

        Write-Host "Repair          : $($Result.RepairName)"
        Write-Host "Risk            : $($Result.Risk)"
        Write-Host ""

        Write-Host "Result          : " -NoNewline

        if ($Result.Success) {

            Write-Host "SUCCESS" -ForegroundColor Green

        }
        else {

            Write-Host "FAILED" -ForegroundColor Red
        }

        Write-Host "Status          : $($Result.RepairStatus)"
        Write-Host ""

        Write-Host "Summary         : $($Result.RepairSummary)"
        Write-Host ""

        Write-Host "Backup Status   : " -NoNewline

        if ($Result.BackupStatus -eq "CREATED") {

            Write-Host "CREATED" -ForegroundColor Green

        }
        else {

            Write-Host "$($Result.BackupStatus)" -ForegroundColor Yellow
        }

        Write-Host ""

        Write-Host "Backup Path     : $($Result.BackupPath)"
        Write-Host ""

        Write-Host "Restore Point   : $($Result.RestorePoint)"

        if ($Result.RestoreReason) {

            Write-Host "Restore Reason  : $($Result.RestoreReason)"
        }

        Write-Host ""

        Write-Host "Health Before   : " -NoNewline

        if ($null -ne $Result.HealthBefore) {

            Write-Host "$($Result.HealthBefore)"

        }
        else {

            Write-Host "N/A"
        }

        Write-Host "Health After    : " -NoNewline

        if ($null -ne $Result.HealthAfter) {

            Write-Host "$($Result.HealthAfter)"

        }
        else {

            Write-Host "N/A"
        }

        Write-Host "Health Delta    : " -NoNewline

        if ($null -ne $Result.HealthDelta) {

            if ($Result.HealthDelta -gt 0) {

                Write-Host "+$($Result.HealthDelta)" -ForegroundColor Green

            }
            elseif ($Result.HealthDelta -lt 0) {

                Write-Host "$($Result.HealthDelta)" -ForegroundColor Red

            }
            else {

                Write-Host "0" -ForegroundColor Gray
            }

        }
        else {

            Write-Host "N/A"
        }

        Write-Host "Health Changed  : $($Result.HealthChanged)"
        Write-Host ""

        if ($Result.CommandResults) {

            Write-Host "COMMAND RESULTS"
            Write-Host " ----------------------------------------------------------"

            foreach ($CommandResult in $Result.CommandResults) {

                Write-Host ""

                if ($CommandResult.FilePath) {

                    Write-Host "File            : $($CommandResult.FilePath)"
                }

                if ($CommandResult.Arguments) {

                    Write-Host "Arguments       : $($CommandResult.Arguments)"
                }

                Write-Host "Exit Code       : $($CommandResult.ExitCode)"

                if ($CommandResult.Success) {

                    Write-Host "Command Status  : SUCCESS" -ForegroundColor Green

                }
                else {

                    Write-Host "Command Status  : FAILED" -ForegroundColor Red
                }

                if ($CommandResult.Summary) {

                    Write-Host "Summary         : $($CommandResult.Summary)"
                }

                if ($CommandResult.Error) {

                    Write-Host ""
                    Write-Host "Error:" -ForegroundColor Red
                    Write-Host $CommandResult.Error -ForegroundColor Red
                }
            }
        }

        Write-Host ""

        if ($Result.RepairStatus -eq "SUCCESS") {

            Write-Host "Repair completed successfully." -ForegroundColor Green

        }
        elseif ($Result.RepairStatus -eq "PARTIAL") {

            Write-Host "Repair completed partially." -ForegroundColor Yellow

        }
        else {

            Write-Host "Repair completed with errors." -ForegroundColor Red
        }

        Write-Host ""

        if ($Selected.Id -eq 4) {

            Write-Host "NOTE: Network stack reset may require a system restart." -ForegroundColor Yellow
            Write-Host ""
        }

        Wait-REWin

    }
    while ($true)
}

# ============================================================
# MAIN MENU
# ============================================================

do {

    Show-REWinTitle

    Write-Host " SYSTEM HEALTH : " -NoNewline

    if ($null -eq $Global:REWinHealthReport) {

        Write-Host "NOT SCANNED" -ForegroundColor Yellow

    }
    else {

        if ($Global:REWinHealthReport.OverallScore -ge 90) {

            Write-Host "$($Global:REWinHealthReport.OverallScore)/100 - $($Global:REWinHealthReport.OverallStatus)" -ForegroundColor Green

        }
        elseif ($Global:REWinHealthReport.OverallScore -ge 70) {

            Write-Host "$($Global:REWinHealthReport.OverallScore)/100 - $($Global:REWinHealthReport.OverallStatus)" -ForegroundColor Cyan

        }
        elseif ($Global:REWinHealthReport.OverallScore -ge 50) {

            Write-Host "$($Global:REWinHealthReport.OverallScore)/100 - $($Global:REWinHealthReport.OverallStatus)" -ForegroundColor Yellow

        }
        else {

            Write-Host "$($Global:REWinHealthReport.OverallScore)/100 - $($Global:REWinHealthReport.OverallStatus)" -ForegroundColor Red
        }
    }

    Write-Host ""

    Show-REWinAdministrator

    Write-Host ""

    Write-Host " ----------------------------------------------------------"
    Write-Host " MAIN MENU"
    Write-Host " ----------------------------------------------------------"
    Write-Host ""

    Write-Host " [1] Quick Health Check"
    Write-Host " [2] System Diagnostics"
    Write-Host " [3] Disk Diagnostics"
    Write-Host " [4] Network Diagnostics"
    Write-Host " [5] Windows Update Diagnostics"
    Write-Host " [6] Event Log Diagnostics"
    Write-Host " [7] Crash Diagnostics"
    Write-Host " [8] Hardware Diagnostics"
    Write-Host " [9] Security Diagnostics"
    Write-Host " [10] HTML Health Report"
    Write-Host " [11] Repair Center"
    Write-Host ""
    Write-Host " [0] Exit"
    Write-Host ""

    $Choice = Read-Host "Select option"

    switch ($Choice) {

        "1" {

            Invoke-REWinQuickHealthCheck
        }

        "2" {

            Invoke-REWinSystemDiagnostics
        }

        "3" {

            Invoke-REWinDiskDiagnostics
        }

        "4" {

            Invoke-REWinNetworkDiagnostics
        }

        "5" {

            Invoke-REWinWindowsUpdateDiagnostics
        }

        "6" {

            Invoke-REWinEventLogDiagnostics
        }

        "7" {

            Invoke-REWinCrashDiagnostics
        }

        "8" {

            Invoke-REWinHardwareDiagnostics
        }

        "9" {

            Invoke-REWinSecurityDiagnostics
        }

        "10" {

            Invoke-REWinHtmlReport
        }

        "11" {

            Invoke-REWinRepairCenter
        }

        "0" {

            Write-Host ""
            Write-Host "Exiting REWin..." -ForegroundColor Cyan
            Write-Host ""
        }

        default {

            Write-Host ""
            Write-Host "Invalid option." -ForegroundColor Red

            Start-Sleep -Seconds 1
        }
    }

}
while ($Choice -ne "0")
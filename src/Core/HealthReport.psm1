function Get-REWinHealthReport {

    # ============================================================
    # LOAD MODULES
    # ============================================================

    $Root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

    $Modules = @(
        @{
            Name = "System"
            Path = Join-Path $Root "Diagnostics\SystemDiagnostics.psm1"
        },
        @{
            Name = "Disk"
            Path = Join-Path $Root "Diagnostics\DiskDiagnostics.psm1"
        },
        @{
            Name = "Network"
            Path = Join-Path $Root "Diagnostics\NetworkDiagnostics.psm1"
        },
        @{
            Name = "WindowsUpdate"
            Path = Join-Path $Root "Diagnostics\WindowsUpdateDiagnostics.psm1"
        },
        @{
            Name = "EventLog"
            Path = Join-Path $Root "Diagnostics\EventLogDiagnostics.psm1"
        },
        @{
            Name = "Crash"
            Path = Join-Path $Root "Diagnostics\CrashDiagnostics.psm1"
        },
        @{
            Name = "Hardware"
            Path = Join-Path $Root "Diagnostics\HardwareDiagnostics.psm1"
        },
        @{
            Name = "Security"
            Path = Join-Path $Root "Security\SecurityDiagnostics.psm1"
        }
    )


    # ============================================================
    # IMPORT MODULES
    # ============================================================

    foreach ($Module in $Modules) {

        if (Test-Path $Module.Path) {
            Import-Module $Module.Path -Force -ErrorAction SilentlyContinue
        }
    }


    # ============================================================
    # RUN DIAGNOSTICS
    # ============================================================

    try {
        $System = Get-REWinSystemDiagnostics
    }
    catch {
        $System = [PSCustomObject]@{
            Status = "ERROR"
            HealthScore = 0
        }
    }

    try {
        $Disk = @(Get-REWinDiskDiagnostics)
    }
    catch {
        $Disk = [PSCustomObject]@{
            Status = "ERROR"
            HealthScore = 0
        }
    }

    try {
        $Network = Get-REWinNetworkDiagnostics
    }
    catch {
        $Network = [PSCustomObject]@{
            Status = "ERROR"
            HealthScore = 0
        }
    }

    try {
        $WindowsUpdate = Get-REWinWindowsUpdateDiagnostics
    }
    catch {
        $WindowsUpdate = [PSCustomObject]@{
            Status = "ERROR"
            HealthScore = 0
        }
    }

    try {
        $EventLog = Get-REWinEventLogDiagnostics
    }
    catch {
        $EventLog = [PSCustomObject]@{
            Status = "ERROR"
            HealthScore = 0
        }
    }

    try {
        $Crash = Get-REWinCrashDiagnostics
    }
    catch {
        $Crash = [PSCustomObject]@{
            Status = "ERROR"
            HealthScore = 0
        }
    }

    try {
        $Hardware = Get-REWinHardwareDiagnostics
    }
    catch {
        $Hardware = [PSCustomObject]@{
            Status = "ERROR"
            HealthScore = 0
        }
    }

    try {
        $Security = Get-REWinSecurityDiagnostics
    }
    catch {
        $Security = [PSCustomObject]@{
            Status = "ERROR"
            HealthScore = 0
        }
    }


    # ============================================================
    # HEALTH ENGINE
    # ============================================================

    $HealthEnginePath = Join-Path $PSScriptRoot "HealthEngine.psm1"

    Import-Module `
        $HealthEnginePath `
        -Force `
        -ErrorAction SilentlyContinue

    $Health = Get-REWinHealthEngine `
        -System $System `
        -Disk $Disk `
        -Network $Network `
        -WindowsUpdate $WindowsUpdate `
        -EventLog $EventLog `
        -Crash $Crash `
        -Hardware $Hardware `
        -Security $Security


    # ============================================================
    # RECOMMENDATIONS
    # ============================================================

    $Recommendations = @()


    # ------------------------------------------------------------
    # Windows Update
    # ------------------------------------------------------------

    if ($WindowsUpdate.PendingReboot) {

        $Recommendations += [PSCustomObject]@{
            Severity = "WARNING"
            Area = "Windows Update"
            Message = "A system restart is pending."
        }
    }


    # ------------------------------------------------------------
    # Event Log
    # ------------------------------------------------------------

    if ($EventLog.ErrorCount -gt 0) {

        $Severity = if ($EventLog.ErrorCount -ge 50) {
            "CRITICAL"
        }
        else {
            "WARNING"
        }

        $Recommendations += [PSCustomObject]@{
            Severity = $Severity
            Area = "Event Log"
            Message = "$($EventLog.ErrorCount) error event(s) detected in the scan period."
        }
    }


    # ------------------------------------------------------------
    # Crash
    # ------------------------------------------------------------

    if ($Crash.BugCheckCount -gt 0) {

        $Recommendations += [PSCustomObject]@{
            Severity = "CRITICAL"
            Area = "Crash"
            Message = "$($Crash.BugCheckCount) BugCheck event(s) detected."
        }
    }

    if ($Crash.LiveKernelDumpCount -gt 0) {

        $Recommendations += [PSCustomObject]@{
            Severity = "WARNING"
            Area = "Crash"
            Message = "$($Crash.LiveKernelDumpCount) Live Kernel dump(s) detected."
        }
    }


    # ------------------------------------------------------------
    # Security
    # ------------------------------------------------------------

    if ($Security.RealTimeProtection -eq "WARNING") {

        $Recommendations += [PSCustomObject]@{
            Severity = "CRITICAL"
            Area = "Security"
            Message = "Windows Defender real-time protection is disabled."
        }
    }

    if ($Security.SecureBootEnabled -eq $false) {

        $Recommendations += [PSCustomObject]@{
            Severity = "WARNING"
            Area = "Security"
            Message = "Secure Boot is disabled."
        }
    }

    if ($Security.BitLockerProblemCount -gt 0) {

        $Recommendations += [PSCustomObject]@{
            Severity = "WARNING"
            Area = "Security"
            Message = "BitLocker protection requires attention."
        }
    }


    # ------------------------------------------------------------
    # Network
    # ------------------------------------------------------------

    if ($Network.HealthScore -lt 50) {

        $Recommendations += [PSCustomObject]@{
            Severity = "CRITICAL"
            Area = "Network"
            Message = "Network health is critically low."
        }
    }
    elseif ($Network.HealthScore -lt 90) {

        $Recommendations += [PSCustomObject]@{
            Severity = "WARNING"
            Area = "Network"
            Message = "Network health requires attention."
        }
    }


    # ------------------------------------------------------------
    # Hardware
    # ------------------------------------------------------------

    if ($Hardware.HealthScore -lt 50) {

        $Recommendations += [PSCustomObject]@{
            Severity = "CRITICAL"
            Area = "Hardware"
            Message = "Hardware health is critically low."
        }
    }
    elseif ($Hardware.HealthScore -lt 90) {

        $Recommendations += [PSCustomObject]@{
            Severity = "WARNING"
            Area = "Hardware"
            Message = "Hardware health requires attention."
        }
    }


    # ============================================================
    # SORT RECOMMENDATIONS
    # ============================================================

    $SeverityOrder = @{
        "CRITICAL" = 1
        "WARNING"  = 2
        "INFO"     = 3
    }

    $Recommendations = @(
        $Recommendations |
            Sort-Object {
                $SeverityOrder[$_.Severity]
            }
    )


    # ============================================================
    # ISSUE COUNTS
    # ============================================================

    $CriticalCount = @(
        $Recommendations |
            Where-Object {
                $_.Severity -eq "CRITICAL"
            }
    ).Count

    $WarningCount = @(
        $Recommendations |
            Where-Object {
                $_.Severity -eq "WARNING"
            }
    ).Count

    $IssueCount = $CriticalCount + $WarningCount

    $AttentionRequired = ($IssueCount -gt 0)


    # ============================================================
    # ATTENTION STATUS
    # ============================================================

    if ($CriticalCount -gt 0) {
        $AttentionStatus = "CRITICAL"
    }
    elseif ($WarningCount -gt 0) {
        $AttentionStatus = "REQUIRED"
    }
    else {
        $AttentionStatus = "NONE"
    }


    # ============================================================
    # RESULT
    # ============================================================

    [PSCustomObject]@{

        GeneratedAt = Get-Date

        OverallScore  = $Health.OverallScore
        OverallStatus = $Health.OverallStatus
        Summary       = $Health.Summary

        AttentionRequired = $AttentionRequired
        AttentionStatus   = $AttentionStatus

        IssueCount    = $IssueCount
        CriticalCount = $CriticalCount
        WarningCount  = $WarningCount

        ModuleScores = $Health.ModuleScores
        WeakAreas    = $Health.WeakAreas

        Recommendations = $Recommendations

        System        = $System
        Disk          = $Disk
        Network       = $Network
        WindowsUpdate = $WindowsUpdate
        EventLog      = $EventLog
        Crash         = $Crash
        Hardware      = $Hardware
        Security      = $Security
    }
}

Export-ModuleMember -Function `
    Get-REWinHealthReport
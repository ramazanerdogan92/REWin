function Get-REWinHealthReport {

    # ============================================================
    # LOAD MODULES
    # ============================================================

    $Root = Split-Path -Parent $PSScriptRoot

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
            Status      = "ERROR"
            HealthScore = 0
        }
    }

    try {
        $Disk = @(Get-REWinDiskDiagnostics)
    }
    catch {
        $Disk = [PSCustomObject]@{
            Status      = "ERROR"
            HealthScore = 0
        }
    }

    try {
        $Network = Get-REWinNetworkDiagnostics
    }
    catch {
        $Network = [PSCustomObject]@{
            Status      = "ERROR"
            HealthScore = 0
        }
    }

    try {
        $WindowsUpdate = Get-REWinWindowsUpdateDiagnostics
    }
    catch {
        $WindowsUpdate = [PSCustomObject]@{
            Status      = "ERROR"
            HealthScore = 0
        }
    }

    try {
        $EventLog = Get-REWinEventLogDiagnostics
    }
    catch {
        $EventLog = [PSCustomObject]@{
            Status      = "ERROR"
            HealthScore = 0
        }
    }

    try {
        $Crash = Get-REWinCrashDiagnostics
    }
    catch {
        $Crash = [PSCustomObject]@{
            Status      = "ERROR"
            HealthScore = 0
        }
    }

    try {
        $Hardware = Get-REWinHardwareDiagnostics
    }
    catch {
        $Hardware = [PSCustomObject]@{
            Status      = "ERROR"
            HealthScore = 0
        }
    }

    try {
        $Security = Get-REWinSecurityDiagnostics
    }
    catch {
        $Security = [PSCustomObject]@{
            Status      = "ERROR"
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
    # RECOMMENDATION ENGINE
    # ============================================================

    $RecommendationEnginePath = Join-Path `
        $PSScriptRoot `
        "RecommendationEngine.psm1"

    Import-Module `
        $RecommendationEnginePath `
        -Force `
        -ErrorAction SilentlyContinue

    $RecommendationInput = [PSCustomObject]@{
        ModuleResults = @(
            [PSCustomObject]@{
                Module = "System"
                Status = $System.Status
                HealthScore = if ($null -ne $System.HealthScore) {
                    $System.HealthScore
                }
                else {
                    0
                }
            }

            [PSCustomObject]@{
                Module = "Disk"
                Status = if ($Disk.Count -gt 0) {
                    ($Disk | Select-Object -First 1).Status
                }
                else {
                    "ERROR"
                }
                HealthScore = if ($Disk.Count -gt 0 -and $null -ne $Disk[0].HealthScore) {
                    $Disk[0].HealthScore
                }
                else {
                    0
                }
            }

            [PSCustomObject]@{
                Module = "Network"
                Status = $Network.Status
                HealthScore = if ($null -ne $Network.HealthScore) {
                    $Network.HealthScore
                }
                else {
                    0
                }
            }

            [PSCustomObject]@{
                Module = "WindowsUpdate"
                Status = $WindowsUpdate.Status
                HealthScore = if ($null -ne $WindowsUpdate.HealthScore) {
                    $WindowsUpdate.HealthScore
                }
                else {
                    0
                }
            }

            [PSCustomObject]@{
                Module = "EventLog"
                Status = $EventLog.Status
                HealthScore = if ($null -ne $EventLog.HealthScore) {
                    $EventLog.HealthScore
                }
                else {
                    0
                }
            }

            [PSCustomObject]@{
                Module = "Crash"
                Status = $Crash.Status
                HealthScore = if ($null -ne $Crash.HealthScore) {
                    $Crash.HealthScore
                }
                else {
                    0
                }
            }

            [PSCustomObject]@{
                Module = "Hardware"
                Status = $Hardware.Status
                HealthScore = if ($null -ne $Hardware.HealthScore) {
                    $Hardware.HealthScore
                }
                else {
                    0
                }
            }

            [PSCustomObject]@{
                Module = "Security"
                Status = $Security.Status
                HealthScore = if ($null -ne $Security.HealthScore) {
                    $Security.HealthScore
                }
                else {
                    0
                }
            }
        )
    }

    $Recommendations = @(
        Get-REWinRecommendation `
            -HealthReport $RecommendationInput
    )

    # ============================================================
    # ISSUE COUNTS
    # ============================================================

    $CriticalCount = @(
        $Recommendations |
            Where-Object {
                $_.Priority -eq "HIGH" -and
                $_.Status -eq "CRITICAL"
            }
    ).Count

    $WarningCount = @(
        $Recommendations |
            Where-Object {
                $_.Status -eq "WARNING"
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
    # RECOMMENDATION SUMMARY
    # ============================================================

    $RecommendationSummary = Get-REWinRecommendationSummary `
        -Recommendations $Recommendations

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

        RecommendationSummary = $RecommendationSummary

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
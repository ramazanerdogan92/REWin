Set-StrictMode -Version Latest

function Get-REWinRecommendation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$HealthReport
    )

    $Recommendations = @()

    if (-not $HealthReport) {
        return @(
            [PSCustomObject]@{
                Module      = "HealthEngine"
                Status      = "CRITICAL"
                Priority    = "HIGH"
                Title       = "Health report unavailable"
                Description = "Health report could not be loaded."
                Recommendation = "Run a Quick Health Check and try again."
                RepairId    = $null
            }
        )
    }

    foreach ($Module in $HealthReport.ModuleResults) {

        $Status = [string]$Module.Status
        $ModuleName = [string]$Module.Module

        switch ($ModuleName) {

            "System" {
                if ($Status -eq "WARNING") {
                    $Recommendations += [PSCustomObject]@{
                        Module         = "System"
                        Status         = "WARNING"
                        Priority       = "MEDIUM"
                        Title          = "System health warning"
                        Description    = "System diagnostics reported a warning."
                        Recommendation = "Review the System Diagnostics details."
                        RepairId       = $null
                    }
                }
            }

            "Disk" {
                if ($Status -eq "WARNING") {
                    $Recommendations += [PSCustomObject]@{
                        Module         = "Disk"
                        Status         = "WARNING"
                        Priority       = "MEDIUM"
                        Title          = "Low disk space"
                        Description    = "One or more disks have a low free-space condition."
                        Recommendation = "Free disk space and remove unnecessary files."
                        RepairId       = $null
                    }
                }

                if ($Status -eq "CRITICAL") {
                    $Recommendations += [PSCustomObject]@{
                        Module         = "Disk"
                        Status         = "CRITICAL"
                        Priority       = "HIGH"
                        Title          = "Critical disk space"
                        Description    = "A disk has reached a critical free-space level."
                        Recommendation = "Free disk space immediately."
                        RepairId       = $null
                    }
                }
            }

            "Network" {
                if ($Status -eq "WARNING") {
                    $Recommendations += [PSCustomObject]@{
                        Module         = "Network"
                        Status         = "WARNING"
                        Priority       = "MEDIUM"
                        Title          = "Network connectivity warning"
                        Description    = "Network diagnostics reported a warning."
                        Recommendation = "Check network connectivity, DNS and TCP connectivity."
                        RepairId       = 4
                    }
                }

                if ($Status -eq "CRITICAL") {
                    $Recommendations += [PSCustomObject]@{
                        Module         = "Network"
                        Status         = "CRITICAL"
                        Priority       = "HIGH"
                        Title          = "Network connectivity failure"
                        Description    = "Network diagnostics reported a critical condition."
                        Recommendation = "Check network configuration and connectivity."
                        RepairId       = 4
                    }
                }
            }

            "WindowsUpdate" {
                if ($Status -eq "WARNING") {
                    $Recommendations += [PSCustomObject]@{
                        Module         = "WindowsUpdate"
                        Status         = "WARNING"
                        Priority       = "MEDIUM"
                        Title          = "Windows Update requires attention"
                        Description    = "Windows Update diagnostics reported a warning."
                        Recommendation = "Restart Windows if a pending reboot is detected and verify Windows Update status."
                        RepairId       = 5
                    }
                }

                if ($Status -eq "CRITICAL") {
                    $Recommendations += [PSCustomObject]@{
                        Module         = "WindowsUpdate"
                        Status         = "CRITICAL"
                        Priority       = "HIGH"
                        Title          = "Windows Update critical issue"
                        Description    = "Windows Update diagnostics reported a critical condition."
                        Recommendation = "Check Windows Update services and repair Windows Update components."
                        RepairId       = 5
                    }
                }
            }

            "EventLog" {
                if ($Status -eq "WARNING") {
                    $Recommendations += [PSCustomObject]@{
                        Module         = "EventLog"
                        Status         = "WARNING"
                        Priority       = "LOW"
                        Title          = "Windows Event Log warnings detected"
                        Description    = "Recent Windows event logs contain warning or error events."
                        Recommendation = "Review recent Error and Warning events to identify recurring problems."
                        RepairId       = $null
                    }
                }

                if ($Status -eq "CRITICAL") {
                    $Recommendations += [PSCustomObject]@{
                        Module         = "EventLog"
                        Status         = "CRITICAL"
                        Priority       = "HIGH"
                        Title          = "Critical event log activity"
                        Description    = "Critical event activity was detected."
                        Recommendation = "Review Critical and Error events immediately."
                        RepairId       = $null
                    }
                }
            }

            "Crash" {
                if ($Status -eq "WARNING") {
                    $Recommendations += [PSCustomObject]@{
                        Module         = "Crash"
                        Status         = "WARNING"
                        Priority       = "MEDIUM"
                        Title          = "Crash diagnostics warning"
                        Description    = "Crash diagnostics reported a warning condition."
                        Recommendation = "Review BugCheck, KernelPower and dump information."
                        RepairId       = $null
                    }
                }

                if ($Status -eq "CRITICAL") {
                    $Recommendations += [PSCustomObject]@{
                        Module         = "Crash"
                        Status         = "CRITICAL"
                        Priority       = "HIGH"
                        Title          = "System crash indicators detected"
                        Description    = "Crash diagnostics detected critical system crash indicators."
                        Recommendation = "Review recent crash events and memory dump files."
                        RepairId       = $null
                    }
                }
            }

            "Hardware" {
                if ($Status -eq "WARNING") {
                    $Recommendations += [PSCustomObject]@{
                        Module         = "Hardware"
                        Status         = "WARNING"
                        Priority       = "MEDIUM"
                        Title          = "Hardware warning detected"
                        Description    = "Hardware diagnostics reported a warning."
                        Recommendation = "Review physical and virtual device status."
                        RepairId       = $null
                    }
                }

                if ($Status -eq "CRITICAL") {
                    $Recommendations += [PSCustomObject]@{
                        Module         = "Hardware"
                        Status         = "CRITICAL"
                        Priority       = "HIGH"
                        Title          = "Hardware problem detected"
                        Description    = "Hardware diagnostics reported a critical condition."
                        Recommendation = "Inspect affected hardware devices and drivers."
                        RepairId       = $null
                    }
                }
            }

            "Security" {
                if ($Status -eq "WARNING") {
                    $Recommendations += [PSCustomObject]@{
                        Module         = "Security"
                        Status         = "WARNING"
                        Priority       = "MEDIUM"
                        Title          = "Security configuration requires attention"
                        Description    = "Security diagnostics reported a warning."
                        Recommendation = "Review Defender, Firewall, TPM, Secure Boot and BitLocker status."
                        RepairId       = $null
                    }
                }

                if ($Status -eq "CRITICAL") {
                    $Recommendations += [PSCustomObject]@{
                        Module         = "Security"
                        Status         = "CRITICAL"
                        Priority       = "HIGH"
                        Title          = "Critical security issue"
                        Description    = "Security diagnostics reported a critical condition."
                        Recommendation = "Review Windows security configuration immediately."
                        RepairId       = $null
                    }
                }
            }
        }
    }

    if ($Recommendations.Count -eq 0) {
        $Recommendations += [PSCustomObject]@{
            Module         = "HealthEngine"
            Status         = "OK"
            Priority       = "INFO"
            Title          = "No issues detected"
            Description    = "All health modules are operating within expected conditions."
            Recommendation = "No action is required."
            RepairId       = $null
        }
    }

    return $Recommendations
}

function Get-REWinRecommendationSummary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object[]]$Recommendations
    )

    $High = @($Recommendations | Where-Object { $_.Priority -eq "HIGH" }).Count
    $Medium = @($Recommendations | Where-Object { $_.Priority -eq "MEDIUM" }).Count
    $Low = @($Recommendations | Where-Object { $_.Priority -eq "LOW" }).Count
    $Info = @($Recommendations | Where-Object { $_.Priority -eq "INFO" }).Count

    [PSCustomObject]@{
        Total  = $Recommendations.Count
        High   = $High
        Medium = $Medium
        Low    = $Low
        Info   = $Info
    }
}

Export-ModuleMember -Function @(
    "Get-REWinRecommendation"
    "Get-REWinRecommendationSummary"
)
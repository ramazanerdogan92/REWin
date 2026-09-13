function Get-REWinHealthEngine {

    param(
        [Parameter(Mandatory)]
        $System,

        [Parameter(Mandatory)]
        $Disk,

        [Parameter(Mandatory)]
        $Network,

        [Parameter(Mandatory)]
        $WindowsUpdate,

        [Parameter(Mandatory)]
        $EventLog,

        [Parameter(Mandatory)]
        $Crash,

        [Parameter(Mandatory)]
        $Hardware,

        [Parameter(Mandatory)]
        $Security
    )

    # ============================================================
    # MODULE SCORES
    # ============================================================

    $Scores = [ordered]@{}

    # ------------------------------------------------------------
    # Helper: Read HealthScore safely
    # ------------------------------------------------------------

    function Get-SafeHealthScore {

        param(
            [Parameter(Mandatory)]
            $Module,

            [Parameter(Mandatory)]
            [string]$ModuleName
        )

        try {

            # Prefer the diagnostic module HealthScore
            if ($null -ne $Module.HealthScore) {

                $Value = [int]$Module.HealthScore

                if ($Value -lt 0) {
                    return 0
                }

                if ($Value -gt 100) {
                    return 100
                }

                return $Value
            }

            # Fallback based on Status
            switch ($Module.Status) {

                "OK" {
                    return 100
                }

                "WARNING" {
                    return 80
                }

                "CRITICAL" {
                    return 40
                }

                default {
                    return 60
                }
            }
        }
        catch {

            # Diagnostic module could not provide a valid score.
            # Use a conservative score instead of silently failing.
            return 60
        }
    }


    # ============================================================
    # READ MODULE SCORES
    # ============================================================

    $Scores.System = Get-SafeHealthScore `
        -Module $System `
        -ModuleName "System"

    $Scores.Disk = Get-SafeHealthScore `
        -Module $Disk `
        -ModuleName "Disk"

    $Scores.Network = Get-SafeHealthScore `
        -Module $Network `
        -ModuleName "Network"

    $Scores.WindowsUpdate = Get-SafeHealthScore `
        -Module $WindowsUpdate `
        -ModuleName "WindowsUpdate"

    $Scores.EventLog = Get-SafeHealthScore `
        -Module $EventLog `
        -ModuleName "EventLog"

    $Scores.Crash = Get-SafeHealthScore `
        -Module $Crash `
        -ModuleName "Crash"

    $Scores.Hardware = Get-SafeHealthScore `
        -Module $Hardware `
        -ModuleName "Hardware"

    $Scores.Security = Get-SafeHealthScore `
        -Module $Security `
        -ModuleName "Security"


    # ============================================================
    # WEIGHTS
    # ============================================================

    $Weights = [ordered]@{
        System        = 10
        Disk          = 15
        Network       = 15
        WindowsUpdate = 10
        EventLog      = 10
        Crash         = 15
        Hardware      = 10
        Security      = 15
    }


    # ============================================================
    # WEIGHTED SCORE
    # ============================================================

    $WeightedTotal = 0
    $WeightTotal = 0

    foreach ($Name in $Scores.Keys) {

        $Score = [double]$Scores[$Name]
        $Weight = [double]$Weights[$Name]

        $WeightedTotal += ($Score * $Weight)
        $WeightTotal += $Weight
    }

    if ($WeightTotal -gt 0) {

        $OverallScore = [math]::Round(
            ($WeightedTotal / $WeightTotal),
            0
        )
    }
    else {

        $OverallScore = 0
    }


    # ============================================================
    # OVERALL STATUS
    # ============================================================

    if ($OverallScore -ge 90) {

        $OverallStatus = "EXCELLENT"
    }
    elseif ($OverallScore -ge 75) {

        $OverallStatus = "GOOD"
    }
    elseif ($OverallScore -ge 50) {

        $OverallStatus = "WARNING"
    }
    else {

        $OverallStatus = "CRITICAL"
    }


    # ============================================================
    # FIND WEAKEST AREAS
    # ============================================================

    $WeakAreas = @(
        $Scores.GetEnumerator() |
            Where-Object {
                $_.Value -lt 90
            } |
            Sort-Object Value
    )

    $WeakAreaNames = @(
        $WeakAreas |
            ForEach-Object {
                $_.Key
            }
    )


    # ============================================================
    # SUMMARY
    # ============================================================

    switch ($OverallStatus) {

        "EXCELLENT" {

            $Summary = "System health is excellent."
        }

        "GOOD" {

            $Summary = "System is healthy with some areas that can be improved."
        }

        "WARNING" {

            $Summary = "System requires attention in one or more areas."
        }

        "CRITICAL" {

            $Summary = "System has critical health issues that require attention."
        }
    }


    # ============================================================
    # RESULT
    # ============================================================

    [PSCustomObject]@{

        OverallScore  = $OverallScore
        OverallStatus = $OverallStatus
        Summary       = $Summary

        ModuleScores  = [PSCustomObject]$Scores
        ModuleWeights = [PSCustomObject]$Weights

        WeakAreas     = $WeakAreaNames

        System        = $Scores.System
        Disk          = $Scores.Disk
        Network       = $Scores.Network
        WindowsUpdate = $Scores.WindowsUpdate
        EventLog      = $Scores.EventLog
        Crash         = $Scores.Crash
        Hardware      = $Scores.Hardware
        Security      = $Scores.Security
    }
}


Export-ModuleMember -Function `
    Get-REWinHealthEngine
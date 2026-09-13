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

    # System
    $Scores.System = if ($System.Status -eq "OK") {
        100
    }
    else {
        70
    }

    # Disk
    if ($Disk.Status -contains "CRITICAL") {
        $Scores.Disk = 30
    }
    elseif ($Disk.Status -contains "WARNING") {
        $Scores.Disk = 60
    }
    else {
        $Scores.Disk = 100
    }

    # Network
    if ($Network.HealthScore -ne $null) {
        $Scores.Network = [int]$Network.HealthScore
    }
    elseif ($Network.Status -eq "OK") {
        $Scores.Network = 100
    }
    else {
        $Scores.Network = 60
    }

    # Windows Update
    $Scores.WindowsUpdate = if ($WindowsUpdate.Status -eq "OK") {
        100
    }
    else {
        80
    }

    # Event Log
    if ($EventLog.Status -eq "OK") {
        $Scores.EventLog = 100
    }
    elseif ($EventLog.Status -eq "WARNING") {
        $Scores.EventLog = 80
    }
    else {
        $Scores.EventLog = 50
    }

    # Crash
    if ($Crash.Status -eq "OK") {
        $Scores.Crash = 100
    }
    elseif ($Crash.Status -eq "WARNING") {
        $Scores.Crash = 80
    }
    else {
        $Scores.Crash = 40
    }

    # Hardware
    if ($Hardware.HealthScore -ne $null) {
        $Scores.Hardware = [int]$Hardware.HealthScore
    }
    elseif ($Hardware.Status -eq "OK") {
        $Scores.Hardware = 100
    }
    else {
        $Scores.Hardware = 60
    }

    # Security
    if ($Security.HealthScore -ne $null) {
        $Scores.Security = [int]$Security.HealthScore
    }
    elseif ($Security.Status -eq "OK") {
        $Scores.Security = 100
    }
    else {
        $Scores.Security = 60
    }


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
            $WeightedTotal / $WeightTotal,
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

    $Summary = switch ($OverallStatus) {

        "EXCELLENT" {
            "System health is excellent."
        }

        "GOOD" {
            "System is healthy with some areas that can be improved."
        }

        "WARNING" {
            "System requires attention in one or more areas."
        }

        "CRITICAL" {
            "System has critical health issues that require attention."
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
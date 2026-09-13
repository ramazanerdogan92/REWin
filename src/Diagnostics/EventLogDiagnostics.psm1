function Get-REWinEventLogDiagnostics {

    $StartTime = (Get-Date).AddHours(-24)

    $LogNames = @(
        "System",
        "Application"
    )

    $AllEvents = @()

    foreach ($LogName in $LogNames) {

        try {

            $Events = Get-WinEvent -FilterHashtable @{
                LogName   = $LogName
                StartTime = $StartTime
            } -ErrorAction Stop

            if ($Events) {
                $AllEvents += $Events
            }

        }
        catch {
            # Log okunamazsa REWin çalışmaya devam eder.
        }
    }

    # Event Level değerleri:
    # 1 = Critical
    # 2 = Error
    # 3 = Warning
    # 4 = Information
    # 5 = Verbose

    $Critical = @(
        $AllEvents |
        Where-Object { $_.Level -eq 1 }
    )

    $Errors = @(
        $AllEvents |
        Where-Object { $_.Level -eq 2 }
    )

    $Warnings = @(
        $AllEvents |
        Where-Object { $_.Level -eq 3 }
    )

    $Information = @(
        $AllEvents |
        Where-Object { $_.Level -eq 4 }
    )

    # Genel durum
    if ($Critical.Count -gt 0) {
        $Status = "CRITICAL"
    }
    elseif ($Errors.Count -gt 0) {
        $Status = "WARNING"
    }
    elseif ($Warnings.Count -gt 0) {
        $Status = "WARNING"
    }
    else {
        $Status = "OK"
    }

    # En çok event üreten providerlar
    $TopProviders = @(
        $AllEvents |
        Group-Object ProviderName |
        Sort-Object Count -Descending |
        Select-Object -First 10 |
        ForEach-Object {

            [PSCustomObject]@{
                Provider = if ($_.Name) {
                    $_.Name
                }
                else {
                    "Unknown"
                }

                Count = $_.Count
            }
        }
    )

    # Son problemli eventler
    $ProblemEvents = @(
        $AllEvents |
        Where-Object {
            $_.Level -in @(1, 2, 3)
        } |
        Sort-Object TimeCreated -Descending |
        Select-Object -First 20 |
        ForEach-Object {

            [PSCustomObject]@{
                Time = $_.TimeCreated

                Log = $_.LogName

                Level = switch ($_.Level) {
                    1 { "Critical" }
                    2 { "Error" }
                    3 { "Warning" }
                    4 { "Information" }
                    5 { "Verbose" }
                    default { "Unknown" }
                }

                EventID = $_.Id

                Provider = if ($_.ProviderName) {
                    $_.ProviderName
                }
                else {
                    "Unknown"
                }

                Message = if ($_.Message) {
                    ($_.Message -replace "`r|`n", " ").Trim()
                }
                else {
                    "No message available"
                }
            }
        }
    )

    # Son eventler
    $LatestEvents = @(
        $AllEvents |
        Sort-Object TimeCreated -Descending |
        Select-Object -First 20 |
        ForEach-Object {

            [PSCustomObject]@{
                Time = $_.TimeCreated

                Log = $_.LogName

                Level = switch ($_.Level) {
                    1 { "Critical" }
                    2 { "Error" }
                    3 { "Warning" }
                    4 { "Information" }
                    5 { "Verbose" }
                    default { "Unknown" }
                }

                EventID = $_.Id

                Provider = if ($_.ProviderName) {
                    $_.ProviderName
                }
                else {
                    "Unknown"
                }
            }
        }
    )

    [PSCustomObject]@{

        Status = $Status

        ScanPeriod = "Last 24 Hours"

        LogSources = $LogNames -join ", "

        TotalEvents = $AllEvents.Count

        CriticalCount = $Critical.Count

        ErrorCount = $Errors.Count

        WarningCount = $Warnings.Count

        InformationCount = $Information.Count

        TopProviders = $TopProviders

        ProblemEvents = $ProblemEvents

        LatestEvents = $LatestEvents
    }
}

Export-ModuleMember -Function Get-REWinEventLogDiagnostics
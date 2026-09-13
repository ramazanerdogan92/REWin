function Get-REWinCrashDiagnostics {

    $CrashEvents = @()

    # Windows Error Reporting / BugCheck event sources
    $LogNames = @(
        "System"
    )

    foreach ($LogName in $LogNames) {

        try {

            $Events = Get-WinEvent -FilterHashtable @{
                LogName = $LogName
                Id      = 1001
            } -ErrorAction Stop

            if ($Events) {
                $CrashEvents += $Events
            }

        }
        catch {
            # Event log okunamazsa devam et.
        }
    }

    $CrashEvents = @(
        $CrashEvents |
        Sort-Object TimeCreated -Descending
    )

    # Minidump klasörü
    $MiniDumpPath = "$env:SystemRoot\Minidump"

    $DumpFiles = @()

    if (Test-Path $MiniDumpPath) {

        $DumpFiles = @(
            Get-ChildItem `
                -Path $MiniDumpPath `
                -Filter "*.dmp" `
                -File `
                -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending
        )
    }

    # Son dump
    $LatestDump = $DumpFiles |
        Select-Object -First 1

    # Son BugCheck Event
    $LatestCrash = $CrashEvents |
        Select-Object -First 1

    $CrashCount = $CrashEvents.Count
    $DumpCount = $DumpFiles.Count

    # Registry üzerinden CrashControl bilgisi
    $CrashControl = Get-ItemProperty `
        "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl" `
        -ErrorAction SilentlyContinue

    $AutoReboot = $null
    $DumpType = $null

    if ($CrashControl) {

        $AutoReboot = $CrashControl.AutoReboot

        $DumpType = switch ($CrashControl.CrashDumpEnabled) {

            0 { "Disabled" }

            1 { "Complete Memory Dump" }

            2 { "Kernel Memory Dump" }

            3 { "Small Memory Dump" }

            7 { "Automatic Memory Dump" }

            default { "Unknown" }
        }
    }

    # Genel durum
    if ($CrashCount -gt 0) {
        $Status = "WARNING"
    }
    elseif ($DumpCount -gt 0) {
        $Status = "WARNING"
    }
    else {
        $Status = "OK"
    }

    # Son crash bilgisi
    $LatestCrashInfo = $null

    if ($LatestCrash) {

        $Message = $LatestCrash.Message

        $LatestCrashInfo = [PSCustomObject]@{

            Time = $LatestCrash.TimeCreated

            EventID = $LatestCrash.Id

            Provider = $LatestCrash.ProviderName

            Message = if ($Message) {
                ($Message -replace "`r|`n", " ").Trim()
            }
            else {
                "No message available"
            }
        }
    }

    # Son dump bilgisi
    $LatestDumpInfo = $null

    if ($LatestDump) {

        $LatestDumpInfo = [PSCustomObject]@{

            FileName = $LatestDump.Name

            Path = $LatestDump.FullName

            SizeMB = [math]::Round(
                $LatestDump.Length / 1MB,
                2
            )

            Created = $LatestDump.CreationTime

            Modified = $LatestDump.LastWriteTime
        }
    }

    [PSCustomObject]@{

        Status = $Status

        CrashEventCount = $CrashCount

        MinidumpCount = $DumpCount

        MinidumpPath = $MiniDumpPath

        LatestCrash = $LatestCrashInfo

        LatestDump = $LatestDumpInfo

        CrashDumpType = $DumpType

        AutoReboot = $AutoReboot
    }
}

Export-ModuleMember -Function Get-REWinCrashDiagnostics
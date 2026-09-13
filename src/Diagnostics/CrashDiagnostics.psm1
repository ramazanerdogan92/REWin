function Get-REWinCrashDiagnostics {

    $StartTime = (Get-Date).AddDays(-30)

    # ------------------------------------------------------------
    # BUGCHECK EVENTS
    # ------------------------------------------------------------

    $BugCheckEvents = @()

    try {

        $BugCheckEvents = @(
            Get-WinEvent -FilterHashtable @{
                LogName   = "System"
                Id        = 1001
                StartTime = $StartTime
            } -ErrorAction Stop |
            Sort-Object TimeCreated -Descending
        )

    }
    catch {
        $BugCheckEvents = @()
    }


    # ------------------------------------------------------------
    # KERNEL-POWER EVENTS
    # ------------------------------------------------------------

    $KernelPowerEvents = @()

    try {

        $KernelPowerEvents = @(
            Get-WinEvent -FilterHashtable @{
                LogName   = "System"
                Id        = 41
                StartTime = $StartTime
            } -ErrorAction Stop |
            Sort-Object TimeCreated -Descending
        )

    }
    catch {
        $KernelPowerEvents = @()
    }


    # ------------------------------------------------------------
    # MINIDUMPS
    # ------------------------------------------------------------

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


    # ------------------------------------------------------------
    # LIVE KERNEL DUMPS
    # ------------------------------------------------------------

    $LiveDumpPath = "$env:SystemRoot\LiveKernelReports"

    $LiveDumpFiles = @()

    if (Test-Path $LiveDumpPath) {

        $LiveDumpFiles = @(
            Get-ChildItem `
                -Path $LiveDumpPath `
                -Recurse `
                -Filter "*.dmp" `
                -File `
                -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending
        )
    }


    # ------------------------------------------------------------
    # LIVE KERNEL DUMP ANALYSIS
    # ------------------------------------------------------------

    $LiveDumpAnalysis = @()

    foreach ($Dump in $LiveDumpFiles) {

        $RelativePath = $Dump.FullName.Substring(
            $LiveDumpPath.Length
        ).TrimStart("\\")

        $Parts = $RelativePath.Split("\")

        $Category = if ($Parts.Count -gt 1) {
            $Parts[0]
        }
        else {
            "Unknown"
        }

        switch -Regex ($Category) {

            "WATCHDOG" {

                $LikelyCause = "Driver / GPU / Hardware Watchdog"

                $Recommendation = @(
                    "Check graphics and chipset drivers."
                    "Check Windows Update for driver updates."
                    "Review recent driver changes."
                    "If the issue repeats, analyze the dump with WinDbg."
                ) -join " "

                break
            }

            "GPU|GRAPHICS|DISPLAY" {

                $LikelyCause = "Graphics Driver / GPU"

                $Recommendation = @(
                    "Check GPU driver version."
                    "Consider clean driver installation."
                    "Check GPU temperature and hardware health."
                    "Analyze the dump if the issue repeats."
                ) -join " "

                break
            }

            "USB" {

                $LikelyCause = "USB Driver / USB Device"

                $Recommendation = @(
                    "Check connected USB devices."
                    "Update chipset and USB drivers."
                    "Test after disconnecting non-essential USB devices."
                ) -join " "

                break
            }

            "PDC" {

                $LikelyCause = "Power Management / Driver"

                $Recommendation = @(
                    "Check power management settings."
                    "Update chipset and device drivers."
                    "Review sleep and hibernation related events."
                ) -join " "

                break
            }

            default {

                $LikelyCause = "Unknown Live Kernel Dump"

                $Recommendation = @(
                    "Review the dump category and timestamp."
                    "Check System Event Log around the same time."
                    "Analyze the dump with WinDbg if the problem repeats."
                ) -join " "
            }
        }


        $LiveDumpAnalysis += [PSCustomObject]@{

            FileName = $Dump.Name

            Category = $Category

            Path = $Dump.FullName

            SizeMB = [math]::Round(
                $Dump.Length / 1MB,
                2
            )

            Modified = $Dump.LastWriteTime

            LikelyCause = $LikelyCause

            Recommendation = $Recommendation
        }
    }


    # ------------------------------------------------------------
    # CRASH CONTROL
    # ------------------------------------------------------------

    $CrashControl = Get-ItemProperty `
        "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl" `
        -ErrorAction SilentlyContinue

    $DumpType = "Unknown"
    $AutoReboot = $null

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


    # ------------------------------------------------------------
    # BUGCHECK ANALYSIS
    # ------------------------------------------------------------

    $LatestBugCheck = $null

    if ($BugCheckEvents.Count -gt 0) {

        $LatestEvent = $BugCheckEvents[0]

        $Message = $LatestEvent.Message

        $Match = [regex]::Match(
            $Message,
            '0x[0-9A-Fa-f]{1,8}'
        )

        $BugCheckCode = if ($Match.Success) {
            $Match.Value.ToUpper()
        }
        else {
            "Unknown"
        }

        $BugCheckName = switch ($BugCheckCode) {

            "0x0000000A" {
                "IRQL_NOT_LESS_OR_EQUAL"
            }

            "0x0000001E" {
                "KMODE_EXCEPTION_NOT_HANDLED"
            }

            "0x0000003B" {
                "SYSTEM_SERVICE_EXCEPTION"
            }

            "0x00000050" {
                "PAGE_FAULT_IN_NONPAGED_AREA"
            }

            "0x0000007E" {
                "SYSTEM_THREAD_EXCEPTION_NOT_HANDLED"
            }

            "0x0000009F" {
                "DRIVER_POWER_STATE_FAILURE"
            }

            "0x00000116" {
                "VIDEO_TDR_FAILURE"
            }

            "0x00000133" {
                "DPC_WATCHDOG_VIOLATION"
            }

            "0x00000139" {
                "KERNEL_SECURITY_CHECK_FAILURE"
            }

            "0x00000124" {
                "WHEA_UNCORRECTABLE_ERROR"
            }

            "0x00000154" {
                "UNEXPECTED_STORE_EXCEPTION"
            }

            default {
                "Unknown BugCheck"
            }
        }

        $LatestBugCheck = [PSCustomObject]@{

            Time = $LatestEvent.TimeCreated

            EventID = $LatestEvent.Id

            BugCheckCode = $BugCheckCode

            BugCheckName = $BugCheckName

            Provider = $LatestEvent.ProviderName

            Message = if ($Message) {
                ($Message -replace "`r|`n", " ").Trim()
            }
            else {
                "No message available"
            }
        }
    }


    # ------------------------------------------------------------
    # LATEST MINIDUMP
    # ------------------------------------------------------------

    $LatestDump = $DumpFiles |
        Select-Object -First 1

    $LatestDumpInfo = $null

    if ($LatestDump) {

        $LatestDumpInfo = [PSCustomObject]@{

            FileName = $LatestDump.Name

            Path = $LatestDump.FullName

            SizeMB = [math]::Round(
                $LatestDump.Length / 1MB,
                2
            )

            Modified = $LatestDump.LastWriteTime
        }
    }


    # ------------------------------------------------------------
    # HEALTH STATUS
    # ------------------------------------------------------------

    if ($BugCheckEvents.Count -gt 0) {

        $Status = "CRITICAL"

    }
    elseif ($KernelPowerEvents.Count -gt 0) {

        $Status = "WARNING"

    }
    elseif ($LiveDumpFiles.Count -gt 0) {

        $Status = "WARNING"

    }
    elseif ($DumpFiles.Count -gt 0) {

        $Status = "WARNING"

    }
    else {

        $Status = "OK"
    }


    # ------------------------------------------------------------
    # RESULT
    # ------------------------------------------------------------

    [PSCustomObject]@{

        Status = $Status

        ScanPeriod = "Last 30 Days"

        BugCheckCount = $BugCheckEvents.Count

        KernelPowerCount = $KernelPowerEvents.Count

        MinidumpCount = $DumpFiles.Count

        LiveKernelDumpCount = $LiveDumpFiles.Count

        MinidumpPath = $MiniDumpPath

        LiveKernelDumpPath = $LiveDumpPath

        CrashDumpType = $DumpType

        AutoReboot = if ($AutoReboot -eq 1) {
            "Enabled"
        }
        elseif ($AutoReboot -eq 0) {
            "Disabled"
        }
        else {
            "Unknown"
        }

        LatestBugCheck = $LatestBugCheck

        LatestMinidump = $LatestDumpInfo

        LiveKernelDumps = $LiveDumpAnalysis
    }
}

Export-ModuleMember -Function Get-REWinCrashDiagnostics
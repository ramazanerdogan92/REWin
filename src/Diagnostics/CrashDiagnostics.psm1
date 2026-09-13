function Get-REWinCrashDiagnostics {

    $StartTime = (Get-Date).AddDays(-30)

    # ------------------------------------------------------------
    # BUGCHECK EVENTS
    # Event ID 1001 = BugCheck / Windows Error Reporting
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
    # Event ID 41 = Unexpected shutdown / restart
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
    # MINIDUMP
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
    # CRASH CONTROL CONFIGURATION
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
    # BUGCHECK CODE ANALYSIS
    # ------------------------------------------------------------

    $LatestBugCheck = $null
    $BugCheckCode = $null
    $BugCheckName = "Unknown"
    $LikelyCause = "Unknown"

    if ($BugCheckEvents.Count -gt 0) {

        $LatestEvent = $BugCheckEvents[0]

        $Message = $LatestEvent.Message

        # Find hexadecimal BugCheck code
        $Match = [regex]::Match(
            $Message,
            '0x[0-9A-Fa-f]{1,8}'
        )

        if ($Match.Success) {

            $BugCheckCode = $Match.Value.ToUpper()

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

            $LikelyCause = switch ($BugCheckCode) {

                "0x0000009F" {
                    "Driver / Power Management"
                }

                "0x00000116" {
                    "Graphics Driver / GPU"
                }

                "0x00000124" {
                    "Hardware / CPU / RAM / PCIe"
                }

                "0x00000133" {
                    "Driver / Kernel / Hardware"
                }

                "0x00000050" {
                    "Driver / Memory"
                }

                "0x0000000A" {
                    "Driver / Kernel Memory"
                }

                "0x0000003B" {
                    "Driver / System Service"
                }

                default {
                    "Requires dump analysis"
                }
            }
        }


        $LatestBugCheck = [PSCustomObject]@{

            Time = $LatestEvent.TimeCreated

            EventID = $LatestEvent.Id

            BugCheckCode = $BugCheckCode

            BugCheckName = $BugCheckName

            LikelyCause = $LikelyCause

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

            Created = $LatestDump.CreationTime

            Modified = $LatestDump.LastWriteTime
        }
    }


    # ------------------------------------------------------------
    # LATEST LIVE KERNEL DUMP
    # ------------------------------------------------------------

    $LatestLiveDump = $LiveDumpFiles |
        Select-Object -First 1

    $LatestLiveDumpInfo = $null

    if ($LatestLiveDump) {

        $LatestLiveDumpInfo = [PSCustomObject]@{

            FileName = $LatestLiveDump.Name

            Path = $LatestLiveDump.FullName

            SizeMB = [math]::Round(
                $LatestLiveDump.Length / 1MB,
                2
            )

            Modified = $LatestLiveDump.LastWriteTime
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
    elseif ($DumpFiles.Count -gt 0) {

        $Status = "WARNING"

    }
    elseif ($LiveDumpFiles.Count -gt 0) {

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

        LatestLiveKernelDump = $LatestLiveDumpInfo
    }
}

Export-ModuleMember -Function Get-REWinCrashDiagnostics
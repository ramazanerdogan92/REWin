function Get-REWinHardwareDiagnostics {

    # ------------------------------------------------------------
    # CPU
    # ------------------------------------------------------------

    $CPU = Get-CimInstance Win32_Processor |
        Select-Object -First 1

    $CPUInfo = [PSCustomObject]@{
        Name              = $CPU.Name
        Manufacturer      = $CPU.Manufacturer
        Cores             = $CPU.NumberOfCores
        LogicalProcessors = $CPU.NumberOfLogicalProcessors
        MaxClockMHz       = $CPU.MaxClockSpeed
        CurrentClockMHz   = $CPU.CurrentClockSpeed
        LoadPercent       = $CPU.LoadPercentage
    }


    # ------------------------------------------------------------
    # MEMORY
    # ------------------------------------------------------------

    $ComputerSystem = Get-CimInstance Win32_ComputerSystem
    $OS = Get-CimInstance Win32_OperatingSystem

    $TotalMemoryGB = [math]::Round(
        $ComputerSystem.TotalPhysicalMemory / 1GB,
        2
    )

    $FreeMemoryGB = [math]::Round(
        $OS.FreePhysicalMemory / 1MB,
        2
    )

    $UsedMemoryGB = [math]::Round(
        $TotalMemoryGB - $FreeMemoryGB,
        2
    )

    if ($TotalMemoryGB -gt 0) {
        $MemoryUsagePercent = [math]::Round(
            ($UsedMemoryGB / $TotalMemoryGB) * 100,
            2
        )
    }
    else {
        $MemoryUsagePercent = 0
    }

    if ($MemoryUsagePercent -ge 90) {
        $MemoryStatus = "CRITICAL"
    }
    elseif ($MemoryUsagePercent -ge 80) {
        $MemoryStatus = "WARNING"
    }
    else {
        $MemoryStatus = "OK"
    }

    $MemoryInfo = [PSCustomObject]@{
        TotalGB      = $TotalMemoryGB
        UsedGB       = $UsedMemoryGB
        FreeGB       = $FreeMemoryGB
        UsagePercent = $MemoryUsagePercent
        Status       = $MemoryStatus
    }


    # ------------------------------------------------------------
    # PHYSICAL DISKS
    # ------------------------------------------------------------

    $PhysicalDisks = @()

    try {

        $PhysicalDisks = @(
            Get-PhysicalDisk -ErrorAction Stop |
            ForEach-Object {

                [PSCustomObject]@{
                    DeviceID = $_.DeviceId

                    FriendlyName = $_.FriendlyName

                    MediaType = $_.MediaType

                    SizeGB = [math]::Round(
                        $_.Size / 1GB,
                        2
                    )

                    HealthStatus = $_.HealthStatus

                    OperationalStatus = (
                        $_.OperationalStatus -join ", "
                    )
                }
            }
        )
    }
    catch {

        $PhysicalDisks = @(
            [PSCustomObject]@{
                DeviceID = "Unavailable"
                FriendlyName = "Get-PhysicalDisk unavailable"
                MediaType = "Unknown"
                SizeGB = 0
                HealthStatus = "Unknown"
                OperationalStatus = "Unknown"
            }
        )
    }

    $BadDisks = @(
        $PhysicalDisks |
        Where-Object {
            $_.HealthStatus -notin @(
                "Healthy",
                "Unknown"
            )
        }
    )

    $DiskStatus = if ($BadDisks.Count -gt 0) {
        "CRITICAL"
    }
    else {
        "OK"
    }


    # ------------------------------------------------------------
    # GPU
    # ------------------------------------------------------------

    $GPUs = @()

    try {

        $GPUs = @(
            Get-CimInstance Win32_VideoController |
            ForEach-Object {

                $VRAMGB = $null

                if ($_.AdapterRAM) {
                    $VRAMGB = [math]::Round(
                        $_.AdapterRAM / 1GB,
                        2
                    )
                }

                [PSCustomObject]@{
                    Name          = $_.Name
                    DriverVersion = $_.DriverVersion
                    DriverDate    = $_.DriverDate
                    VRAMGB        = $VRAMGB
                    Status        = $_.Status
                    PNPDeviceID   = $_.PNPDeviceID
                }
            }
        )
    }
    catch {

        $GPUs = @()
    }

    $GPUProblemCount = @(
        $GPUs |
        Where-Object {
            $_.Status -and $_.Status -ne "OK"
        }
    ).Count

    $GPUStatus = if ($GPUProblemCount -gt 0) {
        "WARNING"
    }
    else {
        "OK"
    }


    # ------------------------------------------------------------
    # BATTERY
    # ------------------------------------------------------------

    $BatteryInfo = @()

    try {

        $Batteries = Get-CimInstance `
            Win32_Battery `
            -ErrorAction Stop

        if ($Batteries) {

            foreach ($Battery in $Batteries) {

                $Runtime = $Battery.EstimatedRunTime

                if (
                    $null -eq $Runtime -or
                    $Runtime -le 0 -or
                    $Runtime -gt 1440
                ) {
                    $RuntimeValue = $null
                }
                else {
                    $RuntimeValue = $Runtime
                }

                $BatteryInfo += [PSCustomObject]@{
                    Name = $Battery.Name
                    StatusCode = $Battery.BatteryStatus
                    ChargePercent = $Battery.EstimatedChargeRemaining
                    EstimatedRunTimeMinutes = $RuntimeValue
                }
            }
        }
    }
    catch {

        $BatteryInfo = @()
    }


    # ------------------------------------------------------------
    # DEVICE MANAGER
    # ------------------------------------------------------------

    $ProblemDevices = @()

    try {

        $ProblemDevices = @(
            Get-CimInstance Win32_PnPEntity |
            Where-Object {
                $_.ConfigManagerErrorCode -ne 0
            } |
            ForEach-Object {

                $Name = if ($_.Name) {
                    $_.Name
                }
                else {
                    "Unknown Device"
                }

                $Category = "Hardware / Device"

                if (
                    $Name -match `
                    "Virtual|VPN|PANGP|TAP|TUN|Hyper-V|VMware|VirtualBox|WireGuard"
                ) {
                    $Category = "Virtual / Network"
                }
                elseif (
                    $Name -match `
                    "Wi-Fi|Wireless|Ethernet|Network|Bluetooth"
                ) {
                    $Category = "Network"
                }

                $ErrorDescription = switch (
                    $_.ConfigManagerErrorCode
                ) {

                    10 {
                        "Device cannot start"
                    }

                    22 {
                        "Device is disabled"
                    }

                    28 {
                        "Driver not installed"
                    }

                    31 {
                        "Driver cannot load"
                    }

                    43 {
                        "Device reported a problem"
                    }

                    default {
                        "Device Manager error code $($_.ConfigManagerErrorCode)"
                    }
                }

                [PSCustomObject]@{

                    Name = $Name

                    Category = $Category

                    DeviceID = $_.PNPDeviceID

                    ErrorCode = $_.ConfigManagerErrorCode

                    ErrorDescription = $ErrorDescription

                    Status = $_.Status
                }
            }
        )
    }
    catch {

        $ProblemDevices = @()
    }

    $PhysicalProblemDevices = @(
        $ProblemDevices |
        Where-Object {
            $_.Category -eq "Hardware / Device"
        }
    )

    $NetworkProblemDevices = @(
        $ProblemDevices |
        Where-Object {
            $_.Category -eq "Network"
        }
    )

    $VirtualProblemDevices = @(
        $ProblemDevices |
        Where-Object {
            $_.Category -eq "Virtual / Network"
        }
    )


    # ------------------------------------------------------------
    # WHEA
    # ------------------------------------------------------------

    $WHEAEvents = @()

    try {

        $WHEAEvents = @(
            Get-WinEvent -FilterHashtable @{
                LogName      = "System"
                ProviderName = "Microsoft-Windows-WHEA-Logger"
                StartTime    = (Get-Date).AddDays(-30)
            } -ErrorAction Stop |
            Sort-Object TimeCreated -Descending
        )
    }
    catch {

        $WHEAEvents = @()
    }

    $WHEAProblems = @(
        $WHEAEvents |
        Where-Object {
            $_.Level -in @(1, 2, 3)
        }
    )


    # ------------------------------------------------------------
    # HEALTH SCORE
    # ------------------------------------------------------------

    $HealthScore = 100

    $HealthReasons = @()

    if ($WHEAProblems.Count -gt 0) {

        $HealthScore -= 30

        $HealthReasons += "WHEA hardware errors detected."
    }

    if ($BadDisks.Count -gt 0) {

        $HealthScore -= 30

        $HealthReasons += "Physical disk health problem detected."
    }

    if ($PhysicalProblemDevices.Count -gt 0) {

        $HealthScore -= 20

        $HealthReasons += "Physical device problem detected."
    }

    if ($NetworkProblemDevices.Count -gt 0) {

        $HealthScore -= 10

        $HealthReasons += "Network device problem detected."
    }

    if ($GPUStatus -ne "OK") {

        $HealthScore -= 15

        $HealthReasons += "GPU problem detected."
    }

    if ($MemoryStatus -eq "WARNING") {

        $HealthScore -= 10

        $HealthReasons += "High memory usage."
    }

    if ($MemoryStatus -eq "CRITICAL") {

        $HealthScore -= 20

        $HealthReasons += "Critical memory usage."
    }

    # Sanal VPN adapter sorunları health score'u düşürmez.
    if ($VirtualProblemDevices.Count -gt 0) {

        $HealthReasons += "Virtual/network adapter issue detected; excluded from hardware health score."
    }

    if ($HealthScore -lt 0) {
        $HealthScore = 0
    }

    if ($HealthScore -ge 90) {
        $HealthStatus = "EXCELLENT"
    }
    elseif ($HealthScore -ge 75) {
        $HealthStatus = "GOOD"
    }
    elseif ($HealthScore -ge 50) {
        $HealthStatus = "WARNING"
    }
    else {
        $HealthStatus = "CRITICAL"
    }


    # ------------------------------------------------------------
    # OVERALL STATUS
    # ------------------------------------------------------------

    if ($WHEAProblems.Count -gt 0) {

        $Status = "CRITICAL"

    }
    elseif ($BadDisks.Count -gt 0) {

        $Status = "CRITICAL"

    }
    elseif ($PhysicalProblemDevices.Count -gt 0) {

        $Status = "WARNING"

    }
    elseif ($NetworkProblemDevices.Count -gt 0) {

        $Status = "WARNING"

    }
    elseif ($GPUStatus -ne "OK") {

        $Status = "WARNING"

    }
    elseif ($MemoryStatus -ne "OK") {

        $Status = $MemoryStatus

    }
    else {

        $Status = "OK"
    }


    # ------------------------------------------------------------
    # RESULT
    # ------------------------------------------------------------

    [PSCustomObject]@{

        Status = $Status

        HealthScore = $HealthScore

        HealthStatus = $HealthStatus

        HealthReasons = $HealthReasons

        CPU = $CPUInfo

        Memory = $MemoryInfo

        PhysicalDisks = $PhysicalDisks

        DiskStatus = $DiskStatus

        GPUs = $GPUs

        GPUStatus = $GPUStatus

        Battery = $BatteryInfo

        ProblemDeviceCount = $ProblemDevices.Count

        PhysicalProblemDeviceCount = $PhysicalProblemDevices.Count

        NetworkProblemDeviceCount = $NetworkProblemDevices.Count

        VirtualProblemDeviceCount = $VirtualProblemDevices.Count

        ProblemDevices = $ProblemDevices

        WHEAEventCount = $WHEAEvents.Count

        WHEAProblemCount = $WHEAProblems.Count

        LatestWHEA = if ($WHEAEvents.Count -gt 0) {

            @(
                $WHEAEvents |
                Select-Object -First 5 |
                ForEach-Object {

                    [PSCustomObject]@{

                        Time = $_.TimeCreated

                        EventID = $_.Id

                        Level = $_.LevelDisplayName

                        Message = if ($_.Message) {
                            ($_.Message -replace "`r|`n", " ").Trim()
                        }
                        else {
                            "No message available"
                        }
                    }
                }
            )
        }
        else {
            @()
        }
    }
}

Export-ModuleMember -Function Get-REWinHardwareDiagnostics
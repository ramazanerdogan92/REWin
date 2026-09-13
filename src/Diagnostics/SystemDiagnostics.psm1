function Get-REWinSystemDiagnostics {

    $OS = Get-CimInstance Win32_OperatingSystem
    $Computer = Get-CimInstance Win32_ComputerSystem
    $CPU = Get-CimInstance Win32_Processor | Select-Object -First 1

    $Uptime = (Get-Date) - $OS.LastBootUpTime

    $DomainStatus = if ($Computer.PartOfDomain) {
        $Computer.Domain
    }
    else {
        "WORKGROUP"
    }

    $HealthScore = 100
    $Reasons = @()

    # ------------------------------------------------------------
    # Uptime
    # ------------------------------------------------------------

    if ($Uptime.TotalDays -gt 30) {
        $HealthScore -= 10
        $Reasons += "System uptime is longer than 30 days."
    }
    elseif ($Uptime.TotalDays -gt 14) {
        $HealthScore -= 5
        $Reasons += "System uptime is longer than 14 days."
    }

    # ------------------------------------------------------------
    # Memory
    # ------------------------------------------------------------

    $MemoryUsagePercent = 0

    if ($Computer.TotalPhysicalMemory -gt 0) {

        $MemoryUsagePercent = [math]::Round(
            (($Computer.TotalPhysicalMemory -
              $OS.FreePhysicalMemory * 1KB) /
              $Computer.TotalPhysicalMemory) * 100,
            2
        )
    }

    if ($MemoryUsagePercent -ge 95) {
        $HealthScore -= 20
        $Reasons += "Memory usage is critically high."
    }
    elseif ($MemoryUsagePercent -ge 90) {
        $HealthScore -= 10
        $Reasons += "Memory usage is high."
    }

    # ------------------------------------------------------------
    # Health status
    # ------------------------------------------------------------

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

    if ($HealthScore -ge 75) {
        $Status = "OK"
    }
    else {
        $Status = "WARNING"
    }

    # ------------------------------------------------------------
    # Result
    # ------------------------------------------------------------

    [PSCustomObject]@{
        Status              = $Status
        HealthScore         = $HealthScore
        HealthStatus        = $HealthStatus
        HealthReasons       = $Reasons

        ComputerName        = $env:COMPUTERNAME
        UserName            = $env:USERNAME

        Manufacturer        = $Computer.Manufacturer
        Model               = $Computer.Model

        OperatingSystem     = $OS.Caption
        Version             = $OS.Version
        Build               = $OS.BuildNumber

        CPU                 = $CPU.Name
        RAM_GB              = [math]::Round(
            $Computer.TotalPhysicalMemory / 1GB,
            2
        )

        MemoryUsagePercent  = $MemoryUsagePercent

        Domain              = $DomainStatus

        LastBoot            = $OS.LastBootUpTime
        UptimeDays          = [math]::Round(
            $Uptime.TotalDays,
            2
        )

        Architecture        = $OS.OSArchitecture
    }
}

Export-ModuleMember -Function `
    Get-REWinSystemDiagnostics
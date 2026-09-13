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

    [PSCustomObject]@{
        ComputerName = $env:COMPUTERNAME
        UserName     = $env:USERNAME

        Manufacturer = $Computer.Manufacturer
        Model        = $Computer.Model

        OperatingSystem = $OS.Caption
        Version         = $OS.Version
        Build           = $OS.BuildNumber

        CPU = $CPU.Name

        RAM_GB = [math]::Round(
            $Computer.TotalPhysicalMemory / 1GB,
            2
        )

        Domain = $DomainStatus

        LastBoot = $OS.LastBootUpTime

        UptimeDays = [math]::Round(
            $Uptime.TotalDays,
            2
        )

        Architecture = $OS.OSArchitecture
    }
}

Export-ModuleMember -Function Get-REWinSystemDiagnostics
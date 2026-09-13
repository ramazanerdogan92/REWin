function Get-REWinNetworkDiagnostics {

    # ------------------------------------------------------------
    # ACTIVE ADAPTERS
    # ------------------------------------------------------------

    $Adapters = @()

    try {

        $Adapters = @(
            Get-NetAdapter -ErrorAction Stop |
                Where-Object {
                    $_.Status -eq "Up"
                } |
                ForEach-Object {

                    $Type = "Physical"

                    if (
                        $_.Name -match `
                        "VPN|Virtual|TAP|TUN|PANGP|Hyper-V|VMware|VirtualBox|WireGuard"
                    ) {
                        $Type = "Virtual / VPN"
                    }

                    [PSCustomObject]@{
                        Name        = $_.Name
                        Description = $_.InterfaceDescription
                        Status      = $_.Status
                        LinkSpeed   = $_.LinkSpeed
                        MacAddress  = $_.MacAddress
                        Type        = $Type
                    }
                }
        )
    }
    catch {
        $Adapters = @()
    }


    # ------------------------------------------------------------
    # IP CONFIGURATION
    # ------------------------------------------------------------

    $Configurations = @()

    try {

        $Configurations = @(
            Get-NetIPConfiguration -ErrorAction Stop |
                Where-Object {
                    $_.NetAdapter.Status -eq "Up"
                } |
                ForEach-Object {

                    $IPv4 = @(
                        $_.IPv4Address |
                            ForEach-Object {
                                $_.IPAddress
                            }
                    )

                    $IPv6 = @(
                        $_.IPv6Address |
                            ForEach-Object {
                                $_.IPAddress
                            }
                    )

                    $Gateway = $_.IPv4DefaultGateway.NextHop

                    $DNS = Get-DnsClientServerAddress `
                        -InterfaceIndex $_.InterfaceIndex `
                        -AddressFamily IPv4 `
                        -ErrorAction SilentlyContinue

                    [PSCustomObject]@{
                        Interface = $_.InterfaceAlias
                        InterfaceIndex = $_.InterfaceIndex
                        IPv4 = $IPv4 -join ", "
                        IPv6 = $IPv6 -join ", "
                        Gateway = $Gateway
                        DNSServers = if ($DNS.ServerAddresses) {
                            $DNS.ServerAddresses -join ", "
                        }
                        else {
                            "N/A"
                        }
                    }
                }
        )
    }
    catch {
        $Configurations = @()
    }


    # ------------------------------------------------------------
    # PRIMARY CONFIGURATION
    # ------------------------------------------------------------

    $Primary = $Configurations |
        Where-Object {
            $_.Gateway
        } |
        Select-Object -First 1

    if (-not $Primary) {

        $Primary = $Configurations |
            Select-Object -First 1
    }


    $Gateway = $Primary.Gateway

    $PrimaryInterface = $Primary.Interface

    $PrimaryIP = $Primary.IPv4

    $PrimaryDNS = $Primary.DNSServers


    # ------------------------------------------------------------
    # GATEWAY TEST
    # ------------------------------------------------------------

    $GatewayStatus = "FAIL"

    $GatewayLatency = $null

    if ($Gateway) {

        try {

            $Ping = Test-Connection `
                -ComputerName $Gateway `
                -Count 2 `
                -ErrorAction Stop

            if ($Ping) {

                $GatewayStatus = "OK"

                $GatewayLatency = [math]::Round(
                    ($Ping | Measure-Object ResponseTime -Average).Average,
                    2
                )
            }
        }
        catch {

            $GatewayStatus = "FAIL"
        }
    }


    # ------------------------------------------------------------
    # INTERNET TEST
    # ------------------------------------------------------------

    $InternetStatus = "FAIL"

    $InternetLatency = $null

    try {

        $Ping = Test-Connection `
            -ComputerName "1.1.1.1" `
            -Count 2 `
            -ErrorAction Stop

        if ($Ping) {

            $InternetStatus = "OK"

            $InternetLatency = [math]::Round(
                ($Ping | Measure-Object ResponseTime -Average).Average,
                2
            )
        }
    }
    catch {

        $InternetStatus = "FAIL"
    }


    # ------------------------------------------------------------
    # DNS TEST
    # ------------------------------------------------------------

    $DNSStatus = "FAIL"

    $DNSResolvedIP = $null

    try {

        $DNSResult = Resolve-DnsName `
            -Name "www.microsoft.com" `
            -Type A `
            -ErrorAction Stop

        $ARecord = $DNSResult |
            Where-Object {
                $_.Type -eq "A"
            } |
            Select-Object -First 1

        if ($ARecord) {

            $DNSStatus = "OK"

            $DNSResolvedIP = $ARecord.IPAddress
        }
    }
    catch {

        $DNSStatus = "FAIL"
    }


    # ------------------------------------------------------------
    # DNS SERVER TEST
    # ------------------------------------------------------------

    $DNSServerTests = @()

    if ($PrimaryDNS -and $PrimaryDNS -ne "N/A") {

        foreach ($DNSServer in (
            $PrimaryDNS -split ", "
        )) {

            $ServerStatus = "FAIL"

            try {

                $Ping = Test-Connection `
                    -ComputerName $DNSServer `
                    -Count 1 `
                    -Quiet `
                    -ErrorAction Stop

                if ($Ping) {

                    $ServerStatus = "OK"
                }
            }
            catch {

                $ServerStatus = "FAIL"
            }

            $DNSServerTests += [PSCustomObject]@{

                Server = $DNSServer

                Status = $ServerStatus
            }
        }
    }


    # ------------------------------------------------------------
    # DHCP
    # ------------------------------------------------------------

    $DHCPEnabled = $null

    $DHCPServer = $null

    try {

        $NetIPInterface = Get-NetIPInterface `
            -InterfaceAlias $PrimaryInterface `
            -AddressFamily IPv4 `
            -ErrorAction Stop

        $DHCPEnabled = (
            $NetIPInterface.Dhcp -eq "Enabled"
        )

        if ($DHCPEnabled) {

            $DHCPServer = (
                Get-CimInstance Win32_NetworkAdapterConfiguration |
                    Where-Object {
                        $_.IPEnabled -and
                        $_.DHCPEnabled
                    } |
                    Select-Object -First 1
            ).DHCPServer
        }
    }
    catch {

        $DHCPEnabled = $null
    }


    # ------------------------------------------------------------
    # PROXY
    # ------------------------------------------------------------

    $WinHTTPProxy = "Unknown"

    try {

        $ProxyOutput = netsh winhttp show proxy 2>$null

        if ($ProxyOutput) {

            $ProxyLine = $ProxyOutput |
                Where-Object {
                    $_ -match "Proxy Server|Direct access"
                } |
                Select-Object -First 1

            if ($ProxyLine) {

                $WinHTTPProxy = $ProxyLine.Trim()
            }
        }
    }
    catch {

        $WinHTTPProxy = "Unknown"
    }


    # ------------------------------------------------------------
    # FIREWALL
    # ------------------------------------------------------------

    $FirewallProfiles = @()

    try {

        $FirewallProfiles = @(
            Get-NetFirewallProfile -ErrorAction Stop |
                Select-Object Name, Enabled
        )
    }
    catch {

        $FirewallProfiles = @()
    }


    # ------------------------------------------------------------
    # TCP 443 TEST
    # ------------------------------------------------------------

    # IMPORTANT:
    # Do not use Test-NetConnection here.
    # It can wait for a long time when the remote endpoint
    # does not respond.
    #
    # TcpClient is used with a 3-second timeout instead.

    $TCP443Status = "FAIL"

    try {

        $TcpClient = New-Object System.Net.Sockets.TcpClient

        $ConnectResult = $TcpClient.BeginConnect(
            "www.microsoft.com",
            443,
            $null,
            $null
        )

        $Connected = $ConnectResult.AsyncWaitHandle.WaitOne(3000)

        if ($Connected -and $TcpClient.Connected) {

            $TCP443Status = "OK"
        }

        $ConnectResult.AsyncWaitHandle.Close()

        $TcpClient.Close()
    }
    catch {

        $TCP443Status = "FAIL"

        if ($TcpClient) {

            try {
                $TcpClient.Close()
            }
            catch {
            }
        }
    }


    # ------------------------------------------------------------
    # VPN / VIRTUAL ADAPTERS
    # ------------------------------------------------------------

    $VirtualAdapters = @(
        $Adapters |
            Where-Object {
                $_.Type -eq "Virtual / VPN"
            }
    )


    # ------------------------------------------------------------
    # OVERALL STATUS
    # ------------------------------------------------------------

    if (-not $Primary) {

        $Status = "CRITICAL"
    }
    elseif ($GatewayStatus -eq "FAIL") {

        $Status = "CRITICAL"
    }
    elseif ($InternetStatus -eq "FAIL") {

        $Status = "WARNING"
    }
    elseif ($DNSStatus -eq "FAIL") {

        $Status = "WARNING"
    }
    elseif ($TCP443Status -eq "FAIL") {

        $Status = "WARNING"
    }
    else {

        $Status = "OK"
    }


    # ------------------------------------------------------------
    # HEALTH SCORE
    # ------------------------------------------------------------

    $HealthScore = 100

    $HealthReasons = @()

    if (-not $Primary) {

        $HealthScore -= 40

        $HealthReasons += "No active network configuration."
    }

    if ($GatewayStatus -eq "FAIL") {

        $HealthScore -= 40

        $HealthReasons += "Default gateway is unreachable."
    }

    if ($InternetStatus -eq "FAIL") {

        $HealthScore -= 20

        $HealthReasons += "Internet connectivity test failed."
    }

    if ($DNSStatus -eq "FAIL") {

        $HealthScore -= 20

        $HealthReasons += "DNS resolution failed."
    }

    if ($TCP443Status -eq "FAIL") {

        $HealthScore -= 10

        $HealthReasons += "TCP 443 connectivity test failed."
    }

    if ($HealthScore -lt 0) {

        $HealthScore = 0
    }


    # ------------------------------------------------------------
    # HEALTH STATUS
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


    # ------------------------------------------------------------
    # RESULT
    # ------------------------------------------------------------

    [PSCustomObject]@{

        Status = $Status

        HealthScore = $HealthScore

        HealthStatus = $HealthStatus

        HealthReasons = $HealthReasons

        PrimaryInterface = $PrimaryInterface

        PrimaryIP = $PrimaryIP

        Gateway = $Gateway

        GatewayStatus = $GatewayStatus

        GatewayLatencyMs = $GatewayLatency

        InternetStatus = $InternetStatus

        InternetLatencyMs = $InternetLatency

        DNSStatus = $DNSStatus

        DNSResolvedIP = $DNSResolvedIP

        DNSServers = $PrimaryDNS

        DNSServerTests = $DNSServerTests

        DHCPEnabled = $DHCPEnabled

        DHCPServer = $DHCPServer

        WinHTTPProxy = $WinHTTPProxy

        TCP443Status = $TCP443Status

        FirewallProfiles = $FirewallProfiles

        ActiveAdapters = $Adapters

        VirtualAdapterCount = $VirtualAdapters.Count

        VirtualAdapters = $VirtualAdapters

        Configurations = $Configurations
    }
}


Export-ModuleMember -Function `
    Get-REWinNetworkDiagnostics
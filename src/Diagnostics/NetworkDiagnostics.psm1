function Get-REWinNetworkDiagnostics {

    $Results = @()

    # Network configuration
    $Config = Get-NetIPConfiguration |
        Where-Object {
            $_.IPv4Address -and $_.NetAdapter.Status -eq "Up"
        } |
        Select-Object -First 1

    if (-not $Config) {
        return [PSCustomObject]@{
            Interface = "N/A"
            IP        = "N/A"
            Gateway   = "N/A"
            DNS       = "N/A"
            GatewayStatus = "FAIL"
            InternetStatus = "FAIL"
            DNSStatus = "FAIL"
            Status = "CRITICAL"
        }
    }

    $Interface = $Config.InterfaceAlias
    $IP = $Config.IPv4Address.IPAddress
    $Gateway = $Config.IPv4DefaultGateway.NextHop

    # DNS servers
    $DNS = Get-DnsClientServerAddress `
        -InterfaceAlias $Interface `
        -AddressFamily IPv4 `
        -ErrorAction SilentlyContinue

    $DNSServers = if ($DNS.ServerAddresses) {
        $DNS.ServerAddresses -join ", "
    }
    else {
        "N/A"
    }

    # Gateway test
    $GatewayOK = $false

    if ($Gateway) {
        $GatewayOK = Test-Connection `
            -ComputerName $Gateway `
            -Count 1 `
            -Quiet `
            -ErrorAction SilentlyContinue
    }

    # Internet test
    $InternetOK = Test-Connection `
        -ComputerName "1.1.1.1" `
        -Count 1 `
        -Quiet `
        -ErrorAction SilentlyContinue

    # DNS resolution test
    $DNSOK = $false

    try {
        $DNSResult = Resolve-DnsName `
            -Name "www.microsoft.com" `
            -ErrorAction Stop

        if ($DNSResult) {
            $DNSOK = $true
        }
    }
    catch {
        $DNSOK = $false
    }

    # Status calculation
    if (-not $GatewayOK) {
        $Status = "CRITICAL"
    }
    elseif (-not $DNSOK -or -not $InternetOK) {
        $Status = "WARNING"
    }
    else {
        $Status = "OK"
    }

    [PSCustomObject]@{
        Interface       = $Interface
        IP              = $IP
        Gateway         = $Gateway
        DNS             = $DNSServers
        GatewayStatus   = if ($GatewayOK) { "OK" } else { "FAIL" }
        InternetStatus  = if ($InternetOK) { "OK" } else { "FAIL" }
        DNSStatus       = if ($DNSOK) { "OK" } else { "FAIL" }
        Status          = $Status
    }
}

Export-ModuleMember -Function Get-REWinNetworkDiagnostics
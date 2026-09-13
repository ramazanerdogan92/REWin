function Get-REWinSecurityDiagnostics {

    $Reasons = @()
    $HealthScore = 100

    # ------------------------------------------------------------
    # Windows Defender
    # ------------------------------------------------------------

    $Defender = $null

    try {
        $Defender = Get-MpComputerStatus -ErrorAction Stop
    }
    catch {
        $Defender = $null
        $Reasons += "Windows Defender status is unavailable."
        $HealthScore -= 15
    }

    if ($Defender) {

        $DefenderStatus = if ($Defender.AntivirusEnabled) {
            "OK"
        }
        else {
            "WARNING"
            $Reasons += "Windows Defender antivirus is disabled."
            $HealthScore -= 25
        }

        $RealTimeStatus = if ($Defender.RealTimeProtectionEnabled) {
            "OK"
        }
        else {
            "WARNING"
            $Reasons += "Real-time protection is disabled."
            $HealthScore -= 20
        }

        $SignatureAge = $null

        if ($Defender.AntivirusSignatureLastUpdated) {
            $SignatureAge = (
                (Get-Date) - $Defender.AntivirusSignatureLastUpdated
            ).TotalDays
        }

        if ($SignatureAge -ne $null -and $SignatureAge -gt 7) {
            $Reasons += "Windows Defender signatures are older than 7 days."
            $HealthScore -= 15
        }

        $SignatureStatus = if ($SignatureAge -eq $null) {
            "UNKNOWN"
        }
        elseif ($SignatureAge -le 7) {
            "OK"
        }
        else {
            "WARNING"
        }
    }
    else {
        $DefenderStatus = "UNKNOWN"
        $RealTimeStatus = "UNKNOWN"
        $SignatureStatus = "UNKNOWN"
        $SignatureAge = $null
    }


    # ------------------------------------------------------------
    # Windows Firewall
    # ------------------------------------------------------------

    $FirewallProfiles = @()
    $FirewallProblemCount = 0

    try {

        $FirewallProfiles = Get-NetFirewallProfile -ErrorAction Stop |
            Select-Object Name, Enabled

        $FirewallProblemCount = @(
            $FirewallProfiles |
            Where-Object {
                $_.Enabled -eq $false
            }
        ).Count

        if ($FirewallProblemCount -gt 0) {
            $Reasons += "$FirewallProblemCount Windows Firewall profile(s) are disabled."
            $HealthScore -= 15
        }
    }
    catch {
        $FirewallProfiles = @()
        $Reasons += "Windows Firewall status is unavailable."
        $HealthScore -= 10
    }


    # ------------------------------------------------------------
    # UAC
    # ------------------------------------------------------------

    $UACEnabled = $false

    try {

        $EnableLUA = Get-ItemPropertyValue `
            -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" `
            -Name "EnableLUA" `
            -ErrorAction Stop

        $UACEnabled = ($EnableLUA -eq 1)

        if (-not $UACEnabled) {
            $Reasons += "User Account Control (UAC) is disabled."
            $HealthScore -= 15
        }
    }
    catch {
        $Reasons += "UAC status is unavailable."
    }


    # ------------------------------------------------------------
    # Secure Boot
    # ------------------------------------------------------------

    $SecureBootEnabled = $null

    try {
        $SecureBootEnabled = Confirm-SecureBootUEFI -ErrorAction Stop

        if (-not $SecureBootEnabled) {
            $Reasons += "Secure Boot is disabled."
            $HealthScore -= 10
        }
    }
    catch {
        $SecureBootEnabled = $null
    }


    # ------------------------------------------------------------
    # TPM
    # ------------------------------------------------------------

    $TPMPresent = $false
    $TPMReady = $false
    $TPMVersion = $null

    try {

        $TPM = Get-Tpm -ErrorAction Stop

        $TPMPresent = [bool]$TPM.TpmPresent
        $TPMReady = [bool]$TPM.TpmReady

        if (-not $TPMPresent) {
            $Reasons += "TPM is not present."
            $HealthScore -= 10
        }
        elseif (-not $TPMReady) {
            $Reasons += "TPM is present but not ready."
            $HealthScore -= 10
        }

        try {
            $TPMInfo = Get-CimInstance `
                -Namespace "root\CIMV2\Security\MicrosoftTpm" `
                -ClassName Win32_Tpm `
                -ErrorAction Stop

            if ($TPMInfo) {
                $TPMVersion = $TPMInfo.SpecVersion
            }
        }
        catch {
            $TPMVersion = $null
        }
    }
    catch {
        $Reasons += "TPM status is unavailable."
    }


    # ------------------------------------------------------------
    # Windows Security Center
    # ------------------------------------------------------------

    $SecurityCenterStatus = "UNKNOWN"

    try {

        $SecurityCenterService = Get-Service `
            -Name "wscsvc" `
            -ErrorAction Stop

        if ($SecurityCenterService.Status -eq "Running") {
            $SecurityCenterStatus = "OK"
        }
        else {
            $SecurityCenterStatus = "WARNING"
            $Reasons += "Windows Security Center service is not running."
            $HealthScore -= 10
        }
    }
    catch {
        $SecurityCenterStatus = "UNKNOWN"
    }


    # ------------------------------------------------------------
    # Defender Service
    # ------------------------------------------------------------

    $DefenderServiceStatus = "UNKNOWN"

    try {

        $DefenderService = Get-Service `
            -Name "WinDefend" `
            -ErrorAction Stop

        if ($DefenderService.Status -eq "Running") {
            $DefenderServiceStatus = "OK"
        }
        else {
            $DefenderServiceStatus = "WARNING"
        }
    }
    catch {
        $DefenderServiceStatus = "UNKNOWN"
    }


    # ------------------------------------------------------------
    # Health Status
    # ------------------------------------------------------------

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


    if (
        $DefenderStatus -eq "WARNING" -or
        $RealTimeStatus -eq "WARNING" -or
        $FirewallProblemCount -gt 0 -or
        -not $UACEnabled
    ) {
        $OverallStatus = "WARNING"
    }
    else {
        $OverallStatus = "OK"
    }


    # ------------------------------------------------------------
    # Result
    # ------------------------------------------------------------

    [PSCustomObject]@{

        Status                  = $OverallStatus
        HealthScore             = $HealthScore
        HealthStatus            = $HealthStatus
        HealthReasons           = $Reasons

        DefenderStatus          = $DefenderStatus
        DefenderServiceStatus   = $DefenderServiceStatus
        RealTimeProtection      = $RealTimeStatus

        SignatureStatus         = $SignatureStatus
        SignatureAgeDays        = if ($SignatureAge -ne $null) {
            [math]::Round($SignatureAge, 2)
        }
        else {
            $null
        }

        SignatureLastUpdated    = if ($Defender) {
            $Defender.AntivirusSignatureLastUpdated
        }
        else {
            $null
        }

        FirewallProfiles        = $FirewallProfiles
        FirewallProblemCount    = $FirewallProblemCount

        UACEnabled              = $UACEnabled

        SecureBootEnabled       = $SecureBootEnabled

        TPMPresent              = $TPMPresent
        TPMReady                = $TPMReady
        TPMVersion              = $TPMVersion

        SecurityCenterStatus    = $SecurityCenterStatus
    }
}

Export-ModuleMember -Function `
    Get-REWinSecurityDiagnostics
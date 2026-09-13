function Get-REWinSecurityDiagnostics {

    $Reasons = @()
    $HealthScore = 100

    # ============================================================
    # WINDOWS DEFENDER
    # ============================================================

    $Defender = $null

    try {
        $Defender = Get-MpComputerStatus -ErrorAction Stop
    }
    catch {
        $Reasons += "Windows Defender status is unavailable."
        $HealthScore -= 15
    }

    if ($Defender) {

        $DefenderStatus = if ($Defender.AntivirusEnabled) {
            "OK"
        }
        else {
            $Reasons += "Windows Defender antivirus is disabled."
            $HealthScore -= 25
            "WARNING"
        }

        $RealTimeStatus = if ($Defender.RealTimeProtectionEnabled) {
            "OK"
        }
        else {
            $Reasons += "Real-time protection is disabled."
            $HealthScore -= 20
            "WARNING"
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

        $AntispywareEnabled = [bool]$Defender.AntispywareEnabled
        $BehaviorMonitorEnabled = [bool]$Defender.BehaviorMonitorEnabled
        $IOAVProtectionEnabled = [bool]$Defender.IOAVProtectionEnabled
        $PUAProtection = $Defender.PUAProtection

        if (-not $AntispywareEnabled) {
            $Reasons += "Windows Defender antispyware protection is disabled."
            $HealthScore -= 10
        }

        if (-not $BehaviorMonitorEnabled) {
            $Reasons += "Windows Defender behavior monitoring is disabled."
            $HealthScore -= 10
        }
    }
    else {

        $DefenderStatus = "UNKNOWN"
        $RealTimeStatus = "UNKNOWN"
        $SignatureStatus = "UNKNOWN"

        $SignatureAge = $null
        $AntispywareEnabled = $false
        $BehaviorMonitorEnabled = $false
        $IOAVProtectionEnabled = $false
        $PUAProtection = "UNKNOWN"
    }


    # ============================================================
    # DEFENDER SCAN INFORMATION
    # ============================================================

    $QuickScanStart = $null
    $QuickScanEnd = $null
    $FullScanStart = $null
    $FullScanEnd = $null

    if ($Defender) {

        $QuickScanStart = $Defender.QuickScanStartTime
        $QuickScanEnd = $Defender.QuickScanEndTime

        $FullScanStart = $Defender.FullScanStartTime
        $FullScanEnd = $Defender.FullScanEndTime
    }


    # ============================================================
    # WINDOWS FIREWALL
    # ============================================================

    $FirewallProfiles = @()
    $FirewallProblemCount = 0

    try {

        $FirewallProfiles = Get-NetFirewallProfile -ErrorAction Stop |
            Select-Object `
                Name,
                Enabled,
                DefaultInboundAction,
                DefaultOutboundAction

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

        $Reasons += "Windows Firewall status is unavailable."
        $HealthScore -= 10
        $FirewallProfiles = @()
    }


    # ============================================================
    # UAC
    # ============================================================

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


    # ============================================================
    # SECURE BOOT
    # ============================================================

    $SecureBootEnabled = $null

    try {

        $SecureBootEnabled = Confirm-SecureBootUEFI `
            -ErrorAction Stop

        if (-not $SecureBootEnabled) {
            $Reasons += "Secure Boot is disabled."
            $HealthScore -= 10
        }
    }
    catch {
        $SecureBootEnabled = $null
    }


    # ============================================================
    # TPM
    # ============================================================

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


    # ============================================================
    # BITLOCKER
    # ============================================================

    $BitLockerVolumes = @()
    $BitLockerProblemCount = 0

    try {

        $BitLockerVolumes = Get-BitLockerVolume `
            -ErrorAction Stop |
            Select-Object `
                MountPoint,
                VolumeStatus,
                ProtectionStatus,
                EncryptionMethod

        foreach ($Volume in $BitLockerVolumes) {

            if (
                $Volume.VolumeStatus -eq "FullyDecrypted" -and
                $Volume.MountPoint -eq $env:SystemDrive
            ) {
                $BitLockerProblemCount++

                $Reasons += "System drive BitLocker encryption is disabled."
                $HealthScore -= 10
            }

            if (
                $Volume.VolumeStatus -eq "FullyEncrypted" -and
                $Volume.ProtectionStatus -ne "On" -and
                $Volume.MountPoint -eq $env:SystemDrive
            ) {
                $BitLockerProblemCount++

                $Reasons += "System drive BitLocker protection is suspended."
                $HealthScore -= 10
            }
        }
    }
    catch {

        $BitLockerVolumes = @()
    }


    # ============================================================
    # WINDOWS SECURITY CENTER
    # ============================================================

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


    # ============================================================
    # DEFENDER SERVICE
    # ============================================================

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


    # ============================================================
    # HEALTH SCORE
    # ============================================================

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


    # ============================================================
    # OVERALL STATUS
    # ============================================================

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


    # ============================================================
    # RESULT
    # ============================================================

    [PSCustomObject]@{

        Status                  = $OverallStatus
        HealthScore             = $HealthScore
        HealthStatus            = $HealthStatus
        HealthReasons           = $Reasons

        DefenderStatus          = $DefenderStatus
        DefenderServiceStatus   = $DefenderServiceStatus
        RealTimeProtection      = $RealTimeStatus

        AntispywareEnabled      = $AntispywareEnabled
        BehaviorMonitorEnabled  = $BehaviorMonitorEnabled
        IOAVProtectionEnabled   = $IOAVProtectionEnabled
        PUAProtection           = $PUAProtection

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

        QuickScanStartTime      = $QuickScanStart
        QuickScanEndTime        = $QuickScanEnd

        FullScanStartTime       = $FullScanStart
        FullScanEndTime         = $FullScanEnd

        DefenderEngineVersion   = if ($Defender) {
            $Defender.AMEngineVersion
        }
        else {
            $null
        }

        DefenderPlatformVersion = if ($Defender) {
            $Defender.AMProductVersion
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

        BitLockerVolumes        = $BitLockerVolumes
        BitLockerProblemCount   = $BitLockerProblemCount

        SecurityCenterStatus    = $SecurityCenterStatus
    }
}

Export-ModuleMember -Function `
    Get-REWinSecurityDiagnostics
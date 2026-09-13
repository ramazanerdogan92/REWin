function Get-REWinWindowsUpdateDiagnostics {

    $ServiceNames = @(
        "wuauserv",
        "BITS",
        "UsoSvc",
        "WaaSMedicSvc"
    )

    $ServiceResults = @()

    foreach ($ServiceName in $ServiceNames) {

        $Service = Get-Service `
            -Name $ServiceName `
            -ErrorAction SilentlyContinue

        if ($Service) {

            $ServiceResults += [PSCustomObject]@{
                Name      = $Service.Name
                Status    = $Service.Status
                StartType = $Service.StartType
                Health    = if ($Service.StartType -eq "Disabled") {
                    "WARNING"
                }
                else {
                    "OK"
                }
            }
        }
    }

    # Windows information
    $OS = Get-CimInstance Win32_OperatingSystem

    # Last installed update
    $LastHotfix = $null

    try {
        $LastHotfix = Get-HotFix |
            Sort-Object InstalledOn -Descending |
            Select-Object -First 1
    }
    catch {
        $LastHotfix = $null
    }

    # Pending reboot detection
    $PendingReboot = $false
    $RebootReasons = @()

    $CBSReboot = Test-Path `
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending"

    if ($CBSReboot) {
        $PendingReboot = $true
        $RebootReasons += "CBS"
    }

    $WUReboot = Test-Path `
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"

    if ($WUReboot) {
        $PendingReboot = $true
        $RebootReasons += "WindowsUpdate"
    }

    $SessionManager = Get-ItemProperty `
        "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" `
        -ErrorAction SilentlyContinue

    if ($SessionManager.PendingFileRenameOperations) {
        $PendingReboot = $true
        $RebootReasons += "PendingFileRenameOperations"
    }

    # Disabled update services are a warning.
    # Stopped + Manual is normal and is NOT treated as failure.
    $DisabledServices = $ServiceResults |
        Where-Object {
            $_.StartType -eq "Disabled"
        }

    # Overall status
    if ($DisabledServices) {
        $OverallStatus = "WARNING"
    }
    elseif ($PendingReboot) {
        $OverallStatus = "WARNING"
    }
    else {
        $OverallStatus = "OK"
    }

    [PSCustomObject]@{
        Status               = $OverallStatus
        WindowsVersion       = $OS.Caption
        Build                = $OS.BuildNumber
        PendingReboot        = $PendingReboot
        RebootReasons        = $RebootReasons -join ", "
        DisabledServices     = ($DisabledServices.Name -join ", ")
        ServiceResults       = $ServiceResults
        LastInstalledHotfix  = if ($LastHotfix) {
            $LastHotfix.HotFixID
        }
        else {
            "Unavailable"
        }
        LastUpdateDate       = if ($LastHotfix) {
            $LastHotfix.InstalledOn
        }
        else {
            "Unavailable"
        }
    }
}

Export-ModuleMember -Function Get-REWinWindowsUpdateDiagnostics
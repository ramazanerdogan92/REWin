function Get-REWinDiskDiagnostics {

    $Disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"

    foreach ($Disk in $Disks) {

        $SizeGB = [math]::Round(
            $Disk.Size / 1GB,
            2
        )

        $FreeGB = [math]::Round(
            $Disk.FreeSpace / 1GB,
            2
        )

        if ($Disk.Size -gt 0) {
            $FreePercent = [math]::Round(
                ($Disk.FreeSpace / $Disk.Size) * 100,
                2
            )
        }
        else {
            $FreePercent = 0
        }

        if ($FreePercent -lt 10) {
            $Status = "CRITICAL"
        }
        elseif ($FreePercent -lt 20) {
            $Status = "WARNING"
        }
        else {
            $Status = "OK"
        }

        [PSCustomObject]@{
            Drive       = $Disk.DeviceID
            SizeGB      = $SizeGB
            FreeGB      = $FreeGB
            FreePercent = $FreePercent
            Status      = $Status
        }
    }
}

Export-ModuleMember -Function Get-REWinDiskDiagnostics
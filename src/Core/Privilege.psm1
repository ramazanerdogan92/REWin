function Test-REWinAdministrator {
    $Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $Principal = New-Object Security.Principal.WindowsPrincipal($Identity)

    return $Principal.IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )
}

function Get-REWinPrivilegeStatus {

    $IsAdministrator = Test-REWinAdministrator

    if ($IsAdministrator) {
        return [PSCustomObject]@{
            IsAdministrator = $true
            Status          = "OK"
            Message         = "REWin is running with administrator privileges."
        }
    }

    return [PSCustomObject]@{
        IsAdministrator = $false
        Status          = "WARNING"
        Message         = "REWin must be run as administrator."
    }
}

Export-ModuleMember -Function `
    Test-REWinAdministrator, `
    Get-REWinPrivilegeStatus
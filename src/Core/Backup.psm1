$REWinRoot = Join-Path $env:ProgramData "REWin"
$BackupDirectory = Join-Path $REWinRoot "Backups"

function Initialize-REWinBackup {

    if (-not (Test-Path $BackupDirectory)) {
        New-Item -Path $BackupDirectory -ItemType Directory -Force | Out-Null
    }

    return $BackupDirectory
}

function New-REWinBackup {

    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    Initialize-REWinBackup

    $Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $SafeName = $Name -replace '[^a-zA-Z0-9_-]', '_'

    $BackupPath = Join-Path `
        $BackupDirectory `
        "${Timestamp}_${SafeName}"

    New-Item -Path $BackupPath -ItemType Directory -Force | Out-Null

    return $BackupPath
}

function Get-REWinBackups {

    Initialize-REWinBackup

    Get-ChildItem `
        -Path $BackupDirectory `
        -Directory |
        Sort-Object LastWriteTime -Descending |
        Select-Object Name, LastWriteTime, FullName
}

Export-ModuleMember -Function `
    Initialize-REWinBackup, `
    New-REWinBackup, `
    Get-REWinBackups
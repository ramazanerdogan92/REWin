$REWinRoot = Join-Path $env:ProgramData "REWin"
$LogDirectory = Join-Path $REWinRoot "Logs"

function Initialize-REWinLogging {
    if (-not (Test-Path $LogDirectory)) {
        New-Item -Path $LogDirectory -ItemType Directory -Force | Out-Null
    }

    $script:REWinLogFile = Join-Path $LogDirectory "REWin.log"

    if (-not (Test-Path $script:REWinLogFile)) {
        New-Item -Path $script:REWinLogFile -ItemType File -Force | Out-Null
    }

    Write-REWinLog "REWin logging initialized."
}

function Write-REWinLog {
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [ValidateSet("INFO","WARNING","ERROR","SUCCESS")]
        [string]$Level = "INFO"
    )

    if (-not $script:REWinLogFile) {
        Initialize-REWinLogging
    }

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    $Entry = "[{0}] [{1}] {2}" -f $Timestamp, $Level, $Message

    Add-Content -Path $script:REWinLogFile -Value $Entry -Encoding UTF8
}

Export-ModuleMember -Function `
    Initialize-REWinLogging, `
    Write-REWinLog
#requires -Version 5.1

Set-StrictMode -Version Latest

$ErrorActionPreference = "Continue"

$Script:REWinRepairRoot = Join-Path $env:ProgramData "REWin"
$Script:REWinRepairBackupRoot = Join-Path $Script:REWinRepairRoot "Backups\Repair"

$Script:REWinModuleRoot = Split-Path $PSScriptRoot -Parent
$Script:REWinProjectRoot = Split-Path $Script:REWinModuleRoot -Parent

$Script:REWinHealthReportPath = Join-Path `
    $Script:REWinModuleRoot `
    "Core\HealthReport.psm1"


# ============================================================
# INTERNAL HELPERS
# ============================================================

function Ensure-REWinRepairDirectories {

    try {

        New-Item -ItemType Directory `
            -Path $Script:REWinRepairRoot `
            -Force `
            -ErrorAction SilentlyContinue | Out-Null

        New-Item -ItemType Directory `
            -Path $Script:REWinRepairBackupRoot `
            -Force `
            -ErrorAction SilentlyContinue | Out-Null

        return $true
    }
    catch {

        return $false
    }
}


function Write-REWinRepairLog {

    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    try {

        $logDir = Join-Path `
            $Script:REWinRepairRoot `
            "Logs"

        New-Item -ItemType Directory `
            -Path $logDir `
            -Force `
            -ErrorAction SilentlyContinue | Out-Null

        $logFile = Join-Path `
            $logDir `
            "REWin.log"

        $line = "[{0}] {1}" -f `
            (Get-Date -Format "yyyy-MM-dd HH:mm:ss"),
            $Message

        Add-Content `
            -Path $logFile `
            -Value $line `
            -Encoding UTF8 `
            -ErrorAction SilentlyContinue
    }
    catch {
    }
}


function Convert-REWinRepairNameToFolderName {

    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $safeName = $Name -replace '[\\/:*?"<>|]', '_'
    $safeName = $safeName -replace '\s+', '_'

    return $safeName
}


function Get-REWinSystemRestoreStatus {

    $serviceStatus = "Unknown"
    $restorePointExists = $false
    $reason = ""

    try {

        $vss = Get-Service `
            -Name "VSS" `
            -ErrorAction SilentlyContinue

        if ($null -ne $vss) {

            $serviceStatus = $vss.Status.ToString()
        }
    }
    catch {

        $serviceStatus = "Unknown"
    }

    try {

        $restorePoints = @(
            Get-ComputerRestorePoint `
                -ErrorAction SilentlyContinue
        )

        if ($restorePoints.Count -gt 0) {

            $restorePointExists = $true
        }
    }
    catch {

        $restorePointExists = $false
    }

    if ($restorePointExists) {

        [PSCustomObject]@{
            Status       = "AVAILABLE"
            Reason       = "Existing restore points were found."
            Service      = $serviceStatus
            RestorePoint = $true
        }

        return
    }

    if ($serviceStatus -eq "Running") {

        [PSCustomObject]@{
            Status       = "NOT_AVAILABLE"
            Reason       = "No existing restore points were found."
            Service      = $serviceStatus
            RestorePoint = $false
        }

        return
    }

    [PSCustomObject]@{
        Status       = "NOT_AVAILABLE"
        Reason       = "System Restore service is not running or no restore points were found."
        Service      = $serviceStatus
        RestorePoint = $false
    }
}


function Get-REWinHealthSnapshot {

    try {

        if (-not (Test-Path $Script:REWinHealthReportPath)) {

            return [PSCustomObject]@{
                Available = $false
                Score     = $null
                Status    = "UNAVAILABLE"
                Report    = $null
            }
        }

        Import-Module `
            $Script:REWinHealthReportPath `
            -Force `
            -ErrorAction Stop

        $report = Get-REWinHealthReport

        if ($null -eq $report) {

            return [PSCustomObject]@{
                Available = $false
                Score     = $null
                Status    = "UNAVAILABLE"
                Report    = $null
            }
        }

        return [PSCustomObject]@{
            Available = $true
            Score     = [int]$report.OverallScore
            Status    = [string]$report.OverallStatus
            Report    = $report
        }
    }
    catch {

        Write-REWinRepairLog `
            ("Health snapshot failed: {0}" -f $_.Exception.Message)

        return [PSCustomObject]@{
            Available = $false
            Score     = $null
            Status    = "UNAVAILABLE"
            Report    = $null
        }
    }
}


function Get-REWinHealthComparison {

    param(
        [Parameter(Mandatory = $true)]
        $Before,

        [Parameter(Mandatory = $true)]
        $After
    )

    $beforeScore = $null
    $afterScore = $null
    $delta = $null
    $changed = $false

    if ($Before.Available -and $After.Available) {

        $beforeScore = [int]$Before.Score
        $afterScore = [int]$After.Score

        $delta = $afterScore - $beforeScore

        $changed = ($delta -ne 0)
    }

    [PSCustomObject]@{

        HealthBefore  = $beforeScore
        HealthAfter   = $afterScore
        HealthDelta   = $delta
        HealthChanged = $changed
    }
}


function Get-REWinRepairSummary {

    param(
        [Parameter(Mandatory = $true)]
        [int]$RepairId,

        [Parameter(Mandatory = $true)]
        [bool]$Success,

        [Parameter(Mandatory = $true)]
        $CommandResults
    )

    $firstResult = $CommandResults |
        Select-Object -First 1

    $output = ""

    if ($null -ne $firstResult) {

        $output = [string]$firstResult.Output
    }

    if ($RepairId -eq 1) {

        if ($output -match "did not find any integrity violations") {

            return "SFC completed successfully. No integrity violations were found."
        }

        if ($output -match "found corrupt files and successfully repaired them") {

            return "SFC completed successfully and repaired corrupted files."
        }

        if ($output -match "found corrupt files but was unable to fix some of them") {

            return "SFC completed but some corrupted files could not be repaired."
        }

        if ($Success) {

            return "SFC completed successfully."
        }

        return "SFC failed."
    }


    if ($RepairId -eq 2) {

        if ($Success) {

            return "DISM component store repair completed successfully."
        }

        return "DISM component store repair failed."
    }


    if ($RepairId -eq 3) {

        if ($Success) {

            return "DNS cache was flushed successfully."
        }

        return "DNS cache reset failed."
    }


    if ($RepairId -eq 4) {

        if ($Success) {

            return "Network stack reset completed successfully. A restart may be required."
        }

        return "Network stack reset failed."
    }


    if ($RepairId -eq 5) {

        if ($Success) {

            return "Windows Update services were started successfully."
        }

        return "Windows Update service operation failed."
    }


    return "Repair operation completed."
}


# ============================================================
# REPAIR OPTIONS
# ============================================================

function Get-REWinRepairOptions {

    @(
        [PSCustomObject]@{
            Id          = 1
            Name        = "System File Repair"
            Risk        = "MEDIUM"
            Description = "Windows protected system files are scanned and repaired with SFC."
            Command     = "sfc.exe /scannow"
        }

        [PSCustomObject]@{
            Id          = 2
            Name        = "Component Store Repair"
            Risk        = "MEDIUM"
            Description = "Repairs the Windows component store using DISM RestoreHealth."
            Command     = "DISM.exe /Online /Cleanup-Image /RestoreHealth"
        }

        [PSCustomObject]@{
            Id          = 3
            Name        = "DNS Cache Reset"
            Risk        = "LOW"
            Description = "Flushes the local Windows DNS resolver cache."
            Command     = "ipconfig.exe /flushdns"
        }

        [PSCustomObject]@{
            Id          = 4
            Name        = "Network Stack Reset"
            Risk        = "MEDIUM"
            Description = "Resets Winsock and TCP/IP configuration. Restart may be required."
            Command     = "netsh.exe winsock reset; netsh.exe int ip reset"
        }

        [PSCustomObject]@{
            Id          = 5
            Name        = "Windows Update Services"
            Risk        = "LOW"
            Description = "Ensures core Windows Update services are running."
            Command     = "Start-Service wuauserv,BITS,UsoSvc"
        }
    )
}


# ============================================================
# BACKUP
# ============================================================

function Initialize-REWinRepairBackup {

    param(
        [Parameter(Mandatory = $true)]
        [string]$RepairName
    )

    Ensure-REWinRepairDirectories | Out-Null

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

    $safeName = Convert-REWinRepairNameToFolderName `
        -Name $RepairName

    $backupPath = Join-Path `
        $Script:REWinRepairBackupRoot `
        "${timestamp}_${safeName}"

    New-Item `
        -ItemType Directory `
        -Path $backupPath `
        -Force `
        -ErrorAction Stop | Out-Null

    Write-REWinRepairLog "BACKUP START: $RepairName"
    Write-REWinRepairLog "BACKUP PATH: $backupPath"

    return $backupPath
}


function New-REWinRepairBackup {

    param(
        [Parameter(Mandatory = $true)]
        [string]$RepairName
    )

    $backupPath = $null

    try {

        $backupPath = Initialize-REWinRepairBackup `
            -RepairName $RepairName


        # ----------------------------------------------------
        # Computer information
        # ----------------------------------------------------

        try {

            Get-CimInstance Win32_ComputerSystem |
                Format-List * |
                Out-File `
                    (Join-Path $backupPath "ComputerInfo.txt") `
                    -Encoding UTF8
        }
        catch {
        }


        # ----------------------------------------------------
        # IP configuration
        # ----------------------------------------------------

        try {

            ipconfig.exe /all |
                Out-File `
                    (Join-Path $backupPath "IPConfig.txt") `
                    -Encoding UTF8
        }
        catch {
        }


        # ----------------------------------------------------
        # TCP/IP configuration
        # ----------------------------------------------------

        try {

            Get-NetIPConfiguration |
                Format-List * |
                Out-File `
                    (Join-Path $backupPath "TCPIPConfiguration.txt") `
                    -Encoding UTF8
        }
        catch {
        }


        # ----------------------------------------------------
        # Network interfaces
        # ----------------------------------------------------

        try {

            Get-NetAdapter |
                Format-List * |
                Out-File `
                    (Join-Path $backupPath "NetworkInterfaceDump.txt") `
                    -Encoding UTF8
        }
        catch {
        }


        # ----------------------------------------------------
        # DNS configuration
        # ----------------------------------------------------

        try {

            Get-DnsClientServerAddress |
                Format-List * |
                Out-File `
                    (Join-Path $backupPath "DNSConfiguration.txt") `
                    -Encoding UTF8
        }
        catch {
        }


        # ----------------------------------------------------
        # Services
        # ----------------------------------------------------

        try {

            Get-Service |
                Select-Object Name,DisplayName,Status,StartType |
                Export-Csv `
                    (Join-Path $backupPath "Services.csv") `
                    -NoTypeInformation `
                    -Encoding UTF8
        }
        catch {
        }


        # ----------------------------------------------------
        # Windows Update services
        # ----------------------------------------------------

        try {

            Get-Service `
                -Name wuauserv,BITS,UsoSvc,WaaSMedicSvc `
                -ErrorAction SilentlyContinue |
                Select-Object Name,Status,StartType |
                Export-Csv `
                    (Join-Path $backupPath "WindowsUpdateServices.csv") `
                    -NoTypeInformation `
                    -Encoding UTF8
        }
        catch {
        }


        # ----------------------------------------------------
        # Winsock registry
        # ----------------------------------------------------

        try {

            reg.exe export `
                "HKLM\SYSTEM\CurrentControlSet\Services\WinSock2" `
                (Join-Path $backupPath "Winsock2.reg") `
                /y | Out-Null
        }
        catch {
        }


        try {

            reg.exe export `
                "HKLM\SYSTEM\CurrentControlSet\Services\WinSock" `
                (Join-Path $backupPath "Winsock.reg") `
                /y | Out-Null
        }
        catch {
        }


        # ----------------------------------------------------
        # Winsock catalog
        # ----------------------------------------------------

        try {

            netsh.exe winsock show catalog |
                Out-File `
                    (Join-Path $backupPath "WinsockCatalog.txt") `
                    -Encoding UTF8
        }
        catch {
        }


        # ----------------------------------------------------
        # Restore Point status
        # ----------------------------------------------------

        $restoreStatus = Get-REWinSystemRestoreStatus

        $restoreStatus |
            ConvertTo-Json -Depth 5 |
            Set-Content `
                -Path (Join-Path $backupPath "RestorePointStatus.json") `
                -Encoding UTF8


        # ----------------------------------------------------
        # Metadata
        # ----------------------------------------------------

        $metadata = [PSCustomObject]@{

            RepairName     = $RepairName

            CreatedAt      = Get-Date

            BackupPath     = $backupPath

            ComputerName   = $env:COMPUTERNAME

            UserName       = $env:USERNAME

            RestorePoint   = $restoreStatus.Status

            RestoreReason  = $restoreStatus.Reason

            RestoreService = $restoreStatus.Service

            Tool           = "REWin"

            RepairEngine   = "2.3"
        }


        $metadata |
            ConvertTo-Json -Depth 5 |
            Set-Content `
                -Path (Join-Path $backupPath "BackupMetadata.json") `
                -Encoding UTF8


        Write-REWinRepairLog `
            ("RESTORE POINT STATUS: {0}" -f $restoreStatus.Status)

        Write-REWinRepairLog `
            ("RESTORE POINT REASON: {0}" -f $restoreStatus.Reason)

        Write-REWinRepairLog `
            ("BACKUP COMPLETE: {0}" -f $backupPath)


        [PSCustomObject]@{

            Success       = $true

            BackupPath    = $backupPath

            RestorePoint  = $restoreStatus.Status

            RestoreReason = $restoreStatus.Reason

            CreatedAt     = Get-Date

            RepairName    = $RepairName
        }
    }
    catch {

        Write-REWinRepairLog `
            ("BACKUP ERROR: {0}" -f $_.Exception.Message)


        [PSCustomObject]@{

            Success       = $false

            BackupPath    = $backupPath

            RestorePoint  = "UNKNOWN"

            RestoreReason = $_.Exception.Message

            CreatedAt     = Get-Date

            RepairName    = $RepairName

            Error         = $_.Exception.Message
        }
    }
}


# ============================================================
# RESTORE POINT
# ============================================================

function New-REWinRestorePoint {

    param(
        [Parameter(Mandatory = $true)]
        [string]$Description
    )

    $status = Get-REWinSystemRestoreStatus

    if ($status.Status -ne "AVAILABLE") {

        Write-REWinRepairLog `
            ("Restore point not available: {0}" -f $status.Reason)

        return [PSCustomObject]@{

            Success = $false

            Status  = "NOT_AVAILABLE"

            Reason  = $status.Reason
        }
    }


    try {

        Checkpoint-Computer `
            -Description $Description `
            -RestorePointType "MODIFY_SETTINGS" `
            -ErrorAction Stop


        Write-REWinRepairLog `
            ("Restore point created: {0}" -f $Description)


        return [PSCustomObject]@{

            Success = $true

            Status  = "CREATED"

            Reason  = "Restore point created successfully."
        }
    }
    catch {

        Write-REWinRepairLog `
            ("Restore point creation failed: {0}" -f $_.Exception.Message)


        return [PSCustomObject]@{

            Success = $false

            Status  = "FAILED"

            Reason  = $_.Exception.Message
        }
    }
}


# ============================================================
# COMMAND EXECUTION
# ============================================================

function Invoke-REWinRepairCommand {

    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [string]$Arguments
    )


    $timestamp = Get-Date -Format "yyyyMMdd_HHmmssfff"

    $outputFile = Join-Path `
        $env:TEMP `
        "REWin_Repair_$timestamp.txt"

    $errorFile = Join-Path `
        $env:TEMP `
        "REWin_Repair_Error_$timestamp.txt"


    Write-REWinRepairLog `
        ("COMMAND START: {0} {1}" -f $FilePath,$Arguments)


    try {

        $process = Start-Process `
            -FilePath $FilePath `
            -ArgumentList $Arguments `
            -Wait `
            -PassThru `
            -WindowStyle Hidden `
            -RedirectStandardOutput $outputFile `
            -RedirectStandardError $errorFile `
            -ErrorAction Stop


        $output = ""

        if (Test-Path $outputFile) {

            $output = Get-Content `
                $outputFile `
                -Raw `
                -ErrorAction SilentlyContinue
        }


        $errorOutput = ""

        if (Test-Path $errorFile) {

            $errorOutput = Get-Content `
                $errorFile `
                -Raw `
                -ErrorAction SilentlyContinue
        }


        Write-REWinRepairLog `
            ("COMMAND EXIT CODE: {0}" -f $process.ExitCode)


        [PSCustomObject]@{

            Success    = ($process.ExitCode -eq 0)

            ExitCode   = $process.ExitCode

            Output     = $output

            Error      = $errorOutput

            OutputFile = $outputFile

            FilePath   = $FilePath

            Arguments  = $Arguments
        }
    }
    catch {

        Write-REWinRepairLog `
            ("COMMAND ERROR: {0}" -f $_.Exception.Message)


        [PSCustomObject]@{

            Success    = $false

            ExitCode   = -1

            Output     = ""

            Error      = $_.Exception.Message

            OutputFile = $outputFile

            FilePath   = $FilePath

            Arguments  = $Arguments
        }
    }
}


# ============================================================
# INDIVIDUAL REPAIR FUNCTIONS
# ============================================================

function Repair-REWinSystemFiles {

    return Invoke-REWinRepairCommand `
        -FilePath "sfc.exe" `
        -Arguments "/scannow"
}


function Repair-REWinComponentStore {

    return Invoke-REWinRepairCommand `
        -FilePath "DISM.exe" `
        -Arguments "/Online /Cleanup-Image /RestoreHealth"
}


function Repair-REWinDNSCache {

    return Invoke-REWinRepairCommand `
        -FilePath "ipconfig.exe" `
        -Arguments "/flushdns"
}


function Repair-REWinNetworkStack {

    $results = @()


    $winsock = Invoke-REWinRepairCommand `
        -FilePath "netsh.exe" `
        -Arguments "winsock reset"

    $results += $winsock


    $tcpip = Invoke-REWinRepairCommand `
        -FilePath "netsh.exe" `
        -Arguments "int ip reset"

    $results += $tcpip


    return $results
}


function Repair-REWinWindowsUpdateServices {

    $results = @()


    $services = @(
        "wuauserv",
        "BITS",
        "UsoSvc"
    )


    foreach ($serviceName in $services) {

        try {

            $service = Get-Service `
                -Name $serviceName `
                -ErrorAction Stop


            if ($service.Status -ne "Running") {

                Start-Service `
                    -Name $serviceName `
                    -ErrorAction Stop


                Write-REWinRepairLog `
                    ("SERVICE STARTED: {0}" -f $serviceName)


                $results += [PSCustomObject]@{

                    Success   = $true

                    ExitCode  = 0

                    Output    = "Service started: $serviceName"

                    Error     = ""

                    FilePath  = "Start-Service"

                    Arguments = $serviceName
                }
            }
            else {

                $results += [PSCustomObject]@{

                    Success   = $true

                    ExitCode  = 0

                    Output    = "Service already running: $serviceName"

                    Error     = ""

                    FilePath  = "Start-Service"

                    Arguments = $serviceName
                }
            }
        }
        catch {

            Write-REWinRepairLog `
                ("SERVICE ERROR: {0} - {1}" -f $serviceName,$_.Exception.Message)


            $results += [PSCustomObject]@{

                Success   = $false

                ExitCode  = -1

                Output    = ""

                Error     = $_.Exception.Message

                FilePath  = "Start-Service"

                Arguments = $serviceName
            }
        }
    }


    return $results
}


# ============================================================
# REPAIR HEALTH TEST
# ============================================================

function Test-REWinRepairHealth {

    $health = Get-REWinHealthSnapshot


    return [PSCustomObject]@{

        Available = $health.Available

        Score     = $health.Score

        Status    = $health.Status

        Report    = $health.Report
    }
}


# ============================================================
# MAIN REPAIR ENGINE
# ============================================================

function Invoke-REWinRepair {

    param(
        [Parameter(Mandatory = $true)]
        [ValidateRange(1,5)]
        [int]$Id
    )


    $options = Get-REWinRepairOptions


    $repair = $options |
        Where-Object {
            $_.Id -eq $Id
        } |
        Select-Object -First 1


    if ($null -eq $repair) {

        throw "Invalid REWin repair ID: $Id"
    }


    Write-REWinRepairLog `
        ("REPAIR START: [{0}] {1}" -f $repair.Id,$repair.Name)


    # --------------------------------------------------------
    # BEFORE HEALTH
    # --------------------------------------------------------

    Write-REWinRepairLog "BEFORE HEALTH START"

    $beforeHealth = Get-REWinHealthSnapshot

    Write-REWinRepairLog `
        ("BEFORE HEALTH COMPLETE: Available={0}; Score={1}; Status={2}" -f `
            $beforeHealth.Available,
            $beforeHealth.Score,
            $beforeHealth.Status)


    # --------------------------------------------------------
    # BACKUP
    # --------------------------------------------------------

    $backup = New-REWinRepairBackup `
        -RepairName $repair.Name


    if (-not $backup.Success) {

        Write-REWinRepairLog `
            "REPAIR ABORTED: Backup failed."


        return [PSCustomObject]@{

            Success         = $false

            RepairId        = $repair.Id

            RepairName      = $repair.Name

            Risk            = $repair.Risk

            RepairStatus    = "BACKUP_FAILED"

            RepairSummary   = "Repair was not executed because backup creation failed."

            BackupPath      = $backup.BackupPath

            RestorePoint    = $backup.RestorePoint

            RestoreReason   = $backup.RestoreReason

            BeforeHealth    = $beforeHealth

            AfterHealth     = $beforeHealth

            HealthBefore    = $beforeHealth.Score

            HealthAfter     = $beforeHealth.Score

            HealthDelta     = 0

            HealthChanged   = $false

            CommandResults  = @()

            CompletedAt     = Get-Date
        }
    }


    # --------------------------------------------------------
    # RESTORE POINT
    # --------------------------------------------------------

    Write-REWinRepairLog "RESTORE POINT CHECK START"

    $restorePoint = New-REWinRestorePoint `
        -Description "REWin - $($repair.Name)"

    Write-REWinRepairLog `
        ("RESTORE POINT CHECK COMPLETE: {0}" -f $restorePoint.Status)


    # --------------------------------------------------------
    # EXECUTE REPAIR
    # --------------------------------------------------------

    Write-REWinRepairLog "REPAIR COMMAND EXECUTION START"

    $commandResults = @()


    switch ($Id) {

        1 {

            $commandResults = @(
                Repair-REWinSystemFiles
            )
        }


        2 {

            $commandResults = @(
                Repair-REWinComponentStore
            )
        }


        3 {

            $commandResults = @(
                Repair-REWinDNSCache
            )
        }


        4 {

            $commandResults = @(
                Repair-REWinNetworkStack
            )
        }


        5 {

            $commandResults = @(
                Repair-REWinWindowsUpdateServices
            )
        }
    }


    Write-REWinRepairLog "REPAIR COMMAND EXECUTION COMPLETE"


    $allCommandsSuccessful = $true


    foreach ($commandResult in $commandResults) {

        if (-not $commandResult.Success) {

            $allCommandsSuccessful = $false
        }
    }


    # --------------------------------------------------------
    # AFTER HEALTH
    # --------------------------------------------------------

    Write-REWinRepairLog "AFTER HEALTH START"

    $afterHealth = Get-REWinHealthSnapshot

    Write-REWinRepairLog `
        ("AFTER HEALTH COMPLETE: Available={0}; Score={1}; Status={2}" -f `
            $afterHealth.Available,
            $afterHealth.Score,
            $afterHealth.Status)


    # --------------------------------------------------------
    # HEALTH COMPARISON
    # --------------------------------------------------------

    Write-REWinRepairLog "HEALTH COMPARISON START"

    $healthComparison = Get-REWinHealthComparison `
        -Before $beforeHealth `
        -After $afterHealth

    Write-REWinRepairLog `
        ("HEALTH COMPARISON COMPLETE: Before={0}; After={1}; Delta={2}" -f `
            $healthComparison.HealthBefore,
            $healthComparison.HealthAfter,
            $healthComparison.HealthDelta)


    # --------------------------------------------------------
    # SUMMARY
    # --------------------------------------------------------

    $summary = Get-REWinRepairSummary `
        -RepairId $Id `
        -Success $allCommandsSuccessful `
        -CommandResults $commandResults


    $repairStatus = "SUCCESS"


    if (-not $allCommandsSuccessful) {

        $repairStatus = "FAILED"
    }


    # --------------------------------------------------------
    # RESULT
    # --------------------------------------------------------

    $result = [PSCustomObject]@{

        Success          = $allCommandsSuccessful

        RepairId         = $repair.Id

        RepairName       = $repair.Name

        Risk             = $repair.Risk

        RepairStatus     = $repairStatus

        RepairSummary    = $summary

        BackupPath       = $backup.BackupPath

        BackupStatus     = if ($backup.Success) {
            "CREATED"
        }
        else {
            "FAILED"
        }

        RestorePoint     = $backup.RestorePoint

        RestoreReason    = $backup.RestoreReason

        CreatedAt        = $backup.CreatedAt

        BeforeHealth     = $beforeHealth

        AfterHealth      = $afterHealth

        HealthBefore     = $healthComparison.HealthBefore

        HealthAfter      = $healthComparison.HealthAfter

        HealthDelta      = $healthComparison.HealthDelta

        HealthChanged    = $healthComparison.HealthChanged

        CommandResults   = $commandResults

        RestoreOperation = $restorePoint

        CompletedAt      = Get-Date
    }


    # ========================================================
    # SAVE RESULT
    # ========================================================

    Write-REWinRepairLog "RESULT FILE WRITE START"


    try {

        # ----------------------------------------------------
        # COMPACT RESULT
        # ----------------------------------------------------
        # The complete HealthReport contains many nested
        # objects. Do not serialize the full health report.
        # Save only the useful repair information.

        $resultForFile = [PSCustomObject]@{

            Success       = $result.Success

            RepairId      = $result.RepairId

            RepairName    = $result.RepairName

            Risk          = $result.Risk

            RepairStatus  = $result.RepairStatus

            RepairSummary = $result.RepairSummary

            BackupPath    = $result.BackupPath

            BackupStatus  = $result.BackupStatus

            RestorePoint  = $result.RestorePoint

            RestoreReason = $result.RestoreReason

            CreatedAt     = $result.CreatedAt

            HealthBefore  = $result.HealthBefore

            HealthAfter   = $result.HealthAfter

            HealthDelta   = $result.HealthDelta

            HealthChanged = $result.HealthChanged

            CommandResults = @(
                $result.CommandResults |
                    ForEach-Object {

                        [PSCustomObject]@{

                            Success   = $_.Success

                            ExitCode  = $_.ExitCode

                            FilePath  = $_.FilePath

                            Arguments = $_.Arguments

                            Output    = $_.Output

                            Error     = $_.Error
                        }
                    }
            )

            CompletedAt = $result.CompletedAt
        }


        $resultForFile |
            ConvertTo-Json -Depth 6 |
            Set-Content `
                -Path (Join-Path $backup.BackupPath "RepairResult.json") `
                -Encoding UTF8 `
                -ErrorAction Stop


        Write-REWinRepairLog "RESULT FILE WRITE COMPLETE"
    }
    catch {

        Write-REWinRepairLog `
            ("RESULT FILE WRITE ERROR: {0}" -f $_.Exception.Message)
    }


    # ========================================================
    # FINAL LOG
    # ========================================================

    Write-REWinRepairLog `
        ("REPAIR STATUS: {0}" -f $repairStatus)


    Write-REWinRepairLog `
        ("HEALTH BEFORE: {0}" -f $healthComparison.HealthBefore)


    Write-REWinRepairLog `
        ("HEALTH AFTER: {0}" -f $healthComparison.HealthAfter)


    Write-REWinRepairLog `
        ("HEALTH DELTA: {0}" -f $healthComparison.HealthDelta)


    Write-REWinRepairLog `
        ("REPAIR COMPLETE: {0}" -f $repair.Name)


    return $result
}


# ============================================================
# EXPORTS
# ============================================================

Export-ModuleMember -Function `
    Initialize-REWinRepairBackup, `
    New-REWinRepairBackup, `
    New-REWinRestorePoint, `
    Invoke-REWinRepairCommand, `
    Repair-REWinSystemFiles, `
    Repair-REWinComponentStore, `
    Repair-REWinDNSCache, `
    Repair-REWinNetworkStack, `
    Repair-REWinWindowsUpdateServices, `
    Get-REWinRepairOptions, `
    Get-REWinSystemRestoreStatus, `
    Test-REWinRepairHealth, `
    Invoke-REWinRepair
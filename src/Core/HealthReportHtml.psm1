function Export-REWinHealthReport {

    param(
        [Parameter(Mandatory)]
        $Report,

        [Parameter(Mandatory)]
        [string]$Path
    )

    # ============================================================
    # HELPERS
    # ============================================================

    function Get-StatusClass {
        param([string]$Status)

        switch ($Status) {
            "CRITICAL"  { return "critical" }
            "WARNING"   { return "warning" }
            "GOOD"      { return "good" }
            "EXCELLENT" { return "excellent" }
            "OK"        { return "excellent" }
            default     { return "neutral" }
        }
    }

    function Get-ScoreClass {
        param([int]$Score)

        if ($Score -ge 90) {
            return "excellent"
        }
        elseif ($Score -ge 75) {
            return "good"
        }
        elseif ($Score -ge 50) {
            return "warning"
        }
        else {
            return "critical"
        }
    }

    function Encode-Html {
        param([object]$Value)

        if ($null -eq $Value) {
            return ""
        }

        return [System.Net.WebUtility]::HtmlEncode(
            [string]$Value
        )
    }


    # ============================================================
    # PREPARE DATA
    # ============================================================

    $GeneratedAt = Encode-Html $Report.GeneratedAt
    $OverallScore = [int]$Report.OverallScore
    $OverallStatus = Encode-Html $Report.OverallStatus
    $Summary = Encode-Html $Report.Summary

    $StatusClass = Get-StatusClass $Report.OverallStatus

    $AttentionText = if ($Report.AttentionRequired) {
        "ATTENTION REQUIRED"
    }
    else {
        "NO ATTENTION REQUIRED"
    }

    $AttentionClass = if ($Report.AttentionRequired) {
        "warning"
    }
    else {
        "excellent"
    }


    # ============================================================
    # MODULE SCORE ROWS
    # ============================================================

    $ModuleRows = ""

    $ModuleNames = @(
        "System",
        "Disk",
        "Network",
        "WindowsUpdate",
        "EventLog",
        "Crash",
        "Hardware",
        "Security"
    )

    foreach ($ModuleName in $ModuleNames) {

        $Score = [int]$Report.ModuleScores.$ModuleName
        $Class = Get-ScoreClass $Score

        $DisplayName = switch ($ModuleName) {
            "WindowsUpdate" { "Windows Update" }
            "EventLog"      { "Event Log" }
            default         { $ModuleName }
        }

        $ModuleRows += @"
<tr>
    <td>$DisplayName</td>
    <td>
        <div class="score-row">
            <div class="bar">
                <div class="bar-fill $Class" style="width:${Score}%"></div>
            </div>
            <span class="score-value $Class">$Score</span>
        </div>
    </td>
</tr>
"@
    }


    # ============================================================
    # RECOMMENDATIONS
    # ============================================================

    $RecommendationRows = ""

    foreach ($Recommendation in $Report.Recommendations) {

        $Severity = Encode-Html $Recommendation.Severity
        $Area = Encode-Html $Recommendation.Area
        $Message = Encode-Html $Recommendation.Message

        $Class = Get-StatusClass $Recommendation.Severity

        $RecommendationRows += @"
<tr>
    <td>
        <span class="badge $Class">$Severity</span>
    </td>
    <td>$Area</td>
    <td>$Message</td>
</tr>
"@
    }

    if ([string]::IsNullOrWhiteSpace($RecommendationRows)) {

        $RecommendationRows = @"
<tr>
    <td colspan="3" class="empty">
        No issues detected.
    </td>
</tr>
"@
    }


    # ============================================================
    # SYSTEM INFORMATION
    # ============================================================

    $System = $Report.System

    $ComputerName = Encode-Html $System.ComputerName
    $OperatingSystem = Encode-Html $System.OperatingSystem
    $Build = Encode-Html $System.Build
    $Manufacturer = Encode-Html $System.Manufacturer
    $Model = Encode-Html $System.Model
    $CPU = Encode-Html $System.CPU
    $RAM = Encode-Html "$($System.RAM_GB) GB"
    $Architecture = Encode-Html $System.Architecture
    $Uptime = Encode-Html "$($System.UptimeDays) days"


    # ============================================================
    # HTML
    # ============================================================

    $Html = @"
<!DOCTYPE html>
<html lang="en">
<head>

<meta charset="UTF-8">

<meta name="viewport"
      content="width=device-width, initial-scale=1.0">

<title>REWin Health Report</title>

<style>

* {
    box-sizing: border-box;
}

body {
    margin: 0;
    padding: 30px;
    font-family:
        -apple-system,
        BlinkMacSystemFont,
        "Segoe UI",
        Arial,
        sans-serif;

    background: #f4f6f8;
    color: #1f2937;
}

.container {
    max-width: 1100px;
    margin: auto;
}

.header {
    background: #111827;
    color: white;
    padding: 28px;
    border-radius: 14px;
    margin-bottom: 20px;
}

.header h1 {
    margin: 0 0 8px 0;
    font-size: 30px;
}

.header p {
    margin: 4px 0;
    color: #d1d5db;
}

.card {
    background: white;
    border-radius: 14px;
    padding: 24px;
    margin-bottom: 20px;

    box-shadow:
        0 2px 8px rgba(0,0,0,0.06);
}

.health-card {
    display: grid;
    grid-template-columns: 220px 1fr;
    gap: 30px;
    align-items: center;
}

.score-circle {
    width: 180px;
    height: 180px;
    border-radius: 50%;

    display: flex;
    align-items: center;
    justify-content: center;

    margin: auto;

    border: 12px solid #e5e7eb;
}

.score-number {
    font-size: 42px;
    font-weight: 700;
}

.score-label {
    text-align: center;
    margin-top: 8px;
    font-weight: 600;
}

.excellent {
    color: #15803d;
}

.good {
    color: #2563eb;
}

.warning {
    color: #b45309;
}

.critical {
    color: #b91c1c;
}

.neutral {
    color: #6b7280;
}

.attention {
    display: inline-block;
    margin-top: 12px;

    padding: 7px 12px;

    border-radius: 20px;

    font-size: 13px;
    font-weight: 700;

    background: #fff7ed;
}

table {
    width: 100%;
    border-collapse: collapse;
}

th {
    text-align: left;
    background: #f9fafb;
    font-size: 13px;
}

th,
td {
    padding: 13px 12px;
    border-bottom: 1px solid #e5e7eb;
}

.score-row {
    display: flex;
    align-items: center;
    gap: 12px;
}

.bar {
    flex: 1;
    height: 10px;
    background: #e5e7eb;
    border-radius: 10px;
    overflow: hidden;
}

.bar-fill {
    height: 100%;
    border-radius: 10px;
}

.bar-fill.excellent {
    background: #22c55e;
}

.bar-fill.good {
    background: #3b82f6;
}

.bar-fill.warning {
    background: #f59e0b;
}

.bar-fill.critical {
    background: #ef4444;
}

.score-value {
    width: 35px;
    text-align: right;
    font-weight: 700;
}

.badge {
    display: inline-block;

    padding: 5px 9px;

    border-radius: 6px;

    font-size: 11px;
    font-weight: 700;
}

.badge.warning {
    background: #fef3c7;
}

.badge.critical {
    background: #fee2e2;
}

.badge.excellent {
    background: #dcfce7;
}

.info-grid {
    display: grid;
    grid-template-columns:
        repeat(auto-fit, minmax(220px, 1fr));

    gap: 12px;
}

.info-item {
    background: #f9fafb;
    padding: 14px;
    border-radius: 8px;
}

.info-label {
    font-size: 12px;
    color: #6b7280;
}

.info-value {
    margin-top: 4px;
    font-weight: 600;
}

.empty {
    text-align: center;
    padding: 25px;
    color: #15803d;
}

.footer {
    text-align: center;
    color: #6b7280;
    font-size: 12px;
    padding: 15px;
}

@media (max-width: 700px) {

    body {
        padding: 15px;
    }

    .health-card {
        grid-template-columns: 1fr;
    }
}

</style>

</head>

<body>

<div class="container">

    <div class="header">

        <h1>REWin Health Report</h1>

        <p>
            Windows IT Diagnostics & Health Assessment
        </p>

        <p>
            Generated: $GeneratedAt
        </p>

    </div>


    <!-- HEALTH SUMMARY -->

    <div class="card health-card">

        <div>

            <div class="score-circle">

                <span class="score-number $StatusClass">
                    $OverallScore
                </span>

            </div>

            <div class="score-label">
                / 100
            </div>

        </div>

        <div>

            <h2 class="$StatusClass">
                $OverallStatus
            </h2>

            <p>
                $Summary
            </p>

            <div class="attention $AttentionClass">
                $AttentionText
            </div>

            <p>
                <strong>Issues:</strong>
                $($Report.IssueCount)
                &nbsp;&nbsp;

                <strong>Critical:</strong>
                $($Report.CriticalCount)
                &nbsp;&nbsp;

                <strong>Warnings:</strong>
                $($Report.WarningCount)
            </p>

        </div>

    </div>


    <!-- MODULE SCORES -->

    <div class="card">

        <h2>Module Health</h2>

        <table>

            <thead>
                <tr>
                    <th>Module</th>
                    <th>Health Score</th>
                </tr>
            </thead>

            <tbody>

                $ModuleRows

            </tbody>

        </table>

    </div>


    <!-- RECOMMENDATIONS -->

    <div class="card">

        <h2>Recommendations</h2>

        <table>

            <thead>

                <tr>
                    <th>Severity</th>
                    <th>Area</th>
                    <th>Message</th>
                </tr>

            </thead>

            <tbody>

                $RecommendationRows

            </tbody>

        </table>

    </div>


    <!-- SYSTEM INFORMATION -->

    <div class="card">

        <h2>System Information</h2>

        <div class="info-grid">

            <div class="info-item">
                <div class="info-label">Computer</div>
                <div class="info-value">$ComputerName</div>
            </div>

            <div class="info-item">
                <div class="info-label">Manufacturer</div>
                <div class="info-value">$Manufacturer</div>
            </div>

            <div class="info-item">
                <div class="info-label">Model</div>
                <div class="info-value">$Model</div>
            </div>

            <div class="info-item">
                <div class="info-label">Operating System</div>
                <div class="info-value">$OperatingSystem</div>
            </div>

            <div class="info-item">
                <div class="info-label">Build</div>
                <div class="info-value">$Build</div>
            </div>

            <div class="info-item">
                <div class="info-label">CPU</div>
                <div class="info-value">$CPU</div>
            </div>

            <div class="info-item">
                <div class="info-label">Memory</div>
                <div class="info-value">$RAM</div>
            </div>

            <div class="info-item">
                <div class="info-label">Architecture</div>
                <div class="info-value">$Architecture</div>
            </div>

            <div class="info-item">
                <div class="info-label">Uptime</div>
                <div class="info-value">$Uptime</div>
            </div>

        </div>

    </div>


    <div class="footer">
        Generated by REWin
    </div>

</div>

</body>
</html>
"@


    # ============================================================
    # WRITE FILE
    # ============================================================

    $Directory = Split-Path -Parent $Path

    if ($Directory -and -not (Test-Path $Directory)) {

        New-Item `
            -Path $Directory `
            -ItemType Directory `
            -Force |
            Out-Null
    }

    Set-Content `
        -Path $Path `
        -Value $Html `
        -Encoding UTF8

    return $Path
}

Export-ModuleMember -Function `
    Export-REWinHealthReport
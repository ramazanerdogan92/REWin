function Export-REWinHealthReport {

    param(
        [Parameter(Mandatory)]
        $Report,

        [Parameter(Mandatory)]
        [string]$Path,

        [ValidateSet("EN", "TR")]
        [string]$Language = "EN"
    )

    # ============================================================
    # HTML ENCODING
    # ============================================================

    function Encode-Html {
        param(
            [object]$Value
        )

        if ($null -eq $Value) {
            return ""
        }

        return [System.Net.WebUtility]::HtmlEncode(
            [string]$Value
        )
    }


    # ============================================================
    # SCORE CLASS
    # ============================================================

    function Get-ScoreClass {
        param(
            [int]$Score
        )

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


    # ============================================================
    # SCORE LABEL
    # ============================================================

    function Get-ScoreLabel {
        param(
            [int]$Score
        )

        if ($Score -ge 90) {
            return "OK"
        }
        elseif ($Score -ge 75) {
            return "GOOD"
        }
        elseif ($Score -ge 50) {
            return "WARN"
        }
        else {
            return "CRIT"
        }
    }


    # ============================================================
    # LANGUAGE
    # ============================================================

    if ($Language -eq "TR") {

        $Title = "REWin Saglik Raporu"
        $Subtitle = "Windows IT Tani ve Saglik Degerlendirmesi"

        $AttentionRequiredText = "DIKKAT GEREKLI"
        $NoAttentionText = "DIKKAT GEREKMIYOR"

        $ModuleHealthText = "Modul Sagligi"
        $IssuesText = "Sorunlar ve Oneriler"
        $SystemInfoText = "Sistem Bilgileri"

        $IssueText = "Sorun"
        $CriticalText = "Kritik"
        $WarningText = "Uyari"

        $ComputerText = "Bilgisayar"
        $ManufacturerText = "Uretici"
        $ModelText = "Model"
        $OSText = "Isletim Sistemi"
        $BuildText = "Build"
        $CPUText = "CPU"
        $MemoryText = "Bellek"
        $ArchitectureText = "Mimari"
        $UptimeText = "Calisma Suresi"
        $GeneratedText = "Olusturulma"

        $ModuleNames = @{
            System        = "Sistem"
            Disk          = "Disk"
            Network       = "Ag"
            WindowsUpdate = "Windows Update"
            EventLog      = "Event Log"
            Crash         = "Crash"
            Hardware      = "Donanim"
            Security      = "Guvenlik"
        }
    }
    else {

        $Title = "REWin Health Report"
        $Subtitle = "Windows IT Diagnostics and Health Assessment"

        $AttentionRequiredText = "ATTENTION REQUIRED"
        $NoAttentionText = "NO ATTENTION REQUIRED"

        $ModuleHealthText = "Module Health"
        $IssuesText = "Issues and Recommendations"
        $SystemInfoText = "System Information"

        $IssueText = "Issues"
        $CriticalText = "Critical"
        $WarningText = "Warnings"

        $ComputerText = "Computer"
        $ManufacturerText = "Manufacturer"
        $ModelText = "Model"
        $OSText = "Operating System"
        $BuildText = "Build"
        $CPUText = "CPU"
        $MemoryText = "Memory"
        $ArchitectureText = "Architecture"
        $UptimeText = "Uptime"
        $GeneratedText = "Generated"

        $ModuleNames = @{
            System        = "System"
            Disk          = "Disk"
            Network       = "Network"
            WindowsUpdate = "Windows Update"
            EventLog      = "Event Log"
            Crash         = "Crash"
            Hardware      = "Hardware"
            Security      = "Security"
        }
    }


    # ============================================================
    # GENERAL DATA
    # ============================================================

    $OverallScore = [int]$Report.OverallScore

    $OverallStatus = Encode-Html $Report.OverallStatus
    $Summary = Encode-Html $Report.Summary
    $GeneratedAt = Encode-Html $Report.GeneratedAt

    $OverallClass = Get-ScoreClass $OverallScore


    if ($Report.AttentionRequired) {
        $AttentionText = $AttentionRequiredText
        $AttentionClass = "warning"
    }
    else {
        $AttentionText = $NoAttentionText
        $AttentionClass = "excellent"
    }


    # ============================================================
    # MODULE CARDS
    # ============================================================

    $ModuleCards = ""

    $ModuleList = @(
        "System",
        "Disk",
        "Network",
        "WindowsUpdate",
        "EventLog",
        "Crash",
        "Hardware",
        "Security"
    )

    foreach ($ModuleName in $ModuleList) {

        $Score = [int]$Report.ModuleScores.$ModuleName

        $Class = Get-ScoreClass $Score
        $Label = Get-ScoreLabel $Score

        $DisplayName = Encode-Html $ModuleNames[$ModuleName]

        $ModuleCards += @"
<div class="module-card">

    <div class="module-header">

        <span class="module-name">
            $DisplayName
        </span>

        <span class="module-label $Class">
            $Label
        </span>

    </div>

    <div class="module-score $Class">
        $Score
    </div>

    <div class="module-bar">

        <div
            class="module-bar-fill $Class"
            style="width: ${Score}%">
        </div>

    </div>

</div>
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

        if ($Recommendation.Severity -eq "CRITICAL") {
            $SeverityClass = "critical"
        }
        elseif ($Recommendation.Severity -eq "WARNING") {
            $SeverityClass = "warning"
        }
        else {
            $SeverityClass = "good"
        }

        $RecommendationRows += @"
<div class="issue-item">

    <div class="issue-line $SeverityClass"></div>

    <div class="issue-content">

        <div class="issue-header">

            <span class="severity $SeverityClass">
                $Severity
            </span>

            <span class="issue-area">
                $Area
            </span>

        </div>

        <div class="issue-message">
            $Message
        </div>

    </div>

</div>
"@
    }


    if ([string]::IsNullOrWhiteSpace($RecommendationRows)) {

        $RecommendationRows = @"
<div class="empty-message">
    OK - No issues detected.
</div>
"@
    }


    # ============================================================
    # SYSTEM INFORMATION
    # ============================================================

    $System = $Report.System

    $ComputerName = Encode-Html $System.ComputerName
    $Manufacturer = Encode-Html $System.Manufacturer
    $Model = Encode-Html $System.Model
    $OperatingSystem = Encode-Html $System.OperatingSystem
    $Build = Encode-Html $System.Build
    $CPU = Encode-Html $System.CPU
    $RAM = Encode-Html "$($System.RAM_GB) GB"
    $Architecture = Encode-Html $System.Architecture
    $Uptime = Encode-Html "$($System.UptimeDays) days"


    # ============================================================
    # HTML
    # ============================================================

    $Html = @"
<!DOCTYPE html>

<html lang="$Language">

<head>

<meta charset="UTF-8">

<meta name="viewport"
      content="width=device-width, initial-scale=1.0">

<title>$Title</title>

<style>

* {
    box-sizing: border-box;
}

body {
    margin: 0;
    padding: 30px;

    font-family:
        "Segoe UI",
        Arial,
        sans-serif;

    background: #f3f4f6;

    color: #111827;
}

.container {
    max-width: 1200px;

    margin: auto;
}


/* ============================================================
   HEADER
   ============================================================ */

.header {

    background: #111827;

    color: white;

    padding: 30px;

    border-radius: 16px;

    margin-bottom: 22px;

    box-shadow:
        0 8px 25px rgba(0, 0, 0, 0.08);
}

.brand {

    display: flex;

    align-items: center;

    gap: 15px;
}

.logo {

    width: 52px;

    height: 52px;

    border-radius: 12px;

    display: flex;

    align-items: center;

    justify-content: center;

    background: #2563eb;

    font-size: 20px;

    font-weight: 800;
}

.header h1 {

    margin: 0;

    font-size: 30px;
}

.header p {

    margin: 5px 0 0;

    color: #d1d5db;
}

.generated {

    margin-top: 20px;

    color: #9ca3af;

    font-size: 13px;
}


/* ============================================================
   SUMMARY
   ============================================================ */

.summary {

    display: grid;

    grid-template-columns: 260px 1fr;

    gap: 30px;

    background: white;

    padding: 30px;

    border-radius: 16px;

    margin-bottom: 22px;

    box-shadow:
        0 4px 15px rgba(0, 0, 0, 0.05);
}

.score-box {

    text-align: center;
}

.score-circle {

    width: 190px;

    height: 190px;

    margin: auto;

    border-radius: 50%;

    display: flex;

    align-items: center;

    justify-content: center;

    border: 12px solid #e5e7eb;
}

.score-number {

    font-size: 48px;

    font-weight: 800;
}

.score-total {

    margin-top: 8px;

    font-size: 14px;

    color: #6b7280;
}

.summary-content {

    display: flex;

    flex-direction: column;

    justify-content: center;
}

.summary-content h2 {

    margin: 0 0 10px;

    font-size: 28px;
}

.summary-text {

    color: #6b7280;

    margin-bottom: 18px;
}

.attention {

    display: inline-block;

    width: fit-content;

    padding: 8px 14px;

    border-radius: 20px;

    font-size: 12px;

    font-weight: 800;
}

.attention.warning {

    background: #fff7ed;

    color: #c2410c;
}

.attention.excellent {

    background: #dcfce7;

    color: #15803d;
}

.counters {

    display: flex;

    gap: 30px;

    margin-top: 20px;
}

.counter strong {

    display: block;

    font-size: 22px;
}

.counter span {

    font-size: 12px;

    color: #6b7280;
}


/* ============================================================
   COLORS
   ============================================================ */

.excellent {

    color: #15803d;
}

.good {

    color: #2563eb;
}

.warning {

    color: #c2410c;
}

.critical {

    color: #b91c1c;
}


/* ============================================================
   SECTION
   ============================================================ */

.section {

    background: white;

    padding: 26px;

    border-radius: 16px;

    margin-bottom: 22px;

    box-shadow:
        0 4px 15px rgba(0, 0, 0, 0.05);
}

.section h2 {

    margin-top: 0;

    font-size: 21px;
}


/* ============================================================
   MODULE CARDS
   ============================================================ */

.module-grid {

    display: grid;

    grid-template-columns:
        repeat(4, 1fr);

    gap: 14px;
}

.module-card {

    border: 1px solid #e5e7eb;

    border-radius: 12px;

    padding: 18px;

    background: #fafafa;
}

.module-header {

    display: flex;

    justify-content: space-between;

    align-items: center;
}

.module-name {

    font-size: 14px;

    font-weight: 700;
}

.module-label {

    padding: 4px 7px;

    border-radius: 5px;

    font-size: 9px;

    font-weight: 800;
}

.module-score {

    margin-top: 15px;

    font-size: 34px;

    font-weight: 800;
}

.module-bar {

    height: 7px;

    margin-top: 10px;

    background: #e5e7eb;

    border-radius: 10px;

    overflow: hidden;
}

.module-bar-fill {

    height: 100%;

    border-radius: 10px;
}

.module-bar-fill.excellent {

    background: #22c55e;
}

.module-bar-fill.good {

    background: #3b82f6;
}

.module-bar-fill.warning {

    background: #f59e0b;
}

.module-bar-fill.critical {

    background: #ef4444;
}

.module-label.excellent {

    background: #dcfce7;
}

.module-label.good {

    background: #dbeafe;
}

.module-label.warning {

    background: #fef3c7;
}

.module-label.critical {

    background: #fee2e2;
}


/* ============================================================
   ISSUES
   ============================================================ */

.issue-item {

    display: flex;

    gap: 15px;

    padding: 16px 0;

    border-bottom: 1px solid #e5e7eb;
}

.issue-item:last-child {

    border-bottom: none;
}

.issue-line {

    width: 5px;

    border-radius: 5px;

    flex-shrink: 0;
}

.issue-line.warning {

    background: #f59e0b;
}

.issue-line.critical {

    background: #ef4444;
}

.issue-content {

    flex: 1;
}

.issue-header {

    display: flex;

    align-items: center;

    gap: 10px;

    margin-bottom: 6px;
}

.severity {

    padding: 4px 8px;

    border-radius: 5px;

    font-size: 10px;

    font-weight: 800;
}

.severity.warning {

    background: #fef3c7;
}

.severity.critical {

    background: #fee2e2;
}

.issue-area {

    font-size: 13px;

    font-weight: 700;
}

.issue-message {

    font-size: 14px;

    color: #4b5563;
}

.empty-message {

    padding: 25px;

    text-align: center;

    color: #15803d;

    font-weight: 600;
}


/* ============================================================
   SYSTEM INFORMATION
   ============================================================ */

.info-grid {

    display: grid;

    grid-template-columns:
        repeat(3, 1fr);

    gap: 12px;
}

.info-item {

    padding: 15px;

    border-radius: 10px;

    background: #f9fafb;
}

.info-label {

    font-size: 11px;

    color: #6b7280;

    text-transform: uppercase;
}

.info-value {

    margin-top: 5px;

    font-size: 14px;

    font-weight: 650;

    word-break: break-word;
}


/* ============================================================
   FOOTER
   ============================================================ */

.footer {

    text-align: center;

    padding: 20px;

    color: #9ca3af;

    font-size: 12px;
}


/* ============================================================
   RESPONSIVE
   ============================================================ */

@media (max-width: 900px) {

    .module-grid {

        grid-template-columns:
            repeat(2, 1fr);
    }

    .info-grid {

        grid-template-columns:
            repeat(2, 1fr);
    }
}


@media (max-width: 650px) {

    body {

        padding: 12px;
    }

    .summary {

        grid-template-columns: 1fr;
    }

    .module-grid {

        grid-template-columns: 1fr;
    }

    .info-grid {

        grid-template-columns: 1fr;
    }

    .counters {

        flex-wrap: wrap;
    }
}

</style>

</head>


<body>

<div class="container">


    <!-- HEADER -->

    <div class="header">

        <div class="brand">

            <div class="logo">
                RE
            </div>

            <div>

                <h1>$Title</h1>

                <p>$Subtitle</p>

            </div>

        </div>

        <div class="generated">

            ${GeneratedText}: $GeneratedAt

        </div>

    </div>


    <!-- SUMMARY -->

    <div class="summary">


        <div class="score-box">

            <div class="score-circle">

                <span class="score-number $OverallClass">
                    $OverallScore
                </span>

            </div>

            <div class="score-total">
                / 100
            </div>

        </div>


        <div class="summary-content">

            <h2 class="$OverallClass">
                $OverallStatus
            </h2>

            <div class="summary-text">
                $Summary
            </div>

            <span class="attention $AttentionClass">
                $AttentionText
            </span>


            <div class="counters">


                <div class="counter">

                    <strong>
                        $($Report.IssueCount)
                    </strong>

                    <span>
                        $IssueText
                    </span>

                </div>


                <div class="counter">

                    <strong class="critical">
                        $($Report.CriticalCount)
                    </strong>

                    <span>
                        $CriticalText
                    </span>

                </div>


                <div class="counter">

                    <strong class="warning">
                        $($Report.WarningCount)
                    </strong>

                    <span>
                        $WarningText
                    </span>

                </div>


            </div>

        </div>

    </div>


    <!-- MODULE HEALTH -->

    <div class="section">

        <h2>
            $ModuleHealthText
        </h2>

        <div class="module-grid">

            $ModuleCards

        </div>

    </div>


    <!-- ISSUES -->

    <div class="section">

        <h2>
            $IssuesText
        </h2>

        $RecommendationRows

    </div>


    <!-- SYSTEM INFORMATION -->

    <div class="section">

        <h2>
            $SystemInfoText
        </h2>

        <div class="info-grid">


            <div class="info-item">

                <div class="info-label">
                    $ComputerText
                </div>

                <div class="info-value">
                    $ComputerName
                </div>

            </div>


            <div class="info-item">

                <div class="info-label">
                    $ManufacturerText
                </div>

                <div class="info-value">
                    $Manufacturer
                </div>

            </div>


            <div class="info-item">

                <div class="info-label">
                    $ModelText
                </div>

                <div class="info-value">
                    $Model
                </div>

            </div>


            <div class="info-item">

                <div class="info-label">
                    $OSText
                </div>

                <div class="info-value">
                    $OperatingSystem
                </div>

            </div>


            <div class="info-item">

                <div class="info-label">
                    $BuildText
                </div>

                <div class="info-value">
                    $Build
                </div>

            </div>


            <div class="info-item">

                <div class="info-label">
                    $CPUText
                </div>

                <div class="info-value">
                    $CPU
                </div>

            </div>


            <div class="info-item">

                <div class="info-label">
                    $MemoryText
                </div>

                <div class="info-value">
                    $RAM
                </div>

            </div>


            <div class="info-item">

                <div class="info-label">
                    $ArchitectureText
                </div>

                <div class="info-value">
                    $Architecture
                </div>

            </div>


            <div class="info-item">

                <div class="info-label">
                    $UptimeText
                </div>

                <div class="info-value">
                    $Uptime
                </div>

            </div>


        </div>

    </div>


    <div class="footer">

        REWin - Windows IT Diagnostics

    </div>


</div>

</body>

</html>
"@


    # ============================================================
    # CREATE DIRECTORY
    # ============================================================

    $Directory = Split-Path -Parent $Path

    if ($Directory -and -not (Test-Path $Directory)) {

        New-Item `
            -Path $Directory `
            -ItemType Directory `
            -Force |
            Out-Null
    }


    # ============================================================
    # WRITE HTML
    # ============================================================

    Set-Content `
        -Path $Path `
        -Value $Html `
        -Encoding UTF8


    # ============================================================
    # RETURN PATH
    # ============================================================

    return $Path
}


Export-ModuleMember -Function `
    Export-REWinHealthReport
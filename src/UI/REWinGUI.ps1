Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

# ============================================================
# REWin GUI
# Windows Diagnostics & Repair
# ============================================================

$Root = Split-Path -Parent $PSScriptRoot

$HealthReportPath = Join-Path $Root "Core\HealthReport.psm1"
$RepairEnginePath = Join-Path $Root "Repair\RepairEngine.psm1"

# ============================================================
# MODULE CHECK
# ============================================================

if (-not (Test-Path $HealthReportPath)) {

    [System.Windows.MessageBox]::Show(
        "HealthReport.psm1 bulunamadi.`n`n$HealthReportPath",
        "REWin",
        "OK",
        "Error"
    )

    exit
}

if (-not (Test-Path $RepairEnginePath)) {

    [System.Windows.MessageBox]::Show(
        "RepairEngine.psm1 bulunamadi.`n`n$RepairEnginePath",
        "REWin",
        "OK",
        "Error"
    )

    exit
}

Import-Module $HealthReportPath -Force -ErrorAction Stop
Import-Module $RepairEnginePath -Force -ErrorAction Stop

# ============================================================
# WINDOW
# ============================================================

$Window = New-Object System.Windows.Window

$Window.Title = "REWin - Windows Diagnostics & Repair"
$Window.Width = 1250
$Window.Height = 750
$Window.MinWidth = 1050
$Window.MinHeight = 650

$Window.WindowStartupLocation = "CenterScreen"
$Window.Background = "#F4F6F8"

# ============================================================
# MAIN GRID
# ============================================================

$MainGrid = New-Object System.Windows.Controls.Grid

$HeaderRow = New-Object System.Windows.Controls.RowDefinition
$HeaderRow.Height = 80

$ContentRow = New-Object System.Windows.Controls.RowDefinition
$ContentRow.Height = "*"

$ButtonRow = New-Object System.Windows.Controls.RowDefinition
$ButtonRow.Height = 70

[void]$MainGrid.RowDefinitions.Add($HeaderRow)
[void]$MainGrid.RowDefinitions.Add($ContentRow)
[void]$MainGrid.RowDefinitions.Add($ButtonRow)

# ============================================================
# HEADER
# ============================================================

$Header = New-Object System.Windows.Controls.Border

$Header.Background = "#1F2937"
$Header.Padding = "30,15"

[System.Windows.Controls.Grid]::SetRow($Header, 0)

$HeaderGrid = New-Object System.Windows.Controls.Grid

$HeaderGrid.ColumnDefinitions.Add(
    (New-Object System.Windows.Controls.ColumnDefinition -Property @{
        Width = "Auto"
    })
)

$HeaderGrid.ColumnDefinitions.Add(
    (New-Object System.Windows.Controls.ColumnDefinition -Property @{
        Width = "*"
    })
)

$Title = New-Object System.Windows.Controls.TextBlock

$Title.Text = "REWin"
$Title.FontSize = 30
$Title.FontWeight = "Bold"
$Title.Foreground = "White"
$Title.VerticalAlignment = "Center"

[System.Windows.Controls.Grid]::SetColumn($Title, 0)

$Subtitle = New-Object System.Windows.Controls.TextBlock

$Subtitle.Text = "Windows Diagnostics & Repair"
$Subtitle.FontSize = 15
$Subtitle.Foreground = "#D1D5DB"
$Subtitle.Margin = "10,8,0,0"
$Subtitle.VerticalAlignment = "Center"

[System.Windows.Controls.Grid]::SetColumn($Subtitle, 1)

[void]$HeaderGrid.Children.Add($Title)
[void]$HeaderGrid.Children.Add($Subtitle)

$Header.Child = $HeaderGrid

[void]$MainGrid.Children.Add($Header)

# ============================================================
# SCROLL VIEWER
# ============================================================

$ScrollViewer = New-Object System.Windows.Controls.ScrollViewer

$ScrollViewer.VerticalScrollBarVisibility = "Auto"
$ScrollViewer.HorizontalScrollBarVisibility = "Disabled"

[System.Windows.Controls.Grid]::SetRow($ScrollViewer, 1)

$ContentStack = New-Object System.Windows.Controls.StackPanel

$ContentStack.Margin = "25,20,25,20"

# ============================================================
# TOP DASHBOARD
# ============================================================

$TopGrid = New-Object System.Windows.Controls.Grid

$ScoreColumn = New-Object System.Windows.Controls.ColumnDefinition
$ScoreColumn.Width = "280"

$ModuleColumn = New-Object System.Windows.Controls.ColumnDefinition
$ModuleColumn.Width = "*"

[void]$TopGrid.ColumnDefinitions.Add($ScoreColumn)
[void]$TopGrid.ColumnDefinitions.Add($ModuleColumn)

# ============================================================
# HEALTH SCORE
# ============================================================

$ScoreBorder = New-Object System.Windows.Controls.Border

$ScoreBorder.Background = "White"
$ScoreBorder.CornerRadius = "12"
$ScoreBorder.Padding = "20"
$ScoreBorder.Margin = "0,0,15,0"
$ScoreBorder.Height = 330

[System.Windows.Controls.Grid]::SetColumn($ScoreBorder, 0)

$ScoreStack = New-Object System.Windows.Controls.StackPanel

$ScoreTitle = New-Object System.Windows.Controls.TextBlock

$ScoreTitle.Text = "HEALTH SCORE"
$ScoreTitle.FontSize = 15
$ScoreTitle.FontWeight = "Bold"
$ScoreTitle.HorizontalAlignment = "Center"

$ScoreValue = New-Object System.Windows.Controls.TextBlock

$ScoreValue.Text = "--"
$ScoreValue.FontSize = 58
$ScoreValue.FontWeight = "Bold"
$ScoreValue.HorizontalAlignment = "Center"
$ScoreValue.Margin = "0,25,0,0"

$ScoreStatus = New-Object System.Windows.Controls.TextBlock

$ScoreStatus.Text = "NOT SCANNED"
$ScoreStatus.FontSize = 18
$ScoreStatus.FontWeight = "Bold"
$ScoreStatus.HorizontalAlignment = "Center"

$LastScan = New-Object System.Windows.Controls.TextBlock

$LastScan.Text = "Last scan: Never"
$LastScan.FontSize = 12
$LastScan.Foreground = "#6B7280"
$LastScan.HorizontalAlignment = "Center"
$LastScan.Margin = "0,15,0,0"

[void]$ScoreStack.Children.Add($ScoreTitle)
[void]$ScoreStack.Children.Add($ScoreValue)
[void]$ScoreStack.Children.Add($ScoreStatus)
[void]$ScoreStack.Children.Add($LastScan)

$ScoreBorder.Child = $ScoreStack

[void]$TopGrid.Children.Add($ScoreBorder)

# ============================================================
# DIAGNOSTIC MODULES
# ============================================================

$ModuleBorder = New-Object System.Windows.Controls.Border

$ModuleBorder.Background = "White"
$ModuleBorder.CornerRadius = "12"
$ModuleBorder.Padding = "20"
$ModuleBorder.Height = 330

[System.Windows.Controls.Grid]::SetColumn($ModuleBorder, 1)

$ModuleStack = New-Object System.Windows.Controls.StackPanel

$ModuleTitle = New-Object System.Windows.Controls.TextBlock

$ModuleTitle.Text = "Diagnostic Modules"
$ModuleTitle.FontSize = 18
$ModuleTitle.FontWeight = "Bold"
$ModuleTitle.Margin = "0,0,0,15"

[void]$ModuleStack.Children.Add($ModuleTitle)

$ModuleGrid = New-Object System.Windows.Controls.Grid

$ModuleNames = @(
    "System",
    "Disk",
    "Network",
    "Windows Update",
    "Event Log",
    "Crash",
    "Hardware",
    "Security"
)

for ($i = 0; $i -lt $ModuleNames.Count; $i++) {

    $Row = New-Object System.Windows.Controls.RowDefinition

    $Row.Height = 32

    [void]$ModuleGrid.RowDefinitions.Add($Row)
}

$ModuleValues = @{}

for ($i = 0; $i -lt $ModuleNames.Count; $i++) {

    $Name = $ModuleNames[$i]

    $NameText = New-Object System.Windows.Controls.TextBlock

    $NameText.Text = $Name
    $NameText.FontSize = 14
    $NameText.VerticalAlignment = "Center"

    [System.Windows.Controls.Grid]::SetRow($NameText, $i)

    $ValueText = New-Object System.Windows.Controls.TextBlock

    $ValueText.Text = "--"
    $ValueText.FontSize = 14
    $ValueText.FontWeight = "Bold"
    $ValueText.HorizontalAlignment = "Right"
    $ValueText.VerticalAlignment = "Center"

    [System.Windows.Controls.Grid]::SetRow($ValueText, $i)

    [void]$ModuleGrid.Children.Add($NameText)
    [void]$ModuleGrid.Children.Add($ValueText)

    $ModuleValues[$Name] = $ValueText
}

[void]$ModuleStack.Children.Add($ModuleGrid)

$ModuleBorder.Child = $ModuleStack

[void]$TopGrid.Children.Add($ModuleBorder)

[void]$ContentStack.Children.Add($TopGrid)

# ============================================================
# RECOMMENDATIONS HEADER
# ============================================================

$RecommendationHeader = New-Object System.Windows.Controls.Border

$RecommendationHeader.Background = "White"
$RecommendationHeader.CornerRadius = "12"
$RecommendationHeader.Padding = "20"
$RecommendationHeader.Margin = "0,15,0,0"

$RecommendationHeaderGrid = New-Object System.Windows.Controls.Grid

$RecommendationTitle = New-Object System.Windows.Controls.TextBlock

$RecommendationTitle.Text = "Recommendations"
$RecommendationTitle.FontSize = 18
$RecommendationTitle.FontWeight = "Bold"
$RecommendationTitle.VerticalAlignment = "Center"

$RecommendationCount = New-Object System.Windows.Controls.TextBlock

$RecommendationCount.Text = "Run Quick Health Check"
$RecommendationCount.FontSize = 13
$RecommendationCount.Foreground = "#6B7280"
$RecommendationCount.HorizontalAlignment = "Right"
$RecommendationCount.VerticalAlignment = "Center"

[void]$RecommendationHeaderGrid.Children.Add($RecommendationTitle)
[void]$RecommendationHeaderGrid.Children.Add($RecommendationCount)

$RecommendationHeader.Child = $RecommendationHeaderGrid

[void]$ContentStack.Children.Add($RecommendationHeader)

# ============================================================
# RECOMMENDATIONS PANEL
# ============================================================

$RecommendationsPanel = New-Object System.Windows.Controls.StackPanel

$RecommendationsPanel.Margin = "0,0,0,15"

[void]$ContentStack.Children.Add($RecommendationsPanel)

# ============================================================
# BUTTON HELPER
# ============================================================

function New-REWinButton {

    param(
        [string]$Text,
        [int]$Width = 190
    )

    $Button = New-Object System.Windows.Controls.Button

    $Button.Content = $Text
    $Button.Width = $Width
    $Button.Height = 40
    $Button.Margin = "8,5,8,5"
    $Button.FontSize = 14

    return $Button
}

# ============================================================
# REPAIR RESULT WINDOW
# ============================================================

function Show-REWinRepairResult {

    param(
        [Parameter(Mandatory)]
        [object]$Result
    )

    $ResultWindow = New-Object System.Windows.Window

    $ResultWindow.Title = "REWin Repair Result"
    $ResultWindow.Width = 550
    $ResultWindow.Height = 430
    $ResultWindow.WindowStartupLocation = "CenterOwner"
    $ResultWindow.Owner = $Window
    $ResultWindow.Background = "#F4F6F8"

    $Border = New-Object System.Windows.Controls.Border

    $Border.Background = "White"
    $Border.Margin = "20"
    $Border.Padding = "25"
    $Border.CornerRadius = "12"

    $Stack = New-Object System.Windows.Controls.StackPanel

    $Title = New-Object System.Windows.Controls.TextBlock

    $Title.Text = "Repair Result"
    $Title.FontSize = 22
    $Title.FontWeight = "Bold"

    $Status = New-Object System.Windows.Controls.TextBlock

    if ($Result.Success) {

        $Status.Text = "SUCCESS"
        $Status.Foreground = "#15803D"
    }
    else {

        $Status.Text = "FAILED"
        $Status.Foreground = "#DC2626"
    }

    $Status.FontSize = 22
    $Status.FontWeight = "Bold"
    $Status.Margin = "0,15,0,15"

    $Details = New-Object System.Windows.Controls.TextBlock

    $Details.FontSize = 14
    $Details.TextWrapping = "Wrap"

    $DetailsText = @()

    $DetailsText += "Repair: $($Result.RepairName)"
    $DetailsText += ""
    $DetailsText += "Status: $($Result.RepairStatus)"
    $DetailsText += ""

    if ($null -ne $Result.HealthBefore) {
        $DetailsText += "Health Before: $($Result.HealthBefore)"
    }

    if ($null -ne $Result.HealthAfter) {
        $DetailsText += "Health After:  $($Result.HealthAfter)"
    }

    if ($null -ne $Result.HealthDelta) {
        $DetailsText += "Health Delta:  $($Result.HealthDelta)"
    }

    $DetailsText += ""

    if ($Result.RepairSummary) {
        $DetailsText += $Result.RepairSummary
    }

    $Details.Text = $DetailsText -join "`n"

    $CloseButton = New-REWinButton "Close" 130
    $CloseButton.HorizontalAlignment = "Right"

    $CloseButton.Add_Click({

        $ResultWindow.Close()
    })

    [void]$Stack.Children.Add($Title)
    [void]$Stack.Children.Add($Status)
    [void]$Stack.Children.Add($Details)
    [void]$Stack.Children.Add($CloseButton)

    $Border.Child = $Stack
    $ResultWindow.Content = $Border

    [void]$ResultWindow.ShowDialog()
}

# ============================================================
# REPAIR CONFIRMATION
# ============================================================

function Confirm-REWinRepair {

    param(
        [Parameter(Mandatory)]
        [object]$Option
    )

    $ConfirmWindow = New-Object System.Windows.Window

    $ConfirmWindow.Title = "REWin Repair Confirmation"
    $ConfirmWindow.Width = 600
    $ConfirmWindow.Height = 430
    $ConfirmWindow.WindowStartupLocation = "CenterOwner"
    $ConfirmWindow.Owner = $Window
    $ConfirmWindow.Background = "#F4F6F8"

    $Border = New-Object System.Windows.Controls.Border

    $Border.Background = "White"
    $Border.Margin = "20"
    $Border.Padding = "25"
    $Border.CornerRadius = "12"

    $Stack = New-Object System.Windows.Controls.StackPanel

    $Title = New-Object System.Windows.Controls.TextBlock

    $Title.Text = "Confirm Repair"
    $Title.FontSize = 22
    $Title.FontWeight = "Bold"

    $RepairName = New-Object System.Windows.Controls.TextBlock

    $RepairName.Text = $Option.Name
    $RepairName.FontSize = 18
    $RepairName.FontWeight = "Bold"
    $RepairName.Margin = "0,20,0,8"

    $Risk = New-Object System.Windows.Controls.TextBlock

    $Risk.Text = "Risk Level: $($Option.Risk)"
    $Risk.FontSize = 14
    $Risk.FontWeight = "Bold"

    if ($Option.Risk -eq "LOW") {

        $Risk.Foreground = "#15803D"
    }
    else {

        $Risk.Foreground = "#CA8A04"
    }

    $Description = New-Object System.Windows.Controls.TextBlock

    $Description.Text = "This operation may modify Windows system settings or components."
    $Description.FontSize = 14
    $Description.TextWrapping = "Wrap"
    $Description.Margin = "0,20,0,10"

    $Warning = New-Object System.Windows.Controls.TextBlock

    $Warning.Text = "The repair will NOT run without your confirmation."
    $Warning.FontSize = 13
    $Warning.Foreground = "#6B7280"

    $ButtonPanel = New-Object System.Windows.Controls.StackPanel

    $ButtonPanel.Orientation = "Horizontal"
    $ButtonPanel.HorizontalAlignment = "Right"
    $ButtonPanel.Margin = "0,25,0,0"

    $CancelButton = New-REWinButton "Cancel" 120
    $RepairButton = New-REWinButton "Repair" 120

    $CancelButton.Add_Click({

        $ConfirmWindow.DialogResult = $false
        $ConfirmWindow.Close()
    })

    $RepairButton.Add_Click({

        $ConfirmWindow.DialogResult = $true
        $ConfirmWindow.Close()
    })

    [void]$ButtonPanel.Children.Add($CancelButton)
    [void]$ButtonPanel.Children.Add($RepairButton)

    [void]$Stack.Children.Add($Title)
    [void]$Stack.Children.Add($RepairName)
    [void]$Stack.Children.Add($Risk)
    [void]$Stack.Children.Add($Description)
    [void]$Stack.Children.Add($Warning)
    [void]$Stack.Children.Add($ButtonPanel)

    $Border.Child = $Stack
    $ConfirmWindow.Content = $Border

    return ($ConfirmWindow.ShowDialog() -eq $true)
}

# ============================================================
# EXECUTE REPAIR
# ============================================================

function Invoke-REWinGUIRepair {

    param(
        [Parameter(Mandatory)]
        [int]$RepairId
    )

    $Options = @(Get-REWinRepairOptions)

    $Option = $Options |
        Where-Object {
            $_.Id -eq $RepairId
        } |
        Select-Object -First 1

    if ($null -eq $Option) {

        [System.Windows.MessageBox]::Show(
            "Repair option not found: $RepairId",
            "REWin",
            "OK",
            "Error"
        )

        return
    }

    $Confirmed = Confirm-REWinRepair -Option $Option

    if (-not $Confirmed) {
        return
    }

    try {

        $QuickCheckButton.IsEnabled = $false
        $ReportButton.IsEnabled = $false
        $RepairCenterButton.IsEnabled = $false

        $RepairCenterButton.Content = "Repairing..."

        $Result = Invoke-REWinRepair -Id $RepairId

        Show-REWinRepairResult -Result $Result

        # Refresh health after repair
        $NewReport = Get-REWinHealthReport

        Update-REWinHealthDisplay -Report $NewReport
    }
    catch {

        [System.Windows.MessageBox]::Show(
            "Repair failed.`n`n$($_.Exception.Message)",
            "REWin Repair Error",
            "OK",
            "Error"
        )
    }
    finally {

        $QuickCheckButton.IsEnabled = $true
        $ReportButton.IsEnabled = $true
        $RepairCenterButton.IsEnabled = $true

        $RepairCenterButton.Content = "Repair Center"
    }
}

# ============================================================
# RECOMMENDATION CARD
# ============================================================

function New-REWinRecommendationCard {

    param(
        [Parameter(Mandatory)]
        [object]$Recommendation
    )

    $Card = New-Object System.Windows.Controls.Border

    $Card.Background = "White"
    $Card.CornerRadius = "10"
    $Card.Padding = "18"
    $Card.Margin = "0,8,0,0"
    $Card.BorderThickness = "1"

    if ($Recommendation.Status -eq "CRITICAL") {

        $Card.BorderBrush = "#DC2626"
    }
    elseif ($Recommendation.Status -eq "WARNING") {

        $Card.BorderBrush = "#F59E0B"
    }
    else {

        $Card.BorderBrush = "#D1D5DB"
    }

    $CardGrid = New-Object System.Windows.Controls.Grid

    $ContentColumn = New-Object System.Windows.Controls.ColumnDefinition
    $ContentColumn.Width = "*"

    $ActionColumn = New-Object System.Windows.Controls.ColumnDefinition
    $ActionColumn.Width = 150

    [void]$CardGrid.ColumnDefinitions.Add($ContentColumn)
    [void]$CardGrid.ColumnDefinitions.Add($ActionColumn)

    # --------------------------------------------------------
    # CONTENT
    # --------------------------------------------------------

    $CardStack = New-Object System.Windows.Controls.StackPanel

    $ModuleText = New-Object System.Windows.Controls.TextBlock

    $ModuleText.Text = "$($Recommendation.Module) - $($Recommendation.Priority)"
    $ModuleText.FontSize = 13
    $ModuleText.FontWeight = "Bold"
    $ModuleText.Foreground = "#6B7280"

    $TitleText = New-Object System.Windows.Controls.TextBlock

    $TitleText.Text = $Recommendation.Title
    $TitleText.FontSize = 16
    $TitleText.FontWeight = "Bold"
    $TitleText.Margin = "0,5,0,5"

    $DescriptionText = New-Object System.Windows.Controls.TextBlock

    $DescriptionText.Text = $Recommendation.Description
    $DescriptionText.FontSize = 13
    $DescriptionText.TextWrapping = "Wrap"
    $DescriptionText.Foreground = "#4B5563"

    $RecommendationText = New-Object System.Windows.Controls.TextBlock

    $RecommendationText.Text = $Recommendation.Recommendation
    $RecommendationText.FontSize = 13
    $RecommendationText.TextWrapping = "Wrap"
    $RecommendationText.Margin = "0,8,0,0"

    [void]$CardStack.Children.Add($ModuleText)
    [void]$CardStack.Children.Add($TitleText)
    [void]$CardStack.Children.Add($DescriptionText)
    [void]$CardStack.Children.Add($RecommendationText)

    [System.Windows.Controls.Grid]::SetColumn($CardStack, 0)

    [void]$CardGrid.Children.Add($CardStack)

    # --------------------------------------------------------
    # ACTIONS
    # --------------------------------------------------------

    $ActionStack = New-Object System.Windows.Controls.StackPanel

    $StatusText = New-Object System.Windows.Controls.TextBlock

    $StatusText.Text = $Recommendation.Status
    $StatusText.FontSize = 13
    $StatusText.FontWeight = "Bold"
    $StatusText.HorizontalAlignment = "Center"

    if ($Recommendation.Status -eq "CRITICAL") {

        $StatusText.Foreground = "#DC2626"
    }
    elseif ($Recommendation.Status -eq "WARNING") {

        $StatusText.Foreground = "#CA8A04"
    }
    else {

        $StatusText.Foreground = "#15803D"
    }

    [void]$ActionStack.Children.Add($StatusText)

    # --------------------------------------------------------
    # REPAIR ID
    # --------------------------------------------------------

    $RepairId = $null

    if ($Recommendation.PSObject.Properties.Name -contains "RepairId") {

        if ($null -ne $Recommendation.RepairId) {

            $RepairId = [int]$Recommendation.RepairId
        }
    }

    # Windows Update recommendation is currently repairable
    if ($null -eq $RepairId -and $Recommendation.Module -eq "WindowsUpdate") {

        $RepairId = 5
    }

    if ($null -ne $RepairId) {

        $RepairButton = New-REWinButton "REPAIR" 120

        $RepairButton.Margin = "8,15,8,0"

        $CapturedRepairId = $RepairId

        $RepairButton.Add_Click({

            Invoke-REWinGUIRepair -RepairId $CapturedRepairId

        }.GetNewClosure())

        [void]$ActionStack.Children.Add($RepairButton)
    }

    [System.Windows.Controls.Grid]::SetColumn($ActionStack, 1)

    [void]$CardGrid.Children.Add($ActionStack)

    $Card.Child = $CardGrid

    return $Card
}

# ============================================================
# UPDATE RECOMMENDATIONS
# ============================================================

function Update-REWinRecommendations {

    param(
        [Parameter(Mandatory)]
        [object]$Report
    )

    $RecommendationsPanel.Children.Clear()

    $Recommendations = @(
        $Report.Recommendations |
            Where-Object {
                $_.Status -ne "OK"
            }
    )

    if ($Recommendations.Count -eq 0) {

        $NoIssues = New-Object System.Windows.Controls.TextBlock

        $NoIssues.Text = "No recommendations. System is operating normally."
        $NoIssues.FontSize = 14
        $NoIssues.Foreground = "#15803D"
        $NoIssues.Margin = "20,15,20,15"

        [void]$RecommendationsPanel.Children.Add($NoIssues)

        $RecommendationCount.Text = "No issues detected"

        return
    }

    $RecommendationCount.Text = "$($Recommendations.Count) item(s) require attention"

    foreach ($Recommendation in $Recommendations) {

        $Card = New-REWinRecommendationCard `
            -Recommendation $Recommendation

        [void]$RecommendationsPanel.Children.Add($Card)
    }
}

# ============================================================
# HEALTH DISPLAY
# ============================================================

function Update-REWinHealthDisplay {

    param(
        [Parameter(Mandatory)]
        [object]$Report
    )

    # --------------------------------------------------------
    # SCORE
    # --------------------------------------------------------

    $ScoreValue.Text = [string]$Report.OverallScore
    $ScoreStatus.Text = [string]$Report.OverallStatus

    $LastScan.Text = "Last scan: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')"

    if ($Report.OverallScore -ge 90) {

        $ScoreValue.Foreground = "#15803D"
        $ScoreStatus.Foreground = "#15803D"
    }
    elseif ($Report.OverallScore -ge 70) {

        $ScoreValue.Foreground = "#CA8A04"
        $ScoreStatus.Foreground = "#CA8A04"
    }
    else {

        $ScoreValue.Foreground = "#DC2626"
        $ScoreStatus.Foreground = "#DC2626"
    }

    # --------------------------------------------------------
    # MODULES
    # --------------------------------------------------------

    foreach ($Module in $ModuleNames) {

        $ScoreKey = $Module.Replace(" ", "")

        if ($Module -eq "Windows Update") {

            $ScoreKey = "WindowsUpdate"
        }

        $Score = $null

        if ($Report.ModuleScores.PSObject.Properties.Name -contains $ScoreKey) {

            $Score = $Report.ModuleScores.$ScoreKey
        }

        if ($null -ne $Score) {

            $ModuleValues[$Module].Text = "$Score / 100"

            if ($Score -ge 90) {

                $ModuleValues[$Module].Foreground = "#15803D"
            }
            elseif ($Score -ge 70) {

                $ModuleValues[$Module].Foreground = "#CA8A04"
            }
            else {

                $ModuleValues[$Module].Foreground = "#DC2626"
            }
        }
        else {

            $ModuleValues[$Module].Text = "--"
        }
    }

    # --------------------------------------------------------
    # RECOMMENDATIONS
    # --------------------------------------------------------

    Update-REWinRecommendations -Report $Report
}

# ============================================================
# BOTTOM BUTTONS
# ============================================================

$ButtonPanel = New-Object System.Windows.Controls.StackPanel

$ButtonPanel.Orientation = "Horizontal"
$ButtonPanel.HorizontalAlignment = "Center"

[System.Windows.Controls.Grid]::SetRow($ButtonPanel, 2)

$QuickCheckButton = New-REWinButton "Quick Health Check"
$ReportButton = New-REWinButton "Health Report"
$RepairCenterButton = New-REWinButton "Repair Center"

[void]$ButtonPanel.Children.Add($QuickCheckButton)
[void]$ButtonPanel.Children.Add($ReportButton)
[void]$ButtonPanel.Children.Add($RepairCenterButton)

[void]$MainGrid.Children.Add($ButtonPanel)

# ============================================================
# QUICK HEALTH CHECK
# ============================================================

$QuickCheckButton.Add_Click({

    $QuickCheckButton.IsEnabled = $false
    $ReportButton.IsEnabled = $false
    $RepairCenterButton.IsEnabled = $false

    $QuickCheckButton.Content = "Scanning..."

    try {

        $Report = Get-REWinHealthReport

        Update-REWinHealthDisplay -Report $Report

        $ScrollViewer.ScrollToTop()
    }
    catch {

        [System.Windows.MessageBox]::Show(
            "Health Check failed.`n`n$($_.Exception.Message)",
            "REWin Error",
            "OK",
            "Error"
        )
    }
    finally {

        $QuickCheckButton.IsEnabled = $true
        $ReportButton.IsEnabled = $true
        $RepairCenterButton.IsEnabled = $true

        $QuickCheckButton.Content = "Quick Health Check"
    }
})

# ============================================================
# HEALTH REPORT
# ============================================================

$ReportButton.Add_Click({

    try {

        $Report = Get-REWinHealthReport

        $Text = @()

        $Text += "REWin Health Report"
        $Text += "==================="
        $Text += ""
        $Text += "Overall Score : $($Report.OverallScore)"
        $Text += "Overall Status: $($Report.OverallStatus)"
        $Text += ""
        $Text += "Issues        : $($Report.IssueCount)"
        $Text += "Critical      : $($Report.CriticalCount)"
        $Text += "Warnings      : $($Report.WarningCount)"
        $Text += ""
        $Text += "Weak Areas:"
        $Text += "-----------"

        foreach ($Area in $Report.WeakAreas) {

            $Text += $Area
        }

        [System.Windows.MessageBox]::Show(
            ($Text -join "`n"),
            "REWin Health Report",
            "OK",
            "Information"
        )
    }
    catch {

        [System.Windows.MessageBox]::Show(
            "Health Report could not be loaded.`n`n$($_.Exception.Message)",
            "REWin Error",
            "OK",
            "Error"
        )
    }
})

# ============================================================
# REPAIRRepairWindow CENTER WINDOW
# ============================================================

$RepairCenterButton.Add_Click({

    try {

        $Options = @(Get-REWinRepairOptions)

        $RepairWindow = New-Object System.Windows.Window

        $RepairWindow.Title = "REWin Repair Center"
        $RepairWindow.Width = 720
        $RepairWindow.Height = 650
        $RepairWindow.WindowStartupLocation = "CenterOwner"
        $RepairWindow.Owner = $Window
        $RepairWindow.Background = "#F4F6F8"

        $Border = New-Object System.Windows.Controls.Border

        $Border.Background = "White"
        $Border.Margin = "20"
        $Border.Padding = "25"
        $Border.CornerRadius = "12"

        $Stack = New-Object System.Windows.Controls.StackPanel

        $Title = New-Object System.Windows.Controls.TextBlock

        $Title.Text = "Repair Center"
        $Title.FontSize = 24
        $Title.FontWeight = "Bold"

        $Description = New-Object System.Windows.Controls.TextBlock

        $Description.Text = "Select a repair operation. No repair is executed until you confirm it."
        $Description.FontSize = 14
        $Description.Foreground = "#6B7280"
        $Description.TextWrapping = "Wrap"
        $Description.Margin = "0,8,0,20"

        [void]$Stack.Children.Add($Title)
        [void]$Stack.Children.Add($Description)

        $OptionsPanel = New-Object System.Windows.Controls.StackPanel

        foreach ($Option in $Options) {

            $OptionBorder = New-Object System.Windows.Controls.Border

            $OptionBorder.Background = "#F9FAFB"
            $OptionBorder.BorderBrush = "#D1D5DB"
            $OptionBorder.BorderThickness = "1"
            $OptionBorder.CornerRadius = "8"
            $OptionBorder.Padding = "15"
            $OptionBorder.Margin = "0,5,0,5"

            $OptionGrid = New-Object System.Windows.Controls.Grid

            $NameColumn = New-Object System.Windows.Controls.ColumnDefinition
            $NameColumn.Width = "*"

            $RiskColumn = New-Object System.Windows.Controls.ColumnDefinition
            $RiskColumn.Width = 100

            $ActionColumn = New-Object System.Windows.Controls.ColumnDefinition
            $ActionColumn.Width = 110

            [void]$OptionGrid.ColumnDefinitions.Add($NameColumn)
            [void]$OptionGrid.ColumnDefinitions.Add($RiskColumn)
            [void]$OptionGrid.ColumnDefinitions.Add($ActionColumn)

            $NameText = New-Object System.Windows.Controls.TextBlock

            $NameText.Text = "$($Option.Id) - $($Option.Name)"
            $NameText.FontSize = 14
            $NameText.FontWeight = "Bold"
            $NameText.VerticalAlignment = "Center"

            [System.Windows.Controls.Grid]::SetColumn($NameText, 0)

            $RiskText = New-Object System.Windows.Controls.TextBlock

            $RiskText.Text = $Option.Risk
            $RiskText.FontSize = 13
            $RiskText.FontWeight = "Bold"
            $RiskText.HorizontalAlignment = "Center"
            $RiskText.VerticalAlignment = "Center"

            if ($Option.Risk -eq "LOW") {

                $RiskText.Foreground = "#15803D"
            }
            else {

                $RiskText.Foreground = "#CA8A04"
            }

            [System.Windows.Controls.Grid]::SetColumn($RiskText, 1)

            $RepairButton = New-REWinButton "SELECT" 100

            [System.Windows.Controls.Grid]::SetColumn($RepairButton, 2)

            $CapturedId = [int]$Option.Id

            $RepairButton.Add_Click({

                $RepairWindow.Close()

                Invoke-REWinGUIRepair -RepairId $CapturedId

            }.GetNewClosure())

            [void]$OptionGrid.Children.Add($NameText)
            [void]$OptionGrid.Children.Add($RiskText)
            [void]$OptionGrid.Children.Add($RepairButton)

            $OptionBorder.Child = $OptionGrid

            [void]$OptionsPanel.Children.Add($OptionBorder)
        }

        [void]$Stack.Children.Add($OptionsPanel)

        $CloseButton = New-REWinButton "Close" 120
        $CloseButton.HorizontalAlignment = "Right"
        $CloseButton.Margin = "0,20,0,0"

        $CloseButton.Add_Click({

            $RepairWindow.Close()
        })

        [void]$Stack.Children.Add($CloseButton)

        $Border.Child = $Stack

        $RepairWindow.Content = $Border

        [void]$RepairWindow.ShowDialog()
    }
    catch {

        [System.Windows.MessageBox]::Show(
            "Repair Center could not be loaded.`n`n$($_.Exception.Message)",
            "REWin Error",
            "OK",
            "Error"
        )
    }
})

# ============================================================
# INITIAL STATE
# ============================================================

$ScrollViewer.Content = $ContentStack

[void]$MainGrid.Children.Add($ScrollViewer)

$Window.Content = $MainGrid

$Window.Add_ContentRendered({

    $ScoreValue.Text = "--"
    $ScoreStatus.Text = "NOT SCANNED"

    $RecommendationCount.Text = "Run Quick Health Check"

})

# ============================================================
# START
# ============================================================

[void]$Window.ShowDialog()
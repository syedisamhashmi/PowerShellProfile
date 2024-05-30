[CmdletBinding()]
param (
  [switch]$Force
)

if ($MyInvocation.InvocationName -ne ".") {
  $tools_repo_path = "$PSScriptRoot/../..";
  . $tools_repo_path/powershell/functions/prepend_path.ps1 "$PSScriptRoot/functions"
}

$config = get_or_create_config_key "AutoUpdate"

if ($config.AutoUpdate.CheckPeriod -eq $null) {
  $choices = @(
    [System.Management.Automation.Host.ChoiceDescription]::new("&daily", "Check for updates daily")
    [System.Management.Automation.Host.ChoiceDescription]::new("&weekly", "Check for updates weekly")
    [System.Management.Automation.Host.ChoiceDescription]::new("&session", "Check for updates every terminal session")
  )
  $decision = $Host.UI.PromptForChoice(
    "Auto Update - Check Frequency",
    "How often would you like to check for updates?",
    $choices,
    -1
  )
  if ($decision -eq 0) {  
    $config = get_or_create_config_key "AutoUpdate.CheckPeriod" -value "daily"
  }
  if ($decision -eq 1) {  
    $config = get_or_create_config_key "AutoUpdate.CheckPeriod" -value "weekly"
  }
  if ($decision -eq 2) {  
    $config = get_or_create_config_key "AutoUpdate.CheckPeriod" -value "session"
  }
}
if ($config.UserPreferences.AutoUpdates -eq $null) {
  
  $decision = yes_no_prompt `
    -title "Automatic Updates" `
    -description "You have not opted in/out of automatic updates.`nWould you like to always attempt auto updates when available?`n(Updates are still fetched, just not applied.)" `
    -yes "Allow automatic updates" `
    -no "Ignore automatic updates, I will handle them myself.";
  if ($decision -eq 0) {  
    $config = get_or_create_config_key "UserPreferences.AutoUpdates" $True
  }
  if ($decision -eq 1) {
    $config = get_or_create_config_key "UserPreferences.AutoUpdates" $false
  }
}

Write-Verbose "Considering if I should check for updates..."
if (
  (-not $Force) -and
  $config.AutoUpdate.CheckPeriod -ne "session"
) {
  $config = get_or_create_config_key "AutoUpdate.CheckPeriod"
  $now = Get-Date
  if (
    $config.AutoUpdate.LastChecked -ne $null
  ) {
    if (
        $config.AutoUpdate.CheckPeriod -eq "weekly" -and
        # if now is before 7 days from the time we checked, do nothing.
        $now -lt ([DateTime]$config.AutoUpdate.LastChecked).AddDays(7)
    ) {
      Write-Verbose "NOT checking for update - it has not been a week"
      return
    }
    if (
      $config.AutoUpdate.CheckPeriod -eq "daily" -and
      # if now is before 24 from the time we checked, do nothing.
      $now -lt ([DateTime]$config.AutoUpdate.LastChecked).AddHours(24)
    ) {
      Write-Verbose "NOT checking for update - it has not been a day"
      return
    }
  }
}

Push-Location $tools_repo_path
Write-Verbose "Actually Checking for update"
# Fetch updates on main
(git fetch origin main -q -n -k --depth 1) 1>$null 2>$null 3>$null 4>$null 5>$null 6>$null
# Check if status says we are behind on commits
$isBehind = (git status) -match "behind|diverged"

if ($isBehind) {
  Write-Host " ╔══════════════════════════════════════════════╗ $($PSStyle.Reset)" -BackgroundColor White -ForegroundColor Black
  Write-Host " ║ Update is available for your developer tools ║ $($PSStyle.Reset)" -BackgroundColor White -ForegroundColor Black
  Write-Host " ╚══════════════════════════════════════════════╝ $($PSStyle.Reset)" -BackgroundColor White -ForegroundColor Black

  $config = get_or_create_config_key "UserPreferences.AutoUpdates"
  if ($config.UserPreferences.AutoUpdates -eq $True) {
    Write-Host "Attempting update..."

    # Ignore all output from all streams
    git checkout -b test 1>$null 2>$null 3>$null 4>$null 5>$null 6>$null
    git branch -D main 1>$null 2>$null 3>$null 4>$null 5>$null 6>$null
    git checkout main 1>$null 2>$null 3>$null 4>$null 5>$null 6>$null
    git branch -D test 1>$null 2>$null 3>$null 4>$null 5>$null 6>$null

    # # Check if status says we are behind on commits
    $isBehind = (git status) -match "behind"
    if ($isBehind) {
      Write-Host "Update FAILED... Please reconcile '$tools_repo_path' manually"
    }
    else {
      Write-Host "Update complete. Please open a new PowerShell."
    }
  }
}

$config = get_or_create_config_key "AutoUpdate.LastChecked" $(Get-Date)
Pop-Location

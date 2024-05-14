[CmdletBinding()]

$autoUpdateTitle = "Automatic Updates"
$autoUpdateDescription = "You have not opted in/out of automatic updates.`nWould you like to always attempt auto updates when available?"
$autoUpdateChoices = @(
  [System.Management.Automation.Host.ChoiceDescription]::new("&YES", "Allow automatic updates")
  [System.Management.Automation.Host.ChoiceDescription]::new("&NO", "Ignore automatic updates, I will handle them myself.")
)

Push-Location $PSScriptRoot
$gitRepoDir = git rev-parse --show-toplevel

$config = Get-Content -Path "$gitRepoDir/config.json" | ConvertFrom-Json
if (
  $config.AutoUpdate.CheckPeriod -ne "session" -and
  $config.AutoUpdate.LastChecked -ne $null
) {
  $now = Get-Date
  if (
    $config.AutoUpdate.CheckPeriod -eq "daily" -and
    # if now is before 24 from the time we checked, do nothing.
    $now -lt ([DateTime]$config.AutoUpdate.LastChecked).AddHours(24)
  ) {
    Pop-Location
    return
  }
  if (
    $config.AutoUpdate.CheckPeriod -eq "weekly" -and
    # if now is before 7 days from the time we checked, do nothing.
    $now -lt ([DateTime]$config.AutoUpdate.LastChecked).AddDays(7)
  ) {
    Pop-Location
    return
  }
}

# Fetch updates on main
(git fetch origin main -q -n -k --depth 1) 1>$null 2>$null 3>$null 4>$null 5>$null 6>$null
# Check if status says we are behind on commits
$isBehind = (git status) -match "behind|diverged" 

if ($isBehind) {
  Write-Host " ╔══════════════════════════════════════════════╗ $($PSStyle.Reset)" -BackgroundColor White -ForegroundColor Black
  Write-Host " ║ Update is available for your developer tools ║ $($PSStyle.Reset)" -BackgroundColor White -ForegroundColor Black
  Write-Host " ╚══════════════════════════════════════════════╝ $($PSStyle.Reset)" -BackgroundColor White -ForegroundColor Black

  CreateRepoConfig >$null
  
  if ($config.UserPreferences.AutoUpdates -eq $null) {
    Write-Host " ══════════════════════════════════════════════   $($PSStyle.Reset)" -BackgroundColor White -ForegroundColor Black
    $decision = $Host.UI.PromptForChoice($autoUpdateTitle, $autoUpdateDescription, $autoUpdateChoices, -1)
    if ($decision -eq 0) {
      $config.UserPreferences.AutoUpdates = $True
      $config | ConvertTo-Json | Out-File -FilePath "$gitRepoDir/config.json"
    }
    if ($decision -eq 1) {
      $config.UserPreferences.AutoUpdates = $False
      $config | ConvertTo-Json | Out-File -FilePath "$gitRepoDir/config.json"
    }
  }

  if ($config.UserPreferences.AutoUpdates -eq $True) {
    Write-Host "Attempting update..."
    
    # # Ignore all output from all streams
    (git checkout main) 1>$null 2>$null 3>$null 4>$null 5>$null 6>$null
    (git pull) 1>$null 2>$null 3>$null 4>$null 5>$null 6>$null
    
    # # Check if status says we are behind on commits
    $isBehind = (git status) -match "behind"
    if ($isBehind) {
      Write-Host "Update FAILED... Please reconcile '$gitRepoDir' manually"
    }
    else {
      Write-Host "Update complete. Please open a new PowerShell."
    }
  }
}

$config.AutoUpdate.LastChecked = Get-Date
$config | ConvertTo-Json | Out-File -FilePath "$gitRepoDir/config.json"

Pop-Location

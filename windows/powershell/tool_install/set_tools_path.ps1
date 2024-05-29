[CmdletBinding()]
param(
  [switch]$forceInstall
)

if ($tools_repo_path -eq $null) {
  $tools_repo_path = "$PSScriptRoot/../..";
}

$toolsPathTitle = "Tools Path"
$toolsPathDescription = "You have not set your 'tools' path.`nWould you like to use the default? (c:/tools)"
$toolsPathDefaultChoices = @(
  [System.Management.Automation.Host.ChoiceDescription]::new("&YES", "Use default tools path for tool binaries. (c:/tools)")
  [System.Management.Automation.Host.ChoiceDescription]::new("&NO", "I want to put my tools elsewhere...")
)

. $tools_repo_path/powershell/functions/create_config.ps1

$config = Get-Content -Path "$tools_repo_path/config.json" | ConvertFrom-Json

# User has tools path set, great.
if ($config.UserPreferences.ToolsPath -ne $null) {
  return
}

# Check and add to config if they rejected tools or not.
if (-not ("RejectedTools" -in $config.InstallPreferences.PSobject.Properties.Name)) {
  Write-Debug "RejectedTools not found"
  Add-Member -Force -InputObject $config.InstallPreferences -NotePropertyName RejectedTools -NotePropertyValue $null
  $config | ConvertTo-Json | Out-File -FilePath "$tools_repo_path/config.json"
}
else {
  Write-Debug "RejectedTools found"
}

# If they have not rejected before, ask if they want to use tools.
if ($config.InstallPreferences.RejectedTools -eq $null)
{
  $toolsPathReqTitle = "Tools Path"
  $toolsPathReqDescription = "Would you like to install developer tools?"
  $toolsPathReqDefaultChoices = @(
    [System.Management.Automation.Host.ChoiceDescription]::new("&YES", "Yes, I want to set my tools in a specified location")
    [System.Management.Automation.Host.ChoiceDescription]::new("&NO", "I will handle my tools...")
  )
  $decision = $Host.UI.PromptForChoice(
    $toolsPathReqTitle,
    $toolsPathReqDescription,
    $toolsPathReqDefaultChoices,
    -1
  )
  # They said they want tools, never ask again.
  if ($decision -eq 0) {
    $config.InstallPreferences.RejectedTools = $false
    $config | ConvertTo-Json | Out-File -FilePath "$tools_repo_path/config.json"
  }
  # They said they don't want tools, never ask again.
  if ($decision -eq 1) {
    $config.InstallPreferences.RejectedTools = $true
    $config | ConvertTo-Json | Out-File -FilePath "$tools_repo_path/config.json"
  }
  
}

$config = Get-Content -Path "$tools_repo_path/config.json" | ConvertFrom-Json
if ($config.InstallPreferences.RejectedTools -eq $true)
{
  exit
}

if ($config.UserPreferences.ToolsPath -eq $null) {
  Write-Debug "ToolsPath not set"

  $decision = $Host.UI.PromptForChoice(
    $toolsPathTitle,
    $toolsPathDescription,
    $toolsPathDefaultChoices,
    -1
  )
  # They are cool with default tools path, great.
  if ($decision -eq 0) {
    Add-Member -Force -InputObject $config.UserPreferences -NotePropertyName ToolsPath -NotePropertyValue "c:/tools"
    if (-not (Test-Path -PathType Container -Path "c:/tools") ) {
      New-Item -ItemType Directory -Path "c:/tools"
    }
    $config | ConvertTo-Json | Out-File -FilePath "$tools_repo_path/config.json"
  }
  # Ask for a path and test it.
  if ($decision -eq 1) {
    $isValidPath = $false
    $user_given_path = ""
    while (-not $isValidPath) {
      $user_given_path = Read-Host "Please provide the path for your tools binaries"
      if (Test-Path -PathType Container -Path $user_given_path) {
        $isValidPath = $true
      }
      else {
        Write-Host "Invalid path ``$user_given_path`` does not exist!"
      }
    }
    Add-Member -Force -InputObject $config.UserPreferences -NotePropertyName ToolsPath -NotePropertyValue $user_given_path

    $config | ConvertTo-Json | Out-File -FilePath "$tools_repo_path/config.json"
  }
}
else {
  Write-Debug "ToolsPath set"
}
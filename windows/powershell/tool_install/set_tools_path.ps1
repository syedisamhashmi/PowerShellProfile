[CmdletBinding()]
param(
  [switch]$forceInstall
)

if ($MyInvocation.InvocationName -ne ".") {
  $tools_repo_path = "$PSScriptRoot/../..";
  . $tools_repo_path/powershell/functions/prepend_path.ps1 "$PSScriptRoot/functions"
}

. create_config.ps1

# User has tools path set, great.
$config = get_or_create_config_key "UserPreferences.ToolsPath"
if ($config.UserPreferences.ToolsPath -ne $null) {
  return
}

$config = get_or_create_config_key "InstallPreferences.RejectedTools"
# If they have not rejected before, ask if they want to use tools.
if ($config.InstallPreferences.RejectedTools -eq $null)
{
  $decision = yes_no_prompt `
    -title "Developer Tools" `
    -description "Would you like to install developer tools?"
    -yes "Yes, I want to install developer tools" `
    -no "I will handle my tools...";
  # They said they want tools, never ask again.
  if ($decision -eq 0) {
    $config = get_or_create_config_key "InstallPreferences.RejectedTools" $false
  }
  # They said they don't want tools, never ask again.
  if ($decision -eq 1) {
    $config = get_or_create_config_key "InstallPreferences.RejectedTools" $true
  }
  
}

if ($config.InstallPreferences.RejectedTools -eq $true)
{
  return
}

$config = get_or_create_config_key "UserPreferences.ToolsPath"
if ($config.UserPreferences.ToolsPath -eq $null) {
  Write-Debug "ToolsPath not set"
  $decision = yes_no_prompt `
    -title "Tools Path" `
    -description "You have not set your 'tools' path.`nWould you like to use the default? (c:/tools)"
    -yes "Use default tools path for tool binaries. (c:/tools)" `
    -no "I want to put my tools elsewhere...";
  
  # They are cool with default tools path, great.
  if ($decision -eq 0) {
    $config = get_or_create_config_key "UserPreferences.ToolsPath" "c:/tools"
    if (-not (Test-Path -PathType Container -Path $config.UserPreferences.ToolsPath) ) {
      New-Item -ItemType Directory -Path $config.UserPreferences.ToolsPath
    }
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
    $config = get_or_create_config_key "UserPreferences.ToolsPath" $user_given_path
  }
}
else {
  Write-Debug "ToolsPath set"
}
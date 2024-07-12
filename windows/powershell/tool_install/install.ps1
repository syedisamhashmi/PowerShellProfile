[CmdletBinding()]
param(
  [switch]$forceInstall
)

if ($MyInvocation.InvocationName -ne ".") {
  $tools_repo_path = "$PSScriptRoot/../..";
  . $tools_repo_path/powershell/functions/prepend_path.ps1 "$PSScriptRoot/functions"
}

# Add install preferences if not present
$config = get_or_create_config_key "InstallPreferences"

# Try to set tools path
. $PSScriptRoot/set_tools_path.ps1 -forceInstall:$forceInstall

# If they rejected installing tools, then I will not even bother with next part.
$config = get_or_create_config_key "InstallPreferences.RejectedTools"
if ($config.InstallPreferences.RejectedTools -eq $true)
{
  Write-Debug "Tools have been rejected"
  return
}

# ----------------------------------------------------------------------------
# Ok - Now I have a place to clone all necessary tools and append them to the path.
# ----------------------------------------------------------------------------

. $tools_repo_path/powershell/functions/prepend_path.ps1 "$PSScriptRoot/functions"
$config = get_or_create_config_key "UserPreferences.ToolsPath"

# Create tools path if it doesn't exist
if (-not (Test-Path -PathType Container -Path $config.UserPreferences.ToolsPath) ) {
  New-Item -ItemType Directory -Path $config.UserPreferences.ToolsPath
}

. $PSScriptRoot/install_jq.ps1 -forceInstall:$forceInstall
. $PSScriptRoot/set_default_shell.ps1 -forceInstall:$forceInstall
. $PSScriptRoot/install_fzf.ps1 -forceInstall:$forceInstall

. $PSScriptRoot/install_azuredatastudio.ps1 -forceInstall:$forceInstall
. $PSScriptRoot/install_az.ps1 -forceInstall:$forceInstall
. $PSScriptRoot/install_vscode.ps1 -forceInstall:$forceInstall

. $PSScriptRoot/install_7zip.ps1 -forceInstall:$forceInstall
. $PSScriptRoot/install_llvm.ps1 -forceInstall:$forceInstall

. $PSScriptRoot/install_dotnet.ps1 -forceInstall:$forceInstall
prepend_path "$tools_install_path/dotnet"

# Add git to path.
$GIT_PATH = where.exe git
if ($GIT_PATH -ne $null)
{
  $GIT_DIR = $GIT_PATH | Split-Path -Parent | Split-Path -Parent | Select-Object -Property $_ -First 1
  #? add the usr/bin tools to the path.
  prepend_path($GIT_DIR + "/usr/bin")
}

. $PSScriptRoot/install_nvm.ps1 -forceInstall:$forceInstall


. $PSScriptRoot/install_ripgrep.ps1 -forceInstall:$forceInstall

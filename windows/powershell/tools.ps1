[CmdletBinding()]
param(
  [switch]$forceInstall
)

if ($tools_repo_path -eq $null) {
  $tools_repo_path = "$PSScriptRoot/..";
}

# Add install preferences if not present
$config = Get-Content -Path "$tools_repo_path/config.json" | ConvertFrom-Json
if (-not ("InstallPreferences" -in $config.PSobject.Properties.Name)) {
  Write-Debug "InstallPreferences not found"
  Add-Member -Force -InputObject $config -NotePropertyName InstallPreferences -NotePropertyValue @{}
  $config | ConvertTo-Json | Out-File -FilePath "$tools_repo_path/config.json"
}
else {
  Write-Debug "InstallPreferences found"
}

# Try to set tools path
. $PSScriptRoot/tool_install/set_tools_path.ps1 -forceInstall:$forceInstall
# If they rejected installing tools, then I will not even bother with next part.
$config = Get-Content -Path "$tools_repo_path/config.json" | ConvertFrom-Json
if ($config.InstallPreferences.RejectedTools -eq $true)
{
  exit
}

# ----------------------------------------------------------------------------
# Ok - Now I have a place to clone all necessary tools and append them to the path.
# ----------------------------------------------------------------------------

. $PSScriptRoot/functions/prepend_path.ps1 "$PSScriptRoot/functions"
$config = Get-Content -Path "$tools_repo_path/config.json" | ConvertFrom-Json
$tools_install_path = $config.UserPreferences.ToolsPath

# Create tools path if it doesn't exist
if (-not (Test-Path -PathType Container -Path $tools_install_path) ) {
  New-Item -ItemType Directory -Path $tools_install_path
}

Clear-Host
. $PSScriptRoot/tool_install/install_fzf.ps1 -forceInstall:$forceInstall

Clear-Host
. $PSScriptRoot/tool_install/install_az.ps1 -forceInstall:$forceInstall

Clear-Host
. $PSScriptRoot/tool_install/install_dotnet.ps1 -forceInstall:$forceInstall

Clear-Host
# Add git to path.
$GIT_PATH = where.exe git
if ($GIT_PATH -ne $null)
{
  $GIT_DIR = $GIT_PATH | Split-Path -Parent | Split-Path -Parent | Select-Object -Property $_ -First 1
  #? add the usr/bin tools to the path.
  prepend_path($GIT_DIR + "/usr/bin")
}

Clear-Host
. $PSScriptRoot/tool_install/install_nvm.ps1 -forceInstall:$forceInstall


Clear-Host
. $PSScriptRoot/tool_install/install_ripgrep.ps1 -forceInstall:$forceInstall

Clear-Host
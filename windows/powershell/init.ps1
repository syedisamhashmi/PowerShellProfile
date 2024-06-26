[CmdletBinding()]
param(
  [switch]$forceInstall
)

$before = $ErrorActionPreference
$ErrorActionPreference = "SilentlyContinue"

if ($PSVersionTable.PSEdition -ne "Core") {
  Write-Error "This is not the correct powershell, use the one from the Windows store!!!!"
  Write-Error "This is not the correct powershell, use the one from the Windows store!!!!"
  Write-Error "This is not the correct powershell, use the one from the Windows store!!!!"
  exit 1;
}

$powershell_path = "$PSScriptRoot".Replace("\", "/");
$tools_repo_path = "$PSScriptRoot/..";
$powershell_functions_path = "$powershell_path/functions";
$powershell_scripts_path = "$powershell_path/scripts";

# Add scripts to path.
# This gives us access to any defined aliases after this point
# and now we can use prepend going forward since it will be in the path.
. $powershell_functions_path/prepend_path.ps1 "$powershell_functions_path"
prepend_path "$powershell_scripts_path"
#? Code (Insiders) (if present)
prepend_path "$HOME/AppData/Local/Programs/Microsoft VS Code Insiders/bin"

# Create config if not found
create_config.ps1


$checkUpdateTime = Measure-Command {
  . check_for_update
}
Write-Debug "Check Update time: $($checkUpdateTime.TotalMilliseconds)"

$toolInstallTime = Measure-Command {
  . $powershell_path/tool_install/install.ps1 -forceInstall:$forceInstall
}
Write-Debug "Tool install time: $($toolInstallTime.TotalMilliseconds)"

$processConfigTime = Measure-Command {
  . $powershell_path/process_config.ps1
}
Write-Debug "Process config time: $($processConfigTime.TotalMilliseconds)"

. $powershell_path/aliases.ps1

# Persist config
$config | ConvertTo-Json | Out-File -FilePath "$tools_repo_path/config.json"
$ErrorActionPreference = $before
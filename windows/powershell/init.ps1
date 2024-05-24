[CmdletBinding()]
param(
)

if ($PSVersionTable.PSEdition -ne "Core") {
  Write-Error "This is not the correct powershell, use the one from the Windows store!!!!"
  Write-Error "This is not the correct powershell, use the one from the Windows store!!!!"
  Write-Error "This is not the correct powershell, use the one from the Windows store!!!!"
  exit 1;
}

$powershell_path = "$PSScriptRoot".Replace("\", "/");
$tools_repo_path = "$PSScriptRoot/..";

. $powershell_path/functions/create_config.ps1;

$powershell_functions_path = "$powershell_path/functions";
$powershell_scripts_path = "$powershell_path/scripts";

# Add scripts to path.
# This gives us access to any defined aliases after this point
# and now we can use prepend going forward since it will be in the path.
. $powershell_functions_path/prepend_path.ps1 "$powershell_functions_path"

. check_for_update

. $powershell_path/tools.ps1

prepend_path "$powershell_scripts_path"

. $powershell_path/aliases.ps1
$powershell_path = "$PSScriptRoot".Replace("\", "/");
$tools_repo_path = "$PSScriptRoot/..";

. $powershell_path/functions/create_config.ps1;

$powershell_functions_path = "$powershell_path/functions";
$powershell_scripts_path = "$powershell_path/scripts";

# Add scripts to path.
# This gives us access to any defined aliases after this point
# and now we can use prepend going forward since it will be in the path.
. $powershell_functions_path/prepend_path.ps1 "$powershell_functions_path"

prepend_path "$powershell_scripts_path"

. $powershell_path/aliases.ps1

. check_for_update
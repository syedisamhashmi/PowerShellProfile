$EDITOR = "vim"

$powershell_path = "$PSScriptRoot".Replace("\", "/");

. $powershell_path/functions/create_config.ps1;

. $powershell_path/aliases.ps1

$powershell_functions_path = "$powershell_path/functions";
$powershell_scripts_path = "$powershell_path/scripts";

# Add scripts to path.
# This gives us access to any defined aliases after this point
# and now we can use prepend going forward since it will be in the path.
. $powershell_functions_path/prepend_path.ps1 "$powershell_functions_path"

prepend_path "$powershell_scripts_path"


# TODO: Setup config for 1. ShouldAutoHome, 2. HomeLocation
if (
  ((Get-Location).tostring() -eq 'C:\WINDOWS\system32') -or
  ((Get-Location).tostring() -eq $HOME)
) {
  cd $PROJECT_ROOT;
}


#? GIT
$GIT_PATH = where.exe git
$GIT_DIR = $GIT_PATH | Split-Path -Parent | Split-Path -Parent
prepend_path "$GIT_DIR/usr/bin"
#? For local dotnet install
prepend_path "$HOME/AppData/local/Microsoft/dotnet"

# TODO: Setup config for Tools path
$TOOLS_PATH = "c:/tools";
#? AZ
prepend_path "$TOOLS_PATH/az"
#? Ripgrep
prepend_path "$TOOLS_PATH/ripgrep"
#? FuzzyFind
prepend_path "$TOOLS_PATH/fzf"
#? bat
prepend_path "$TOOLS_PATH/bat"
#? Code (Insiders)
prepend_path "$HOME/AppData/Local/Programs/Microsoft VS Code Insiders/bin"

install_package("posh-git")
install_package("z")

. check_for_update
# Housekeeping
#------------------------------------------------------------------------------
#? Wherever projects are stored.
#? Big fan of the pharmacy, you know... CVS *ba dum tss*
$PROJECT_ROOT = "c:/vs"; 
$TOOLS_PATH = "c:/tools";

#? To run scripts as needed.
#? I typically just copy paste,
#? but might make an alias at some point...
#? (after all, I am taking the time to copy paste all this anyways)
#Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

#? I have a hotkey to run powershell from system32,
#? but new terminal sessions start from ~
#? so this just sets me to my home directory
if (
  ((Get-Location).tostring() -eq 'C:\WINDOWS\system32') -or
  ((Get-Location).tostring() -eq $HOME)
) {
  cd $PROJECT_ROOT;
}

# Script sourcing
#------------------------------------------------------------------------------
. $PSScriptRoot/aliases.ps1
. $PSScriptRoot/functions.ps1

# Path manipulation
#------------------------------------------------------------------------------
#? For local dotnet install
prepend_path("$HOME/AppData/local/Microsoft/dotnet")

#? Find git, and go up two dirs to the install location and
$GIT_PATH = where.exe git
$GIT_DIR = $GIT_PATH | Split-Path -Parent | Split-Path -Parent
#? add the usr/bin tools to the path.
prepend_path($GIT_DIR + "/usr/bin")

#? Add NVM.
prepend_path("nvm")
. c:\tools\nvm\use-node.ps1
#? For access to bins in npm
#prepend_path("$HOME/AppData/Roaming/npm")

#? Ripgrep
prepend_path("$TOOLS_PATH/ripgrep")

#? FuzzyFind
prepend_path("$TOOLS_PATH/fzf")

#? bat
prepend_path("$TOOLS_PATH/bat")

#? Code (Insiders)
prepend_path("$HOME/AppData/Local/Programs/Microsoft VS Code Insiders/bin")

# Re-source in case new aliases can be installed.
#------------------------------------------------------------------------------
. $PSScriptRoot/aliases.ps1
. $PSScriptRoot/functions.ps1


# Install and import modules
setup-modules
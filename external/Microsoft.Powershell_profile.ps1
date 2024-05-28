#? To run scripts as needed.
#? I typically just copy paste,
#? but might make an alias at some point...
#? (after all, I am taking the time to copy paste all this anyways)
#Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# Script sourcing
#------------------------------------------------------------------------------
. $PSScriptRoot/aliases.ps1
. $PSScriptRoot/functions.ps1

# Path manipulation
#------------------------------------------------------------------------------
#? For local dotnet install
prepend_path("$HOME/AppData/local/Microsoft/dotnet")

#? For access to bins in npm
#prepend_path("$HOME/AppData/Roaming/npm")


#? Ripgrep
prepend_path("$TOOLS_PATH/ripgrep")


#? bat
prepend_path("$TOOLS_PATH/bat")


# Re-source in case new aliases can be installed.
#------------------------------------------------------------------------------
. $PSScriptRoot/aliases.ps1
. $PSScriptRoot/functions.ps1


# Install and import modules
setup-modules

# Ignore history commands getting stored that are just noise.
Set-PSReadLineOption -AddToHistoryHandler {
  param($command)
  if (
    $false -and
    (
      $command -like 'cd [~|.\|./|../|..\|..|..\]*' -or
      $command -like 'mkdir *' -or
      $command -like 'ls *' -or
      $command -like 'dotnet [build|restore|clean]' -or
      $command -like 'history|history-open' -or
      $command -like 'echo *' -or
      $command -like 'cat *'
    )
  ) {
    return $false
  }
  return $true
}
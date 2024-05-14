#-----------------------------------------------------------------------------------------
# README
#
# Description: 
#   Prepends a path for binary access to the users PATH
#   Only for the terminal session. Made for use within your powershell profile
#-----------------------------------------------------------------------------------------
[CmdletBinding()]
param(
  [string]$pathToAdd
)
if (Test-Path -Path $pathToAdd) {
  $path_old = $env:PATH;
  $env:PATH = "$pathToAdd;" + $path_old;
}

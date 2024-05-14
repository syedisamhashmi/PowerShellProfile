#--------------------------------------------------------------------------------------------------------
# README
#
# Description: 
#   Adds any and all csproj files to the sln in the current directory
#   (or another directory if one is specified via the `start` flag)
#   and then all children directories recursively.
#   
# Note: 
#   Calling this from a high point in the file tree may require killing the process.
# 
# Example:
#   populate-sln.ps1
#   or
#   populate-sln
#   or
#   populate-sln ./child-directory/subdir
#
#--------------------------------------------------------------------------------------------------------
[CmdletBinding()]
param (
  [Parameter()]
  [string] $start
)

# Start at the specified start
$startingDir = $start
# If no start specified, start at the current working directory.
if ($startingDir -eq $null) {
  $startingDir = $cwd
}

$ignoredDirectories = @(
  "bin",
  "obj",
  ".bin",
  ".vscode",
  ".net6.0",
  "win",
  "lib",
  "libwin-x64",
  "win-x86",
  "azure-pipelines",
  "Properties",
  "dist",
  "node_modules"
)

function AddDirectoryCsprojToSlnRecursive($dirName) {
  # Get all files ending with csproj or directories in "dirName"  
  $csprojFilesAndDirs = dir $dirName | Where-Object { $_.FullName.EndsWith(".csproj") -or $_.psiscontainer}
  $csprojFilesAndDirs | ForEach-Object {
    # If the file ends with csproj
    if ($_.FullName.EndsWith(".csproj"))
    {
      echo "Adding csproj '$_' to sln"
      # Attempt to add to sln
      dotnet sln add $_.FullName
    }
    # If it is a directory, recurse into it.
    if ($_.psiscontainer) {
      # Almost a 100% chance no csproj we care about will be in these dirs
      # Just a small optimization
      if ($ignoredDirectories.Contains($_.Name)) {
        return
      }
      AddDirectoryCsprojToSlnRecursive $_
    }  
  }
}

Push-Location $startingDir
$startingDir = $cwd
AddDirectoryCsprojToSlnRecursive $startingDir
Pop-Location
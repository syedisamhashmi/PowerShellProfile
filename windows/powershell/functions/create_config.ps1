[CmdletBinding()]

$location=$PSScriptRoot
Push-Location $location
$gitRepoDir = git rev-parse --show-toplevel 
Pop-Location

# Create config if non-existent
if (-Not(Test-Path "$gitRepoDir/windows/config.json")) {
  Write-Output "User config does not exist, creating..."
  Copy-Item "$gitRepoDir/windows/config.json.sample" -Destination "$gitRepoDir/windows/config.json" | Out-Null
  Write-Debug "User config created..."
}
else {
  Write-Debug "User config already exists..."
}

[CmdletBinding()]

$gitRepoDir = git rev-parse --show-toplevel
# Create config if non-existent
if (-Not(Test-Path "$gitRepoDir/config.json")) {
  Write-Output "User config does not exist, creating..."
  Copy-Item "$gitRepoDir/config.json.sample" -Destination "$gitRepoDir/config.json" | Out-Null
  Write-Debug "User config created..."
}
else {
  Write-Debug "User config already exists..."
}
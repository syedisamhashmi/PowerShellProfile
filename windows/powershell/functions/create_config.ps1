[CmdletBinding()]

$location = $PSScriptRoot

# Create config if non-existent
if (-Not(Test-Path "$tools_repo_path/config.json")) {
  Write-Output "User config does not exist, creating..."
  Copy-Item "$tools_repo_path/config.json.sample" -Destination "$tools_repo_path/config.json" | Out-Null
  Write-Debug "User config created..."
}
else {
  Write-Debug "User config already exists..."
}
[CmdletBinding()]
param(
)

if ($tools_repo_path -eq $null) {
  $tools_repo_path = "$PSScriptRoot/../..";
}

# Create config if non-existent or empty
if (
  -Not(Test-Path "$tools_repo_path/config.json") -or
  [string]::IsNullOrEmpty((Get-Content -Path "$tools_repo_path/config.json"))
) {
  Write-Output "User config does not exist, creating..."
  Copy-Item "$tools_repo_path/config.json.sample" -Destination "$tools_repo_path/config.json" | Out-Null
  Write-Debug "User config created..."
}
else {
  Write-Debug "User config already exists..."
}
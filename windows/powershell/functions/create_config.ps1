[CmdletBinding()]
param(
)

if ($config -ne $null) {
  return
}

if ($MyInvocation.InvocationName -ne ".") {
  $tools_repo_path = "$PSScriptRoot/../..";
  . $tools_repo_path/powershell/functions/prepend_path.ps1 "$PSScriptRoot/functions"
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
  Write-Verbose "User config already exists..."
}
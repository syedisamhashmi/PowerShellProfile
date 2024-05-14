# Create PowerShell Profile if it doesn't exist.
if (-Not(Test-Path "$PROFILE")) {
  Write-Output "PowerShell profile did not exist, creating..."
  New-Item -ItemType File -Path $PROFILE | Out-Null
  Write-Output "PowerShell profile created..."
}
else {
  Write-Output "Profile found..."
}

# Create config if not found
. ./powershell/functions/create_config.ps1

# Add powershell tools to path.
$tools_path = "$PSScriptRoot".Replace("\", "/");
$tools_powershell_path = "$tools_path/powershell".Replace("\", "/");
Write-Output "Adding powershell tools to users PowerShell profile path at ($PROFILE) if not present..."
if ( -Not ((Get-Content $PROFILE) -match "$tools_powershell_path") ) {
  Write-Output "PowerShell tools not found in path..."
  Add-Content -Path $PROFILE -value ""
  Add-Content -Path $PROFILE -value ". $tools_powershell_path/init.ps1;"
  Add-Content -Path $PROFILE -value ""
  Write-Output "PowerShell tools added to path..."
  Write-Output "Reloaded profile... (if this does not work, you may need to reboot PowerShell)"
  . $PROFILE
}
else {
  Write-Output "PowerShell tools found in path..."
}

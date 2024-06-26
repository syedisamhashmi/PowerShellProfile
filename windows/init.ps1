$before = $ErrorActionPreference
$ErrorActionPreference = "SilentlyContinue"

if ($PSVersionTable.PSEdition -ne "Core") {
  Write-Error "This is not the correct powershell, use the one from the Windows store!!!!"
  Write-Error "This is not the correct powershell, use the one from the Windows store!!!!"
  Write-Error "This is not the correct powershell, use the one from the Windows store!!!!"
  exit 1;
}

# Create PowerShell Profile if it doesn't exist.
if (-Not(Test-Path "$PROFILE")) {
  Write-Host "PowerShell profile did not exist, creating..."
  New-Item -ItemType File -Path "$PROFILE" -Force | Out-Null
  Write-Host "PowerShell profile created..."
}
else {
  Write-Host "Profile found..."
}

# Create config if not found
. $PSScriptRoot/powershell/functions/create_config.ps1

# Add powershell tools to path.
$tools_path = "$PSScriptRoot".Replace("\", "/");
$tools_powershell_path = "$tools_path/powershell".Replace("\", "/");
Write-Host "Adding powershell tools to users PowerShell profile path at ($PROFILE) if not present..."
if ( -Not ((Get-Content "$PROFILE") -match "$tools_powershell_path") ) {
  Write-Host "PowerShell tools not found in path..."
  Add-Content -Path "$PROFILE" -value ""
  Add-Content -Path "$PROFILE" -value ". $tools_powershell_path/init.ps1;"
  Add-Content -Path "$PROFILE" -value ""
  Write-Host "PowerShell tools added to path..."
  Write-Host "Reloaded profile... (if this does not work, you may need to reboot PowerShell)"
  . "$PROFILE"
}
else {
  Write-Host "PowerShell tools found in path..."
}

$ErrorActionPreference = $before
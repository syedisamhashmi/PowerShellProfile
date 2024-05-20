[CmdletBinding()]
param(
  [string]$package
)

if (
  -Not(
    Get-InstalledModule -Name $package  -errorAction SilentlyContinue
  )
) {
  Write-Information "Package $package is missing... Installing $package..."
  Install-Module $package
}
Import-Module $package
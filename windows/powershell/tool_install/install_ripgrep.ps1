[CmdletBinding()]
param(
  [switch]$forceInstall
)

if ($tools_repo_path -eq $null) {
  $tools_repo_path = "$PSScriptRoot/../..";
}

# Add install preferences if not present
$config = Get-Content -Path "$tools_repo_path/config.json" | ConvertFrom-Json

# Ripgrep installation
prepend_path "$tools_install_path/ripgrep"
$rgInstalled = Get-Command rg -errorAction SilentlyContinue
if (-not $forceInstall -and $rgInstalled) {
  Write-Debug "rg installed, nice!"
}
else {
  Write-Debug "rg not installed"
  $config = Get-Content -Path "$tools_repo_path/config.json" | ConvertFrom-Json
  if (-not ("RejectedRipgrep" -in $config.InstallPreferences.PSobject.Properties.Name)) {
    Write-Debug "RejectedRipgrep not found"
    Add-Member -Force -InputObject $config.InstallPreferences -NotePropertyName RejectedRipgrep -NotePropertyValue $false
    $config | ConvertTo-Json | Out-File -FilePath "$tools_repo_path/config.json"
  }
  else {
    Write-Debug "RejectedRipgrep found"
  }

  if ($forceInstall -or (-not ($config.InstallPreferences.RejectedRipgrep)))
  {
    $toolInstallTitle = "Install ``ripgrep`` to your tools?"
    $toolInstallDescription = "You have not installed ripgrep. This might be necessary for certain tools. Install it?"
    $toolInstallDefaultChoices = @(
      [System.Management.Automation.Host.ChoiceDescription]::new("&YES", "Install rg")
      [System.Management.Automation.Host.ChoiceDescription]::new("&NO", "I will accept responsibility for installing it on my own...")
    )
    $toolInstallDecision = $Host.UI.PromptForChoice(
      $toolInstallTitle,
      $toolInstallDescription,
      $toolInstallDefaultChoices,
      -1
    )
    # They are cool with me installing it.
    if ($toolInstallDecision -eq 0) {
      if (Test-Path -PathType Container -Path "$tools_install_path/ripgrep") {
        Remove-Item -Recurse -Force -Path "$tools_install_path/ripgrep"
      }
      Invoke-WebRequest -Uri https://github.com/BurntSushi/ripgrep/releases/download/14.1.0/ripgrep-14.1.0-x86_64-pc-windows-gnu.zip -OutFile "$tools_install_path/ripgrep.zip"
      Expand-Archive -Force -Path "$tools_install_path/ripgrep.zip" -DestinationPath "$tools_install_path/ripgrep"
      Move-Item "$tools_install_path/ripgrep/ripgrep-14.1.0-x86_64-pc-windows-gnu/*"  "$tools_install_path/ripgrep"
      Remove-Item -Path "$tools_install_path/ripgrep/ripgrep-14.1.0-x86_64-pc-windows-gnu"
      Remove-Item -Path "$tools_install_path/ripgrep.zip"
    }
    # They will install on their own, document and never ask again.
    if ($toolInstallDecision -eq 1) {
      $config.InstallPreferences.RejectedRipgrep = $true
      $config | ConvertTo-Json | Out-File -FilePath "$tools_repo_path/config.json"
    }
  }
  else {
    Write-Debug "NOT asking to install ripgrep, they rejected previously"
  }
}

[CmdletBinding()]
param(
  [switch]$forceInstall
)

if ($tools_repo_path -eq $null) {
  $tools_repo_path = "$PSScriptRoot/../..";
}

# Add install preferences if not present
$config = Get-Content -Path "$tools_repo_path/config.json" | ConvertFrom-Json


#? Add NVM.
prepend_path "$tools_install_path/nvm"
$nvmInstalled = Get-Command nvm -errorAction SilentlyContinue
if (-not $forceInstall -and $nvmInstalled) {
  Write-Debug "nvm installed, nice!"
}
else {
  Write-Debug "nvm not installed"
  $config = Get-Content -Path "$tools_repo_path/config.json" | ConvertFrom-Json
  if (-not ("RejectedNvm" -in $config.InstallPreferences.PSobject.Properties.Name)) {
    Write-Debug "RejectedNvm not found"
    Add-Member -Force -InputObject $config.InstallPreferences -NotePropertyName RejectedNvm -NotePropertyValue $false
    $config | ConvertTo-Json | Out-File -FilePath "$tools_repo_path/config.json"
  }
  else {
    Write-Debug "RejectedNvm found"
  }

  if ($forceInstall -or (-not ($config.InstallPreferences.RejectedNvm)))
  {
    $toolInstallTitle = "Install ``nvm`` to your tools?"
    $toolInstallDescription = "You have not installed nvm. This is necessary for certain tools. Install it?"
    $toolInstallDefaultChoices = @(
      [System.Management.Automation.Host.ChoiceDescription]::new("&YES", "Install nvm")
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
      if (Test-Path -PathType Container -Path "$tools_install_path/nvm") {
        Remove-Item -Recurse -Force -Path "$tools_install_path/nvm"
      }
      Invoke-WebRequest -Uri https://github.com/coreybutler/nvm-windows/releases/download/1.1.12/nvm-noinstall.zip -OutFile "$tools_install_path/nvm.zip"
      Expand-Archive -Force -Path "$tools_install_path/nvm.zip" -DestinationPath "$tools_install_path/nvm"
      Remove-Item -Path "$tools_install_path/nvm.zip"
      Invoke-Expression "$PSScriptRoot/functions/create_symlink.ps1 -H `"$tools_install_path/nvm/use-node.ps1`" `"$tools_repo_path/powershell/scripts/use-node.ps1`""
      Invoke-Expression "$PSScriptRoot/functions/create_symlink.ps1 -H `"$tools_install_path/nvm/settings.txt`" `"$tools_repo_path/powershell/scripts/settings.txt`""
    }
    # They will install on their own, document and never ask again.
    if ($toolInstallDecision -eq 1) {
      $config.InstallPreferences.RejectedNvm = $true
      $config | ConvertTo-Json | Out-File -FilePath "$tools_repo_path/config.json"
    }
  }
  else {
    Write-Debug "NOT asking to install nvm, they rejected previously"
  }
}
prepend_path "$tools_install_path/nvm"
$nvmInstalled = Get-Command nvm -errorAction SilentlyContinue

if (
  $nvmInstalled -and 
  (Test-Path "$tools_install_path/nvm" -PathType Container)
) {
  . $tools_install_path/nvm/use-node.ps1
  Write-Debug "nvm installed, sourced use-node script"
}
if (
  $nvmInstalled -and 
  (Test-Path "$tools_install_path/nvm"  -PathType Container) -and
  (Get-ChildItem -Path "$tools_install_path/nvm" | Where-Object {$_ -match "nodejs"} | Where-Object { Test-Path -Path $_ -PathType Container }).Count -eq 0
) {
  Write-Debug "nodejs not linked"
  use-node 1>$null 2>$null 3>$null 4>$null 5>$null 6>$null
}
if (
  $nvmInstalled -and
  (Test-Path "$tools_install_path/nvm") -and
  (Get-ChildItem -Path "$tools_install_path/nvm" | Where-Object {Test-Path -Path $_ -PathType Container } | Where-Object {$_.Name -match "^v" }).Count -eq 0
) {
  Write-Output "Reminder: You need to install a version of node!"
  Write-Output "Reminder: Run something like ``nvm install 16.20.2; use-node v16.20.2;``"
}

[CmdletBinding()]
param(
  [switch]$forceInstall
)

if ($MyInvocation.InvocationName -ne ".") {
  $tools_repo_path = "$PSScriptRoot/../..";
  . $tools_repo_path/powershell/functions/prepend_path.ps1 "$PSScriptRoot/functions"
}

# Add install preferences if not present
$config = get_or_create_config_key "InstallPreferences"
$tools_install_path = $config.UserPreferences.ToolsPath

#? Add NVM.
prepend_path "$tools_install_path/nvm"
$nvmInstalled = Get-Command nvm -errorAction SilentlyContinue
if (
  -not $forceInstall -and 
  $nvmInstalled -and
  (Test-Path -PathType Container -Path "$tools_install_path/nvm")
) {
  Write-Debug "nvm installed, nice!"
}
else {
  Write-Debug "nvm not installed or force install"
  
  $config = get_or_create_config_key "InstallPreferences.RejectedNvm"
  if (
    $forceInstall -or 
    ($config.InstallPreferences.RejectedNvm -eq $null) -or 
    (-not $config.InstallPreferences.RejectedNvm)
  )
  {
    $toolInstallDecision = yes_no_prompt `
      -title "Install ``nvm`` to your tools?" `
      -description "You have not installed nvm. This is necessary for certain tools. Install it?"
      -yes "Install nvm" `
      -no "I will accept responsibility for installing it on my own...";
    # They are cool with me installing it.
    if ($toolInstallDecision -eq 0) {
      $config = get_or_create_config_key "InstallPreferences.RejectedNvm" $false
      if (Test-Path -PathType Container -Path "$tools_install_path/nvm") {
        Remove-Item -Recurse -Force -Path "$tools_install_path/nvm"
      }
      Invoke-WebRequest -Uri https://github.com/coreybutler/nvm-windows/releases/download/1.1.12/nvm-noinstall.zip -OutFile "$tools_install_path/nvm.zip"
      Expand-Archive -Force -Path "$tools_install_path/nvm.zip" -DestinationPath "$tools_install_path/nvm"
      Remove-Item -Path "$tools_install_path/nvm.zip"
      Invoke-Expression "$PSScriptRoot/../functions/create_symlink.ps1 -H `"$tools_install_path/nvm/use-node.ps1`" `"$tools_repo_path/powershell/scripts/use-node.ps1`""
      Invoke-Expression "$PSScriptRoot/../functions/create_symlink.ps1 -H `"$tools_install_path/nvm/settings.txt`" `"$tools_repo_path/powershell/scripts/settings.txt`""
    }
    # They will install on their own, document and never ask again.
    if ($toolInstallDecision -eq 1) {
      $config = get_or_create_config_key "InstallPreferences.RejectedNvm" $true
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
  Write-Host "Reminder: You need to install a version of node!"
  Write-Host "Reminder: Run something like ``nvm install 16.20.2; use-node v16.20.2;``"
}

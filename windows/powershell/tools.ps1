[CmdletBinding()]
param(
  [switch]$forceInstall
)

if ($tools_repo_path -eq $null) {
  $tools_repo_path = "$PSScriptRoot/..";
}

$toolsPathTitle = "Tools Path"
$toolsPathDescription = "You have not set your 'tools' path.`nWould you like to use the default? (c:/tools)"
$toolsPathDefaultChoices = @(
  [System.Management.Automation.Host.ChoiceDescription]::new("&YES", "Use default tools path for tool binaries. (c:/tools)")
  [System.Management.Automation.Host.ChoiceDescription]::new("&NO", "I want to put my tools elsewhere...")
)

. $PSScriptRoot/functions/create_config.ps1

$config = Get-Content -Path "$tools_repo_path/config.json" | ConvertFrom-Json
if ($config.UserPreferences.ToolsPath -eq $null) {
  Write-Debug "ToolsPath not set"

  $decision = $Host.UI.PromptForChoice(
    $toolsPathTitle,
    $toolsPathDescription,
    $toolsPathDefaultChoices,
    -1
  )
  # They are cool with default tools path, great.
  if ($decision -eq 0) {
    Add-Member -Force -InputObject $config.UserPreferences -NotePropertyName ToolsPath -NotePropertyValue "c:/tools"
    if (-not (Test-Path -PathType Container -Path "c:/tools") ) {
      New-Item -ItemType Directory -Path "c:/tools"
    }
    $config | ConvertTo-Json | Out-File -FilePath "$tools_repo_path/config.json"
  }
  # Ask for a path and test it.
  if ($decision -eq 1) {
    $isValidPath = $false
    $user_given_path = ""
    while (-not $isValidPath) {
      $user_given_path = Read-Host "Pleade provide the path for your tools binaries"
      if (Test-Path -PathType Container -Path $user_given_path) {
        $isValidPath = $true
      }
      else {
        Write-Host "Invalid path ``$user_given_path`` does not exist!"
      }
    }
    Add-Member -Force -InputObject $config.UserPreferences -NotePropertyName ToolsPath -NotePropertyValue $user_given_path

    $config | ConvertTo-Json | Out-File -FilePath "$tools_repo_path/config.json"
  }
}
else {
  Write-Debug "ToolsPath set"
}

# ----------------------------------------------------------------------------
# Ok - Now I have a place to clone all necessary tools append them to the path.
# ----------------------------------------------------------------------------

$config = Get-Content -Path "$tools_repo_path/config.json" | ConvertFrom-Json
$tools_install_path = $config.UserPreferences.ToolsPath
if (-not (Test-Path -PathType Container -Path $tools_install_path) ) {
  New-Item -ItemType Directory -Path $tools_install_path
}

if (-not (Get-Command fzf -errorAction SilentlyContinue)) {
  . $PSScriptRoot/functions/prepend_path.ps1 "$PSScriptRoot/functions"
}

# fzf installation
prepend_path "$tools_install_path/fzf"
$fzfInstalled = Get-Command fzf -errorAction SilentlyContinue
if (-not $forceInstall -and $fzfInstalled) {
  Write-Debug "fzf installed, nice!"
}
else {
  $toolInstallTitle = "Install ``fzf`` to your tools?"
  $toolInstallDescription = "You have not installed fzf. This is necessary for certain tools. Install it?"
  $toolInstallDefaultChoices = @(
    [System.Management.Automation.Host.ChoiceDescription]::new("&YES", "Install fzf")
    [System.Management.Automation.Host.ChoiceDescription]::new("&NO", "I will accept responibility for installing it on my own...")
  )
  $toolInstallDecision = $Host.UI.PromptForChoice(
    $toolInstallTitle,
    $toolInstallDescription,
    $toolInstallDefaultChoices,
    -1
  )
  # They are cool with me installing it.
  if ($toolInstallDecision -eq 0) {
    Invoke-WebRequest -Uri https://github.com/junegunn/fzf/releases/download/0.52.1/fzf-0.52.1-windows_amd64.zip -OutFile "$tools_install_path/fzf.zip"
    Expand-Archive -Force -Path "$tools_install_path/fzf.zip" -DestinationPath "$tools_install_path/fzf"
    Remove-Item -Path "$tools_install_path/fzf.zip"
  }
}

# Azure CLI installation
prepend_path "$tools_install_path/az"
prepend_path "$tools_install_path/az/bin"
$azInstalled = Get-Command az -errorAction SilentlyContinue
if (-not $forceInstall -and $azInstalled) {
  Write-Debug "az installed, nice!"
}
else {
  $toolInstallTitle = "Install ``az`` to your tools?"
  $toolInstallDescription = "You have not installed az. This is necessary for certain tools. Install it?"
  $toolInstallDefaultChoices = @(
    [System.Management.Automation.Host.ChoiceDescription]::new("&YES", "Install az")
    [System.Management.Automation.Host.ChoiceDescription]::new("&NO", "I will accept responibility for installing it on my own...")
  )
  $toolInstallDecision = $Host.UI.PromptForChoice(
    $toolInstallTitle,
    $toolInstallDescription,
    $toolInstallDefaultChoices,
    -1
  )
  # They are cool with me installing it.
  if ($toolInstallDecision -eq 0) {
    Invoke-WebRequest -Uri https://aka.ms/installazurecliwindowszipx64 -OutFile "$tools_install_path/az.zip"
    Expand-Archive -Force -Path "$tools_install_path/az.zip" -DestinationPath "$tools_install_path/az"
    Remove-Item -Path "$tools_install_path/az.zip"
  }
}

# Add git to path.
$GIT_PATH = where.exe git
$GIT_DIR = $GIT_PATH | Split-Path -Parent | Split-Path -Parent
#? add the usr/bin tools to the path.
prepend_path($GIT_DIR + "/usr/bin")


#? Add NVM.
prepend_path "$tools_install_path/nvm"
$nvmInstalled = Get-Command nvm -errorAction SilentlyContinue
if (-not $forceInstall -and $nvmInstalled) {
  Write-Debug "nvm installed, nice!"
}
else {
  $toolInstallTitle = "Install ``nvm`` to your tools?"
  $toolInstallDescription = "You have not installed nvm. This is necessary for certain tools. Install it?"
  $toolInstallDefaultChoices = @(
    [System.Management.Automation.Host.ChoiceDescription]::new("&YES", "Install nvm")
    [System.Management.Automation.Host.ChoiceDescription]::new("&NO", "I will accept responibility for installing it on my own...")
  )
  $toolInstallDecision = $Host.UI.PromptForChoice(
    $toolInstallTitle,
    $toolInstallDescription,
    $toolInstallDefaultChoices,
    -1
  )
  # They are cool with me installing it.
  if ($toolInstallDecision -eq 0) {
    Invoke-WebRequest -Uri https://github.com/coreybutler/nvm-windows/releases/download/1.1.12/nvm-noinstall.zip -OutFile "$tools_install_path/nvm.zip"
    Expand-Archive -Force -Path "$tools_install_path/nvm.zip" -DestinationPath "$tools_install_path/nvm"
    Remove-Item -Path "$tools_install_path/nvm.zip"
    Copy-Item "$tools_repo_path/powershell/scripts/use-node.ps1" -Destination "$tools_install_path/nvm"
    Copy-Item "$tools_repo_path/powershell/scripts/settings.txt" -Destination "$tools_install_path/nvm"
  }
}
prepend_path "$tools_install_path/nvm"
$nvmInstalled = Get-Command nvm -errorAction SilentlyContinue
if ($nvmInstalled) {
  . c:\tools\nvm\use-node.ps1
}
if (
  $nvmInstalled -and
  (Get-ChildItem -Path "$tools_install_path/nvm" | Where-Object {$_ -match "nodejs"} | Where-Object { Test-Path -Path $_ -PathType Container }).Count -eq 0
) {
  (Get-ChildItem -Path "$tools_install_path/nvm")
  use-node 1>$null 2>$null 3>$null 4>$null 5>$null 6>$null
}
if (
  $nvmInstalled -and
  (Get-ChildItem -Path "$tools_install_path/nvm" | Where-Object {Test-Path -Path $_ -PathType Container } | Where-Object {$_.Name -match "^v" }).Count -eq 0
) {
  Write-Output "Reminder: You need to install a version of node!"
  Write-Output "Reminder: Run something like ``nvm install 16.20.2; use-node v16.20.2;``"
}

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
      $user_given_path = Read-Host "Please provide the path for your tools binaries"
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

$config = Get-Content -Path "$tools_repo_path/config.json" | ConvertFrom-Json
if (-not ("InstallPreferences" -in $config.PSobject.Properties.Name)) {
  Write-Debug "InstallPreferences not found"
  Add-Member -Force -InputObject $config -NotePropertyName InstallPreferences -NotePropertyValue @{}
  $config | ConvertTo-Json | Out-File -FilePath "$tools_repo_path/config.json"
}
else {
  Write-Debug "InstallPreferences found"
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
  Write-Debug "fzf not installed or forceInstall"
  $config = Get-Content -Path "$tools_repo_path/config.json" | ConvertFrom-Json
  if (-not ("RejectedFzf" -in $config.InstallPreferences.PSobject.Properties.Name)) {
    Write-Debug "RejectedFzf not found"
    Add-Member -Force -InputObject $config.InstallPreferences -NotePropertyName RejectedFzf -NotePropertyValue $false
    $config | ConvertTo-Json | Out-File -FilePath "$tools_repo_path/config.json"
  }
  else {
    Write-Debug "RejectedFzf found"
  }

  if ($forceInstall -or (-not ($config.InstallPreferences.RejectedFzf)))
  {
    $toolInstallTitle = "Install ``fzf`` to your tools?"
    $toolInstallDescription = "You have not installed fzf. This is necessary for certain tools. Install it?"
    $toolInstallDefaultChoices = @(
      [System.Management.Automation.Host.ChoiceDescription]::new("&YES", "Install fzf")
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
      if (Test-Path -PathType Container -Path "$tools_install_path/fzf") {
        Remove-Item -Recurse -Force -Path "$tools_install_path/fzf"
      }
      Invoke-WebRequest -Uri https://github.com/junegunn/fzf/releases/download/0.52.1/fzf-0.52.1-windows_amd64.zip -OutFile "$tools_install_path/fzf.zip"
      Expand-Archive -Force -Path "$tools_install_path/fzf.zip" -DestinationPath "$tools_install_path/fzf"
      Remove-Item -Path "$tools_install_path/fzf.zip"
    }
    # They will install on their own, document and never ask again.
    if ($toolInstallDecision -eq 1) {
      $config.InstallPreferences.RejectedFzf = $true
      $config | ConvertTo-Json | Out-File -FilePath "$tools_repo_path/config.json"
    }
  } else {
    Write-Debug "NOT asking to install fzf, they rejected previously"
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
  Write-Debug "az not installed"
  $config = Get-Content -Path "$tools_repo_path/config.json" | ConvertFrom-Json
  if (-not ("RejectedAz" -in $config.InstallPreferences.PSobject.Properties.Name)) {
    Write-Debug "RejectedAz not found"
    Add-Member -Force -InputObject $config.InstallPreferences -NotePropertyName RejectedAz -NotePropertyValue $false
    $config | ConvertTo-Json | Out-File -FilePath "$tools_repo_path/config.json"
  }
  else {
    Write-Debug "RejectedAz found"
  }

  if ($forceInstall -or (-not ($config.InstallPreferences.RejectedAz)))
  {
    $toolInstallTitle = "Install ``az`` to your tools?"
    $toolInstallDescription = "You have not installed az. This is necessary for certain tools. Install it?"
    $toolInstallDefaultChoices = @(
      [System.Management.Automation.Host.ChoiceDescription]::new("&YES", "Install az")
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
      if (Test-Path -PathType Container -Path "$tools_install_path/az") {
        Remove-Item -Recurse -Force -Path "$tools_install_path/az"
      }
      Invoke-WebRequest -Uri https://aka.ms/installazurecliwindowszipx64 -OutFile "$tools_install_path/az.zip"
      Expand-Archive -Force -Path "$tools_install_path/az.zip" -DestinationPath "$tools_install_path/az"
      Remove-Item -Path "$tools_install_path/az.zip"
    }
    # They will install on their own, document and never ask again.
    if ($toolInstallDecision -eq 1) {
      $config.InstallPreferences.RejectedAz = $true
      $config | ConvertTo-Json | Out-File -FilePath "$tools_repo_path/config.json"
    }
  } else {
    Write-Debug "NOT asking to install az, they rejected previously"
  }
}

# Add git to path.
$GIT_PATH = where.exe git
$GIT_DIR = $GIT_PATH | Split-Path -Parent | Split-Path -Parent | Select-Object -Property $_ -First 1
#? add the usr/bin tools to the path.
prepend_path($GIT_DIR + "/usr/bin")


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

  if (-not ($config.InstallPreferences.RejectedRipgrep))
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
    if ($forceInstall -or ($toolInstallDecision -eq 0)) {
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

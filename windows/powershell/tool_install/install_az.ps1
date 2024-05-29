[CmdletBinding()]
param(
  [switch]$forceInstall
)

if ($tools_repo_path -eq $null) {
  $tools_repo_path = "$PSScriptRoot/../..";
}

# Add install preferences if not present
$config = Get-Content -Path "$tools_repo_path/config.json" | ConvertFrom-Json


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
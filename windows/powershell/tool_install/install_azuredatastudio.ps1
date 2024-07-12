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

# AzureDataStudio installation
prepend_path "$tools_install_path/AzureDataStudio"
$azureDataStudioInstalled = Get-Command azuredatastudio -errorAction SilentlyContinue
if (-not $forceInstall -and $azureDataStudioInstalled) {
  Write-Verbose "Azure Data Studio installed, nice!"
}
else {
  Write-Debug "Azure Data Studio not installed or forceInstall"

  $config = get_or_create_config_key "InstallPreferences.RejectedAzureDataStudio"
  if (
    $forceInstall -or
    ($config.InstallPreferences.RejectedAzureDataStudio -eq $null) -or
    (-not $config.InstallPreferences.RejectedAzureDataStudio)
  )
  {
    $toolInstallDecision = yes_no_prompt `
      -title "Install ``Azure Data Studio`` to your tools?" `
      -description "You have not installed Azure Data Studio. This is necessary for certain tools. Install it?" `
      -yes "Install Azure Data Studio" `
      -no "I will accept responsibility for installing it on my own...";
    # They are cool with me installing it.
    if ($toolInstallDecision -eq 0) {
      $config = get_or_create_config_key "InstallPreferences.RejectedAzureDataStudio" $false
      if (Test-Path -PathType Container -Path "$tools_install_path/AzureDataStudio") {
        Remove-Item -Recurse -Force -Path "$tools_install_path/AzureDataStudio"
      }
      Invoke-WebRequest -Uri https://azuredatastudio-update.azurewebsites.net/latest/win32-x64-archive/stable -OutFile "$tools_install_path/AzureDataStudio.zip"
      Expand-Archive -Force -Path "$tools_install_path/AzureDataStudio.zip" -DestinationPath "$tools_install_path/AzureDataStudio"
      Remove-Item -Path "$tools_install_path/AzureDataStudio.zip"
    }
    # They will install on their own, document and never ask again.
    if ($toolInstallDecision -eq 1) {
      $config = get_or_create_config_key "InstallPreferences.RejectedAzureDataStudio" $true
    }
  } else {
    Write-Debug "NOT asking to install Azure Data Studio, they rejected previously"
  }
}

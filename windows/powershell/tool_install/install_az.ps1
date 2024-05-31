[CmdletBinding()]
param(
  [switch]$forceInstall
)

if ($MyInvocation.InvocationName -ne ".") {
  $tools_repo_path = "$PSScriptRoot/../..";
  . $tools_repo_path/powershell/functions/prepend_path.ps1 "$PSScriptRoot/functions"
}

# Add install preferences if not present

$config = get_or_create_config_key "UserPreferences.ToolsPath"
$tools_install_path = $config.UserPreferences.ToolsPath

# Azure CLI installation
prepend_path "$tools_install_path/az"
prepend_path "$tools_install_path/az/bin"
$azInstalled = Get-Command az -errorAction SilentlyContinue
if (-not $forceInstall -and $azInstalled) {
  Write-Verbose "az installed, nice!"
}
else {
  Write-Debug "az not installed or force install"

  $config = get_or_create_config_key "InstallPreferences.RejectedAz"
  if (
    $forceInstall -or 
    ($config.InstallPreferences.RejectedAz -eq $null) -or 
    (-not $config.InstallPreferences.RejectedAz)
  )
  {
    $toolInstallDecision = yes_no_prompt `
      -title "Install ``az`` to your tools?" `
      -description "You have not installed az. This is necessary for certain tools. Install it?"
      -yes "Install az" `
      -no "I will accept responsibility for installing it on my own...";
    # They are cool with me installing it.
    if ($toolInstallDecision -eq 0) {
      $config = get_or_create_config_key "InstallPreferences.RejectedAz" $false
      if (Test-Path -PathType Container -Path "$tools_install_path/az") {
        Remove-Item -Recurse -Force -Path "$tools_install_path/az"
      }
      Invoke-WebRequest -Uri https://aka.ms/installazurecliwindowszipx64 -OutFile "$tools_install_path/az.zip"
      Expand-Archive -Force -Path "$tools_install_path/az.zip" -DestinationPath "$tools_install_path/az"
      Remove-Item -Path "$tools_install_path/az.zip"
    }
    # They will install on their own, document and never ask again.
    if ($toolInstallDecision -eq 1) {
      $config = get_or_create_config_key "InstallPreferences.RejectedAz" $true
    }
  } else {
    Write-Debug "NOT asking to install az, they rejected previously"
  }
}

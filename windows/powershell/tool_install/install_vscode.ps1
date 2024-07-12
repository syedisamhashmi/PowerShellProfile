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

# VsCode installation
prepend_path "$tools_install_path/code"
prepend_path "$tools_install_path/code-insiders"
$vsCodeInstalled = Get-Command code -errorAction SilentlyContinue
if (-not $forceInstall -and $vsCodeInstalled) {
  Write-Verbose "VS Code installed, nice!"
}
else {
  Write-Debug "VS Code not installed or forceInstall"

  $config = get_or_create_config_key "InstallPreferences.RejectedVsCode"
  if (
    $forceInstall -or
    ($config.InstallPreferences.RejectedVsCode -eq $null) -or
    (-not $config.InstallPreferences.RejectedVsCode)
  )
  {
    $toolInstallDecision = yes_no_prompt `
      -title "Install ``VS Code`` to your tools?" `
      -description "You have not installed VS Code. This is necessary for certain tools. Install it?" `
      -yes "Install VS Code" `
      -no "I will accept responsibility for installing it on my own...";
    # They are cool with me installing it.
    if ($toolInstallDecision -eq 0) {
      $config = get_or_create_config_key "InstallPreferences.RejectedVsCode" $false
      if (Test-Path -PathType Container -Path "$tools_install_path/code") {
        Remove-Item -Recurse -Force -Path "$tools_install_path/code"
	      New-Item -Force -Path "$tools_install_path/code" -ItemType Container 1>$null 2>$null 3>$null 4>$null 5>$null 6>$null
      }
      if (Test-Path -PathType Container -Path "$tools_install_path/code-insiders") {
        Remove-Item -Recurse -Force -Path "$tools_install_path/code-insiders"
	      New-Item -Force -Path "$tools_install_path/code-insiders" -ItemType Container 1>$null 2>$null 3>$null 4>$null 5>$null 6>$null
      }

      $altInstall= yes_no_prompt `
      -title "Install ``VS Code Insiders`` instead?" `
      -description "Install VS Code Insiders instead? This is highly unnecessary unless you are hyper-loser like me. Install it?" `
      -yes "Install VS Code Insiders" `
      -no "I am fine being normal...";
      if ($altInstall -eq 0) {
        Invoke-WebRequest -Uri "https://code.visualstudio.com/sha/download?build=insider&os=win32-x64-archive" -OutFile "$tools_install_path/VsCode.zip"
        Expand-Archive -Force -Path "$tools_install_path/VsCode.zip" -DestinationPath "$tools_install_path/code-insiders"
        . create_symlink.ps1 -h "$tools_install_path/code-insiders/code.exe" "$tools_install_path/code-insiders/Code - Insiders.exe"
      } else {
        Invoke-WebRequest -Uri "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-archive" -OutFile "$tools_install_path/VsCode.zip"
        Expand-Archive -Force -Path "$tools_install_path/VsCode.zip" -DestinationPath "$tools_install_path/code"
        #. create_symlink.ps1 -h "$tools_install_path/code/code.exe" "$tools_install_path/code/Code.exe"
      }
      Remove-Item -Path "$tools_install_path/VsCode.zip"
    }
    # They will install on their own, document and never ask again.
    if ($toolInstallDecision -eq 1) {
      $config = get_or_create_config_key "InstallPreferences.RejectedVsCode" $true
    }
  } else {
    Write-Debug "NOT asking to install VS Code, they rejected previously"
  }
}

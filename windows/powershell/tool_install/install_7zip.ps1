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

# 7z installation
prepend_path "$tools_install_path/7z"
$isToolInstalled = Get-Command 7z -errorAction SilentlyContinue
if (-not $forceInstall -and $isToolInstalled) {
  Write-Verbose "7z installed, nice!"
}
else {
  Write-Debug "7z not installed or force install"

  $config = get_or_create_config_key "InstallPreferences.Rejected7z"
  if (
    $forceInstall -or 
    ($config.InstallPreferences.Rejected7z -eq $null) -or 
    (-not $config.InstallPreferences.Rejected7z)
  )
  {
    $toolInstallDecision = yes_no_prompt `
      -title "Install ``7z`` to your tools?" `
      -description "You have not installed 7z. This is necessary for certain tools. Install it?" `
      -yes "Install 7z" `
      -no "I will accept responsibility for installing it on my own...";
    # They are cool with me installing it.
    if ($toolInstallDecision -eq 0) {
      $config = get_or_create_config_key "InstallPreferences.Rejected7z" $false
      if (Test-Path -PathType Container -Path "$tools_install_path/7z") {
        Remove-Item -Recurse -Force -Path "$tools_install_path/7z"
      }
      if (-not (Test-Path -PathType Container -Path "$tools_install_path/7z")) {
        New-Item -ItemType Directory -Path "$tools_install_path/7z"
      }

      Invoke-WebRequest -Uri https://www.7-zip.org/a/7zr.exe -OutFile "$tools_install_path/7z/7z.exe"
    }
    # They will install on their own, document and never ask again.
    if ($toolInstallDecision -eq 1) {
      $config = get_or_create_config_key "InstallPreferences.Rejected7z" $true
    }
  } else {
    Write-Debug "NOT asking to install 7z, they rejected previously"
  }
}

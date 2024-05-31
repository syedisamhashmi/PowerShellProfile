[CmdletBinding()]
param(
  [switch]$forceInstall
)

if ($MyInvocation.InvocationName -ne ".") {
  $tools_repo_path = "$PSScriptRoot/../..";
  . $tools_repo_path/powershell/functions/prepend_path.ps1 "$PSScriptRoot/functions"
}

$config = get_or_create_config_key "InstallPreferences"
$tools_install_path = $config.UserPreferences.ToolsPath

# Ripgrep installation
prepend_path "$tools_install_path/ripgrep"
$rgInstalled = Get-Command rg -errorAction SilentlyContinue
if (-not $forceInstall -and $rgInstalled) {
  Write-Verbose "rg installed, nice!"
}
else {
  Write-Debug "rg not installed or force install"

  $config = get_or_create_config_key "InstallPreferences.RejectedRipGrep"
  if (
    $forceInstall -or 
    ($config.InstallPreferences.RejectedRipGrep -eq $null) -or 
    (-not $config.InstallPreferences.RejectedRipgrep)
  )
  {
    $toolInstallDecision = yes_no_prompt `
      -title "Install ``ripgrep`` to your tools?" `
      -description "You have not installed ripgrep. This is necessary for certain tools. Install it?"
      -yes "Install ripgrep" `
      -no "I will accept responsibility for installing it on my own...";
    
    # They are cool with me installing it.
    if ($toolInstallDecision -eq 0) {
      $config = get_or_create_config_key "InstallPreferences.RejectedRipGrep" $false
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
      $config = get_or_create_config_key "InstallPreferences.RejectedRipGrep" $true
    }
  }
  else {
    Write-Debug "NOT asking to install ripgrep, they rejected previously"
  }
}

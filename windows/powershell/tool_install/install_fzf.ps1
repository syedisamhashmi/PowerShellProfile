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

# fzf installation
prepend_path "$tools_install_path/fzf"
$fzfInstalled = Get-Command fzf -errorAction SilentlyContinue
if (-not $forceInstall -and $fzfInstalled) {
  Write-Verbose "fzf installed, nice!"
}
else {
  Write-Debug "fzf not installed or forceInstall"
  
  $config = get_or_create_config_key "InstallPreferences.RejectedFzf"
  if (
    $forceInstall -or 
    ($config.InstallPreferences.RejectedFzf -eq $null) -or 
    (-not $config.InstallPreferences.RejectedFzf)
  )
  {
    $toolInstallDecision = yes_no_prompt `
      -title "Install ``fzf`` to your tools?" `
      -description "You have not installed fzf. This is necessary for certain tools. Install it?" `
      -yes "Install fzf" `
      -no "I will accept responsibility for installing it on my own...";
    # They are cool with me installing it.
    if ($toolInstallDecision -eq 0) {
      $config = get_or_create_config_key "InstallPreferences.RejectedFzf" $false
      if (Test-Path -PathType Container -Path "$tools_install_path/fzf") {
        Remove-Item -Recurse -Force -Path "$tools_install_path/fzf"
      }
      Invoke-WebRequest -Uri https://github.com/junegunn/fzf/releases/download/0.52.1/fzf-0.52.1-windows_amd64.zip -OutFile "$tools_install_path/fzf.zip"
      Expand-Archive -Force -Path "$tools_install_path/fzf.zip" -DestinationPath "$tools_install_path/fzf"
      Remove-Item -Path "$tools_install_path/fzf.zip"
    }
    # They will install on their own, document and never ask again.
    if ($toolInstallDecision -eq 1) {
      $config = get_or_create_config_key "InstallPreferences.RejectedFzf" $true
    }
  } else {
    Write-Debug "NOT asking to install fzf, they rejected previously"
  }
}

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

# jq installation
prepend_path "$tools_install_path/jq"
$isToolInstalled = Get-Command jq -errorAction SilentlyContinue
if (-not $forceInstall -and $isToolInstalled) {
  Write-Verbose "jq installed, nice!"
}
else {
  Write-Debug "jq not installed or force install"

  $config = get_or_create_config_key "InstallPreferences.RejectedJq"
  if (
    $forceInstall -or
    ($config.InstallPreferences.RejectedJq -eq $null) -or
    (-not $config.InstallPreferences.RejectedJq)
  )
  {
    $toolInstallDecision = yes_no_prompt `
      -title "Install ``jq`` to your tools?" `
      -description "You have not installed jq. This is necessary for certain tools. Install it?" `
      -yes "Install jq" `
      -no "I will accept responsibility for installing it on my own...";
    # They are cool with me installing it.
    if ($toolInstallDecision -eq 0) {
      $config = get_or_create_config_key "InstallPreferences.RejectedJq" $false
      if (Test-Path -PathType Container -Path "$tools_install_path/jq") {
        Remove-Item -Recurse -Force -Path "$tools_install_path/jq"
      }
      if (-not (Test-Path -PathType Container -Path "$tools_install_path/jq")) {
        New-Item -ItemType Directory -Path "$tools_install_path/jq"
      }

      Invoke-WebRequest -Uri https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-windows-amd64.exe -OutFile "$tools_install_path/jq/jq.exe"
    }
    # They will install on their own, document and never ask again.
    if ($toolInstallDecision -eq 1) {
      $config = get_or_create_config_key "InstallPreferences.Rejectedjq" $true
    }
  } else {
    Write-Debug "NOT asking to install jq, they rejected previously"
  }
}


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

# Dotnet installation
prepend_path "$tools_install_path/dotnet"
$dotnetInstalled = Get-Command dotnet -errorAction SilentlyContinue
if (
  (-not $forceInstall) -and 
  $dotnetInstalled -and 
  (Test-Path -Path "$tools_install_path/dotnet" -PathType Container)
) {
  
  $DOTNET_ROOT = "tools_install_path/dotnet"
  prepend_path "$HOME/AppData/Local/Microsoft/dotnet"
  Write-Verbose "dotnet installed, nice!"
}
else {
  Write-Debug "dotnet not installed or force install"
  
  $config = get_or_create_config_key "InstallPreferences.RejectedDotnet"
  if (
    $forceInstall -or 
    ($config.InstallPreferences.RejectedDotnet -eq $null) -or
    (-not $config.InstallPreferences.RejectedDotnet)
  )
  {
    $toolInstallDecision = yes_no_prompt `
      -title "Install ``dotnet`` to your tools?" `
      -description "You have not installed dotnet to your tools. This is necessary for certain tools. Install it?"
      -yes "Install dotnet" `
      -no "I will accept responsibility for installing it on my own...";
    # They are cool with me installing it.
    if ($toolInstallDecision -eq 0) {
      $config = get_or_create_config_key "InstallPreferences.RejectedDotnet" $false
      if (Test-Path -PathType Container -Path "$tools_install_path/dotnet") {
        Remove-Item -Recurse -Force -Path "$tools_install_path/dotnet"
      }
      if (-not (Test-Path -PathType Container -Path "$tools_install_path/dotnet")) {
        New-Item -Force -Path "$tools_install_path/dotnet" -ItemType Container 1>$null 2>$null 3>$null 4>$null 5>$null 6>$null
      }
      $DOTNET_ROOT = "tools_install_path/dotnet"
      prepend_path "$HOME/AppData/Local/Microsoft/dotnet"
      Invoke-WebRequest -Uri https://dot.net/v1/dotnet-install.ps1 -OutFile "$tools_install_path/dotnet/dotnet-install.ps1"
      Write-Output "Installing dotnet version 6.0.422..."
      Invoke-Expression "$tools_install_path/dotnet/dotnet-install.ps1 dotnet -Version 6.0.422 -InstallDir $tools_install_path/dotnet" 1>$null 2>$null 3>$null 4>$null 5>$null 6>$null
      Write-Output "Done installing dotnet version 6.0.422."
      Write-Output "To install other dotnet versions, run ``install_dotnet_version``"
    }
    # They will install on their own, document and never ask again.
    if ($toolInstallDecision -eq 1) {
      $config = get_or_create_config_key "InstallPreferences.RejectedDotnet" $true
    }
  } else {
    Write-Debug "NOT asking to install dotnet, they rejected previously"
  }
}

# Declare helper function
function install_dotnet_version (
  $version, 
  [switch]$runtime,
  [switch] $help
) {
  if ($help -eq $true)
  {
    Write-Host "NOTE: Requires `$tools_install_path/dotnet to exist and to have install-script inside it."
    Write-Host "-Version: the version to install"
    Write-Host "-Runtime: if present, only installs the runtime and not the SDK"
    Write-Host "install_dotnet_version -Version [version] [-Runtime]"
    return
  }

  $install_expression = "$tools_install_path/dotnet/dotnet-install.ps1 dotnet -Version $version -InstallDir $tools_install_path/dotnet"
  if ($runtime)
  {
    $install_expression += " -Runtime"
  }
  Invoke-Expression $install_expression
}


[CmdletBinding()]
param(
  [switch]$forceInstall
)

if ($tools_repo_path -eq $null) {
  $tools_repo_path = "$PSScriptRoot/../..";
}

# Add install preferences if not present
$config = Get-Content -Path "$tools_repo_path/config.json" | ConvertFrom-Json


# Dotnet installation
prepend_path "$tools_install_path/dotnet"
$dotnetInstalled = Get-Command dotnet -errorAction SilentlyContinue
if (
  (-not $forceInstall) -and 
  $dotnetInstalled -and 
  (Test-Path -Path "$tools_install_path/dotnet" -PathType Container)
) {
  Write-Debug "dotnet installed, nice!"
}
else {
  Write-Debug "dotnet not installed"
  $config = Get-Content -Path "$tools_repo_path/config.json" | ConvertFrom-Json
  if (-not ("RejectedDotnet" -in $config.InstallPreferences.PSobject.Properties.Name)) {
    Write-Debug "RejectedDotnet not found"
    Add-Member -Force -InputObject $config.InstallPreferences -NotePropertyName RejectedDotnet -NotePropertyValue $false
    $config | ConvertTo-Json | Out-File -FilePath "$tools_repo_path/config.json"
  }
  else {
    Write-Debug "RejectedDotnet found"
  }

  if ($forceInstall -or (-not ($config.InstallPreferences.RejectedDotnet)))
  {
    $toolInstallTitle = "Install ``dotnet`` to your tools?"
    $toolInstallDescription = "You have not installed dotnet to your tools. This is necessary for certain tools. Install it?"
    $toolInstallDefaultChoices = @(
      [System.Management.Automation.Host.ChoiceDescription]::new("&YES", "Install dotnet")
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
      if (Test-Path -PathType Container -Path "$tools_install_path/dotnet") {
        Remove-Item -Recurse -Force -Path "$tools_install_path/dotnet"
      }
      if (-not (Test-Path -PathType Container -Path "$tools_install_path/dotnet")) {
        New-Item -Force -Path "$tools_install_path/dotnet" -ItemType Container 1>$null 2>$null 3>$null 4>$null 5>$null 6>$null
      }
      Invoke-WebRequest -Uri https://dot.net/v1/dotnet-install.ps1 -OutFile "$tools_install_path/dotnet/dotnet-install.ps1"
      Write-Output "Installing dotnet version 6.0.422..."
      Invoke-Expression "$tools_install_path/dotnet/dotnet-install.ps1 dotnet -Version 6.0.422 -InstallDir $tools_install_path/dotnet" 1>$null 2>$null 3>$null 4>$null 5>$null 6>$null
      Write-Output "Done installing dotnet version 6.0.422."
      Write-Output "To install other dotnet versions, run ``install_dotnet_version``"
    }
    # They will install on their own, document and never ask again.
    if ($toolInstallDecision -eq 1) {
      $config.InstallPreferences.RejectedDotnet = $true
      $config | ConvertTo-Json | Out-File -FilePath "$tools_repo_path/config.json"
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
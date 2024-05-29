[CmdletBinding()]
param(
  [switch]$forceInstall
)

if ($tools_repo_path -eq $null) {
  $tools_repo_path = "$PSScriptRoot/../..";
}

# Add install preferences if not present
$config = Get-Content -Path "$tools_repo_path/config.json" | ConvertFrom-Json

# fzf installation
prepend_path "$tools_install_path/fzf"
$fzfInstalled = Get-Command fzf -errorAction SilentlyContinue
if (-not $forceInstall -and $fzfInstalled) {
  Write-Debug "fzf installed, nice!"
}
else {
  Write-Debug "fzf not installed or forceInstall"
  $config = Get-Content -Path "$tools_repo_path/config.json" | ConvertFrom-Json
  if (-not ("RejectedFzf" -in $config.InstallPreferences.PSobject.Properties.Name)) {
    Write-Debug "RejectedFzf not found"
    Add-Member -Force -InputObject $config.InstallPreferences -NotePropertyName RejectedFzf -NotePropertyValue $false
    $config | ConvertTo-Json | Out-File -FilePath "$tools_repo_path/config.json"
  }
  else {
    Write-Debug "RejectedFzf found"
  }

  if ($forceInstall -or (-not ($config.InstallPreferences.RejectedFzf)))
  {
    $toolInstallTitle = "Install ``fzf`` to your tools?"
    $toolInstallDescription = "You have not installed fzf. This is necessary for certain tools. Install it?"
    $toolInstallDefaultChoices = @(
      [System.Management.Automation.Host.ChoiceDescription]::new("&YES", "Install fzf")
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
      if (Test-Path -PathType Container -Path "$tools_install_path/fzf") {
        Remove-Item -Recurse -Force -Path "$tools_install_path/fzf"
      }
      Invoke-WebRequest -Uri https://github.com/junegunn/fzf/releases/download/0.52.1/fzf-0.52.1-windows_amd64.zip -OutFile "$tools_install_path/fzf.zip"
      Expand-Archive -Force -Path "$tools_install_path/fzf.zip" -DestinationPath "$tools_install_path/fzf"
      Remove-Item -Path "$tools_install_path/fzf.zip"
    }
    # They will install on their own, document and never ask again.
    if ($toolInstallDecision -eq 1) {
      $config.InstallPreferences.RejectedFzf = $true
      $config | ConvertTo-Json | Out-File -FilePath "$tools_repo_path/config.json"
    }
  } else {
    Write-Debug "NOT asking to install fzf, they rejected previously"
  }
}
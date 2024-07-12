[CmdletBinding()]
param(
  [switch]$forceInstall
)

if (
  -not $forceInstall -and
  $MyInvocation.InvocationName -ne "."
) {
  $tools_repo_path = "$PSScriptRoot/../..";
  . $tools_repo_path/powershell/functions/prepend_path.ps1 "$PSScriptRoot/functions"
}

# it really `should` be Microsoft.WindowsTerminal_8wekyb3d8bbwe
# but i dont want to hardcode that
$windowsTerminalDir = (ls "$HOME/AppData/Local/Packages/Microsoft.WindowsTerminal*" | Select-Object -Property Name -First 1).Name
$settingsFile = "$HOME/AppData/Local/Packages/$windowsTerminalDir/LocalState/settings.json"
if (-not $forceInstall -and -not (Test-Path -PathType Leaf -Path $settingsFile) ) {
  Write-Host "Settings file NOT found! Do you have the proper Windows store powershell installed?"
  return;
}
$settingJsonObject = (Get-Content $settingsFile) | ConvertFrom-Json

$defaultProfile = $settingJsonObject.defaultProfile
$powershellCore = $settingJsonObject.profiles.list | Where-Object -Property source -Match "Windows.Terminal.PowershellCore" | Select-Object -First 1

if ( $defaultProfile.ToString() -ne "$($powershellCore.guid)") {
  Write-Host "Default profile NOT set properly"

  $config = $null
  if (-not $forceInstall) {
    $config = get_or_create_config_key "InstallPreferences.RejectedDefaultTerminal"
  }
  if (
    $forceInstall -or
    ($config.InstallPreferences.RejectedDefaultTerminal -eq $null) -or
    (-not $config.InstallPreferences.RejectedDefaultTerminal)
  )
  {
    $toolInstallDecision = $null
    if (-not $forceInstall)
    {
      $toolInstallDecision = yes_no_prompt `
        -title "Set your default terminal to the proper powershell?" `
        -description "Your powershell does not default to the proper terminal, do you want me to update that?" `
        -yes "Please update my default terminal" `
        -no "I will accept responsibility for selecting my own terminal when making new sessions...";
    }

    # They are cool with me updating it.
    if ($forceInstall -or $toolInstallDecision -eq 0) {
      if ($forceInstall) {
        Write-Host("I just force installed your default profile so that you (hopefully) do not see this again.")
        Write-Host("Please open a new powershell (pwsh) and re-run the initialization script.")
      }
      if (-not $forceInstall) {
        $config = get_or_create_config_key "InstallPreferences.RejectedDefaultTerminal" $false
      }

      $settingJson = (Get-Content $settingsFile) | ConvertFrom-Json
      $settingJson.defaultProfile = "$($powershellCore.guid)"
      $updated = $settingJson | ConvertTo-Json -Depth 10
      $updated | Out-File -Encoding "UTF8" -FilePath $settingsFile
    }
    # They will install on their own, document and never ask again.
    if (-not $forceInstall -and $toolInstallDecision -eq 1) {
      $config = get_or_create_config_key "InstallPreferences.RejectedDefaultTerminal" $true
    }
  } else {
    Write-Debug "NOT asking to update terminal, they rejected previously"
  }
}

if ($tools_repo_path -eq $null) {
  $tools_repo_path = "$PSScriptRoot/..";
}

$shouldAutoHomeTitle = "Auto Home?"
$shouldAutoHomeDescription = "Would you like to automatically have your new terminals default to a directory?"
$shouldAutoHomeDefaultChoices = @(
  [System.Management.Automation.Host.ChoiceDescription]::new("&YES", "Yes, I want new terminals to default to a specified location")
  [System.Management.Automation.Host.ChoiceDescription]::new("&NO", "I want my terminal to behave 'normally', no thanks...")
)

. $PSScriptRoot/functions/create_config.ps1

$config = Get-Content -Path "$tools_repo_path/config.json" | ConvertFrom-Json

if ($config.UserPreferences.ShouldAutoHome -eq $null) {
  Write-Debug "ShouldAutoHome not set"

  $decision = $Host.UI.PromptForChoice(
    $shouldAutoHomeTitle,
    $shouldAutoHomeDescription,
    $shouldAutoHomeDefaultChoices,
    -1
  )

  # They are cool with default tools path, great.
  if ($decision -eq 0) {
    Add-Member -Force -InputObject $config.UserPreferences -NotePropertyName ShouldAutoHome -NotePropertyValue $true
    $config | ConvertTo-Json | Out-File -FilePath "$tools_repo_path/config.json"
  }
  if ($decision -eq 1) {
    Add-Member -Force -InputObject $config.UserPreferences -NotePropertyName ShouldAutoHome -NotePropertyValue $false
    $config | ConvertTo-Json | Out-File -FilePath "$tools_repo_path/config.json"
  }
}


if (
  $config.UserPreferences.ShouldAutoHome -eq $true -and
  $config.UserPreferences.AutoHomeDirectory -eq $null
) {
  $autoHomeDirectoryTitle = "Auto Home Location?"
  $autoHomeDirectoryDescription = "Would you like to automatically have your new terminals default to ``c:/vs/``?"
  $autoHomeDirectoryDefaultChoices = @(
    [System.Management.Automation.Host.ChoiceDescription]::new("&YES", "Yes, I want my new terminals to default the same location as everyone else")
    [System.Management.Automation.Host.ChoiceDescription]::new("&NO", "I want my terminal to go to a location of my choosing...")
  )
  Write-Debug "AutoHomeDirectory not set"

  $decision = $Host.UI.PromptForChoice(
    $autoHomeDirectoryTitle,
    $autoHomeDirectoryDescription,
    $autoHomeDirectoryDefaultChoices,
    -1
  )
  # They are cool with default home path, great.
  if ($decision -eq 0) {
    # Create it if it does not exist.
    if (-not (Test-Path -PathType Container -Path "c:/vs") ) {
      New-Item -ItemType Directory -Path "c:/vs"
    }

    Add-Member -Force -InputObject $config.UserPreferences -NotePropertyName AutoHomeDirectory -NotePropertyValue "c:/vs"
    $config | ConvertTo-Json | Out-File -FilePath "$tools_repo_path/config.json"
  }
  if ($decision -eq 1) {
    $isValidPath = $false
    $user_given_path = ""
    while (-not $isValidPath) {
      $user_given_path = Read-Host "Pleade provide the path for your default terminal home"
      if (Test-Path -PathType Container -Path $user_given_path) {
        $isValidPath = $true
      }
      else {
        Write-Host "Invalid path ``$user_given_path`` does not exist!"
      }
    }
    Add-Member -Force -InputObject $config.UserPreferences -NotePropertyName AutoHomeDirectory -NotePropertyValue $user_given_path
    $config | ConvertTo-Json | Out-File -FilePath "$tools_repo_path/config.json"
  }
}

if (
  $config.UserPreferences.AutoHomeDirectory -ne $null
) {
  # Create it if it does not exist.
  if (Test-Path -PathType Container -Path $config.UserPreferences.AutoHomeDirectory) {
    if (
      ((Get-Location).tostring() -eq 'C:\WINDOWS\system32') -or
      ((Get-Location).tostring() -eq $HOME)
    ) {
      Push-Location $config.UserPreferences.AutoHomeDirectory | Out-Null
    }
  }
}
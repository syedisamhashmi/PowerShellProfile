if ($tools_repo_path -eq $null) {
  $tools_repo_path = "$PSScriptRoot/..";
}

. $PSScriptRoot/functions/create_config.ps1

$config = Get-Content -Path "$tools_repo_path/config.json" | ConvertFrom-Json

if ($config.UserPreferences.ShouldAutoHome -eq $null) {
  Write-Debug "ShouldAutoHome not set"

  $shouldAutoHomeTitle = "Auto Home?"
  $shouldAutoHomeDescription = "Would you like to automatically have your new terminals default to a directory?"
  $shouldAutoHomeDefaultChoices = @(
    [System.Management.Automation.Host.ChoiceDescription]::new("&YES", "Yes, I want new terminals to default to a specified location")
    [System.Management.Automation.Host.ChoiceDescription]::new("&NO", "I want my terminal to behave 'normally', no thanks...")
  )
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
      $user_given_path = Read-Host "Please provide the path for your default terminal home"
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


if (-not ("Editor" -in $config.UserPreferences.PSobject.Properties.Name)) {
  Write-Debug "Editor not found"
  Add-Member -Force -InputObject $config.UserPreferences -NotePropertyName Editor -NotePropertyValue $null
  $config | ConvertTo-Json | Out-File -FilePath "$tools_repo_path/config.json"
}

if ($config.UserPreferences.Editor -eq $null)
{
  Write-Debug "Editor not set"
  
  if (-not ("RejectedEditor" -in $config.InstallPreferences.PSobject.Properties.Name)) {
    Write-Debug "RejectedEditor not found"
    Add-Member -Force -InputObject $config.InstallPreferences -NotePropertyName RejectedEditor -NotePropertyValue $false
    $config | ConvertTo-Json | Out-File -FilePath "$tools_repo_path/config.json"
  }
  else {
    Write-Debug "RejectedEditor found"
  }

  if (-not $config.InstallPreferences.RejectedEditor) {
    
    $editorTitle = "Editor?"
    $editorDescription = "Would you like to specify an editor? (`$EDITOR environment variable, some scripts may use this) "
    $editorDefaultChoices = @(
      [System.Management.Automation.Host.ChoiceDescription]::new("&YES", "Yes, I want to use a specific editor")
      [System.Management.Automation.Host.ChoiceDescription]::new("&NO", "No thanks, I will do it myself...")
    )
    $decision = $Host.UI.PromptForChoice(
      $editorTitle,
      $editorDescription,
      $editorDefaultChoices,
      -1
    )
    if (
      ($decision -eq 0) -and
      (get-command code.cmd -errorAction SilentlyContinue) -ne $null
    ) {
      $codeTitle = "Editor?"
      $codeDescription = "I see you have VS Code installed, use that?"
      $codeDefaultChoices = @(
        [System.Management.Automation.Host.ChoiceDescription]::new("&YES", "Yes, I want to use VS Code")
        [System.Management.Automation.Host.ChoiceDescription]::new("&NO", "No thanks, I want to use my own...")
      )
      $codeDecision = $Host.UI.PromptForChoice(
        $codeTitle,
        $codeDescription,
        $codeDefaultChoices,
        -1
      )
      # They are cool with default tools path, great.
      if ($codeDecision -eq 0) {
        Add-Member -Force -InputObject $config.UserPreferences -NotePropertyName Editor -NotePropertyValue "code"
        $config | ConvertTo-Json | Out-File -FilePath "$tools_repo_path/config.json"
        $EDITOR=$config.UserPreferences.Editor
      }
    }
    if (
      $decision -eq 0 -and 
      $config.UserPreferences.Editor -eq $null
    ) {
      $isValidCommand = $false
      $user_given_command = ""
      while (-not $isValidCommand) {
        $user_given_command = Read-Host "Please provide the command you use for your editor"
        if (Get-Command "$user_given_command" -errorAction SilentlyContinue) {
          $isValidCommand = $true
        }
        else {
          Write-Host "Invalid command ``$user_given_command`` not found on your path!"
        }
      }
      Add-Member -Force -InputObject $config.UserPreferences -NotePropertyName Editor -NotePropertyValue $user_given_command
      $config | ConvertTo-Json | Out-File -FilePath "$tools_repo_path/config.json"
      $EDITOR=$config.UserPreferences.Editor
    }

    if ($decision -eq 1) {
      Add-Member -Force -InputObject $config.InstallPreferences -NotePropertyName RejectedEditor -NotePropertyValue $true
      $config | ConvertTo-Json | Out-File -FilePath "$tools_repo_path/config.json"
    }

  }

}
else {
  Write-Debug "Editor found"
  $EDITOR=$config.UserPreferences.Editor
}

if ($MyInvocation.InvocationName -ne ".") {
  $tools_repo_path = "$PSScriptRoot/..";
  . $tools_repo_path/powershell/functions/prepend_path.ps1 "$PSScriptRoot/functions"
}

$config = get_or_create_config_key "UserPreferences.ShouldAutoHome"
if ($config.UserPreferences.ShouldAutoHome -eq $null) {
  Write-Debug "ShouldAutoHome not set"

  $decision = yes_no_prompt `
    -title "Auto Home?" `
    -description "Would you like to automatically have your new terminals default to a directory?" `
    -yes "Yes, I want new terminals to default to a specified location" `
    -no "I want my terminal to behave 'normally', no thanks...";
    
  # They are cool with default tools path, great.
  if ($decision -eq 0) {
    get_or_create_config_key "UserPreferences.ShouldAutoHome" $true
  }
  if ($decision -eq 1) {
    get_or_create_config_key "UserPreferences.ShouldAutoHome" $false
  }
}

$config = get_or_create_config_key "UserPreferences.ShouldAutoHome"
$config = get_or_create_config_key "UserPreferences.AutoHomeDirectory"

if (
  $config.UserPreferences.ShouldAutoHome -eq $true -and
  $config.UserPreferences.AutoHomeDirectory -eq $null
) {
  Write-Debug "AutoHomeDirectory not set"
  $decision = yes_no_prompt `
    -title "Auto Home Location?" `
    -description "Would you like to automatically have your new terminals default to ``c:/vs/``?" `
    -yes "Yes, I want my new terminals to default the same location as everyone else" `
    -no "I want my terminal to go to a location of my choosing...";
  # They are cool with default home path, great.
  if ($decision -eq 0) {
    # Create it if it does not exist.
    if (-not (Test-Path -PathType Container -Path "c:/vs") ) {
      New-Item -ItemType Directory -Path "c:/vs"
    }
    $config = get_or_create_config_key "UserPreferences.AutoHomeDirectory" "c:/vs"
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
    $config = get_or_create_config_key "UserPreferences.AutoHomeDirectory" $user_given_path
  }
}
    
if ($config.UserPreferences.AutoHomeDirectory -ne $null) {
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

$config = get_or_create_config_key "UserPreferences.Editor"
if ($config.UserPreferences.Editor -eq $null)
{
  Write-Debug "Editor not set"
  
  $config = get_or_create_config_key "InstallPreferences.RejectedEditor"
  if (-not $config.InstallPreferences.RejectedEditor) {
    
    $decision = yes_no_prompt `
      -title "Editor?" `
      -description "Would you like to specify an editor? (`$EDITOR environment variable, some scripts may use this) " `
      -yes "Yes, I want to use a specific editor" `
      -no "No thanks, I will do it myself...";
    if (
      ($decision -eq 0) -and
      (get-command code.cmd -errorAction SilentlyContinue) -ne $null
    ) {
      
      $codeDecision = yes_no_prompt `
        -title "Editor?" `
        -description "I see you have VS Code installed, use that?" `
        -yes "Yes, I want to use VS Code" `
        -no "No thanks, I want to use my own...";
      
      $config = get_or_create_config_key "InstallPreferences.RejectedEditor" $false
      
      # They are cool with default tools path, great.
      if ($codeDecision -eq 0) {
        $config = get_or_create_config_key "UserPreferences.Editor" "code"
        $EDITOR =$config.UserPreferences.Editor
      }
    }
    if (
      $decision -eq 0 -and 
      $config.UserPreferences.Editor -eq $null
    ) {
      $config = get_or_create_config_key "InstallPreferences.RejectedFzf" $false
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
      $config = get_or_create_config_key "UserPreferences.Editor" $user_given_command
      $EDITOR = $config.UserPreferences.Editor
    }

    if ($decision -eq 1) {
      $config = get_or_create_config_key "InstallPreferences.RejectedEditor" $true
    }
  }
}
else {
  Write-Verbose "Editor found"
  $EDITOR = $config.UserPreferences.Editor
}

[CmdletBinding()]
param(
  [string]$configKey,
  $value
)
# Write-Verbose "Get_Or_Create_Config_Key::ConfigKey=$configKey, value=$value"

function CreateOrUpdate($object, $key, $value) {
  # Write-Verbose("CreateOrUpdate::message=Checking if leaf key exists, object=$object, key=$key, value=$value")
  # Create key if does not exist, if querying it.
  if (-not ("$key" -in $object.PSobject.Properties.Name)) {
    # Write-Verbose "message=leaf key not found, object=$object, key=$key, val=$valueToSet"
    Add-Member -InputObject $object -NotePropertyName $key -NotePropertyValue $valueToSet
    return $object
  }

  # Update key, if the current value is null
  # or if the value being set is not null
  # Prevents overwrites from queries.
  # Write-Verbose "message-leaf key found, object=$object, key=$key, currVal=$object.$key, update=$value"
  if (
    $object.$key -eq $null -or
    (
      $object.$key -ne $null -and 
      $valueToSet -ne $null
    )
  )
  {
    $object.$key = $valueToSet
  }
  return $object
}

function AddOrUpdateKeyToObject($key, $object, $valueToSet)
{
  $initialPath, $subPaths = $key
  # Handle subkey pathing. ! Recursive !
  if ($subPaths) {
    #Write-Verbose "AddOrUpdateKeyToObject::Message=Checking containercontainer, initialPath=$initialPath, subkeys=`"$subPaths`""
    if (-not ("$initialPath" -in $object.PSobject.Properties.Name)) {
      #Write-Verbose "container key not found: $initialPath"
      Add-Member -InputObject $object -NotePropertyName $initialPath -NotePropertyValue (new-Object PsObject -property @{}) 
    }
    # Write-Verbose "container val: $($object.$initialPath)"
    $currVal = AddOrUpdateKeyToObject -object $object.$initialPath -key $subPaths -valueToSet $valueToSet
    $object.$initialPath = $currVal
    return $object
  } 

  # Write-Verbose "initialPath: $initialPath, leaf key: $key, obj=$object, val=$valueToSet"
  if (-not ($key -in $object.PSobject.Properties.Name)) {
    # Write-Verbose "object=$object, leaf key not found: $key, val=$valueToSet"
    Add-Member -Force -InputObject $object -NotePropertyName $key -NotePropertyValue $valueToSet
    # Write-Verbose "object=$object, leaf key added: $key, val=$valueToSet"
    return $object
  }
  
  $object = CreateOrUpdate -object $object -key $key -valueToSet $valueToSet
  return $object
}

if ($MyInvocation.InvocationName -ne ".") {
  $tools_repo_path = "$PSScriptRoot/../..";
  . $tools_repo_path/powershell/functions/prepend_path.ps1 "$PSScriptRoot/functions"
}


# Create config if it does not exist
create_config.ps1

# Get config
if ($config -eq $null) {
  $config = Get-Content -Path "$tools_repo_path/config.json" | ConvertFrom-Json
} 

# Add key if not present
$parts = $configKey -Split "\."
$valueAdded = AddOrUpdateKeyToObject -key $parts -object $config -valueToSet $value

# Persist config
# Config is persisted at end of init, this is for running individually
if (
  $MyInvocation.InvocationName -ne "." -and 
  $MyInvocation.InvocationName -ne "get_or_create_config_key"
) {
  #Write-Host "Saving config $($MyInvocation.InvocationName)"
  $config | ConvertTo-Json | Out-File -FilePath "$tools_repo_path/config.json"
}

# Give value back
return $valueAdded
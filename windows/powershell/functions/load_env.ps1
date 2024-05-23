#--------------------------------------------------------------------------------------------------------
# README
#
# Description:
#   Loads a `.env` file into the current powershell session.
#
# Parameters:
#   Directory: A directory override to use, otherwise defaults to current directory.
#
# Run example:
#  PS C:\vs\EDHC> load_env --directory ./directory
#  PS C:\vs\EDHC> load_env
#
#--------------------------------------------------------------------------------------------------------

[CmdletBinding()]
param(
  [string]$dir = ".",
  [bool]$secure,
  [switch]$writeError
)

if (-not (test-path "$dir/.env") ) {
  if ($writeError) {
    Write-Warning "no .env file found in the current directory"
  }
  return
}

$lines = ""
if ($secure) {
  $lines = (unprotect .env).Split("`n")
}
else {
  $lines = Get-Content .env
}

$lines | ForEach-Object {
  if ($_.StartsWith('#')) {
    $skipped = $_.Substring(1)
    Write-Debug "skipping '$skipped'"

  }
  else {
    $index = $_.IndexOf("=");
    if ($index -ge 0) {
      $key = $_.Substring(0, $index);
      $val = $_.Substring($index + 1);
      [environment]::SetEnvironmentVariable(
        $key,
        $val.Trim('"')
      );
      Write-Debug "$key set to $val"
    }
  }

}

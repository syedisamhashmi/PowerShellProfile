[CmdletBinding()]
param(
  [Parameter(Position = 0, mandatory = $true)]
  [string]$symbolToMake,
  [Parameter(Position = 1, mandatory = $true)]
  [string]$originalFile,
  [switch]$h
)

$symbolToMake = $symbolToMake.Replace("\", "/");
$originalFile = $originalFile.Replace("\", "/");

Write-Output "Linking $symbolToMake to $originalFile"

# Allow symbolic links by default, hard links require -h flag.
# Workaround for non-admin access... Thanks Ross :)
if ($h) {
  start "cmd.exe" -ArgumentList "/C", `""mklink /H /D `""$symbolToMake"`" `""$originalFile"`"`"" -NoNewWindow -Wait
}
else {
  start "cmd.exe" -ArgumentList "/C", `""mklink `""$symbolToMake"`" `""$originalFile"`"`"" -NoNewWindow -Wait
}
#--------------------------------------------------------------------------------------------------------
# README
#
# Description:
#   Selects an azure tenant
#
# Requires installation of fzf: https://github.com/junegunn/fzf
# 1. Download and install latest release.
# 2. Extract zip to desired location. (ex: c:/tools/fzf)
# 3. Add location to path in your PowerShell profile.
# (your profile lives in the location found by running `echo $PROFILE`)
# ```
#   $path_old = $env:PATH;
#   $env:PATH = "c:/tools/fzf;" + $path_old;
# ```
#
# Requires installation of Azure CLI:
# https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-windows?tabs=azure-cli#install-or-update
# 1. Go to `ZIP Package`
# 2. Download the latest zip of Azure CLI.
# 2. Extract zip to desired location. (ex: c:/tools/az)
# 3. Add location to path in your PowerShell profile.
# (your profile lives in the location found by running `echo $PROFILE`)
# ```
#   $path_old = $env:PATH;
#   $env:PATH = "c:/tools/az;" + $path_old;
# ```
#
# Run example:
#  PS C:\vs> use_az_account
#
#--------------------------------------------------------------------------------------------------------
[CmdletBinding()]
param (
  [switch]$module
)

# the descending sort and fzf are a bit weird
$accounts = (az account list) | ConvertFrom-Json
$selected = $accounts.name | sort -descending | fzf | % {
  $accounts | where name -eq $_ | select -first 1
};

$selected

az account set -s "$($selected.id)"
if ($module) {
  set-azcontext -Subscription "$($selected.id)"
}
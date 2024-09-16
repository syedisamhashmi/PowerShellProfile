[CmdletBinding()]
param(
  [string] $dacpac,
  [string] $dbName,
  [string] $targetServer
)
use-az-account

if (-not $targetServer) {
  $serverQuery = "[].{n:name, l:location, rg:resourceGroup}"
  $serverList = az resource list --resource-type Microsoft.Sql/Servers --query $serverQuery -o tsv;
  $targetServer = $serverList | fzf | % {
    $_.Split("`t")[0]
  }

  $targetServer += '.database.windows.net'
}

# this requires a sql express 2019 installation
# if this command fails, ensure that you have
# opted in to the localdb feature.
# set-alias sql_package "C:/Program Files (x86)/Microsoft Visual Studio/2019/*/Common7/IDE/Extensions/Microsoft/SQLDB/DAC/150/sqlpackage.exe"
Write-Debug "Using token: $token"

$token = (az account get-access-token --resource https://database.windows.net --query accessToken -o tsv);

sqlpackage /Action:Publish `
  /SourceFile:"$dacpac" `
  /TargetServerName:$targetServer `
  /TargetDatabaseName:"$dbName" `
  /TargetTimeout:120 `
  /AccessToken:"$token" `
  /p:RebuildIndexesOfflineForDataPhase=True `
  /p:BlockOnPossibleDataLoss=false `
  /p:IncludeTransactionalScripts=true `
  /p:AllowUnsafeRowLevelSecurityDataMovement=true
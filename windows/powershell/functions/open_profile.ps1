Push-Location $PSScriptRoot
$gitRepoDir = git rev-parse --show-toplevel
Start-Process -FilePath $EDITOR -ArgumentList $gitRepoDir
Pop-Location
# Made to be added within c:/tools/npm.
# This is here (mostly) as documentation, but also so we can clean it up
# and have it work better.
# as a workaround to having to install npm as an admin
# in conjunction with nvm.
#
# Using nvm, install a node version
# and then have this placed

# This tool assumes you have nvm on your path.
# get it from here: https://0xbadcode.blob.core.windows.net/tools/nvm.zip
# it's a storage account we manage in az nonprod, it just has a silly name, definitely not malware.
#
# To use this, install a version with NVM:
# nvm install 16.20.2
#
# Then use the use-node script:
# use-node v16.20.2
#
$env:NVM_HOME = Split-Path -Parent (where.exe nvm);

# adds the nvm junction at the head of the path
$env:PATH = "$env:NVM_HOME/nodejs;" + $env:PATH + ";$env:NVM_HOME;";

function use-node ($v) {
  if (-not $env:NVM_HOME) {
    write-error "NVM_HOME not set"
    return;
  }

  # ensure the paths are correct
  $nvm_home = $env:NVM_HOME.Replace('/', '\');
  $src = [system.io.path]::combine($nvm_home, $v);
  $dest = [system.io.path]::combine($nvm_home, "nodejs");

  if (-not (test-path $src)) {
    write-error "invalid NodeJS path $path";
    return;
  }

  if (test-path $dest) {
    rm $dest
  }

  start 'cmd.exe' -ArgumentList "/C", `""mklink /J nodejs $src`"" -WorkingDirectory $nvm_home -NoNewWindow -Wait;
}

Register-ArgumentCompleter -CommandName use-node -ScriptBlock {
  param(
    $commandName,
    $parameterName,
    $wordToComplete,
    $commandAst,
    $fakeBoundParameters
  )

  (dir $env:NVM_HOME -Directory v*) | % {
    [System.Management.Automation.CompletionResult]::new($_.Name, $_.Name, 'ParameterValue', $_.Name)
  }
}
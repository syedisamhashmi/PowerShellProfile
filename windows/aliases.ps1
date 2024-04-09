if (
  Get-Command code-insiders.cmd -errorAction SilentlyContinue
) {
  Set-Alias -Name code -Value code-insiders.cmd
}

set-alias mkpr git-make-pull-request

set-alias cat bat
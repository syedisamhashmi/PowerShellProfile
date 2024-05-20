if (
  Get-Command code-insiders.cmd -errorAction SilentlyContinue
) {
  Set-Alias -Name code -Value code-insiders.cmd
}

set-alias mkpr git-make-pull-request.ps1

set-alias populate-sln $PSScriptRoot/scripts/populate-sln.ps1

set-alias cat bat

# Utils
set-alias ldenv load_env.ps1
set-alias load_env load_env.ps1

set-alias prepend_path prepend_path.ps1

set-alias check_for_update check_for_update.ps1

set-alias ln create_symlink.ps1

set-alias history open_history.ps1

set-alias profile open_profile.ps1

set-alias grep color_grep.ps1
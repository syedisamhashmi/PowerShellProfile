set-alias mkpr git-make-pull-request.ps1

# Source the generate release notes so we can alias it.
. $PSScriptRoot/scripts/generate-release-notes.ps1;
set-alias BuildReleaseNotes Build-ReleaseNotes
set-alias populate-sln $PSScriptRoot/scripts/populate_sln.ps1

# If someone runs the "./generate-release-notes.ps1", show help
# so that we can be kind of nice and backwards compatible lol
set-alias ./generate-release-notes.ps1 Show-ReleaseNotesHelpText

# Utils
set-alias ldenv load_env.ps1
set-alias load_env load_env.ps1
set-alias prepend_path prepend_path.ps1
set-alias check_for_update check_for_update.ps1

set-alias check_for_update check_for_update.ps1

set-alias ln create_symlink.ps1

set-alias open_history open_history.ps1

set-alias profile open_profile.ps1

set-alias grep color_grep.ps1

set-alias use_az_account use_az_account.ps1
set-alias use-az-account use_az_account.ps1

function coverage_clean()
{
  Get-ChildItem ./* -Recurse -Force -Include "coverage.cobertura.xml" | Remove-Item -Force
}
function coverage()
{
  coverage_clean
  dotnet test /p:CollectCoverage=true /p:CoverletOutputFormat=cobertura /p:CoverletOutput='./'
}

#? Backgrounds code when used
function code()
{
  if (
    get-command code -errorAction SilentlyContinue
  ) {
    (code $args &) 1>$null 2>$null 3>$null 4>$null 5>$null 6>$null
  }
}

set-alias chrome_debug chrome_debug.ps1
set-alias mkpr git-make-pull-request.ps1

# Source the generate release notes so we can alias it.
. $PSScriptRoot/scripts/generate-release-notes.ps1;
set-alias BuildReleaseNotes Build-ReleaseNotes
set-alias populate-sln $PSScriptRoot/scripts/populate-sln.ps1

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

set-alias history open_history.ps1

set-alias profile open_profile.ps1

set-alias grep color_grep.ps1

set-alias use_az_account use_az_account.ps1
set-alias use-az-account use_az_account.ps1
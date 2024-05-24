#--------------------------------------------------------------------------------------------------------
# README
#
# Description:
#   Formats and creates a properly formatted pull request in Azure DevOps to the specified target branch.
#
# Requires installation of `tools` from `tools.ps1`
#
# Run the init script to have this code made available to you as well as have tools set up for you.
#
# Run example:
#  PS C:\vs> mkpr main
#
#--------------------------------------------------------------------------------------------------------
param(
  [string]$target,
  [string]$description
)

# Finalize target branch selection if not specified
if ($target) {
  $branch = $target
}
else {
  $branch = git for-each-ref refs/remotes/origin/** --format='%(refname:short)' `
  | ForEach-Object { $_ -replace "origin/", "" } `
  | Sort-Object | Get-Unique `
  | fzf;
}
Write-Output "Making PR to: $branch"

# If there is a description override, don't use template content or git log.
if (-not $description) {
  # Fetch repo path from git to get template-content, if present
  $repo_path = git rev-parse --show-toplevel
  $template_path = "$repo_path/docs/pull_request_template.md"
  $template_content = ""
  $template_exists = Test-Path $template_path -PathType Leaf
  if ($template_exists) {
    $template_content = Get-Content -Path $template_path -Raw
    $template_content = $template_content.Split([Environment]::NewLine)
    $template_content = $template_content | ForEach-Object { '"{0}"' -f $_ };
  }

  # collect all the commit messages
  $git_log = git log --format='"- %s"' "origin/$branch..HEAD"
  $template_content += $git_log
}
else {
  $template_content = $description
}

$current_branch = git branch --show-current
$title = $current_branch

# Replace _TICKET_IDENTIFIER_ in template description if found.
if ($current_branch.ToString() -match "\w+-\d+") {
  $tag = $Matches[0];
  $template_content = $template_content -replace "_TICKET_IDENTIFIER_", $tag;
}

# Run az pr create command
$params = @(
  "--delete-source-branch"
  "--open"
  "--draft"
  "--target-branch"
  $branch
  "--title"
  $title
  "--description"
)
# Can't really substring without joining and resplitting - if your PR is that long, too bad.
az repos pr create @params $template_content
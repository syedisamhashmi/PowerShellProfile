$EDITOR = "vim"

#? For local dotnet install
prepend_path "$HOME/AppData/local/Microsoft/dotnet"

# TODO: Setup config for Tools path
$TOOLS_PATH = "c:/tools";
#? Ripgrep
prepend_path "$TOOLS_PATH/ripgrep"
#? bat
prepend_path "$TOOLS_PATH/bat"

install_package("posh-git")
install_package("z")


set-alias cat bat





#------------------------------------------------------------------------------
# Helper function to kill all chrome and re-run it with debug port enabled.
#? Where Chrome is installed
$CHROME_LOCATION = ""
function kill-chrome-re-run-with-debug {
  foreach ($id in (ps | Where ProcessName -eq chrome | Select Id)) {
    Stop-Process -Id $id.Id
  }
  Start-Process $CHROME_LOCATION --remote-debugging-port=9222
}

#------------------------------------------------------------------------------
function setup-modules() {
  install-package("posh-git")
  install-package("z")
}

#------------------------------------------------------------------------------
# function git-make-pull-request ($target, $description) {
#   # Finalize target branch selection if not specified
#   if ($target) {
#     $branch = $target
#   }
#   else {
#     $branch = git for-each-ref refs/remotes/origin/* --format='%(refname:short)' `
#   | ForEach-Object { $_ -replace "origin/", "" } `
#   | Sort-Object | Get-Unique `
#   | fzf;
#   }
#   Write-Output "Making PR to: $branch"

#   # If there is a description override, don't use template content or git log.
#   if (-not $description) {
#     # Fetch repo path from git to get template-content, if present
#     $repo_path = git rev-parse --show-toplevel
#     $template_path = "$repo_path/docs/pull_request_template.md"
#     $template_content = ""
#     $template_exists = Test-Path $template_path -PathType Leaf
#     if ($template_exists) {
#       $template_content = Get-Content -Path $template_path -Raw
#       $template_content = $template_content.Split([Environment]::NewLine)
#       $template_content = $template_content | ForEach-Object { '"{0} "' -f $_ };
#     }

#     # collect all the commit messages
#     $description = $template_content;
#     $description += (git log --format="- %s" "origin/$branch..HEAD") | ForEach-Object { '"{0}"' -f $_ };
#   }

#   $current_branch = git branch --show-current
#   $title = $current_branch

#   # Replace _TICKET_IDENTIFIER_ in template description if found.
#   if ($current_branch.ToString() -match "\w+-\d+") {
#     $tag = $Matches[0];
#     $description = $description.Replace("_TICKET_IDENTIFIER_", $tag);
#   }

#   # Run az pr create command
#   $params = @(
#     "--delete-source-branch"
#     "--open"
#     "--draft"
#     "--target-branch"
#     $branch
#     "--title"
#     $title
#     "--description"
#     $description.Substring(0, [math]::Min($description.Length, 3999))
#   )
#   az repos pr create @params
# }
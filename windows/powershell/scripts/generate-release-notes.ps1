# add this file from a powershell window!:
# > . ./GenerateReleaseNotes.ps1
# requires git cli

function Build-ReleaseNotes {
  Param
  (
      [Parameter(Mandatory = $false, Position = 0)]
      [string] $metadataFilePath,
      [Parameter(Mandatory = $false, Position = 1, ParameterSetName = 'RefRange')]
      [string] $refRange,
      [Parameter(Mandatory = $false, Position = 2)]
      [switch]
      $isChangesTableUpdate = $false
  )

  # try to load metadata
  If ([System.String]::IsNullOrWhiteSpace($metadataFilePath)) {
      $metadataFilePath = "$(git rev-parse --show-toplevel)/repo-projects.json";
  }
  If (!([System.IO.File]::Exists($metadataFilePath))) {
      throw "The metadata file $metadataFilePath could not be found";
  }
  # for compatability reasons with oldder powershell versions, strip comments out 
  $meta = Get-Content $metadataFilePath | where { $_ -NotMatch "^\s*\/\/ " } | ConvertFrom-Json;
  If ($null -eq $meta) {
      throw 'Could not load the metadata file';
  }
  Write-Debug $meta;

  # get ref range
  If ([System.String]::IsNullOrWhiteSpace($refRange)) {
      $refRange = Prompt-RefRange;
  }
  Write-Debug "Using commit range $refRange";

  $($notesBuilder = New-Object System.Text.StringBuilder);

  If ($isChangesTableUpdate -eq $true) {
      $changesTable = Generate-ChangesTable $meta $refRange -DontGenerateHeader;
      $notesBuilder = Append-Join "`n" $changesTable $notesBuilder
      #  $notesBuilder = $notesBuilder.AppendJoin("`n",  $(Generate-ChangesTable $meta $refRange -DontGenerateHeader));
  }
  Else {
      $notesBuilder = $notesBuilder.AppendLine( $(Get-MdSecionHeader "Release Notes" 1) );

      $notesText = Generate-NotesText $refRange;

      $notesBuilder = Append-Join "`n" $notesText $notesBuilder
      # $notesBuilder = $notesBuilder.AppendJoin("`n", $(Generate-NotesText $refRange));

      $components = Generate-ComponentsTable $meta $refRange
      $notesBuilder = Append-Join "`n" $components $notesBuilder

      $components | % { Write-Debug $_ };
      # $notesBuilder = $notesBuilder.AppendJoin("`n", $(Generate-ComponentsTable $meta $refRange));

      $changes = Generate-ChangesTable $meta $refRange;
      $notesBuilder = Append-Join "`n" $changes $notesBuilder
      # $notesBuilder = $notesBuilder.AppendJoin("`n",  $(Generate-ChangesTable $meta $refRange));
  }

  $result = $notesBuilder.ToString();

  $result;
}

#region non table data methods
function Generate-NotesText {
  Param (
      [Parameter(Mandatory)]
      [string]
      $refRange
  )
  $branch = Get-CurrentBranch;
  $newestHash = git rev-list $refRange -n 1 | Assert-Success "> git rev-list $refRange -n 1";
  $newestTag = Get-LastTag $newestHash;
  $oldestHash = git rev-list $refRange | Assert-Success "> git rev-list $refRange" | Select-Object -Last 1;
  $oldestTag = Get-LastTag $oldestHash;
  "| Key | Value |"
  "| :-- | :--: |";
  "| __Release Branch__ | ``$branch`` |";
  If (![System.String]::IsNullOrWhiteSpace($newestTag)) {
      "| __Most Recent Change Tag__ | ``$newestTag`` |";
  }
  "| __Most Recent Change Hash__ | ``$newestHash`` |";
  If (![System.String]::IsNullOrWhiteSpace($oldestTag)) {
      "| __Oldest New Change Tag__ | ``$oldestTag`` |";
  }
  "| __Oldest New Change Hash__ | ``$oldestHash`` |";
  "";
}
#endregion non table data methods

#region Generate Markdown Data Tables
function Generate-ComponentsTable {
  Param (
      [Parameter(Mandatory)]
      $metadataObject,
      [Parameter(Mandatory)]
      [string]
      $refRange,
      [Parameter()]
      [switch]
      $dontGenerateHeader = $false
  )
  If (!($metadataObject.Components) ) {
      Write-Debug 'No components found'
      return;
  }
  If ($dontGenerateHeader -ne $true) {
      Get-MdSecionHeader "Updated Components" 2
      $(Generate-MdTableHeader 'Component', 'Updated', 'Latest Version', 'Build', 'Release');
  }
  $metadataObject.Components.PSObject.Properties `
  | % {
      $scope = $_.Value;
          
      $updated = If ($scope.count -ne 0) { Get-WasUpdated $refRange $scope } Else { '' };
      $lastTag = If ($updated -eq $true) {
          "$(Get-LastTag $refRange $scope -ShowRecentTag)";
      }
      Else { '' };
      If (![System.String]::IsNullOrWhiteSpace($lastTag)) {
          $lastTag = "``$lastTag``"
      }

      [PSCustomObject]@{
          Name    = $_.Name
          Updated = "$(If($updated -eq $true) {"✅"} Else {"❌"})"
          LastTag = "$lastTag"
          Build   = ''
          Release = ''
      } } `
  | ConvertTo-MdTableRows;
  "`n";
}
function Generate-ChangesTable {
  Param (
      [Parameter(Mandatory)]
      $metadataObject,
      [Parameter(Mandatory)]
      [string]
      $refRange,
      [Parameter()]
      [switch]
      $dontGenerateHeader = $false
  )
  
  $wiLinkTemplate = If ([System.String]::IsNullOrWhiteSpace($meta.wiLink)) { '' } Else { $meta.wiLink }
  $prLinkTemplate = If ([System.String]::IsNullOrWhiteSpace($meta.prLink)) { '' } Else { $meta.prLink }
  $commitLinkTemplate = If ([System.String]::IsNullOrWhiteSpace($meta.commitLink)) { '' } Else { $meta.commitLink }
  $gitLogArguments = If ([System.String]::IsNullOrWhiteSpace($meta.gitLogArguments)) { $null } Else { $meta.gitLogArguments }

  If ($dontGenerateHeader -ne $true) {
      Get-MdSecionHeader "Included Changes" 2
      $(Generate-MdTableHeader 'Author', 'Date', 'Feature', 'Pull Request', 'Tag', 'Commit');
  }


  # starting with the git log entries, get the table content
  # use --merges switch for DB PRs when the squash strategy is not used
  $logParams = @{

  }
  Write-Debug "> git log --format=""%cs``t%H``t%an``t%ae``t%s``t%(describe)"" $gitLogArguments $refRange -- $scope"
  git log --format="%cs`t%H`t%an`t%ae`t%s`t%(describe)" $gitLogArguments $refRange -- $scope `
  | ForEach-Object { $_.Replace("|", "\|") } `
  | ConvertFrom-Csv -Delimiter "`t" -Header ("Date", "CommitId", "Author", "Email", "Subject", "Tag") `
  | ForEach-Object {
      # extract data from commit description and generate links
      #only show tag if this was the version tagged
      $lastTag = git describe --tags --abbrev=0 $_.CommitId;
      $tag = If ($_.Tag -eq $($lastTag)) { $lastTag } Else { '' };
      $date = $_.Date;
      If ($null -eq $tag) { $tag = '' }
      $prNum = If ($_.Subject -match "^Merged PR (\d+): ") {
          If ($prLinkTemplate -ne '') {
              "[$(Escape-MdCharacters($_.Subject))]($($prLinkTemplate -f $Matches[1]))"
          }
          Else { $_.Subject }
      }
      Else { $_.Subject };
      $wiNum = If ($_.Subject -match "([A-Z]{2,})-(\d+)") {
          $workItem = $Matches[1] + '-' + $Matches[2];
          If ($wiLinkTemplate -ne '') {
              $wiLinkTemplate -f $workItem
          }
          Else { $workItem }
      }
      Else { '' };
      $shortHash = git rev-parse --short $_.CommitId | Assert-Success "> git rev-parse --short $_.CommitId";
      If ($commitLinkTemplate -ne '') {
          $commit = "``$shortHash`` ([⎘]($($commitLinkTemplate -f $_.CommitId)))"
      }

      # map to table object
      [PSCustomObject]@{
          Author     = "[$($_.Author)](mailto:$($_.Email))"
          Date       = $date
          Feature    = $wiNum
          CodeReview = $prNum
          Tag        = $tag
          Commit     = $commit
      } } `
  | ConvertTo-MdTableRows;
  "`n";
}
#endregion Generate Markdown Data Tables

#region prompt methods
function Prompt-RefRange {
  #  1. verify branch up to date
  $branch = Get-CurrentBranch;
  $delta = git rev-list --count $branch...origin/$branch | Assert-Success "git rev-list --count $branch...origin/$branch";
  If ($delta -ne 0) {
      $ahead = git rev-list --left-only --count $branch...origin/$branch | Assert-Success "> git rev-list --left-only --count $branch...origin/$branch";
      $behind = git rev-list --right-only --count $branch...origin/$branch | Assert-Success "> git rev-list --right-only --count $branch...origin/$branch";
      If ($Host.UI.PromptForChoice("Your local branch $branch is $ahead commits ahead and $behind commits behind origin/$branch.", 'Would you like to update your local before proceeding?', @('&Yes'; '&No'), 1) -eq 0) {
          Write-Debug "> git pull origin $branch --ff-only"
          git pull origin $branch --ff-only 2>$null | Assert-Success "> git pull origin $branch --ff-only 2>$null" ;
      }
  }

  $rangeStart = '';
  $rangeEnd = '';
  $lastTags = git tag --sort=-taggerdate --merged $branch `
  | Assert-Success "git tag --sort=-taggerdate --merged $branch" `
  | Get-Unique `
  | Select -First 9;
  $rangeEnd = Prompt-PickCommit "Pick a tag or HEAD for the most recent change to include" | Get-FullHash;
  $rangeStart = Prompt-PickCommit "Pick a tag for begining of the range:" | Get-FullHash;

  return "$rangeStart~1..$rangeEnd";
}

function Prompt-PickCommit {
  Param (
      [Parameter(Mandatory = $true)]
      [string]
      $Title
  )

  $result = $null;

  while ($null -eq $result) {
      $result = Prompt-PickByTag $Title
      If ($null -eq $result) {
          $result = Prompt-PickByHash $Title
      }
  }

  Write-Debug "Selected tag $result"

  $result;
}
function Prompt-PickByTag {
  Param (
      [Parameter(Mandatory = $true)]
      [string]
      $Title
  )
  $options = @();
  $optIdx = 0;

  $options += New-Object Management.Automation.Host.ChoiceDescription "HE&AD", "HEAD";
  
  $branch = Get-CurrentBranch;
  $options += git tag --sort=-taggerdate --merged $branch `
  | Assert-Success "> git tag --sort=-taggerdate --merged $branch" `
  | Get-Unique `
  | Select-Object -First 10 `
  | % {
      New-Object Management.Automation.Host.ChoiceDescription "&$optIdx", $_;
      $optIdx++;
  };

  $options += New-Object Management.Automation.Host.ChoiceDescription "Enter &Manually", "Enter Hash or Tag Manually";

  Write-Host "The following tags exist on branch $branch"
  $options `
  | % {
      Write-Host "$($_.Label -replace '&', '') - $($_.HelpMessage)"
  };

  $response = $Host.UI.PromptForChoice($Title, $null, $options, 0);

  $match = switch ($response) {
      'A' { "HEAD" }
      'M' { $null }
      Default {
          $options `
          | Where-Object { $_.Label -match "&$response" } `
          | % {
              $_.HelpMessage;
          }
      }
  }

  return $match;
}
function Prompt-PickByHash {
  Param (
      [Parameter(Mandatory = $true)]
      [string]
      $Title
  )

  $Title;
  $result = $null;
  while ($null -eq $result) {
      try {
          $result = Read-Host "Enter the Hash or Tag, or 'Back' to pick by tag"
          Write-Debug "User entered the value $result";
          If ($result -match "Back") {
              return $null;
          }
          $result = $result | Get-FullHash;
      }
      catch {
          $_.Message
          $result = null;
      }
  }
  $result;
}
#endregion prompt methods

#region MarkDown Table Helpers
function Generate-MdTableHeader {
  Param (
      [Parameter(Position = 0)]
      [string[]] $values
  )
  $headers = Escape-MdCharacters($values) | % { "__$($_)__" };
  $headerLines = $headers | % { $_ -replace '.', '-' } ;
  '| ' + $($headers -join ' | ') + ' |';
  "| " + $($headerLines -join ' | ') + ' |';
}
function ConvertTo-MdTableRows {
  Param (
      [Parameter(ValueFromPipeline)]
      [PSObject[]] $input
  )
  return $input `
  | ConvertTo-Csv -Delimiter '|' -NoTypeInformation `
  | Select-Object -skip 1 `
  | % { "`"|$_|`"".Replace('"|"', ' | ').Replace('""', '"').Trim() };
}
#endregion MarkDown Table Helpers

#region markdown utility methods

# I would rather use the string builder method, but the availability of that is inconsistent based on net framework version
function Append-Join {
  Param (
      [Parameter(Mandatory, Position = 0)]
      [string]
      $separator,
      [Parameter(Mandatory, Position = 1)]
      [object[]]
      $content,
      [Parameter(Mandatory, Position = 2)]
      [System.Text.StringBuilder]
      $builder
  )
  $isFirst = $true;
  $content | % {
      if ($isFirst -eq $false) {
          $builder = $builder.Append($separator);
      }
      $builder = $builder.Append($_);
      $isFirst = $false;
  }
  return $builder;
}
function Escape-MdCharacters {
  $txt = $args[0];
  if ($null -eq $txt -or $txt -eq '') {
      return '';
  }
  return $txt -replace "([\\\`\*\{\}\[\]\(\)\#\+\!])", '\$1'
}
function Get-MdSecionHeader {
  Param (
      [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline)]
      [string]
      $Header,
      [Parameter(Position = 1)]
      [int]
      $Depth = 2
  )
  If ($Depth -lt 1) {
      $Depth = 1;
  }
  "$('#' * $Depth) __$($Header)__`n";
}
#endregion markdown utility methods

#region git utility methods
function Get-WasUpdated {
  Param (
      [Parameter(Mandatory)]
      [string]
      $refRange,
      [Parameter(Mandatory)]
      [string[]]
      $scope
  )
  
  Write-Debug "Scope: $scope";

  $repoRoot = git rev-parse --show-toplevel | Assert-Success "> git rev-parse --show-toplevel";
  $scope = $scope | % {
      Join-Path -Path $repoRoot -ChildPath $_
  };

  Write-Debug "> git rev-list $refRange -- $scope";
  $log = $($scope | % { git rev-list $refRange -- $_ } ) -join '';
  Write-Debug "Log: $log";
  $result = If ([System.String]::IsNullOrWhiteSpace($log)) { $false } Else { $true };
  return $result;
}
function Get-LastTag {
  Param (
      [Parameter(Position = 0, Mandatory)]
      [string]
      $refRange,
      [Parameter(Position = 1)]
      $scope,
      [Parameter()]
      [switch]
      $showRecentTag = $false
  )
  
  Write-Debug "> git rev-parse --show-toplevel";
  $repoRoot = git rev-parse --show-toplevel | Assert-Success "> git rev-parse --show-toplevel";
  $scope = $scope | % {
      Join-Path -Path $repoRoot -ChildPath $_
  };
  $scope = $scope -join ' ';

  Write-Debug "> git rev-list -n 1 $refRange -- $scope";
  $resultHash = If ($refRange -match "^[0-9a-f]{5,40}$") { 
      #refRange is exact match
      $refRange
  }
  Else {
      # gets most recent commit in range & scope
      git rev-list -n 1 $refRange -- $scope | Assert-Success "> git rev-list -n 1 $refRange -- $scope";
  }

  $result = '';
  try {
      $result = git describe $resultHash --tags --abbrev=0 | Assert-Success "> git describe $resultHash --tags --abbrev=0";
  }
  catch {
      Write-Debug "Could not get last tag, this is usually because there are no tags in the repository";
      return '';
  }

  IF (!$showRecentTag) {
      $fullTag = git describe $resultHash --tags | Assert-Success "> git describe $resultHash --tags";
      If ($fullTag -ne $result) {
          $result = '';
      }
  }
  return $result;
}

function Get-FullHash {
  [cmdletbinding()]
  Param(
      [parameter(
          Mandatory = $true,
          ValueFromPipeline = $true,
          Position = 0)
      ]
      $commit
  )
  Write-Debug "input: $commit";

  $result = '';

  If ($commit -eq "") {
      throw "Please specify either a commit hash (full), or a tag";
  }

  # if the supplied hash is a short hash, get the full version
  If ($commit -match "^[0-9a-f]{5,39}$") {
      Write-Debug 'Expanding Partial Hash';
      $commit = git rev-parse $commit
  }

  $result = If ($commit -match "^[0-9a-f]{40}$") {
      $commit;
  }
  ElseIf ($commit -eq 'HEAD') {
      $commit
  }
  Else {
      Write-Debug 'Looking up tag';
      Write-Debug "git log -1 ""tags/$commit"" --format=""%H"" 2>`$null";
      $(git log -1 "tags/$commit" --format="%H" 2>$null)  | Assert-Success "Could not find the tag $commit"
  }

  return $result;
}

function Get-CurrentBranch {
  git rev-parse --abbrev-ref HEAD | Assert-Success "> git rev-parse --abbrev-ref HEAD";
}
#endregion git utility methods

#region misc utility methods
function Assert-Success {
  # [CmdletBinding()]
  param(
      [Parameter(ValueFromPipeline = $true)]
      $input,

      [Parameter(Position = 0, Mandatory = $true)]
      [string] $errorMessage
  );
  

  if ($LASTEXITCODE -ne 0) {
      $input
      $errorMessage = If ([System.String]::IsNullOrWhiteSpace($errorMessage)) { "The last operation failed with an exit code of $LASTEXITCODE" } Else { $errorMessage }
      throw $errorMessage;
  }
  Else {
      # pipe input through - make usable as pipeline func w/ no changes to the value passed through
      return $input;
  }
}
#endregion misc utility methods

#region help methods
function Show-ReleaseNotesHelpText {
  Write-Host "Before using this script, checkout your release branch and get latest"
  Write-Host ""
  Write-Host "This code expects a build info file, './repo-projects.json', at the respository root"
  Write-Host "You can specify the file path in the Build-ReleaseNotes command, if found elsewhere"
  Write-Host ""
  Write-Host "If you don't have a range for the notes to cover prepared, you can specify one with either tags or the hash in interactive mode."
  Write-Host "This also pipes the output to your clipboard."
  Write-Host "> Build-ReleaseNotes | Set-Clipboard"
  Write-Host ""
  Write-Host "If you do have a range prepared, you can build release notes with the following command."
  Write-Host "In this, 581b5e2671 is the point where the prior release was split from the development branch, and up to the tip of the current branch:"
  Write-Host "> `$refRange = '581b5e26711b33b32cdf388fbde515105f84f7d2~1..HEAD'"
  Write-Host "> Build-ReleaseNotes -RefRange `$refRange | Set-Clipboard"
}
#endregion help methods
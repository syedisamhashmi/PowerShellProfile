[CmdletBinding()]
param (
  [string]$title,
  [string]$description,
  [string]$yes,
  [string]$no
)

$choices = @(
  [System.Management.Automation.Host.ChoiceDescription]::new("&YES", $yes)
  [System.Management.Automation.Host.ChoiceDescription]::new("&NO", $no)
)
$decision = $Host.UI.PromptForChoice(
  $title,
  $description,
  $choices,
  -1
)
return $decision
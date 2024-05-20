$externalGrep = Get-Command -Type Application grep
if ($MyInvocation.ExpectingInput) {
  # pipeline (stdin) input present
  # $args passes all arguments through.
  $input | & $externalGrep --color $args
}
else {
  & $externalGrep --color $args
}
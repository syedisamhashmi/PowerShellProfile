Push-Location $HOME/.vim

if (
  -Not (Test-Path ./pack)
)
{
  New-Item pack -ItemType Directory `
  1>$null 2>$null 3>$null 4>$null 5>$null 6>$null
  Write-Output "Created 'pack' directory"
}

Push-Location ./pack
if (
  -Not (Test-Path ./vendor)
)
{
  New-Item vendor -ItemType Directory `
    1>$null 2>$null 3>$null 4>$null 5>$null 6>$null
  Write-Output "Created 'vendor' directory"
}

Push-Location ./vendor
if (
  -Not (Test-Path ./opt)
)
{
  New-Item opt -ItemType Directory `
    1>$null 2>$null 3>$null 4>$null 5>$null 6>$null
  Write-Output "Created 'opt' directory"
  P
}
Push-Location ./opt

if (
  -Not (Test-Path ./nerd_tree)
)
{
  "Cloning nerdtree"
  git clone --depth 1 https://github.com/preservim/nerdtree.git nerd_tree `
    1>$null 2>$null 3>$null 4>$null 5>$null 6>$null
}
else
{
  echo "Deleting nerd_tree and recloning..."
  Remove-Item -Recurse -Force ./nerd_tree
  (git clone --depth 1 https://github.com/preservim/nerdtree.git nerd_tree) `
    1>$null 2>$null 3>$null 4>$null 5>$null 6>$null
  echo "Done cloning..."
}

Pop-Location
Pop-Location
Pop-Location
Pop-Location

if (
  -Not (Test-Path $HOME/.vimrc)
)
{
  ln -h "$HOME/.vimrc" "$powershell_path/../../arch/conf/vim/.vimrc"
}
else
{
  Write-Output "Removing link"
  rm $HOME/.vimrc
  
  Write-Output "relinking..."
  ln -h "$HOME/.vimrc" "$powershell_path/../../arch/conf/vim/.vimrc"
  Write-Output "Done relinking"
}
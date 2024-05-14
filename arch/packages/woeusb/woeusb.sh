#!/usr/bin/env bash

pushd $repos_dir_default
rm -rfd $repos_dir_default/woeusb
git clone https://aur.archlinux.org/woeusb.git
cd $repos_dir_default/woeusb
makepkg -f

#----------------------------------------------
echo "Adding woeusb to bashrc if not present."
env_str="export PATH=\$PATH:$repos_dir_default/woeusb/pkg/woeusb/usr/bin"

if ! grep -q $env_str $bashrc 
then
  echo "Adding woeusb source to $bashrc path"
  echo $'\n# Load woeusb onto path' >> $bashrc
  echo $env_str >> $bashrc
fi

popd

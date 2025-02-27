#!/usr/bin/env bash

script_directory=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

echo $'Linking .Xresources to $HOME/.Xresources\n'
ln -sf $script_directory/.Xresources $HOME/.Xresources

echo $'Linking .xinitrc to $HOME/.xinitrc\n'
ln -sf $script_directory/.xinitrc $HOME/.xinitrc

if ! [ -d "$HOME/.screenlayout" ];
then
  echo "Making directory $HOME/.screenlayout"
  mkdir $HOME/.screenlayout
fi
echo "Copying screen_layout_default.sh to $HOME/.screenlayout/screen_layout_default.sh"
ln -sf $script_directory/screen_layout_default.sh $HOME/.screenlayout/screen_layout_default.sh


echo $'Linking .xprofile to $HOME/.xprofile\n'
ln -sf $script_directory/.xprofile $HOME/.xprofile

echo $'Linking xorg.conf to $HOME/.xprofile\n'
ln -sf $script_directory/xorg.conf /etc/X11/xorg.conf

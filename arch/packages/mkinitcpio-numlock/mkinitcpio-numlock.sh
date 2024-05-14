#!/usr/bin/env bash

repos_dir_default=$HOME/repos

pushd $repos_dir_default
rm -rfd $repos_dir_default/mkinitcpio-numlock
git clone https://aur.archlinux.org/mkinitcpio-numlock.git

cd $repos_dir_default/mkinitcpio-numlock
makepkg -f
sudo pacman -U $(ls | grep tar.zst)


file_id=$(uuidgen | head -c 5)
echo "Backing up /etc/mkinitcpio.conf to /etc/mkinitcpio.bkp.$file_id"
sudo cp /etc/mkinitcpio.conf /etc/mkinitcpio.conf.bkp.$file_id

echo "Generating new configuration file"

#MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm uinput) 

new_conf_file=$(sudo sed 's/modconf kms keyboard/modconf numlock kms keyboard/' "/etc/mkinitcpio.conf")

echo "Writing new configuration file to /etc/mkinitcpio.conf"
echo "${new_conf_file}" | sudo tee /etc/mkinitcpio.conf > /dev/null

echo "Generating new initramfs.img"
sudo mkinitcpio --config /etc/mkinitcpio.conf --generate /boot/initramfs.img

popd

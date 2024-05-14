#!/usr/bin/env bash

script_directory=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

echo "Copying config to $HOME/.config/i3status/config"
mkdir -p $HOME/.config/i3status
ln -sf $script_directory/config  $HOME/.config/i3status/config 
ln -sf $script_directory/uptime.sh $HOME/.config/i3status/uptime.sh

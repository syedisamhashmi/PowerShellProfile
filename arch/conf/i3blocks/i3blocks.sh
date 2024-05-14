#!/usr/bin/env bash

script_directory=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

echo "Linking config to $HOME/.config/i3/config"
ln -sf $script_directory/config  $HOME/.config/i3blocksconfig 

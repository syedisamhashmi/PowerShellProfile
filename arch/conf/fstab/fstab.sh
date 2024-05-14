#!/bin/sh

script_directory=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
echo $"Linking fstab to $script_directory/fstab"
# CAN NOT DO THIS. THIS LIVES IN HOME DIR, WHICH IS A DIFF PARTITION, THIS IS JUST A BACKUP
#sudo ln -sf $script_directory/fstab /etc/fstab

#!/usr/bin/bash

script_directory=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

echo "Copying sddm.conf to /etc/sddm.conf"
sudo cp $script_directory/sddm.conf /etc/sddm.conf


#!/usr/bin/bash

script_directory=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

echo "Copying client.conf to $HOME/.pulse/client.conf"
cp $script_directory/client.conf  $HOME/.pulse/client.conf


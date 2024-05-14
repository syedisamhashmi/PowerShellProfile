#!/usr/bin/bash 

script_directory=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
echo "Linking crontab for prosdkr"
sudo ln -sf $script_directory/prosdkr /var/spool/cron/prosdkr 

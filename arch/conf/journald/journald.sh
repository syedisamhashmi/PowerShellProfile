#!/usr/bin/env bash

conf_path=/etc/systemd
conf_fname=journald.conf

orig_conf=$conf_path/$conf_fname

file_id=$(uuidgen | head -c 5)
conf_bkp=$conf_path/$conf_fname.bkp.$file_id

echo "Backing up $orig_conf to $conf_bkp"

sudo mv $orig_conf $conf_bkp

echo "Setting journald logs to be persistent"
sudo sh -c "cat $conf_bkp | sed 's/#Storage=auto/Storage=persistent/' > $orig_conf"

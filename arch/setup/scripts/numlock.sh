#!/usr/bin/sh

echo "Creating /usr/local/bin/numlock"
sudo sh -c "echo '#!/bin/bash
for tty in /dev/tty{1..6} 
do 
    /usr/bin/setleds -D +num < \"\$tty\"; 
done' > /usr/local/bin/numlock"

echo "Creating numlock.service"
sudo sh -c $'echo "[Unit]
description=numlock
\n[Service]
ExecStart=/usr/local/bin/numlock
StandardInput=tty
RemainAfterxit=yes
\n[Install]
WantedBy=multi-user.target" > /etc/systemd/system/numlock.service'


sudo systemctl enable numlock

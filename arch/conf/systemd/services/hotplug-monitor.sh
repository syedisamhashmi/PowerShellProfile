#!/usr/bin/env bash

USER_NAME=prosdkr
USER_ID=1000

# Export user's X-related environment variables
export DISPLAY=":0"
export XAUTHORITY="/home/${USER_NAME}/.Xauthority"
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${USER_ID}/bus"

device="card1-DP-1" 

echo "Checking monitor $device start" #| tee -a /home/prosdkr/hotplug-monitor.log

if [ $(cat /sys/class/drm/${device}/status) == "disconnected" ];
then
  echo "Monitor $device DISconnected" #| tee -a /home/prosdkr/hotplug-monitor.log
  exit	
else
  echo "Monitor $device connected" #| tee -a /home/prosdkr/hotplug-monitor.log
  
  xrandr --output "DP-0" --auto;	 
  xrandr --output "DP-2" --auto;
  xrandr --output "DP-2" --mode 5120x1440 --rate 239.76 --pos 2560x0; 
  xrandr --output "DP-0" --mode 2560x1440 --rate 59.95 --pos 0x0;	 

  i3-msg reload;
  i3-msg restart;

  xset dmps force off; 
  xset dpms force on;
  systemctl restart ratbagd;
fi

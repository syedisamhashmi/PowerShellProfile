#!/bin/sh
if [ -z "$DISPLAY" ];
then
  xinit
fi

xrandr --output "DP-0" --auto;	 
xrandr --output "DP-2" --auto;
xrandr --output "DP-2" --mode 5120x1440 --rate 239.76 --pos 2560x0; 
xrandr --output "DP-0" --mode 2560x1440 --rate 59.95 --pos 0x0;

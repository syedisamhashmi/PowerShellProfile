#!/bin/sh
if [ -z "$DISPLAY" ];
then
  xinit
fi

xrandr \
  --output DP-0 --primary --mode 5120x1440 --pos 2560x0 --rotate normal \
  --output DP-2 --mode 2560x1440 --pos 0x0 --rotate normal \

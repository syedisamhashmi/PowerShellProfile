([[ -f ~/.Xresources ]] && xrdb -load ~/.Xresources) &
numlockx &

exec /usr/share/monitor_layout_default.sh &

export LIBVA_DRIVER_NAME=nvidia

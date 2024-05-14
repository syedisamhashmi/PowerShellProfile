if ! command -v liquidctl &> /dev/null;
then
  [ $ISAMBASH_VERBOSE_ENABLED -eq 1 ] && echo "liquidctl not installed"
else
  liquidctl --match "Gigabyte RGB Fusion 2.0 5702 Controller" initialize 
  #liquidctl --match "Gigabyte RGB Fusion 2.0 5702 Controller" set led1 color fixed ff0000
  liquidctl --match "Gigabyte RGB Fusion 2.0 5702 Controller" set sync color fixed 000000  
fi
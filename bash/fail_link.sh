# What a waste of time trying to ling
# /bin/bash to /usr/bin/bash for osx and
# linux compatabilityy...
# It is write-protected... FOR GOOD REASON.
# https://stackoverflow.com/questions/32659348/operation-not-permitted-when-on-root-el-capitan-rootless-disabled/38435256#38435256

if ! [ -f /usr/bin/bash ];
then
  echo
  echo "/usr/bin/bash NOT found on your OSX..."

  if ! [ -f /bin/bash ];
  then
    echo "/bin/bash also not found... how are you here?"
    exit 1
  fi

  echo "/bin/bash WAS found on your OSX..."
  echo
  while true; do
    read -p read -p "Do you want me to link it for you? (y/n) " yn
    case $yn in
        [Yy]* ) 
          echo
          echo "Ok... Running \"ln -s /bin/bash /usr/bin/bash\""
          echo
          ln -s /bin/bash /usr/bin/bash 
          if [ $? -eq 1 ];
          then
            echo
            echo "I tried without sudo first, it did not work..."
          
            while true; do
                read -p "Can I try again with sudo? (y/n) " yn
                case $yn in
                    [Yy]* ) 
                      echo
                      echo "Ok... Running \"sudo ln -s /bin/bash /usr/bin/bash\""
                      echo
                      sudo ln -s /bin/bash /usr/bin/bash
                      if [ $? -eq 1 ];
                      then
                        echo "Still could not link it!!! Is your system write protected?"
                        exit 1
                      fi
                      break;;
                    [Nn]* ) 
                      echo
                      echo "Ok... Link it yourself and try again!"
                      exit 1;
                    # * ) 
                    #   echo "Please answer yes or no.";;
                esac
            done
          fi

          break;;

        [Nn]* ) 
          echo
          echo "Ok... Link it yourself and try again!"
          exit 1
        # * ) 
        #   echo "Please answer yes or no.";;
    esac
  done
fi
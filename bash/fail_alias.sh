
# Block comment hack so i can fold this away lol
# Wasted my time again!!!
# #!/usr/bin/env bash
# is fine and cross platform!
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
    read -p read -p "Do you want me to alias it for you? (y/n) " yn
    case $yn in
        [Yy]* ) 
          echo
          echo "Ok... Running \"alias /usr/bin/bash=/bin/bash\""
          echo
          alias /usr/bin/bash=/bin/bash
          ALIAS_RESULT=$?
          if [ $ALIAS_RESULT -ne 0 ];
          then
            echo
            echo "I tried.... Error: $ALIAS_RESULT"
            exit $ALIAS_RESULT
          fi
          break;;

        [Nn]* ) 
          echo
          echo "Ok... Alias it yourself and try again!"
          exit 1
        # * ) 
        #   echo "Please answer yes or no.";;
    esac
  done
fi
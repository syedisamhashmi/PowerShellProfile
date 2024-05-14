#!/usr/bin/bash

if [[ -z $PROFILE ]]; then
  export PROFILE="$HOME/.bashrc"
  echo "\$PROFILE unset, setting to: '$PROFILE'"
fi

if [ -f $PROFILE ]; 
then
  echo "Profile exists, checking if it is initialized..."
else
  echo "Profile does not exist, creating..."
  touch $PROFILE
fi

init_marker="# IsamBash_Init"
if grep -q "$init_marker" $PROFILE;
then
  echo "Already initialized..."
else
  echo "Profile not initialized..."
  echo "Initializing..."

  SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
  echo $init_marker >> $PROFILE
  echo "export ISAMBASH_INIT_POINT=$SCRIPT_DIR/.bashrc" >> $PROFILE
  echo "source \$ISAMBASH_INIT_POINT" >> $PROFILE
  echo "" >> $PROFILE
  echo "Initialized..."
fi

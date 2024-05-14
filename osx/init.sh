#!/usr/bin/env bash

#  TODO: do this kind of thing for linux and windows...

export repo_dir=$(git rev-parse --show-toplevel)
while true; do
  read -p read -p "Do you want me to clean up, install arch, or install OSX? (c/a/o) " cao
  case $cao in
    [Cc]* ) 
      echo "Cleaning up..."
      if [ -f $HOME/.bashrc ];
      then
        echo "Removing $HOME/.bashrc"
        rm $HOME/.bashrc
      fi
      if [ -f $HOME/.zshrc ];
      then
        echo "Removing $HOME/.zshrc"
        rm $HOME/.zshrc
      fi
      echo "All done!"
      echo
      exit 0;;

    [Aa]* ) 
      export BASH_FILE_OVERRIDE='$HOME/.zshrc'
      echo "Overriding bash file to '$BASH_FILE_OVERRIDE'"

      echo "Calling arch/init.sh..."
      echo

      source $repo_dir/arch/init.sh
      exit 0;;

    [Oo]* ) 
      echo
      echo "Ok... OSX is no longer getting updates...!"
      cp $repo_dir/osx/.zshrc $HOME/.zshrc
      exit 1;;
    # * ) 
    #   echo "Please answer yes or no.";;
  esac
done
#!/usr/bin/env bash

if [ -z $ISAMBASH_INIT_POINT ];
then
  echo "\$ISAMBASH_INIT_POINT NOT set"
  echo "Please run the init script in the repository."
  return 10
fi

export ISAMBASH_VERBOSE_ENABLED=0
while getopts "v" OPTION
do
  case $OPTION in
    v)
      ISAMBASH_VERBOSE_ENABLED=1
       ;;
  esac
done

if [ -n $BASH_FILE_OVERRIDE ];
then
  [ $ISAMBASH_VERBOSE_ENABLED -eq 1 ] && echo "Bash file override found: $BASH_FILE_OVERRIDE"
  BASH_FILE=$BASH_FILE_OVERRIDE
else
  BASH_FILE='.bashrc'
fi

# export SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export SCRIPT_DIR=$(dirname $ISAMBASH_INIT_POINT)

pushd $SCRIPT_DIR > /dev/null
export ISAMBASH_REPO_DIR=$(git rev-parse --show-toplevel)
popd> /dev/null

# Load Environment Variables
source $SCRIPT_DIR/env.sh
# Load aliases
source $SCRIPT_DIR/aliases.sh

# Set up LEDs, its fast.
source $SCRIPT_DIR/conf/liquidctl/liquidctl.sh

# Path
#-------------------------------------------------------------------
# Can you say... bootstrap!
# You gotta admit... pretty cool, eh? :)
# (if you even know what's going on, or are reading this lol)
. $SCRIPT_DIR/functions/prepend_path $SCRIPT_DIR/functions

# Load woeusb onto path
. prepend_path $HOME/repos/woeusb/pkg/woeusb/usr/bin
# # export PATH=":$PATH"

# # Add dotnet tools to path
export DOTNET_ROOT=$HOME/.dotnet
. prepend_path $DOTNET_ROOT
. prepend_path $DOTNET_ROOT/tools
# export PATH="$DOTNET_ROOT:$PATH"
# # export PATH="$DOTNET_ROOT/tools:$PATH"

# # Aseprite
# # TODO: define repos dir properly...
. prepend_path $HOME/repos/aseprite/build/bin

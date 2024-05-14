export PROFILE="$HOME/.bashrc"

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Load Environment Variables
source $SCRIPT_DIR/env.sh
# Load aliases
source $SCRIPT_DIR/aliases.sh

exec $SCRIPT_DIR/conf/liquidctl/liquidctl.sh 

# Path
#-------------------------------------------------------------------
# Load woeusb onto path
export PATH="$HOME/repos/woeusb/pkg/woeusb/usr/bin:$PATH"
# Add dotnet tools to path
export DOTNET_ROOT=$HOME/.dotnet
export PATH="$DOTNET_ROOT:$PATH"
export PATH="$DOTNET_ROOT/tools:$PATH"
# Aseprite
export PATH="$HOME/repos/aseprite/build/bin:$PATH"

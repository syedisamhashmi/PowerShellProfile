#!/bin/bash

# Add homebrew.
eval "$(/opt/homebrew/bin/brew shellenv)"

# Add dotnet.
export PATH="$HOME/.dotnet:$PATH"
export PATH="$HOME/.dotnet/tools:$PATH"
export DOTNET_ROOT="$HOME/.dotnet"

# Add kubernetes, todo: hardcoded version....
export PATH="/opt/homebrew/opt/kubernetes-cli@1.22/bin:$PATH"

# Add and set up NVM
export NVM_DIR="$HOME/.nvm"
# This loads nvm
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh" 
# This loads nvm bash_completion
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  
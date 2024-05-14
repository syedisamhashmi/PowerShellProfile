#!/usr/bin/env bash

# The entire osx folder is/will/should be deprecated
# In favord of the `arch` folder since osx and linux both have
# Respectable access to bash. check the init script here.
# Consider this your only warning and get out of this unmaintained code now.

# ACTION NECESSARY - Set path to repo containing my dotfiles.
export REPO_PATH="$HOME/vs/dotfiles";
# ACTION NECESSARY - Set path to proper OS.
export SPECIFIC_OS_FOLDER="$REPO_PATH/osx";

# Loads all the split files in the osx folder.
for file in "${SPECIFIC_OS_FOLDER}/"*.*; do
  source "${file}"
done

osx_configure

unset file
unset REPO_PATH
unset SPECIFIC_OS_FOLDER

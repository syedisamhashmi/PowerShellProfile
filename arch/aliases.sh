#!/usr/bin/env bash

# TODO: Function this
alias clearram="\
  sudo sh -c 'echo 1 > /proc/sys/vm/drop_caches';\
  sudo sh -c 'echo 2 > /proc/sys/vm/drop_caches';\
  sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches';\
"

alias reload_profile="${ISAMBASH_INIT_POINT}"

# USAGE - type `profile` to open dotfiles repo in VS Code
alias profile='code $SCRIPT_DIR'

# USAGE - `cat` to cat a file using `bat`
alias cat='bat'

# USAGE - `grep` to grep a file with color
alias grep="grep --color=always"
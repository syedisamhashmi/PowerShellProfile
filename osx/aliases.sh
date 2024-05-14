#!/bin/bash

# USAGE - type `profile` to open zshrc profile in VS Code
# Migrated
alias profile='code ~/vs/dotfiles'

# USAGE - type `tabname ["desired_name"]` to set the terminal tab's name
alias tabname=osx_tabname

# USAGE - type `newtab ["desired_name"] ["command to run"]` to open a new terminal tab, set its name, and run a command
alias newtab=osx_newtab

# USAGE - type `random ["length"]` to generate a random number.
alias random=osx_random

# USAGE - type `sendsql "query" ` to run a query against localhost sql server.
# ASSUMES ENV_VARS EXIST. CHECK `utils.sh` for more information
alias send_sql=osx_send_sql_env_vars

# USAGE - `ui` to run the local command in a package.json
alias ui=osx_run__npmlocal

# USAGE - `chrome` to run the chrome with debugging port 9222 open.
alias chrome=osx_run__chrome_debug

# USAGE - `testReport` to run a dotnet test command collecting coverage to an lcov file.
alias testReport='dotnet test /p:CollectCoverage=true /p:CoverletOutputFormat=lcov /p:CoverletOutput=./TEST.lcov.xml'

# USAGE - `sonar` to run sonar in a dotnet project against a local running sonar docker image.
alias sonar=osx_sonar;

# USAGE - `cat` to cat a file using `bat`
# Migrated
alias cat='bat'

# USAGE - `grep` to grep a file with color
# Migrated
alias grep="grep --color=always"
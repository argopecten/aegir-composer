#! /bin/bash
#
# Aegir 3.x install scripts for Debian / Ubuntu
#
# on Github: https://github.com/argopecten/aegir-composer
#
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
source "$DIR/../../aegir.cfg"

###########################################################
# Move aegir-composer directory into Aegir home
#
#   This is a workaround:
#   composer create-project cannot download into an existing directory
#
###########################################################

# target directory is the aegir home: $AEGIR_HOME
# download directory
SRC="./*"

#  move aegir-composer into aegir home
sudo su aegir -c "cp -a $SRC $AEGIR_HOME"

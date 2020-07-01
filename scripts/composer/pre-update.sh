#! /bin/bash
#
# Aegir 3.x install/update scripts for Debian / Ubuntu
#
# on Github: https://github.com/argopecten/aegir-composer
#
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
source "$DIR/common/common-functions.sh"
CONFIGDIR="$DIR/../../config"
source "$CONFIGDIR/aegir.cfg"
source "$CONFIGDIR/mariadb.cfg"
source "$CONFIGDIR/php.cfg"
source "$CONFIGDIR/postfix.cfg"

###############################################################################
# This script runs when the pre-update-cmd event is fired by composer
# functions:
# - call subsequent scripts depending on which scenario is there:
#   1) fresh install of Aegir, w/o composer.lock file, i.e. called via
#      composer create-project
#   2) update existing Aegir setup, i.e. called via composer update
#
###############################################################################

echo "ÆGIR | ------------------------------------------------------------------"
# check current setup
if [ -d "$AEGIR_HOME" ] && getent passwd aegir >/dev/null ; then
  # aegir home and aegir user exists --> it's an update scenario
  echo "ÆGIR | Preparing to update an existing Aegir setup ..."
else
  # no aegir home --> fresh install
  echo "ÆGIR | Preparing to install Aegir ..."
  bash "$DIR/lamp-config.sh" < /dev/tty
fi
echo "ÆGIR | ------------------------------------------------------------------"

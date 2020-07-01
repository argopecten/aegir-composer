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
# This script runs when the post-update-cmd event is fired by composer
# functions:
# - call subsequent scripts depending on which scenario is there:
#   1) update existing Aegir setup, i.e. called via composer update
#   2) fresh install of Aegir, w/o composer.lock file, i.e. called via
#      composer create-project
#
###############################################################################

echo "ÆGIR | ------------------------------------------------------------------"
# check current setup: if aegir home and aegir user exists --> it's an update
if [ -d "$AEGIR_HOME" ] && getent passwd aegir >/dev/null ; then
  # 1) update existing Aegir setup, i.e. called via composer update
  echo "ÆGIR | Updating existing Aegir setup ..."

  # update Aegir backend
  bash "$DIR/backend-update.sh"

  # update Aegir frontend
  bash "$DIR/frontend-update.sh"

else
  # 2) fresh install of Aegir, w/o composer.lock file, i.e. called via composer create-project
  echo "ÆGIR | Installing Aegir ..."

  # setup aegir user & home
  bash "$DIR/aegir-user.sh" < /dev/tty

  # install Aegir backend
  bash "$DIR/backend-install.sh"

  # install Aegir frontend
  bash "$DIR/frontend-install.sh"
fi
echo "ÆGIR | ------------------------------------------------------------------"

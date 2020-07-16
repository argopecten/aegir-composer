#! /bin/bash
#
# Aegir 3.x install scripts for Debian / Ubuntu
#
# on Github: https://github.com/argopecten/aegir-composer
#
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
CONFIGDIR="$DIR/../config"
source "$CONFIGDIR/aegir.cfg"

###############################################################################
# Common bash functions for Aegir install/update via composer
#
# 1) fetch the running webserver
# 2) fetch version of installed PHP
# 3) fetch new aegir version
# 4) checks whether Aegir is installed or not
#
###############################################################################

###########################################################
# 1) fetch the running webserver
fetch_webserver() {
  WS="not known any"
  if [[ `ps -acx | grep apache | wc -l` > 0 ]]; then
    WS="apache"
  fi
  if [[ `ps -acx | grep nginx | wc -l` > 0 ]]; then
    WS="nginx"
  fi
  # TODO: check variable and exit is empty
  echo $WS
}

###########################################################
# 2) fetch version of installed PHP
fetch_php_version() {
  V=`php -v | awk '/PHP 7/ {print $2}' |  cut -d. -f1-2`
  echo $V
}

###########################################################
# 3) fetch new aegir version
new_aegir_version() {
  # called during aegir install and update scenarios by various users
  HM_DIR="$HOME/$INSTALL_DIR"
  if [ `whoami` == "aegir" ]; then HM_DIR="$AEGIR_HOME"; fi
  V=`grep "version=" $HM_DIR/hostmaster/sites/all/drush/provision/provision.info | cut -d- -f2-3`
  echo $V | tee $HM_DIR/aegir_version
}

###########################################################
# 4) checks whether Aegir is installed or not
aegir_is_there() {
  if [ -d "$AEGIR_HOME" ] && getent passwd aegir >/dev/null ; then
    # aegir home and aegir user exists
    return 0
  else
    # something from Aegir is missing
    return 1
  fi
}

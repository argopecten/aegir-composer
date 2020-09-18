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
# 5) fetch the running database server
#
###############################################################################

###########################################################
# 1) fetch the running webserver
fetch_webserver() {
  #   supported webserver flavors: nginx or apache2
  SUPPORTED_WEBSERVER_FLAVORS="apache|nginx"

  if [[ `ps -acx | grep apache | wc -l` > 0 ]]; then
    WEBSERVER="apache"
  elif [[ `ps -acx | grep nginx | wc -l` > 0 ]]; then
    WEBSERVER="nginx"
  else
    WEBSERVER="something else"
  fi
    # check variable and exit if not supported
  [[ ${WEBSERVER} =~ ${SUPPORTED_WEBSERVER_FLAVORS} ]] && echo $WEBSERVER \
     || (echo "It needs to be one of $SUPPORTED_WEBSERVER_FLAVORS, but none of these has been found!" && exit 1)
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

###########################################################
# 5) fetch the running database server
fetch_dbserver() {
  #   supported database server flavors: mysql or mariadb
  SUPPORTED_DBSERVER_FLAVORS="mysql|mariadb"

  if [[ `apt list --installed  2>/dev/null | grep mariadb | wc -l` > 0 ]]; then
    DBSERVER="mariadb"
  elif [[ `apt list --installed  2>/dev/null | grep mysql | wc -l` > 0 ]]; then
    DBSERVER="mysql"
  else
    DBSERVER="something else"
  fi
  # check variable and exit if not supported
  [[ ${DBSERVER} =~ ${SUPPORTED_DBSERVER_FLAVORS} ]] && echo $DBSERVER \
     || (echo "It needs to be one of $SUPPORTED_DBSERVER_FLAVORS, but none of these has been found!" && exit 1)
}

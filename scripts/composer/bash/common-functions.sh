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
#  only activies not relying on location of aegir home!
#
# 1) fetch the running webserver
# 2) fetch version of installed PHP
# 3)
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

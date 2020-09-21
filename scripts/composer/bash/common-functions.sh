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
# 6) deploy "fix ownership & permissions" scripts
# 7) setup Drush
# 8) webserver configuragtion for Aegir
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
  [[ `whoami` == "aegir" ]] && HM_DIR="$AEGIR_HOME"

  # fetch and log Aegir version from provision.info
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

###############################################################################
# 6) webserver configuration for Aegir
config_webserver() {
    WEBSERVER=$(fetch_webserver)
    echo "ÆGIR | Enabling aegir configuration for $WEBSERVER..."
    AEGIR_CONF="$AEGIR_HOME/config/$WEBSERVER.conf"
    case "$WEBSERVER" in
        nginx)
            WEBSERVER_CONF="/etc/nginx/conf.d/aegir.conf"
            ;;
        apache)
            WEBSERVER_CONF="/etc/apache2/conf-enabled/aegir.conf"
            ;;
    esac
    [[ -f "$WEBSERVER_CONF" ]] && sudo su -c "rm $WEBSERVER_CONF"
    sudo su -c "ln -s $AEGIR_CONF $WEBSERVER_CONF"
}

###############################################################################
# 7) get hostmaster directory
get_hostmaster_dir() {
    if [ -f "$AEGIR_HOME/aegir_version" ] ; then
      AEGIR_VERSION=`cat $AEGIR_HOME/aegir_version`
    else
      # fetch new aegir version
      AEGIR_VERSION=$(new_aegir_version)
    fi
    AEGIR_HOSTMASTER="$AEGIR_HOME/hostmaster-$AEGIR_VERSION"
    echo "$AEGIR_HOSTMASTER"
}

###############################################################################
# 8) deploy "fix ownership & permissions" scripts
deploy_fix_scripts() {
    echo "ÆGIR | deploy fix ownership & permissions scripts"

    # get hostmaster directory
    AEGIR_HOSTMASTER=$(get_hostmaster_dir)

    # remove old scripts, if any
    sudo su -c "rm /usr/local/bin/fix-drupal-*.sh 2>/dev/null"
    sudo su -c "rm /etc/sudoers.d/fix-drupal-* 2>/dev/null"

    # deploy scripts
    sudo bash $AEGIR_HOSTMASTER/sites/all/modules/contrib/hosting_tasks_extra/fix_permissions/scripts/standalone-install-fix-permissions-ownership.sh

    # uncomment to see result
    # ls -la /usr/local/bin/fix-drupal-*.sh
}

###############################################################################
# 9) setup Drush
setup_drush() {
    # only if not yet setup
    [[ -f "/usr/local/bin/drush" ]] && return 0

    echo "ÆGIR | Initializing Drush ..."
    # initialize Drush with Aegir home
    DRUSH=$AEGIR_HOME/vendor/bin/drush
    sudo su - aegir -c "$DRUSH core:init  --add-path=$AEGIR_HOME --bg -y >/dev/null 2>&1"

    # add drush path for all user
    echo '#!/bin/sh
    export PATH="$PATH:$AEGIR_HOME/vendor/bin"' | sudo tee /etc/profile.d/drush.sh
    sudo su -c "chmod +x /etc/profile.d/drush.sh"

    # link drush into /usr/local/bin/drush, otherwise hosting-queued is not running
    sudo su -c "ln -s $AEGIR_HOME/vendor/bin/drush /usr/local/bin"
}

###############################################################################
# 10) configure Provision module
config_provision() {
    echo "ÆGIR | Configuring the Provision module ..."
    DRUSH_COMMANDS=/usr/share/drush/commands

    # get hostmaster directory
    AEGIR_HOSTMASTER=$(get_hostmaster_dir)

    # remove old version, if any
    [[ -d "$DRUSH_COMMANDS" ]] && sudo rm -rf $DRUSH_COMMANDS

    # link provision drush commands to site/all/drush directory
    sudo mkdir -p $DRUSH_COMMANDS
    sudo ln -s $AEGIR_HOSTMASTER/sites/all/drush/provision $DRUSH_COMMANDS

    # refresh drush cache to see provisions drush commands
    sudo su - aegir -c "drush cache:clear drush"
}

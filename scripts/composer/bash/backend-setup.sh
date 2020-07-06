#! /bin/bash
#
# Aegir 3.x install/update scripts for Debian / Ubuntu
#
# on Github: https://github.com/argopecten/aegir-composer
#
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
source "$DIR/common-functions.sh"
CONFIGDIR="$DIR/../config"
source "$CONFIGDIR/aegir.cfg"

###############################################################################
# This script runs when Aegir installed, updated or upgraded, and is called by
# post-install-cmd or post-update-cmd event of Composer
#
# functions: configure Drush, Provision and some more backend settings
#
#  - Manage webserver config to use aegir settings
#  - Prepare new hostmaster directory
#  - Deploy "fix ownership & permissions" scripts
#  - Drush configurations
#  - Configure the Provision module of Aegir
#
###############################################################################

echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | Setting up Aegir backend ..."

###############################################################################
#  - webserver config to use aegir settings
WS=$(fetch_webserver)
case "$WS" in
  nginx)
    echo "ÆGIR | Enabling aegir configuration for Nginx..."
    AEGIR_CONF_FILE="$AEGIR_HOME/config/$WS.conf"
    WEBSERVER_CONF="/etc/$WS/conf.d/aegir.conf"
    ;;

  apache)
    echo "ÆGIR | Enabling aegir configuration for Apache..."
    AEGIR_CONF_FILE=$AEGIR_HOME/config/$WS.conf
    WEBSERVER_CONF=/etc/"$WS"2/conf.d/aegir.conf
    sudo a2disconf aegir 2>/dev/null aegir
    ;;

  *) echo "ÆGIR | No webserver found, aborting!"
     exit 1
     ;;
esac
if [ -f "$WEBSERVER_CONF" ]; then sudo su -c "rm $WEBSERVER_CONF"; fi
sudo ln -s $AEGIR_CONF_FILE $WEBSERVER_CONF
if [ $WS == "apache" ]; then sudo a2enconf aegir; fi

###############################################################################
#  - Prepare new hostmaster directory: if there is a new hostmaster directory,
#    from any update activity, it has to be renamed like hostmaster-3.186,
#    to allow future upgrades
if [ -d "$AEGIR_HOSTMASTER" ]; then
  # this is one of the update scenarios: either aegir upgrade or drupal core & vendor update
  HM_VERSION=`drush site-alias @hm | grep root | cut -d"'" -f4 | awk -F \- {'print $2'}`
  if [ "$HM_VERSION" == "$AEGIR_VERSION" ];  then
    # drupal core and/or vendor package update scenario
    # update everything except hostmaster sites directory
    sudo su - aegir -c "cp -r $AEGIR_HOSTMASTER/sites/$SITE_URI $AEGIR_HOME/hostmaster/sites"
    sudo mv $AEGIR_HOSTMASTER "$AEGIR_HOSTMASTER-backup"
  fi
fi
echo "ÆGIR | Actual hostmaster directory is $AEGIR_HOSTMASTER"
sudo mv $AEGIR_HOME/hostmaster $AEGIR_HOSTMASTER

###############################################################################
#  - Deploy "fix ownership & permissions" scripts
echo "ÆGIR | deploy fix ownership & permissions scripts"
sudo su -c "rm /usr/local/bin/fix-drupal-*.sh 2>/dev/null"
sudo su -c "rm /etc/sudoers.d/fix-drupal-* 2>/dev/null"
sudo bash $AEGIR_HOSTMASTER/sites/all/modules/contrib/hosting_tasks_extra/fix_permissions/scripts/standalone-install-fix-permissions-ownership.sh
# ls -la /usr/local/bin/fix-drupal-*.sh

###############################################################################
#  - Drush configurations
#  - download: done via Composer, see composer.json
#    https://github.com/drush-ops/drush/releases
#  - initialize Drush with Aegir home
#  - add drush path for all user
#  - link drush into /usr/local/bin/drush

# probe drush command
/usr/local/bin/drush >/dev/null 2>&1
if [ $? -ne 0 ]; then

  # drush is not yet installed, so it will be done here
  echo "ÆGIR | Initializing Drush with Aegir ..."

  #  - initialize Drush with Aegir home
  DRUSH=$AEGIR_HOME/vendor/bin/drush
  sudo su - aegir -c "$DRUSH core:init  --add-path=$AEGIR_HOME --bg -y >/dev/null 2>&1"

  #  - add drush path for all user
  echo '#!/bin/sh
  export PATH="$PATH:$AEGIR_HOME/vendor/bin"' | sudo tee /etc/profile.d/drush.sh
  sudo su -c "chmod +x /etc/profile.d/drush.sh"

  #  - link drush into /usr/local/bin/drush
  # otherwise hosting-queued is not running
  sudo su -c "ln -s $AEGIR_HOME/vendor/bin/drush /usr/local/bin"
fi

# drush status
echo "ÆGIR | Drush setup is OK."
sudo su - aegir -c "drush status"

###############################################################################
# Configure the Provision module https://www.drupal.org/project/provision/
#  - download: done via Composer, see composer.json
#  - initialize: link provision module into drush paths
echo "ÆGIR | Configuring the Provision module ..."

#  - link provision module into drush paths
DRUSH_COMMANDS=/usr/share/drush/commands

# remove old version, if any
if [ -d "$DRUSH_COMMANDS" ]; then sudo rm -rf $DRUSH_COMMANDS; fi

# link provision drush commands into drush directory
sudo mkdir -p $DRUSH_COMMANDS
sudo ln -s $AEGIR_HOSTMASTER/sites/all/drush/provision $DRUSH_COMMANDS

# refresh drush cache to see provisions drush commands
sudo su - aegir -c "drush cc drush"

echo "ÆGIR | ------------------------------------------------------------------"

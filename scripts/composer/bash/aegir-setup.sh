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
source "$CONFIGDIR/mariadb.cfg"

###############################################################################
# This script runs when the post-install-cmd event is fired by composer via
# "composer create-project" or "composer install".
#
# Functionality:
#   - on a fresh OS it installs Aegir
#   - if Aegir is there, it upgrades Aegir to a newer version, if available

# Create Aegir user and grant permissions, prepare Aegir home
#  - create user and add to webserver group
#  - grant passwordless sudo rights for everything
###############################################################################

# fetch the running webserver
WEBSERVER=$(fetch_webserver)
# fetch new aegir version
AEGIR_VERSION=$(new_aegir_version)
# new hostmester directory
AEGIR_HOSTMASTER="$AEGIR_HOME/hostmaster-$AEGIR_VERSION"

echo "ÆGIR | ------------------------------------------------------------------"
# check current Aegir setup
if aegir_is_there ; then
  # fetch current aegir version
  HM_VERSION=`drush site:alias @hm | grep root | cut -d"'" -f4 | awk -F \- {'print $2'}`
  if [ "$HM_VERSION" != "$AEGIR_VERSION" ];  then
    # aegir upgrade scenario
    echo "ÆGIR | Upgrading Aegir from $HM_VERSION to $AEGIR_VERSION ..."
    echo "ÆGIR | New hostmaster directory will be: $AEGIR_HOSTMASTER"
    sudo mv $AEGIR_HOME/hostmaster $AEGIR_HOSTMASTER
  else
    # drupal core and/or vendor package update scenario: do nothing here
    echo "ÆGIR | There is no new Aegir version to upgrade."
    echo "ÆGIR | Current version: $AEGIR_VERSION"
    echo "ÆGIR | Use composer update to update vendor packages and drupal core!"
    echo "ÆGIR | ------------------------------------------------------------------"
    exit 0
  fi
else
  # no aegir home --> fresh install, do something
  echo "ÆGIR | Installing Aegir $AEGIR_VERSION ..."

  #  create user and add to webserver group
    echo "ÆGIR | Setting up the Aegir user ..."
  if ! getent passwd aegir >/dev/null ; then
    sudo adduser --quiet --system --no-create-home --group \
      --home "$AEGIR_HOME" \
      --shell '/bin/bash' \
      --gecos 'Aegir user,,,' \
      aegir
    sudo adduser --quiet aegir www-data
  fi
  #  grant passwordless sudo rights for everything
  echo 'aegir ALL=(ALL) NOPASSWD:ALL     # no password' > /tmp/aegir
  sudo chmod 0440 /tmp/aegir
  sudo chown root:root /tmp/aegir
  sudo mv /tmp/aegir /etc/sudoers.d/aegir
  echo "ÆGIR | The aegir user and its permsisions have been setup."

  # prepare directories and set permissions in fresh install case
  echo "ÆGIR | Preparing aegir home at $AEGIR_HOME ..."
  TMPDIR="$HOME/$INSTALL_DIR"
  # move downloaded stuff to aegir home and set permissions
  sudo cp -R $TMPDIR $AEGIR_HOME/
  # grant user permissions on all directories downloaded by composer
  sudo chown aegir:aegir -R "$AEGIR_HOME"
  # the new hostmaster directory has to be renamed like hostmaster-3.186
  sudo mv $AEGIR_HOME/hostmaster $AEGIR_HOSTMASTER
  echo "ÆGIR | Hostmaster directory is $AEGIR_HOSTMASTER"

  #  - webserver config to use aegir settings
  echo "ÆGIR | Enabling aegir configuration for $WEBSERVER..."
  case "$WEBSERVER" in
    nginx)
      AEGIR_CONF_FILE="$AEGIR_HOME/config/$WEBSERVER.conf"
      WEBSERVER_CONF="/etc/$WEBSERVER/conf.d/aegir.conf"
      ;;
    apache)
      AEGIR_CONF_FILE=$AEGIR_HOME/config/$WEBSERVER.conf
      WEBSERVER_CONF=/etc/"$WEBSERVER"2/conf.d/aegir.conf
      sudo a2disconf aegir 2>/dev/null aegir
      ;;
    *) echo "ÆGIR | No webserver found, aborting!"
       exit 1
       ;;
  esac
  if [ -f "$WEBSERVER_CONF" ]; then sudo su -c "rm $WEBSERVER_CONF"; fi
  sudo ln -s $AEGIR_CONF_FILE $WEBSERVER_CONF
  if [ $WEBSERVER == "apache" ]; then sudo a2enconf aegir; fi

  # setup drush
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
fi

###############################################################################
#  Deploy "fix ownership & permissions" scripts
echo "ÆGIR | deploy fix ownership & permissions scripts"
sudo su -c "rm /usr/local/bin/fix-drupal-*.sh 2>/dev/null"
sudo su -c "rm /etc/sudoers.d/fix-drupal-* 2>/dev/null"
sudo bash $AEGIR_HOSTMASTER/sites/all/modules/contrib/hosting_tasks_extra/fix_permissions/scripts/standalone-install-fix-permissions-ownership.sh
# ls -la /usr/local/bin/fix-drupal-*.sh

###############################################################################
# Configure the Provision module https://www.drupal.org/project/provision/
echo "ÆGIR | Configuring the Provision module ..."
DRUSH_COMMANDS=/usr/share/drush/commands
# remove old version, if any
if [ -d "$DRUSH_COMMANDS" ]; then sudo rm -rf $DRUSH_COMMANDS; fi
# link provision drush commands into drush directory
sudo mkdir -p $DRUSH_COMMANDS
sudo ln -s $AEGIR_HOSTMASTER/sites/all/drush/provision $DRUSH_COMMANDS
# refresh drush cache to see provisions drush commands
sudo su - aegir -c "drush cache:clear drush"

# Check if @hostmaster is already there.
sudo su - aegir -c "drush site:alias @hostmaster > /dev/null 2>&1"
if [ ${PIPESTATUS[0]} == 0 ]; then
  # yes, we have site alias for hostmester, so we'll upgrade Aegir frontend by
  # migrating hostmaster into the new hostmaster platform
  sudo su - aegir -c "drush @hostmaster hostmaster-migrate $HOSTNAME $AEGIR_HOSTMASTER -y"
  echo "ÆGIR | -----------------------------------------------------------------"
  echo "ÆGIR | $SITE_URI has been updated, and now runs on Aegir $AEGIR_VERSION."
  echo "ÆGIR | ------------------------------------------------------------------"

else
  # no hostmaster found, so install Aegir frontend
  echo "ÆGIR | Hostmaster install ..."

  # set random database password for aegir user
  # it will be stored in /var/aegir/.drush/server_localhost.alias.drushrc.php
  AEGIR_DB_PASS=$(openssl rand -base64 12)
  #  Create db user for aegir: GRANT ALL ON *.* TO 'aegir_db_user'@'localhost' IDENTIFIED BY 'strongpassword' WITH GRANT OPTION;
  echo "GRANT ALL ON *.* TO '$AEGIR_DB_USER'@'$AEGIR_DB_HOST' IDENTIFIED BY '$AEGIR_DB_PASS' WITH GRANT OPTION;" | sudo mysql

  #  Install Aegir frontend via drush hostmaster-install
  echo "ÆGIR | We will install Aegir frontend with the following options:"
  echo "ÆGIR | "
  echo "ÆGIR | Aegir URI:      $SITE_URI"
  echo "ÆGIR | Aegir server:   $AEGIR_HOST"
  echo "ÆGIR | Aegir root:     $AEGIR_HOME"
  echo "ÆGIR | Admin name:     $AEGIR_CLIENT_NAME"
  echo "ÆGIR | Web group:      www-data"
  echo "ÆGIR | Webserver:      $WEBSERVER"
  echo "ÆGIR | Webserver port: 80"
  echo "ÆGIR | Database host:  $AEGIR_DB_HOST"
  echo "ÆGIR | Database user:  $AEGIR_DB_USER"
  echo "ÆGIR | Database pwd:   stored in $AEGIR_HOME/.drush/server_localhost.alias.drushrc.php"
  echo "ÆGIR | Database port:  3306"
  echo "ÆGIR | Aegir version:  $AEGIR_VERSION"
  echo "ÆGIR | Hostmaster dir: $AEGIR_HOSTMASTER"
  echo "ÆGIR | Admin email:    $AEGIR_CLIENT_EMAIL"
  echo "ÆGIR | Aegir profile:  hostmaster"
  echo "ÆGIR | "

  echo "ÆGIR | Running: drush hostmaster-install:"
  sudo su - aegir -c " \
  drush hostmaster-install -y --strict=0 $SITE_URI \
    --aegir_db_host=$AEGIR_DB_HOST \
    --aegir_db_pass=$AEGIR_DB_PASS \
    --aegir_db_port='3306' \
    --aegir_db_user=$AEGIR_DB_USER \
    --aegir_host=$AEGIR_HOST \
    --aegir_root=$AEGIR_HOME \
    --client_name=$AEGIR_CLIENT_NAME \
    --client_email=$AEGIR_CLIENT_EMAIL \
    --http_service_type=$WEBSERVER \
    --root=$AEGIR_HOSTMASTER \
    --version=$AEGIR_VERSION \
  "

  # just to be sure :)
  sleep 3
  # Flush the drush cache to find new commands
  sudo su - aegir -c "drush cache:clear drush"

  # install hosting-queued daemon
  echo "ÆGIR | Install hosting-queued daemon..."
  # Install the init script
  sudo cp $AEGIR_HOSTMASTER/sites/all/modules/contrib/hosting/queued/init.d.example /etc/init.d/hosting-queued
  sudo chmod 755 /etc/init.d/hosting-queued
  sudo systemctl daemon-reload
  sudo systemctl enable hosting-queued

  #  - Enable Aegir modules: hosting_civicrm, hosting_civicrm_cron, ...
  echo "ÆGIR | Enabling hosting modules for CiviCRM ..."
  sudo su - aegir -c "drush @hostmaster pm:enable -y hosting_queued"
  sudo su - aegir -c "drush @hostmaster pm:enable -y fix_ownership fix_permissions"
  # sudo su - aegir -c "drush @hostmaster pm:enable -y hosting_civicrm hosting_civicrm_cron"

  echo "ÆGIR | -----------------------------------------------------------------"
  echo "ÆGIR | Aegir $AEGIR_VERSION has been installed via Composer ..."
  echo "ÆGIR | -----------------------------------------------------------------"

fi
# restart queued daemon
sudo systemctl restart hosting-queued

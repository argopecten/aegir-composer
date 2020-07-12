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
# This script runs when Aegir installed, updated or upgraded, and is called by
# post-install-cmd or post-update-cmd event of Composer
#
# functions: install & configure Aegir frontend, and some more settings
#    https://www.drupal.org/project/hostmaster/
#
# The script checks for existing hostmaster install. If there is one Hostmaster
# site, then it migrates it. If there is no Hostmaster, it installes one.
#
#  - Create db user for aegir
#  - Install Aegir frontend via drush hostmaster-install
#  - Install hosting-queued daemon
#  - Enable Aegir modules: hosting_civicrm, hosting_civicrm_cron, ...
#
###############################################################################

echo "ÆGIR | ------------------------------------------------------------------"
AEGIR_VERSION=`cat $AEGIR_HOME/aegir_version`
AEGIR_HOSTMASTER="$AEGIR_HOME/hostmaster-$AEGIR_VERSION"

# Check if @hostmaster is already there.
sudo su - aegir -c "drush site:alias @hostmaster > /dev/null 2>&1"
if [ ${PIPESTATUS[0]} == 0 ]; then
  # this is one of the update scenarios: either aegir upgrade or drupal core & vendor update
  echo "ÆGIR | Hostmaster site found. Upgrading ..."
  sudo su - aegir -c "drush @hostmaster cache:clear all"

  HM_VERSION=`drush site:alias @hm | grep root | cut -d"'" -f4 | awk -F \- {'print $2'}`
  if [ "$HM_VERSION" == "$AEGIR_VERSION" ];  then
    # drupal core and/or vendor package update scenario
    sudo su - aegir -c "drush @platform_hostmaster provision-verify"
    sudo su - aegir -c "drush @hostmaster provision-verify"
    sudo su - aegir -c "drush @hostmaster updatedb"
    sudo su - aegir -c "drush @platform_hostmaster provision-verify"
  else
    # migrate hostmaster into new hostmaster platform
    sudo su - aegir -c "drush @hostmaster hostmaster-migrate $HOSTNAME $AEGIR_HOSTMASTER -y"
  fi
  echo "ÆGIR | -----------------------------------------------------------------"
  echo "ÆGIR | $SITE_URI has been updated, and runs now on Aegir $AEGIR_VERSION."

else
  # if @hostmaster is not accessible, install it.
  echo "ÆGIR | Hostmaster install ..."

  # set random database password for aegir user
  # it will be stored in /var/aegir/.drush/server_localhost.alias.drushrc.php
  AEGIR_DB_PASS=$(openssl rand -base64 12)

  #  Create db user for aegir: GRANT ALL ON *.* TO 'aegir_db_user'@'localhost' IDENTIFIED BY 'strongpassword' WITH GRANT OPTION;
  echo "GRANT ALL ON *.* TO '$AEGIR_DB_USER'@'$AEGIR_DB_HOST' IDENTIFIED BY '$AEGIR_DB_PASS' WITH GRANT OPTION;" | sudo mysql

  # fetch the running webserver
  WEBSERVER=$(fetch_webserver)

  #  Install Aegir frontend via drush hostmaster-install
  echo "ÆGIR | We will install Aegir frontend with the following options:"
  echo "ÆGIR | "
  echo "ÆGIR | Aegir URI:      $SITE_URI"
  echo "ÆGIR | Aegir server:   $AEGIR_HOST"
  echo "ÆGIR | Aegir root:     $AEGIR_HOME"
  echo "ÆGIR | Admin name:     $AEGIR_CLIENT_NAME"
  echo "ÆGIR | Web group:      'www-data'"
  echo "ÆGIR | Webserver:      $WEBSERVER"
  echo "ÆGIR | Webserver port: '80'"
  echo "ÆGIR | Database host:  $AEGIR_DB_HOST"
  echo "ÆGIR | Database user:  $AEGIR_DB_USER"
  echo "ÆGIR | Database pwd:   stored in $AEGIR_HOME/.drush/server_localhost.alias.drushrc.php"
  echo "ÆGIR | Database port:  '3306'"
  echo "ÆGIR | Aegir version:  $AEGIR_VERSION"
  echo "ÆGIR | Hostmaster dir: $AEGIR_HOSTMASTER"
  echo "ÆGIR | Admin email:    $AEGIR_CLIENT_EMAIL"
  echo "ÆGIR | Aegir profile:  'hostmaster'"
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
  sudo su - aegir -c "drush @hostmaster pm:enable -y hosting_civicrm hosting_civicrm_cron"

  echo "ÆGIR | -----------------------------------------------------------------"
  echo "ÆGIR | Aegir $AEGIR_VERSION has been installed via Composer ..."
fi

# restart queued daemon
sudo systemctl restart hosting-queued
echo "ÆGIR | -----------------------------------------------------------------"

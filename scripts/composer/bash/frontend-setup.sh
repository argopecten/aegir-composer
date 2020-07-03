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

# Check if @hostmaster is already set and accessible.
sudo su - aegir -c "drush @hostmaster vget site_name > /dev/null 2>&1"
if [ ${PIPESTATUS[0]} == 0 ]; then
  echo "ÆGIR | Hostmaster site found."

  HM_VERSION=`drush sa @hm | grep root | cut -d"'" -f4 | awk -F \- {'print $2'}`
  if [ "$HM_VERSION" == "$AEGIR_VERSION" ]; then
    # it's just a drupal core and/or vendor package update
    echo "ÆGIR | Drupal core and/or vendor package updates."

    # Verify the upgraded platform.
    PLATFORM=`drush sa @hm | grep platform | cut -d"'" -f4`
    sudo su - aegir -c "drush $PLATFORM provision-verify"
    # Verify the Hostmaster site.
    sudo su - aegir -c "drush @hostmaster provision-verify"
    # Run database updates
    sudo su - aegir -c "drush @hostmaster updatedb"

  else
    # a new aegir version is there
    echo "ÆGIR | Clear Hostmaster caches and migrate the site into the new platform ... "
    sudo su - aegir -c "drush @hostmaster cc all; drush cache-clear drush"

    echo "ÆGIR | Running 'drush @hostmaster hostmaster-migrate $HOSTNAME $AEGIR_HOSTMASTER -y'...!"
    sudo su - aegir -c "drush @hostmaster hostmaster-migrate $HOSTNAME $AEGIR_HOSTMASTER -y -v"

    echo "ÆGIR | $SITE_URI has been updated, and runs now on Aegir $AEGIR_VERSION."
  fi

else
  # if @hostmaster is not accessible, install it.
  echo "ÆGIR | Hostmaster install..."

  # set random database password for aegir user
  # it will be stored in /var/aegir/.drush/server_localhost.alias.drushrc.php
  AEGIR_DB_PASS=$(openssl rand -base64 12)

  #  Create db user for aegir: GRANT ALL ON *.* TO 'aegir_db_user'@'localhost' IDENTIFIED BY 'strongpassword' WITH GRANT OPTION;
  echo "GRANT ALL ON *.* TO '$AEGIR_DB_USER'@'$AEGIR_DB_HOST' IDENTIFIED BY '$AEGIR_DB_PASS' WITH GRANT OPTION;" | sudo mysql
  # echo "select host, user, password from mysql.user;" |  sudo mysql

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
  echo "ÆGIR | Flush the drush cache to find new commands ... "
  sudo su - aegir -c "drush cc drush"

  # install hosting-queued daemon
  echo "ÆGIR | Install hosting-queued daemon..."
  # Install the init script
  sudo cp $AEGIR_HOSTMASTER/sites/all/modules/contrib/hosting/queued/init.d.example /etc/init.d/hosting-queued
  sudo chmod 755 /etc/init.d/hosting-queued
  # reload the daemons and start hosting-queued
  sudo systemctl daemon-reload
  sudo systemctl enable hosting-queued

  #  - Enable Aegir modules: hosting_civicrm, hosting_civicrm_cron, ...
  echo "ÆGIR | Enabling hosting modules for CiviCRM ..."
  sudo su - aegir -c "drush @hostmaster pm-enable -y hosting_queued"
  sudo su - aegir -c "drush @hostmaster pm-enable -y fix_ownership fix_permissions"
  sudo su - aegir -c "drush @hostmaster pm-enable -y hosting_civicrm hosting_civicrm_cron"

  echo "ÆGIR | Aegir $AEGIR_VERSION has been installed via Composer ..."
fi

# restart queued daemon
sudo systemctl restart hosting-queued

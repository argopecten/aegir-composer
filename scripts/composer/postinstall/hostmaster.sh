#! /bin/bash
#
# Aegir 3.x install scripts for Debian / Ubuntu
#
# on Github: https://github.com/argopecten/aegir-composer
#
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
source "$DIR/../../aegir.cfg"

###########################################################
# Install Aegir
#  - install Hostmast module of Aegir
#    https://www.drupal.org/project/hostmaster/
###########################################################


#### Check apache and database
echo "ÆGIR | -------------------------"
# echo "ÆGIR | Starting apache2 now to reduce downtime."
# sudo apache2ctl graceful
# sudo apache2ctl configtest

# Fix ownership & permissions scripts
sudo bash $AEGIR_HOSTMASTER_ROOT/sites/all/modules/contrib/hosting_tasks_extra/fix_permissions/scripts/standalone-install-fix-permissions-ownership.sh
# ls -la /usr/local/bin/fix-drupal-*.sh

# - create user aegir db user
# Random password, will be stored in /var/aegir/.drush/server_localhost.alias.drushrc.php
AEGIR_DB_PASS=$(openssl rand -base64 12)
AEGIR_DB_HOST='localhost'
# GRANT ALL ON *.* TO 'aegir_db_user'@'localhost' IDENTIFIED BY 'strongpassword' WITH GRANT OPTION;
sudo su -c "mysql --execute='GRANT ALL ON *.* TO '$AEGIR_DB_USER'@'$AEGIR_DB_HOST' IDENTIFIED BY '$AEGIR_DB_PASS' WITH GRANT OPTION;'"

# Returns true once mysql can connect.
while ! mysqladmin ping -h"$AEGIR_DB_HOST" --silent; do
  sleep 3
  echo "ÆGIR | Waiting for database on $AEGIR_DB_HOST ..."
done
echo "ÆGIR | Database is active!"

# variables for Aegir
echo "ÆGIR | -------------------------"
echo 'ÆGIR | Hello! '
echo 'ÆGIR | We will install Aegir with the following options:'
SITE_URI=$AEGIR_HOST
AEGIR_ROOT="$AEGIR_HOME/web/"
AEGIR_HOSTMASTER_ROOT=$AEGIR_ROOT/hostmaster-$AEGIR_VERSION
echo "ÆGIR | -------------------------"
echo "ÆGIR | Aegir URI:      $SITE_URI"
echo "ÆGIR | Aegir server:   $AEGIR_HOST"
echo "ÆGIR | Aegir root:     $AEGIR_ROOT"
echo "ÆGIR | Admin name:     $AEGIR_CLIENT_NAME"
echo "ÆGIR | Web group:      'www-data'"
echo "ÆGIR | Webserver:      $WEBSERVER"
echo "ÆGIR | Webserver port: '80'"
echo "ÆGIR | Database host:  $AEGIR_DB_HOST"
echo "ÆGIR | Database user:  $AEGIR_DB_USER"
echo "ÆGIR | Database port:  '3306'"
echo "ÆGIR | Aegir version:  $AEGIR_VERSION"
echo "ÆGIR | Aegir platform: $AEGIR_HOSTMASTER_ROOT"
echo "ÆGIR | Admin email:    $AEGIR_CLIENT_EMAIL"
echo "ÆGIR | Aegir profile:  'hostmaster'"
echo "ÆGIR | -------------------------"
echo "ÆGIR | Checking Aegir directory..."
ls -lah $AEGIR_HOME

echo "ÆGIR | -------------------------"
echo "ÆGIR | Hostmaster install..."
echo 'ÆGIR | Checking drush status...'
sudo su - aegir -c "drush cc drush"
sudo su - aegir -c "drush status"

echo "ÆGIR | -------------------------"
echo "ÆGIR | Running: drush hostmaster-install"
sudo su - aegir -c " \
drush hostmaster-install -y --strict=0 $SITE_URI \
  --aegir_db_host     = $AEGIR_DB_HOST \
  --aegir_db_pass     = $AEGIR_DB_PASS \
  --aegir_db_port     = '3306' \
  --aegir_db_user     = $AEGIR_DB_USER \
  --aegir_host        = $AEGIR_HOST \
  --aegir_root        = $AEGIR_ROOT \
  --client_name       = $AEGIR_CLIENT_NAME \
  --client_email      = $AEGIR_CLIENT_EMAIL \
  --http_service_type = $WEBSERVER \
  --root              = $AEGIR_HOSTMASTER_ROOT \
  --version           = $AEGIR_VERSION \
"

# sleep 3
echo "ÆGIR | Flush the drush cache to find new commands ... "
sudo su - aegir -c "drush cc drush"

# install hosting-queued daemon
echo "ÆGIR | Install hosting-queued daemon..."
# Install the init script
sudo cp $AEGIR_HOSTMASTER_ROOT/sites/all/modules/contrib/hosting/queued/init.d.example /etc/init.d/hosting-queued
sudo chmod 755 /etc/init.d/hosting-queued
# Setup symlinks and runlevels
sudo update-rc.d hosting-queued defaults
# Start the daemon
sudo systemctl start hosting-queued
sudo systemctl enable hosting-queued
# enable module in Aegir
sudo su - aegir -c "drush @hostmaster pm-enable -y hosting_queued"

# echo "ÆGIR | Enabling hosting modules for CiviCRM ..."
# fix_permissions, fix_ownership, hosting_civicrm, hosting_civicrm_cron
# drush @hostmaster en hosting_civicrm_cron -y

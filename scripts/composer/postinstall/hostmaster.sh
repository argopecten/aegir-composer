#! /bin/bash
#
# Aegir 3.x install scripts for Debian / Ubuntu
#
# on Github: https://github.com/argopecten/aegir-composer
#
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
source "$DIR/../../config/aegir.cfg"
source "$DIR/../../config/mariadb.cfg"

###########################################################
# Install Aegir
#  - install Hostmaster module of Aegir
#    https://www.drupal.org/project/hostmaster/
###########################################################

# Deploy the "fix ownership & permissions" scripts
sudo bash $AEGIR_HOSTMASTER/sites/all/modules/contrib/hosting_tasks_extra/fix_permissions/scripts/standalone-install-fix-permissions-ownership.sh
# ls -la /usr/local/bin/fix-drupal-*.sh

# - create user aegir db user
# GRANT ALL ON *.* TO 'aegir_db_user'@'localhost' IDENTIFIED BY 'strongpassword' WITH GRANT OPTION;
echo "GRANT ALL ON *.* TO '$AEGIR_DB_USER'@'$AEGIR_DB_HOST' IDENTIFIED BY '$AEGIR_DB_PASS' WITH GRANT OPTION;" | sudo mysql
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | aegir_db_user is set"
echo "select host, user, password from mysql.user;" |  sudo mysql

# fetching the webserver type from config file
echo "Server has $WEBSERVER as webserver."

# variables for Aegir
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | We will install Aegir frontend with the following options:"
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | Aegir URI:      $SITE_URI"
echo "ÆGIR | Aegir server:   $AEGIR_HOST"
echo "ÆGIR | Aegir root:     $AEGIR_ROOT"
echo "ÆGIR | Admin name:     $AEGIR_CLIENT_NAME"
echo "ÆGIR | Web group:      'www-data'"
echo "ÆGIR | Webserver:      $WEBSERVER"
echo "ÆGIR | Webserver port: '80'"
echo "ÆGIR | Database host:  $AEGIR_DB_HOST"
echo "ÆGIR | Database user:  $AEGIR_DB_USER"
echo "ÆGIR | Database pwd:   $AEGIR_DB_PASS"
echo "ÆGIR | Database port:  '3306'"
echo "ÆGIR | Aegir version:  $AEGIR_VERSION"
echo "ÆGIR | Hostmaster dir: $AEGIR_HOSTMASTER"
echo "ÆGIR | Admin email:    $AEGIR_CLIENT_EMAIL"
echo "ÆGIR | Aegir profile:  'hostmaster'"
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | Checking Aegir directory..."
ls -lah $AEGIR_HOME

echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | Hostmaster install..."
echo "ÆGIR | Checking drush status..."
sudo su - aegir -c "drush cc drush"
sudo su - aegir -c "drush status"
echo "ÆGIR | Checking Aegir frontend directory..."
ls -lah $AEGIR_HOSTMASTER

echo "ÆGIR | -------------------------"
echo "ÆGIR | Running: drush hostmaster-install"
sudo su - aegir -c " \
drush hostmaster-install -y --strict=0 $SITE_URI \
  --aegir_db_host=$AEGIR_DB_HOST \
  --aegir_db_pass=$AEGIR_DB_PASS \
  --aegir_db_port='3306' \
  --aegir_db_user=$AEGIR_DB_USER \
  --aegir_host=$AEGIR_HOST \
  --aegir_root=$AEGIR_ROOT \
  --client_name=$AEGIR_CLIENT_NAME \
  --client_email=$AEGIR_CLIENT_EMAIL \
  --http_service_type=$WEBSERVER \
  --root=$AEGIR_HOSTMASTER \
  --version=$AEGIR_VERSION \
"

# just to be sure :)
sleep 3
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | Flush the drush cache to find new commands ... "
sudo su - aegir -c "drush cc drush"

# install hosting-queued daemon
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | Install hosting-queued daemon..."
# Install the init script
sudo cp $AEGIR_HOSTMASTER/sites/all/modules/contrib/hosting/queued/init.d.example /etc/init.d/hosting-queued
sudo chmod 755 /etc/init.d/hosting-queued
# reload the daemons and start hosting-queued
sudo systemctl daemon-reload
sudo systemctl enable hosting-queued
sudo systemctl start hosting-queued
# enable the Aegir frontend module
sudo su - aegir -c "drush @hostmaster pm-enable -y hosting_queued"

# fix_permissions, fix_ownership, hosting_civicrm, hosting_civicrm_cron
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | Enabling hosting modules for CiviCRM ..."
#drush @hostmaster en fix_ownership fix_permissions hosting_civicrm hosting_civicrm_cron -y

echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | Aegir $AEGIR_VERSION has been installed via Composer ..."
echo "ÆGIR | ------------------------------------------------------------------"

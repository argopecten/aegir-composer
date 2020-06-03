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

# Returns true once mysql can connect.
while ! mysqladmin ping -hlocalhost --silent; do
  sleep 3
  echo "ÆGIR | Waiting for database on localhost ..."
done
echo "ÆGIR | Database is active!"

# variables for Aegir
echo "ÆGIR | -------------------------"
echo 'ÆGIR | Hello! '
echo 'ÆGIR | We will install Aegir with the following options:'
HOSTNAME=`hostname --fqdn`
AEGIR_HOSTMASTER_ROOT="$AEGIR_HOME/web"
AEGIR_CLIENT_EMAIL="aegir@ubuntu.local"
AEGIR_CLIENT_NAME="admin"
AEGIR_PROFILE="hostmaster"
AEGIR_WORKING_COPY="0"
echo "ÆGIR | -------------------------"
echo "ÆGIR | Hostname: $HOSTNAME"
echo "ÆGIR | Version: $AEGIR_VERSION"
echo "ÆGIR | Database Host: localhost"
echo "ÆGIR | Profile: $AEGIR_PROFILE"
echo "ÆGIR | Root: $AEGIR_HOSTMASTER_ROOT"
echo "ÆGIR | Client Name: $AEGIR_CLIENT_NAME"
echo "ÆGIR | Client Email: $AEGIR_CLIENT_EMAIL"
echo "ÆGIR | Working Copy: $AEGIR_WORKING_COPY"
echo "ÆGIR | -------------------------"
echo "ÆGIR | Checking Aegir directory..."
ls -lah $AEGIR_HOME
echo "ÆGIR | -------------------------"
echo "ÆGIR | Running 'drush cc drush' ... "
drush cc drush
echo 'ÆGIR | Checking drush status...'
drush status

# if @hostmaster is not accessible, install it.
echo "ÆGIR | Hostmaster install..."
echo "ÆGIR | -------------------------"
echo "ÆGIR | Running: drush cc drush"
drush cc drush

# test sudo
sudo su - aegir -c '
echo "ÆGIR | -------------------------"
echo "ÆGIR | This is the aegir user."
'

echo "ÆGIR | -------------------------"
echo "ÆGIR | Running: drush hostmaster-install"
sudo su - aegir -c " \
  drush hostmaster-install -y --strict=0 $HOSTNAME \
    --aegir_db_host     = 'localhost' \
    --aegir_db_pass     = $MYSQL_AEGIR_DB_PASSWORD \
    --aegir_db_port     = '3306' \
    --aegir_db_user     = $MYSQL_AEGIR_DB_USER \
    --aegir_host        = $HOSTNAME \
    --client_name       = $AEGIR_CLIENT_NAME \
    --client_email      = $AEGIR_CLIENT_EMAIL \
    --http_service_type = $WEBSERVER \
    --profile           = $AEGIR_PROFILE \
    --root              = $AEGIR_HOSTMASTER_ROOT \
    --working-copy      = $AEGIR_WORKING_COPY \
"
sleep 3
echo "ÆGIR | Running 'drush cc drush' ... "
drush cc drush

# enable modules
echo "ÆGIR | Enabling hosting queued..."

# TODO: should be aegir user?
drush @hostmaster en hosting_queued -y

# echo "ÆGIR | Enabling hosting modules for CiviCRM ..."
# fix_permissions, fix_ownership, hosting_civicrm, hosting_civicrm_cron
# drush @hostmaster en hosting_civicrm_cron -y

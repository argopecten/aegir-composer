#! /bin/bash
#
# Aegir 3.x install/update scripts for Debian / Ubuntu
#
# on Github: https://github.com/argopecten/aegir-composer
#
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
source "$DIR/../common/common-functions.sh"
source "$DIR/../../config/aegir.cfg"
source "$DIR/../../config/mariadb.cfg"

###########################################################
# Install/Update Aegir
#  - install Hostmaster module of Aegir
#    https://www.drupal.org/project/hostmaster/

#  - Deploy "fix ownership & permissions" scripts
#  - Create db user for aegir
#  - Install Aegir frontend via drush hostmaster-install
#  - Install hosting-queued daemon
#  - Enable Aegir modules: hosting_civicrm, hosting_civicrm_cron, ...
###########################################################

echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | Hostmaster install..."

# list Aegir root directory..."
# ls -lah $AEGIR_HOME
# list hostmaster directory
# ls -lah $AEGIR_HOSTMASTER

#  - Deploy "fix ownership & permissions" scripts
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | deploy fix ownership & permissions scripts"
sudo su -c "rm /usr/local/bin/fix-drupal-*.sh"
sudo su -c "rm /etc/sudoers.d/fix-drupal-*"
sudo bash $AEGIR_HOSTMASTER/sites/all/modules/contrib/hosting_tasks_extra/fix_permissions/scripts/standalone-install-fix-permissions-ownership.sh
ls -la /usr/local/bin/fix-drupal-*.sh

# fetch the running webserver
WEBSERVER=$(fetch_webserver)

#  - Migrate Aegir frontend via drush hostmaster-migrate
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | We will install Aegir frontend with the following options:"
echo "ÆGIR | ------------------------------------------------------------------"
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
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | Running: drush hostmaster-migrate"

# Check if @hostmaster is already set and accessible.
sudo su - aegir -c "drush @hostmaster vget site_name > /dev/null 2>&1"
if [ ${PIPESTATUS[0]} == 0 ]; then
    echo "ÆGIR | Hostmaster site found. Upgrading ..."
    echo "ÆGIR | Clear Hostmaster caches and migrate the site into the new platform ... "
    echo "ÆGIR | Running 'drush @hostmaster hostmaster-migrate $HOSTNAME $AEGIR_HOSTMASTER -y'...!"
    sudo su - aegir -c "drush @hostmaster cc all; drush cache-clear drush"
    sudo su - aegir -c "drush @hostmaster hostmaster-migrate $HOSTNAME $AEGIR_HOSTMASTER -y -v"
else
  # if @hostmaster is not accessible, install it.
  echo "ÆGIR | Hostmaster not found. Try composer install! Exiting..."
  exit 1
fi

# just to be sure :)
sleep 3
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | Flush the drush cache to find new commands ... "
sudo su - aegir -c "drush cc drush"

echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | Aegir $AEGIR_VERSION has been installed via Composer ..."
echo "ÆGIR | ------------------------------------------------------------------"

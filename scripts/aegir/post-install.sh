#! /bin/bash
#
# Aegir 3.x install/update scripts Ubuntu
#
# on Github: https://github.com/argopecten/aegir-composer
#

echo "ÆGIR | post-install script is running ..." | tee -a log.txt
# runs after the install command has been executed with a lock file present
# all files are downloaded and relocated by composer

# some variable
# webserver: apache2 or nginx, for now it is just nginx
WEBSERVER="nginx"
# hostmaster directory
AEGIR_HOSTMASTER="/var/aegir/hostmaster"
# vendor directory
AEGIR_VENDOR="/var/aegir/vendor"
# global drush
DRUSH_PATH="/usr/bin/drush"

echo " - ÆGIR | Setup aegir user" | tee -a log.txt
# create user if not yet exists
if ! getent passwd aegir >/dev/null ; then
    sudo adduser --quiet --system --group --no-create-home --home '/var/aegir' --shell '/bin/bash' --gecos 'Aegir user,,,' aegir
    sudo adduser --quiet aegir www-data
    sudo cp /etc/skel/.bash* /var/aegir
    sudo cp /etc/skel/.profile /var/aegir
fi
sudo chown -R aegir:aegir /var/aegir
sudo chmod 755 /var/aegir

#  grant passwordless sudo rights for everything
echo 'aegir ALL=(ALL) NOPASSWD:ALL     # no password' > /tmp/aegir
sudo chmod 0440 /tmp/aegir
sudo chown root:root /tmp/aegir
sudo mv /tmp/aegir /etc/sudoers.d/aegir
echo " - ÆGIR | The aegir user and its permissions have been setup." | sudo tee -a log.txt


#  - webserver config to use aegir settings
echo " - ÆGIR | $WEBSERVER is using the Aegir configuration." | sudo tee -a log.txt
AEGIR_CONF="/var/aegir/config/$WEBSERVER.conf"
case "$WEBSERVER" in
    nginx)
        WEBSERVER_CONF="/etc/nginx/conf.d/aegir.conf"
        ;;
    apache)
        WEBSERVER_CONF="/etc/apache2/conf-enabled/aegir.conf"
        ;;
esac
[[ -L "$WEBSERVER_CONF" ]] && sudo su -c "rm $WEBSERVER_CONF"
sudo su -c "ln -s $AEGIR_CONF $WEBSERVER_CONF"


#  Deploy "fix ownership & permissions" scripts
echo " - ÆGIR | deploying fix ownership & permissions scripts" | sudo tee -a log.txt
# remove old scripts, if any
sudo su -c "rm /usr/local/bin/fix-drupal-*.sh 2>/dev/null"
sudo su -c "rm /etc/sudoers.d/fix-drupal-* 2>/dev/null"
# deploy scripts
sudo bash $AEGIR_HOSTMASTER/sites/all/modules/contrib/hosting_tasks_extra/fix_permissions/scripts/standalone-install-fix-permissions-ownership.sh 2>&1>/dev/null


# setup drush8, download done by composer
echo " - ÆGIR | Setup global Drush8 for Aegir 3.x" | sudo tee -a log.txt
# allow drush via PATH
[[ -L "$DRUSH_PATH" ]] && sudo su -c "rm $DRUSH_PATH"
sudo ln -s $AEGIR_VENDOR/aegir/drush8/drush $DRUSH_PATH
# clear cache
sudo su - aegir -c "drush cache:clear drush"


# Configure the Provision module
# echo " - ÆGIR | Configure the Provision module" | sudo tee -a log.txt
# download done by composer, nothing else to do here


# Configure db user for Aegir
echo " - ÆGIR | db user for Aegir" | sudo tee -a log.txt
# random database password for aegir user will be stored in
#    /var/aegir/.drush/server_localhost.alias.drushrc.php
#    generate 5x4 bits and replace space with underscore as password
AEGIR_DB_PASS=$(echo `pwgen 5 4 -c -n -s -B` | tr -s ' ' '_' )
AEGIR_DB_USER="aegirdbuser"
AEGIR_DB_HOST="localhost"
# Create db-user for Aegir, aligned to changes in MySQL 8.0
# https://www.drupal.org/project/provision/issues/3145881
sudo /usr/bin/mysql -e "CREATE USER IF NOT EXISTS '$AEGIR_DB_USER'@'$AEGIR_DB_HOST'"
sudo /usr/bin/mysql -e "ALTER USER '$AEGIR_DB_USER'@'$AEGIR_DB_HOST' IDENTIFIED BY '$AEGIR_DB_PASS'"
sudo /usr/bin/mysql -e "GRANT ALL ON *.* TO '$AEGIR_DB_USER'@'$AEGIR_DB_HOST' WITH GRANT OPTION"

#The URL of the site to install
SITE_URI="aegir.example.com"
# Fully qualified domain name of the local server
AEGIR_HOST="aegir.example.com"
# version of this Aegir release
AEGIR_VERSION="7.x-3.x"


# Install Aegir frontend via drush hostmaster-install -y
echo " - ÆGIR | Install Aegir frontend via drush hostmaster-install" | sudo tee -a log.txt

ez make-install-ra ment, ami hülyeség
sudo su - aegir -c "drush hostmaster-install --strict=0 $SITE_URI \
  --aegir_db_host=$AEGIR_DB_HOST \
  --aegir_db_pass=$AEGIR_DB_PASS \
  --aegir_db_port='3306' \
  --aegir_db_user=$AEGIR_DB_USER \
  --aegir_host=$AEGIR_HOST \
  --aegir_root="/var/aegir" \
  --client_name="admin" \
  --client_email="admin@aegir.example.com" \
  --http_service_type=$WEBSERVER \
  --root=$AEGIR_HOSTMASTER \
  --version=$AEGIR_VERSION \
"

ez működött (profile install), ha minden paraméternek volt értéke, kivéve VERSION(?).
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
          --version=$AEGIR_VERSION

The following settings will be used:
 Aegir frontend URL: aegir.example.com
 Master server FQDN: aegir.example.com
 Aegir root: /var/aegir
 Aegir user: aegir
 Web group: www-data
 Web server: nginx
 Web server port: 80
 Aegir DB host: localhost
 Aegir DB user: aegirdbuser
 Aegir DB password: <previously set>
 Aegir DB port: 3306
 Aegir version:
 Aegir platform path: /var/aegir/hostmaster
 Admin email: admin@aegir.example.com

 Aegir install profile: hostmaster


# Flush the drush cache to find new commands
# sudo su - aegir -c "drush cache:clear drush"


# install hosting-queued daemon
echo " - ÆGIR | Install hosting-queued daemon..." | sudo tee -a log.txt


#  - Enable Aegir modules: hosting_civicrm, hosting_civicrm_cron, ...
echo " - ÆGIR | Enabling hosting modules: hosting-queued daemon, fix ownership & permissions ..."  | sudo tee -a log.txt


#  - Reload services: nginx, queue, ...
echo " - ÆGIR | Reload services: nginx, queue, ..."  | sudo tee -a log.txt

#  - Status message and login URL
# this will ensure that this script aborts if the site can't be bootstrapped
if sudo su - aegir -c "drush @hostmaster status" 2>&1 | grep -q 'Drupal bootstrap.*Successful'; then
    echo " - ÆGIR | Aegir frontend bootstrap correctly, operation was a success!"
    echo "Use this URL to login on your new site:"
    sudo su - aegir -c "drush @hostmaster uli"
else
    echo " - ÆGIR | Aegir frontend failed to bootstrap, something went wrong!"
    echo " - ÆGIR | Look at the log above for clues or run with DPKG_DEBUG=developer"
    exit 1
fi

#! /bin/bash
#
# Aegir 3.x install/update scripts Ubuntu
#
# on Github: https://github.com/argopecten/aegir-composer
#

echo "ÆGIR | post-install script is running ..."
# runs after the install command has been executed with a lock file present
# all files are downloaded and relocated by composer

# some variable
# webserver: apache2 or nginx, for now it is just nginx
WEBSERVER="nginx"
# hostmaster root directory
HOSTMASTER="/var/aegir/hostmaster"
# drush directory in Aegir
AEGIR_DRUSH="/var/aegir/drush"
# global drush
GLOBAL_DRUSH="/usr/bin/drush"


# prepare Aegir directory and set permissions
echo " - ÆGIR | Copying Aegir files into aegir home ..."
# move downloaded stuff into aegir home
sudo cp -R /tmp/aegir-composer/* /var/aegir/
# grant user permissions
sudo chown -R aegir:aegir /var/aegir
# access for webserver
sudo chmod 755 /var/aegir

#  - webserver config to use aegir settings
echo " - ÆGIR | $WEBSERVER is using the Aegir configuration."
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
echo " - ÆGIR | deploying fix ownership & permissions scripts"
# remove old scripts, if any
sudo su -c "rm /usr/local/bin/fix-drupal-*.sh 2>/dev/null"
sudo su -c "rm /etc/sudoers.d/fix-drupal-* 2>/dev/null"
# deploy scripts
sudo bash $HOSTMASTER/sites/all/modules/contrib/hosting_tasks_extra/fix_permissions/scripts/standalone-install-fix-permissions-ownership.sh 2>&1>/dev/null


# setup drush8, download done by composer
echo " - ÆGIR | Setup global Drush8 for Aegir 3.x"
# download vendors for drush (is it really needed?)
sudo su - aegir -c "cd $AEGIR_DRUSH && composer install"
# allow drush via PATH
[[ -L "$GLOBAL_DRUSH" ]] && sudo su -c "rm $GLOBAL_DRUSH"
sudo ln -s $AEGIR_DRUSH/drush $GLOBAL_DRUSH
# clear cache
sudo su - aegir -c "drush cache:clear drush"


# Configure db user for Aegir
echo " - ÆGIR | db user for Aegir"
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

# Fully qualified domain name of the local server
AEGIR_HOST=$(hostname -f)
#The URL of the ÆGIR site is the hostname
SITE_URI=$(echo $AEGIR_HOST)
# version of this Aegir release
AEGIR_VERSION="7.x-3.x"

# Install Aegir frontend via drush hostmaster-install -y
echo " - ÆGIR | Install Aegir frontend via drush hostmaster-install"

echo "ÆGIR | We will install Aegir frontend with the following options:"
echo "ÆGIR | "
echo "ÆGIR | Aegir URI:             $SITE_URI"
echo "ÆGIR | Aegir server (host):   $AEGIR_HOST"
echo "ÆGIR | Aegir root:            /var/aegir"
echo "ÆGIR | Admin name:            admin"
echo "ÆGIR | Admin email:           admin@example.com"
echo "ÆGIR | Web group:             www-data"
echo "ÆGIR | Webserver:             $WEBSERVER"
echo "ÆGIR | Webserver port:        80"
echo "ÆGIR | Database host:         $AEGIR_DB_HOST"
echo "ÆGIR | Database user:         $AEGIR_DB_USER"
echo "ÆGIR | Database pwd:          stored in /var/aegir/.drush/server_localhost.alias.drushrc.php"
echo "ÆGIR | Database port:         3306"
echo "ÆGIR | Aegir version:         $AEGIR_VERSION"
echo "ÆGIR | Hostmaster dir:        $HOSTMASTER"
echo "ÆGIR | Aegir profile:         hostmaster"
echo "ÆGIR | "

echo "ÆGIR | Running: drush hostmaster-install:"
sudo su - aegir -c "drush hostmaster-install -y --strict=0 $SITE_URI \
          --aegir_db_host=$AEGIR_DB_HOST \
          --aegir_db_pass=$AEGIR_DB_PASS \
          --aegir_db_port='3306' \
          --aegir_db_user=$AEGIR_DB_USER \
          --aegir_host=$AEGIR_HOST \
          --aegir_root=$AEGIR_HOME \
          --client_name=admin \
          --client_email=admin@$AEGIR_HOST \
          --http_service_type=$WEBSERVER \
          --root=$HOSTMASTER \
          --version=$AEGIR_VERSION
"
# Flush the drush cache to find new commands
sudo su - aegir -c "drush cache:clear drush"


# install hosting-queued daemon
echo " - ÆGIR | Install hosting-queued daemon..."
sudo cp $HOSTMASTER/sites/all/modules/contrib/hosting/queued/init.d.example /etc/init.d/hosting-queued
sudo chmod 755 /etc/init.d/hosting-queued
sudo systemctl daemon-reload
sudo systemctl enable hosting-queued


#  - Enable Aegir modules: hosting_civicrm, hosting_civicrm_cron, ...
echo " - ÆGIR | Enabling hosting modules: hosting-queued daemon, fix ownership & permissions ..."
sudo su - aegir -c "drush @hostmaster pm:enable -y hosting_queued"
sudo su - aegir -c "drush @hostmaster pm:enable -y fix_ownership fix_permissions"
# sudo su - aegir -c "drush @hostmaster pm:enable -y hosting_civicrm hosting_civicrm_cron"


#  - Reload services: nginx, queue, ...
echo " - ÆGIR | Reload services: nginx, queue, ..."
case $WEBSERVER in
    nginx)
        sudo systemctl restart nginx
        ;;
    apache)
        sudo systemctl restart apache2
        ;;
esac
# restart queued daemon
sudo systemctl restart hosting-queued

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

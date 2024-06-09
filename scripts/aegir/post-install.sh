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


echo " - ÆGIR | Prepare /var/aegir..." | tee -a log.txt
# move downloaded files into /var/aegir
sudo mv /tmp/aegir-composer /var/aegir

echo " - ÆGIR | Setup aegir user" | tee -a log.txt
# create user if not yet exists
if ! getent passwd aegir >/dev/null ; then
    sudo adduser --quiet --system --group --no-create-home --home '/var/aegir' --shell '/bin/bash' --gecos 'Aegir user,,,' aegir
    sudo adduser --quiet aegir www-data
    sudo cp /etc/skel/.bash* /var/aegir
    sudo cp /etc/skel/.profile /var/aegir
    sudo chown -R aegir:aegir /var/aegir
    sudo chmod 755 /var/aegir
fi
#  grant passwordless sudo rights for everything
echo 'aegir ALL=(ALL) NOPASSWD:ALL     # no password' > /tmp/aegir
sudo chmod 0440 /tmp/aegir
sudo chown root:root /tmp/aegir
sudo mv /tmp/aegir /etc/sudoers.d/aegir
echo " - ÆGIR | The aegir user and its permissions have been setup." | tee -a log.txt


#  - webserver config to use aegir settings
echo " - ÆGIR | $WEBSERVER is using the Aegir configuration." | tee -a log.txt
AEGIR_CONF="/var/aegir/config/$WEBSERVER.conf"
case "$WEBSERVER" in
    nginx)
        WEBSERVER_CONF="/etc/nginx/conf.d/aegir.conf"
        ;;
    apache)
        WEBSERVER_CONF="/etc/apache2/conf-enabled/aegir.conf"
        ;;
esac
[[ -f "$WEBSERVER_CONF" ]] && sudo su -c "rm $WEBSERVER_CONF"
sudo su -c "ln -s $AEGIR_CONF $WEBSERVER_CONF"


#  Deploy "fix ownership & permissions" scripts
echo " - ÆGIR | deploying fix ownership & permissions scripts" | tee -a log.txt

# remove old scripts, if any
sudo su -c "rm /usr/local/bin/fix-drupal-*.sh 2>/dev/null"
sudo su -c "rm /etc/sudoers.d/fix-drupal-* 2>/dev/null"

# deploy scripts
sudo bash $AEGIR_HOSTMASTER/sites/all/modules/contrib/hosting_tasks_extra/fix_permissions/scripts/standalone-install-fix-permissions-ownership.sh


# setup drush8, download done by composer
echo " - ÆGIR | Setup global Drush8 for Aegir 3.x" | tee -a log.txt
# allow drush via PATH
sudo ln -s $AEGIR_VENDOR/aegir/drush8/drush /usr/bin/drush
# clear cache
sudo su - aegir -c "drush cache:clear drush"

# Configure the Provision module
echo " - ÆGIR | config_provision" | tee -a log.txt

# Configure db user for Aegir
echo " - ÆGIR | db user for Aegir" | tee -a log.txt

# Install Aegir frontend via drush hostmaster-install
echo " - ÆGIR | Install Aegir frontend via drush hostmaster-install" | tee -a log.txt
# Flush the drush cache to find new commands
# sudo su - aegir -c "drush cache:clear drush"

# install hosting-queued daemon
echo " - ÆGIR | Install hosting-queued daemon..."

#  - Enable Aegir modules: hosting_civicrm, hosting_civicrm_cron, ...
echo " - ÆGIR | Enabling hosting modules: hosting-queued daemon, fix ownership & permissions ..."

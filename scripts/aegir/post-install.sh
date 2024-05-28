#! /bin/bash
#
# Aegir 3.x install/update scripts Ubuntu
#
# on Github: https://github.com/argopecten/aegir-hostmaster
#
echo "post-install script" | tee -a log.txt
# occurs after the install command has been executed with a lock file present.

#  - webserver config to use aegir settings
echo " - ÆGIR | config_webserver" | tee -a log.txt

#  Deploy "fix ownership & permissions" scripts
echo " - ÆGIR | deploy_fix_scripts" | tee -a log.txt

# setup drush
echo " - ÆGIR | Setup global Drush8 for Aegir 3.x" | tee -a log.txt
# install mehet a composer.json-ba
# - git clone https://github.com/omega8cc/drush /usr/share/drush8
#  - chown root:ubuntu /usr/share/drush8
#  - chmod 775 /usr/share/drush8
#  - su - ubuntu -c "composer install --working-dir=/usr/share/drush8 -n"
#  - ln -s /usr/share/drush8/drush /usr/bin/drush
#
# init drush
# clear cache

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

#! /bin/bash
#
# Aegir 3.x install/update scripts Ubuntu
#
# on Github: https://github.com/argopecten/aegir-hostmaster
#
echo "post-update script" | tee -a log.txt
# occurs after the update command has been executed,
# or after the install command has been executed without a lock file present.

echo " - ÆGIR | drush @platform_hostmaster provision-verify" | tee -a log.txt
echo " - ÆGIR | drush @hostmaster provision-verify" | tee -a log.txt
echo " - ÆGIR | drush @hostmaster updatedb" | tee -a log.txt
echo " - ÆGIR | drush @platform_hostmaster provision-verify" | tee -a log.txt

#composer update: update vendor packages and drupal core
    # update database for drupal core modules, if necessary
#    sudo su - aegir -c "drush @platform_hostmaster provision-verify"
#    sudo su - aegir -c "drush @hostmaster provision-verify"
#    sudo su - aegir -c "drush @hostmaster updatedb"
#    sudo su - aegir -c "drush @platform_hostmaster provision-verify"

#! /bin/bash
#
# Aegir 3.x install/update scripts Ubuntu
#
# on Github: https://github.com/argopecten/aegir-composer
#
echo "ÆGIR | post-update script is running..."
# occurs after the update command has been executed,
# or after the install command has been executed without a lock file present.

echo " - ÆGIR | drush @platform_hostmaster provision-verify"
echo " - ÆGIR | drush @hostmaster provision-verify"
echo " - ÆGIR | drush @hostmaster updatedb"
echo " - ÆGIR | drush @platform_hostmaster provision-verify"

#composer update: update vendor packages and drupal core
    # update database for drupal core modules, if necessary
#    sudo su - aegir -c "drush @platform_hostmaster provision-verify"
#    sudo su - aegir -c "drush @hostmaster provision-verify"
#    sudo su - aegir -c "drush @hostmaster updatedb"
#    sudo su - aegir -c "drush @platform_hostmaster provision-verify"

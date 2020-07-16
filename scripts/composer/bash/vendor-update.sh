#! /bin/bash
#
# Aegir 3.x install/update scripts for Debian / Ubuntu
#
# on Github: https://github.com/argopecten/aegir-composer
#
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
source "$DIR/common-functions.sh"
CONFIGDIR="$DIR/../config"
source "$CONFIGDIR/aegir.cfg"

###############################################################################
# This script runs when the post-update-cmd event is fired by composer via
# "composer update".
#
# - if Aegir is not found on the server, it does nothing
# - if Aegir is already there, it updates the same Aegir version with vendor
#   packages and drupal core to their latest supported version, as defined in
#   composer.json
#
# Functionality:
#  - Prepare final hostmaster directory
#  - Run database update via drush
#  - Clear cache & restart hosting-queued daemon
#
###############################################################################

echo "ÆGIR | ------------------------------------------------------------------"
###############################################################################
#  - Prepare new hostmaster directory
AEGIR_VERSION=$(new_aegir_version)
AEGIR_HOSTMASTER="$AEGIR_HOME/hostmaster-$AEGIR_VERSION"

if [ -f "$AEGIR_HOME/aegir_version" ]; then
  # this is one of the update scenarios: either aegir upgrade or drupal core & vendor update
  # fetch current aegir version
  HM_VERSION=`drush site:alias @hm | grep root | cut -d"'" -f4 | awk -F \- {'print $2'}`
  if [ "$HM_VERSION" == "$AEGIR_VERSION" ];  then
    # drupal core and/or vendor package update scenario
    echo "ÆGIR | Updating Aegir vendor packages and drupal core ..."
    # maintain content of hostmaster site directory
    sudo su - aegir -c "cp -r $AEGIR_HOSTMASTER/sites/$SITE_URI $AEGIR_HOME/hostmaster/sites"
    # move old hostmaster into backups directory
    sudo mv $AEGIR_HOSTMASTER "$AEGIR_HOME/backups/hostmaster-$HM_VERSION-`date +'%y%m%d-%H%M'`"
    # the new hostmaster directory has to be renamed like hostmaster-3.186
    sudo mv $AEGIR_HOME/hostmaster $AEGIR_HOSTMASTER
    # update databa for drupal core modules, if necessary
    sudo su - aegir -c "drush @platform_hostmaster provision-verify"
    sudo su - aegir -c "drush @hostmaster provision-verify"
    sudo su - aegir -c "drush @hostmaster updatedb"
    sudo su - aegir -c "drush @platform_hostmaster provision-verify"
  else
    # Aegir upgrade scenario: do nothing here
    sudo rm -rf $AEGIR_HOME/hostmaster
    echo "ÆGIR | New Aegir version ($AEGIR_VERSION) has been found."
    echo "ÆGIR | Current version is: $HM_VERSION"
    echo "ÆGIR | Use composer install to upgrade Aegir!"
    exit 0
  fi
else
  # fresh aegir install scenario: there is nothing to update
  sudo rm -rf $AEGIR_HOME/hostmaster
  echo "ÆGIR | Aegir has been not found on server, there is nothing to update."
  echo "ÆGIR | Use composer create-project to install Aegir!"
  exit 0
fi

# refresh drush cache to see provisions drush commands
sudo su - aegir -c "drush cache:clear drush"
# restart queued daemon
sudo systemctl restart hosting-queued

echo "ÆGIR | -----------------------------------------------------------------"
echo "ÆGIR | Vendor packages and Drupal core of $SITE_URI has been updated."
echo "ÆGIR | Site still runs on Aegir $AEGIR_VERSION."
echo "ÆGIR | -----------------------------------------------------------------"

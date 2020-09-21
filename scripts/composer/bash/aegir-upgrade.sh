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
# The script runs when the post-install-cmd event is fired by composer.
# This is the case when "composer install" is executed having a composer.lock
# file present.
#
# Functionality:
#  - it upgrades Aegir to a newer version, if a new version exists.
#  - if Aegir is not found on the server, it does nothing.
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
        sudo rm -rf $AEGIR_HOME/hostmaster

        echo "ÆGIR | There is no new Aegir version to upgrade."
        echo "ÆGIR |   - current version: $HM_VERSION"
        echo "ÆGIR | Run 'composer update' to update vendor packages and drupal core!"
        echo "ÆGIR | Aegir version now remains $HM_VERSION, nothing has changed."
        echo "ÆGIR | ------------------------------------------------------------------"
    else
        # composer install: upgrades Aegir to a newer version
        echo "ÆGIR | New Aegir version ($AEGIR_VERSION) has been found."
        echo "ÆGIR | Current version is: $HM_VERSION"
        echo "ÆGIR | Use composer install to upgrade Aegir!"
        exit 0

        # the new hostmaster directory has to be renamed like hostmaster-3.186
        sudo mv $AEGIR_HOME/hostmaster $AEGIR_HOSTMASTER
        echo "ÆGIR | New hostmaster directory is: $AEGIR_HOSTMASTER"

        # we'll upgrade Aegir frontend by migrating into new hostmaster platform
        sudo su - aegir -c "drush @hostmaster hostmaster-migrate $HOSTNAME $AEGIR_HOSTMASTER -y"

        # refresh drush cache to see provisions drush commands
        sudo su - aegir -c "drush cache:clear drush"
        # restart queued daemon
        sudo systemctl restart hosting-queued

        echo "ÆGIR | -----------------------------------------------------------------"
        echo "ÆGIR | $SITE_URI has been updated, and now runs on Aegir $AEGIR_VERSION."
        echo "ÆGIR | ------------------------------------------------------------------"
    fi
fi

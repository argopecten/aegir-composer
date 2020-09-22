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


# show debug info by setting AEGIR_DEBUG="show"
if [ "$AEGIR_DEBUG" = "show" ]; then
    set -x
fi

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

# set version and hostmaster directory
AEGIR_VERSION=$(new_aegir_version)
AEGIR_HOSTMASTER="$AEGIR_HOME/hostmaster-$AEGIR_VERSION"

# exit if there is no aegir install on server
[[ -f "$AEGIR_HOME/aegir_version" ]] || exit 0

echo "ÆGIR | ------------------------------------------------------------------"
# there in an Aegir on server, so this is one of the update scenarios:
# either aegir upgrade or drupal core & vendor update

# fetch current aegir version
HM_VERSION=`drush site:alias @hm | grep root | cut -d"'" -f4 | awk -F \- {'print $2'}`

if [ "$HM_VERSION" == "$AEGIR_VERSION" ];  then
    # this is the vendor package update scenario, we do nothing here

    # remove the new hostmaster directory downloaded by composer
    sudo rm -rf $AEGIR_HOME/hostmaster

    # inform user
    echo "ÆGIR | Aegir runs on latest version ($HM_VERSION) and won't be upgraded."
    echo "ÆGIR | Run 'composer update' to update vendor packages and drupal core!"
    echo "ÆGIR | ------------------------------------------------------------------"
else
    # upgrades Aegir to a newer version
    echo "ÆGIR | There is a new Aegir version to upgrade."
    echo "ÆGIR |   - current version: $HM_VERSION"
    echo "ÆGIR |   - new version: $AEGIR_VERSION"
    echo "ÆGIR | Upgrading Aegir to $AEGIR_VERSION ..."

    # the new hostmaster directory has to be renamed like hostmaster-3.186
    sudo mv $AEGIR_HOME/hostmaster $AEGIR_HOSTMASTER
    echo "ÆGIR | New hostmaster directory is: $AEGIR_HOSTMASTER"

    # stop hosting queued daemon
    sudo systemctl stop hosting-queued

    # upgrade Aegir frontend by migrating into new hostmaster platform
    sudo su - aegir -c "drush @hostmaster hostmaster-migrate $SITE_URI $AEGIR_HOSTMASTER -y"

    # refresh drush cache to see provisions drush commands
    sudo su - aegir -c "drush cache:clear drush"

    # start queued daemon
    sudo systemctl start hosting-queued

    echo "ÆGIR | -----------------------------------------------------------------"
    if site_status_is_ok ; then
        echo "ÆGIR | $SITE_URI has been updated, and now runs on Aegir $AEGIR_VERSION."
    else
        echo "ÆGIR | Something went wrong!"
        echo "ÆGIR | Look at the log above for clues or run with AEGIR_DEBUG=show"
        exit 1
    fi
    echo "ÆGIR | ------------------------------------------------------------------"
fi

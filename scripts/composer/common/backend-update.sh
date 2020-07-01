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

###########################################################
# Configure Drush, Provision and some more backend settings
#  - prepare new hostmaster directory
#  - Drush configurations
#  - Configure the Provision module
###########################################################
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | Initializing Aegir backend ..."
echo "ÆGIR | ------------------------------------------------------------------"

###############################################################################
#  - prepare new hostmaster directory
###############################################################################
if [ -d "$AEGIR_HOME/hostmaster" ]; then
  # rename hostmaster directory, to allow future upgrades
  sudo mv $AEGIR_HOME/hostmaster $AEGIR_HOSTMASTER
fi

###########################################################
#  Drush configurations
#  - nothing to do here
###########################################################
# drush status
echo "ÆGIR | Checking drush status..."
sudo su - aegir -c "drush cc drush"
sudo su - aegir -c "drush status"


###########################################################
# Configure the Provision module
#  - download: done via Composer, see composer.json
#    https://www.drupal.org/project/provision/
#  - initialize: link provision module into drush path
###########################################################
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | Configuring the Provision module ..."
echo "ÆGIR | ------------------------------------------------------------------"
#  - link provision module into drush paths
DRUSH_COMMANDS=/usr/share/drush/commands
# remove old version, if any
if [ -d "$DRUSH_COMMANDS" ]; then
    sudo rm -rf $DRUSH_COMMANDS
fi
# link provisions drush commands into drush path
sudo mkdir -p $DRUSH_COMMANDS
sudo ln -s $AEGIR_HOSTMASTER/sites/all/drush/provision $DRUSH_COMMANDS

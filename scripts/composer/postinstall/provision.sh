#! /bin/bash
#
# Aegir 3.x install scripts for Debian / Ubuntu
#
# on Github: https://github.com/argopecten/aegir-composer
#
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
source "$DIR/../../aegir.cfg"

###########################################################
# Configure the Provision module
#  - download: done via Composer, see composer.json
#    https://www.drupal.org/project/provision/
#  - initialize: link provision module into drush paths
###########################################################

echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | Initializing Aegir backend ..."
echo "ÆGIR | ------------------------------------------------------------------"


DRUSH_COMMANDS=/usr/share/drush/commands
# remove old version, if any
if [ -d "$DRUSH_COMMANDS" ]; then
    # provision exists
    sudo rm -rf $DRUSH_COMMANDS
else
    sudo mkdir -p $DRUSH_COMMANDS
fi

#  - link provision module into drush paths
sudo ln -s $AEGIR_HOME/hostmaster/sites/all/drush/provision $DRUSH_COMMANDS

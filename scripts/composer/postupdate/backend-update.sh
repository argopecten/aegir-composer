#! /bin/bash
#
# Aegir 3.x install/update scripts for Debian / Ubuntu
#
# on Github: https://github.com/argopecten/aegir-composer
#
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
source "$DIR/../../config/aegir.cfg"

###########################################################
# Configure Drush, Provision and some more backend settings
#  - webserver settings to use aegir config
#  - Drush configurations
#  - Configure the Provision module
###########################################################
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | Updating Aegir backend ..."
echo "ÆGIR | ------------------------------------------------------------------"


###########################################################
#  Drush configurations
#  - download: done via Composer, see composer.json
#    https://github.com/drush-ops/drush/releases
#  - initialize Drush with Aegir home
#  - add drush path for all user
#  - link drush into /usr/local/bin/drush
###########################################################
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | Upgrading Drush ..."
echo "ÆGIR | ------------------------------------------------------------------"

NEWV=`$AEGIR_HOME/vendor/bin/drush --version | awk '/Drush Version/ {print $4}' |  cut -d. -f1-3`
echo "ÆGIR | Drush version before upgrade: $NEWV"

if [[ $ACTUALDRUSHVERSION == $NEWV ]]; then
    # latest version, do nothing
else
    # upgrade drush
    # remove link to previous version
    sudo su -c "rm /usr/local/bin/drush"
    #  link drush into /usr/local/bin/drush
    sudo su -c "ln -s $AEGIR_HOME/vendor/bin/drush /usr/local/bin"
fi

# drush status
echo "ÆGIR | Checking drush status..."
sudo su - aegir -c "drush cc drush"
sudo su - aegir -c "drush status"


###########################################################
# Configure the Provision module
#  - download: done via Composer, see composer.json
#    https://www.drupal.org/project/provision/
#  - initialize: link provision module into drush paths
###########################################################
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | Configuring the Provision module ..."
echo "ÆGIR | ------------------------------------------------------------------"
#  - link provision module into drush paths
DRUSH_COMMANDS=/usr/share/drush/commands
# remove old version, if any
if [ -d "$DRUSH_COMMANDS" ]; then
    # provision exists
    sudo rm -rf $DRUSH_COMMANDS
else
    sudo mkdir -p $DRUSH_COMMANDS
fi
sudo ln -s $AEGIR_HOSTMASTER/sites/all/drush/provision $DRUSH_COMMANDS

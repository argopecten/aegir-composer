#! /bin/bash
#
# Aegir 3.x install scripts for Debian / Ubuntu
#
# on Github: https://github.com/argopecten/aegir-composer
#
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
source "$DIR/../../config/aegir.cfg"

###########################################################
# Configure Drush, Provision and some more backend settings
#  - move downloaded stuff to aegir home, adjust permissions
#  - webserver settings to use aegir config
#  - Drush configurations
#  - Configure the Provision module
###########################################################
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | Initializing Aegir backend ..."
echo "ÆGIR | ------------------------------------------------------------------"


###########################################################
#  - move downloaded stuff to aegir home, adjust permissions
#
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | Prepare aegir home at $AEGIR_HOME ..."

exit 1

###########################################################
#  - webserver settings to use aegir config
sudo ln -s $AEGIR_ROOT/config/nginx.conf /etc/nginx/conf.d/aegir.conf
# remove /etc/nginx/sites-enabled/default ???
# enable aegir
sudo ln -s $AEGIR_ROOT/config/apache.conf /etc/apache2/conf-available/aegir.conf
sudo a2enconf aegir


###########################################################
#  Drush configurations
#  - download: done via Composer, see composer.json
#    https://github.com/drush-ops/drush/releases
#  - initialize Drush with Aegir home
#  - add drush path for all user
#  - link drush into /usr/local/bin/drush
###########################################################
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | Initializing Drush with Aegir ..."
echo "ÆGIR | ------------------------------------------------------------------"

#  - initialize Drush with Aegir home
DRUSH=$AEGIR_HOME/vendor/bin/drush
sudo su - aegir -c "$DRUSH init  --add-path=$AEGIR_HOME --bg -y"

#  - add drush path for all user
echo '#!/bin/sh
export PATH="$PATH:$AEGIR_HOME/vendor/bin"' | sudo tee /etc/profile.d/drush.sh
sudo su -c "chmod +x /etc/profile.d/drush.sh"

#  - link drush into /usr/local/bin/drush
# otherwise hosting-queued is not running
sudo su -c "ln -s $AEGIR_HOME/vendor/bin/drush /usr/local/bin"

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
echo "ÆGIR | Initializing Aegir backend ..."
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

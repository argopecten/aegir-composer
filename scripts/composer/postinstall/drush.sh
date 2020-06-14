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
# Configure Drush on the server
#  - download: done via Composer, see composer.json
#    https://github.com/drush-ops/drush/releases
#
#  - initialize Drush with Aegir home
#  - add drush path for all user
#  - link drush into /usr/local/bin/drush
#
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

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
# Configure Drush on the server
#  - download: done via Composer, see composer.json
#    https://github.com/drush-ops/drush/releases
#
#  - initialize drush:
#    copy example Drush configuration file to /var/aegir/.drush/drushrc.php
#    copy example Drush bash configuration file to /var/aegir/.drush/drush.bashrc
#    copy Drush completion file to /var/aegir/.drush/drush.complete.sh
#    copy example Drush prompt file to /var/aegir/.drush/drush.prompt.sh
#    add path to Drush: export PATH="$PATH:/var/aegir/vendor/bin"
#
###########################################################

echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | Initializing Drush with Aegir ..."
echo "ÆGIR | ------------------------------------------------------------------"

#  - initialize Drush with Aegir home
DRUSH=$AEGIR_HOME/vendor/bin/drush
sudo su - aegir -c "$DRUSH init  --add-path=$AEGIR_HOME --bg -y"

# add drush path to all user
echo '#!/bin/sh
export PATH="$PATH:/var/aegir/vendor/bin"' | sudo tee /etc/profile.d/drush.sh
sudo su -c "chmod +x /etc/profile.d/drush.sh"

# link drush into /usr/local/bin/drush
# otherwise hosting-queued is not running
sudo su -c "ln -s /var/aegir/vendor/bin/drush /usr/local/bin"

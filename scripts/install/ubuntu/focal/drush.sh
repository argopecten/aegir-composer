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
###########################################################


DRUSH=$AEGIR_HOME/vendor/bin/drush

# does it really needed? drush init does it anyway...
# link drush into /usr/local/bin
# sudo ln -s $DRUSH /usr/local/bin/drush

#  - initialize Drush with Aegir adduser
sudo su - aegir -c "$DRUSH init  --add-path=$AEGIR_HOME --bg -y"

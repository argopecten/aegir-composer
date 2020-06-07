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

#  - link provision module into drush paths
sudo mkdir -p /usr/share/drush/commands
sudo ln -s $AEGIR_HOME/hostmaster/sites/all/drush/provision /usr/share/drush/commands

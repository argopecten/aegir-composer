#! /bin/bash
#
# Aegir 3.x install scripts for Debian / Ubuntu
#
# on Github: https://github.com/argopecten/aegir-composer
#
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
source "$DIR/../../aegir.cfg"

# Called by aegir-install.sh and run with root privileges

###########################################################
# Configure user for Aegir
#  - create user
#  - add to groups
#  - sudo rights to restart webserver
###########################################################

#  - create user
adduser --system --group --home $AEGIR_HOME aegir --shell /usr/bin/bash

#  - add to groups
adduser aegir www-data

#  - sudo rights to restart webserver
echo 'aegir ALL=NOPASSWD: /etc/init.d/nginx    # for Nginx'  | tee /tmp/aegir
echo 'aegir ALL=NOPASSWD: /usr/sbin/apache2ctl # for Apache' | tee /tmp/aegir
chmod 0440 /tmp/aegir
mv /tmp/aegir /etc/sudoers.d/aegir

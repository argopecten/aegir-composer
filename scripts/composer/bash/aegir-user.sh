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

###############################################################################
# This script runs when the pre-install-cmd event is fired by composer
#
# functions: Create Aegir user and grant permissions, prepare Aegir home
#  - create user and add to webserver group
#  - grant passwordless sudo rights for everything
###############################################################################

echo "ÆGIR | ------------------------------------------------------------------"
# check current setup
if [ -d "$AEGIR_HOME" ] && getent passwd aegir >/dev/null ; then
  # aegir home and aegir user exists --> skip, it's an update scenario
  echo "ÆGIR | The aegir user has been already setup."
else
  # no aegir home --> fresh install, do something
  echo "ÆGIR | Setting up the Aegir user ..."
  #  - create user and add to webserver group
  if ! getent passwd aegir >/dev/null ; then
      sudo adduser --quiet --system --no-create-home --group \
          --home "$AEGIR_HOME" \
          --shell '/bin/bash' \
          --gecos 'Aegir user,,,' \
          aegir
  fi
  sudo adduser --quiet aegir www-data

  #############################################################################
  #  - grant passwordless sudo rights for everything
  echo 'aegir ALL=(ALL) NOPASSWD:ALL     # no password' > /tmp/aegir
  # restricted permissions only to restart webserver
  # echo 'aegir ALL=NOPASSWD: /etc/init.d/nginx    # for Nginx'  >  /tmp/aegir
  # echo 'aegir ALL=NOPASSWD: /usr/sbin/apache2ctl # for Apache' >> /tmp/aegir
  sudo chmod 0440 /tmp/aegir
  sudo chown root:root /tmp/aegir
  sudo mv /tmp/aegir /etc/sudoers.d/aegir

  echo "ÆGIR | The aegir user has been setup."
fi
echo "ÆGIR | ------------------------------------------------------------------"

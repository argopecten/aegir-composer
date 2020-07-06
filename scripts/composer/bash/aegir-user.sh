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
#  - move downloaded stuff to aegir home and set permissions
#  - add github personal token
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
  # TODO: use config file from source
  echo 'aegir ALL=(ALL) NOPASSWD:ALL     # no password' > /tmp/aegir
  # restricted permissions only to restart webserver
  # echo 'aegir ALL=NOPASSWD: /etc/init.d/nginx    # for Nginx'  >  /tmp/aegir
  # echo 'aegir ALL=NOPASSWD: /usr/sbin/apache2ctl # for Apache' >> /tmp/aegir
  sudo chmod 0440 /tmp/aegir
  sudo chown root:root /tmp/aegir
  sudo mv /tmp/aegir /etc/sudoers.d/aegir

  #############################################################################
  #  - move downloaded stuff to aegir home and set permissions
  echo "ÆGIR | Preparing aegir home at $AEGIR_HOME ..."
  # copy composer downloads into aegir home
  sudo cp -R $TMPDIR_AEGIR $AEGIR_HOME/
  # - grant user permissions on all directories installed via composer
  sudo chown aegir:aegir -R "$AEGIR_HOME"

  #############################################################################
  # Because of GitHub's rate limits on their API it can happen that Composer prompts
  # for authentication asking your username and password so it can go ahead with its work.
  # Optionally set your personal token here, it will be stored in
  # "/var/aegir/.config/composer/auth.json" for future use by Composer.
  unset githubtoken
  # fetch the token of the acting user
  actinguser=`whoami`
  githubtoken=`grep "github.com" /home/$actinguser/.config/composer/auth.json | awk -F'"' '{print $4}'`
  if [ -z $githubtoken ]; then
      echo "ÆGIR | Github personal token has NOT been found."
      echo "ÆGIR | This may later interrupt the deployment process!"
      read -sp "Enter your github personal token here (or take the risk and press enter to continue): " githubtoken
      echo
  fi
  # githubtoken is set, store it for aegir user
  sudo su - aegir -c "composer config -g github-oauth.github.com $githubtoken"
  echo "ÆGIR | Github personal token has been set for aegir user in $AEGIR_HOME/.config/composer/auth.json"
  unset githubtoken

  echo "ÆGIR | The aegir user has been setup."

fi
echo "ÆGIR | ------------------------------------------------------------------"

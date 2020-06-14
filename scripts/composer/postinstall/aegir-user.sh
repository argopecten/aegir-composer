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
#  Create Aegir user with permission to restart webserver
#  - create the user
#  - add aegir user to webserver group
#  - grant sudo rights
#  - fix permissions on installed directories
#  - add github personal token
###########################################################

#  - create user if not yet there
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | Creating aegir user ..."
echo "ÆGIR | ------------------------------------------------------------------"
if ! getent passwd aegir >/dev/null ; then
    sudo adduser --quiet --system --no-create-home --group \
        --home "$AEGIR_HOME" \
        --shell '/bin/bash' \
        --gecos 'Aegir user,,,' \
        aegir
fi

#  - add to groups
sudo adduser --quiet aegir www-data

#  - grant sudo rights for everything
# TODO: use config file from source
echo 'aegir ALL=(ALL) NOPASSWD:ALL     # no password' > /tmp/aegir
# restricted permissions only to restart webserver
# echo 'aegir ALL=NOPASSWD: /etc/init.d/nginx    # for Nginx'  >  /tmp/aegir
# echo 'aegir ALL=NOPASSWD: /usr/sbin/apache2ctl # for Apache' >> /tmp/aegir
sudo chmod 0440 /tmp/aegir
sudo chown root:root /tmp/aegir
sudo mv /tmp/aegir /etc/sudoers.d/aegir

# - set user permissions on installed directories
sudo chown aegir:aegir -R "$AEGIR_HOME"

# set github personal token for aegir user
unset githubtoken
# fetch the token of the acting user
actinguser=`whoami`
githubtoken=`grep "github.com" /home/$actinguser/.config/composer/auth.json | awk -F'"' '{print $4}'`
if [ -z $githubtoken ]; then
    # githubtoken remains unset, do nothing
    echo "ÆGIR | Github personal token has NOT been set for the aegir user."
    echo "ÆGIR | This may later interrupt the deployment process!"
else
    # githubtoken is set, store it for aegir user
    sudo su - aegir -c "composer config -g github-oauth.github.com $githubtoken"
    echo "ÆGIR | Github personal token has been set in .config/composer/auth.json"
    unset githubtoken
fi

echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | aegir user installed."
echo "ÆGIR | ------------------------------------------------------------------"

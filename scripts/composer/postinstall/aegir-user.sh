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
#  - move downloaded stuff to aegir home
#  - create user if not yet there
#  - add aegir user to webserver group
#  - grant sudo rights
#  - grant user permissions on all directories
#  - add github personal token
###########################################################

cho "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | Creating aegir user ..."
echo "ÆGIR | ------------------------------------------------------------------"

###########################################################
#  - move downloaded stuff to aegir home
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | Preparing aegir home at $AEGIR_HOME ..."
#  - move composer downloads into aegir home
cd $TMPDIR_AEGIR
sudo cp -R $TMPDIR_AEGIR/. $AEGIR_HOME/

#  - create user if not yet there
echo "ÆGIR | Creating user ..."
if ! getent passwd aegir >/dev/null ; then
    sudo adduser --quiet --system --no-create-home --group \
        --home "$AEGIR_HOME" \
        --shell '/bin/bash' \
        --gecos 'Aegir user,,,' \
        aegir
fi

echo "ÆGIR | Grand permissions ..."
#  - add to groups
sudo adduser --quiet aegir www-data
# - grant user permissions on all directories installed via composer
sudo chown aegir:aegir -R "$AEGIR_HOME"

#  - grant sudo rights for everything
# TODO: use config file from source
echo 'aegir ALL=(ALL) NOPASSWD:ALL     # no password' > /tmp/aegir
# restricted permissions only to restart webserver
# echo 'aegir ALL=NOPASSWD: /etc/init.d/nginx    # for Nginx'  >  /tmp/aegir
# echo 'aegir ALL=NOPASSWD: /usr/sbin/apache2ctl # for Apache' >> /tmp/aegir
sudo chmod 0440 /tmp/aegir
sudo chown root:root /tmp/aegir
sudo mv /tmp/aegir /etc/sudoers.d/aegir

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

echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | aegir user installed."
echo "ÆGIR | ------------------------------------------------------------------"

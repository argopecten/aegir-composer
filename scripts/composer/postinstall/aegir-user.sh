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
#  Create Aegir user with permission to restart webserver
#  - create the user
#  - add aegir user to webserver group
#  - grant sudo rights
# - fix permissions on installed directories
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

# - set permissions on installed directories
sudo chown aegir:aegir -R "$AEGIR_HOME"

echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | aegir user installed."
echo "ÆGIR | ------------------------------------------------------------------"

#! /bin/bash
#
# Aegir 3.x install/update scripts Ubuntu
#
# on Github: https://github.com/argopecten/aegir-composer
#
echo "ÆGIR | pre-install script is running..."
# before the install command is executed with a lock file present
# before any files downloaded by composer

echo " - ÆGIR | Setup aegir user"
# create user if not yet exists
if ! getent passwd aegir >/dev/null ; then
    sudo adduser --quiet --home "/var/aegir" --disabled-password --gecos 'Aegir user,,,' aegir
    sudo adduser --quiet aegir www-data
fi

#  grant passwordless sudo rights for everything
[[ -f /tmp/aegir ]] && sudo su -c "rm -rf /tmp/aegir"
echo 'aegir ALL=(ALL) NOPASSWD:ALL     # no password' > /tmp/aegir
sudo chmod 0440 /tmp/aegir
sudo chown root:root /tmp/aegir
sudo mv /tmp/aegir /etc/sudoers.d/aegir
echo " - ÆGIR | The aegir user and its permissions have been setup." | sudo tee -a log.txt

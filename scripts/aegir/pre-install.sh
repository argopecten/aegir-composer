#! /bin/bash
#
# Aegir 3.x install/update scripts Ubuntu
#
# on Github: https://github.com/argopecten/aegir-composer
#
echo "ÆGIR | pre-install script is running..." | tee -a log.txt
# before the install command is executed with a lock file present
# before any files downloaded by composer

echo " - ÆGIR | Setup aegir user" | tee -a log.txt
# create user if not yet exists
if ! getent passwd aegir >/dev/null ; then
    sudo adduser --quiet --system --group --no-create-home --home '/var/aegir' --shell '/bin/bash' --gecos 'Aegir user,,,' aegir
    sudo adduser --quiet aegir www-data
    sudo cp /etc/skel/.bash* /var/aegir
    sudo cp /etc/skel/.profile /var/aegir
fi

#  grant passwordless sudo rights for everything
echo 'aegir ALL=(ALL) NOPASSWD:ALL     # no password' > /tmp/aegir
sudo chmod 0440 /tmp/aegir
sudo chown root:root /tmp/aegir
sudo mv /tmp/aegir /etc/sudoers.d/aegir
echo " - ÆGIR | The aegir user and its permissions have been setup." | sudo tee -a log.txt

# prepare Aegir directory and set permissions
echo " - ÆGIR | Preparing aegir home ..." | sudo tee -a log.txt
# move downloaded stuff intto aegir home
sudo cp -R /tmp/aegir /var/aegir/
# grant user permissions
sudo chown -R aegir:aegir /var/aegir

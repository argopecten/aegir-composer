#! /bin/bash
#
# Aegir 3.x install scripts for Debian / Ubuntu
#
# on Github: https://github.com/argopecten/aegir-composer
#
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
source "$DIR/../../config/postfix.cfg"

###########################################################
# Install required OS packages for Aegir, except LAMP
###########################################################

# Update & upgrade OS packages
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | Upgrading packages..."
sudo apt update -y
sudo apt upgrade -y
sudo apt autoremove -y

# all aegir dependencies as per control file
#    (https://git.drupalcode.org/project/provision/blob/7.x-3.x/debian/control)
# sudo, adduser, ucf, curl, git-core, unzip, lsb-base, rsync, nfs-client
# packages being part of the standard Focal 20.04 image:
#    sudo, adduser, ucf, curl, git, unzip, ls-base, rsync

# packages installed on Ubuntu Focal LTS 20.04
echo "ÆGIR | Installing packages for Aegir..."
sudo apt install nfs-common ssl-cert -y

echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | OS packages installed & upgraded."
echo "ÆGIR | ------------------------------------------------------------------"

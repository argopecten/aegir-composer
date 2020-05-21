#! /bin/bash
#
# Aegir 3.x install scripts for Debian / Ubuntu
#
# on Github: https://github.com/argopecten/aegir-composer
#
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
source "$DIR/../../postfix.cfg"

###########################################################
# Install required dependencies for Aegir
#   installed elsewhere: web, DB & PHP packages
###########################################################

# update & upgrade packages
sudo apt update -y
sudo apt upgrade -y
sudo apt autoremove -y

# all aegir dependencies as per control file
#    (https://git.drupalcode.org/project/provision/blob/7.x-3.x/debian/control)
# sudo, adduser, ucf, curl, git-core, unzip, lsb-base, rsync, nfs-client
# packages being part of the standard Focal 20.04 image:
#    sudo, adduser, ucf, curl, git, unzip, ls-base, rsync

# packages installed on Ubuntu Focal LTS 20.04
sudo apt install nfs-common ssl-cert -y

# Postfix install
#    TODO: does it really needed?
sudo debconf-set-selections <<< "postfix postfix/mailname string $hostname"
sudo debconf-set-selections <<< "postfix postfix/main_mailer_type string $mailer_type"
sudo apt install postfix -y

# TDOD
# sudo ufw allow 'Postfix'
# sudo ufw app info 'Postfix'
#  Postfix SMTPS
#  Postfix Submission

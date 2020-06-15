#! /bin/bash
#
# Aegir 3.x install scripts for Debian / Ubuntu
# on Github: https://github.com/argopecten/aegir-composer
#
###########################################################
# Install required dependencies for Aegir
#
#   0) Setting hostname ...
#   1) Update OS & install packages
#   2) database server
#   3) webserver
#   4) postfix
#   5) PHP libraries for Aegir
#   6) PHP composer
###########################################################


###########################################################
# Variables used in install.
# Change them if you know what are you doing.
#
# Hostname and default for Aegir frontend
AEGIR_HOST="aegir.local"
#
#############
# Webserver: set to Nginx or Apache
WEBSERVER="nginx"
# WEBSERVER="apache2"

#############
# PHP version and run mode
#  - PHP version
PHP_VERSION="7.3"
# PHP_VERSION="7.2"
#
#  - PHP run mode:
PHP_MOD=fpm
# PHP_MOD=mod-php

# PHP Composer
# https://github.com/composer/getcomposer.org
COMPOSER_VERSION="c5e3f5a2a8e6742d38a9eb716161c32931243f57"   # 2020-06-03 build 1.10.7

# Postfix mailer type
mailer_type='Internet Site'

###########################################################


# Check OS and its flavor
OS=ubuntu
FLAVOR=focal


# (re)set hostname
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | 0) Setting hostname ..."
echo "ÆGIR | ------------------------------------------------------------------"
unset hn
echo "ÆGIR | Default hostname is $AEGIR_HOST ..."
read -sp "Enter your FQDN hostname here (or press enter to continue with default): " hn
if [ -z $hn ]; then
    echo
else
    AEGIR_HOST=$hn
    unset hn
fi
echo "ÆGIR | Continuing with hostname: $AEGIR_HOST"
sudo hostnamectl set-hostname "$AEGIR_HOST"

# Install required OS packages for Aegir
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | 1) Installing system packages ..."
###########################################################
# Install required OS packages for Aegir, except LAMP
###########################################################

# Update & upgrade OS packages
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | Upgrading packages..."
sudo apt update -y
sudo apt upgrade -y

# all aegir dependencies as per control file
#    (https://git.drupalcode.org/project/provision/blob/7.x-3.x/debian/control)
# sudo, adduser, ucf, curl, git-core, unzip, lsb-base, rsync, nfs-client
# packages being part of the standard Focal 20.04 image:
#    sudo, adduser, ucf, curl, git, unzip, ls-base, rsync

# packages to be installed on Ubuntu Focal LTS 20.04:
echo "ÆGIR | Installing packages for Aegir..."
sudo apt install nfs-common ssl-cert unzip -y
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | OS packages installed & upgraded."
echo "ÆGIR | ------------------------------------------------------------------"


# Install database server
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | 2) Installing database server for Aegir ..."
echo "ÆGIR | ------------------------------------------------------------------"
sudo apt install -y mariadb-server mariadb-client
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | Database server installed."
echo "ÆGIR | ------------------------------------------------------------------"


# Install webserver
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | 3) Installing the webserver for Aegir ..."
echo "ÆGIR | ------------------------------------------------------------------"
case "$WEBSERVER" in
  nginx)
      sudo apt install nginx -y
      sudo systemctl enable nginx
      ;;

  apache2)
      sudo apt install apache2 -y
      ;;

  *) echo "No webserver defined, aborting!"
     exit 1
     ;;
esac
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | Webserver installed."
echo "ÆGIR | ------------------------------------------------------------------"


# Postfix install
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | 4) Postfix install & config ..."
echo "ÆGIR | ------------------------------------------------------------------"
#    TODO: does it really needed here?
sudo debconf-set-selections <<< "postfix postfix/mailname string $AEGIR_HOST"
sudo debconf-set-selections <<< "postfix postfix/main_mailer_type string $mailer_type"
sudo apt install postfix -y
# is it needed???
sudo systemctl enable postfix
sudo systemctl start postfix
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | Postfix installed."
echo "ÆGIR | ------------------------------------------------------------------"

# Install PHP libraries for Aegir
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | 5) Installing PHP libraries ..."
###########################################################
# Install and configure PHP packages for Drupal & Aegir
#  - set PHP repo
#  - install required PHP packages for Aegir
#  - install required PHP packages for CiviCRM
###########################################################
V=$PHP_VERSION
echo "PHP version=$V"
echo "ÆGIR | ------------------------------------------------------------------"

# using the PHP repo https://packages.sury.org/php/
sudo LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/php -y
sudo apt update -y

case "$PHP_MOD" in
    fpm) echo "PHP: FPM"
        PHP_PKG=php$V-fpm
        ;;
    mod-php) echo "PHP: mod-php"
        PHP_PKG=libapache2-mod-php$V
        ;;
    *) echo "PHP mode is not defined, aborting!"
        exit 1
        ;;
esac

# install PHP libraries for Drupal & Aegir
sudo apt install php$V-mysql php$V-xml php$V-gd $PHP_PKG -y

# install PHP libraries for CiviCRM
sudo apt install php$V-mbstring php$V-curl php$V-zip -y

echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | PHP libraries installed."
echo "ÆGIR | ------------------------------------------------------------------"


# Install Composer
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | 6) Installing PHP Composer ..."
echo "ÆGIR | ------------------------------------------------------------------"
wget https://raw.githubusercontent.com/composer/getcomposer.org/$COMPOSER_VERSION/web/installer -O - -q | php -- --quiet > ./composer.phar
sudo mv ./composer.phar /usr/bin/composer
composer --version
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | PHP Composer installed."
echo "ÆGIR | ------------------------------------------------------------------"

# clean up
sudo apt autoremove -y

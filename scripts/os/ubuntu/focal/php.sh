#! /bin/bash
#
# Aegir 3.x install scripts for Debian / Ubuntu
#
# on Github: https://github.com/argopecten/aegir-composer
#
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
source "$DIR/../../../aegir.cfg"
source "$DIR/../../config/php.cfg"

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

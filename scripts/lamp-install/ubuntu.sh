#! /bin/bash
#
################################################################################
# Aegir 3.x install scripts for Debian / Ubuntu
# on Github: https://github.com/argopecten/aegir-composer
################################################################################
### Install required dependencies for Aegir
#   - Ubuntu 20.04 (focal)
#   - Ubuntu 18.04 (bionic)
#
#   use it with default values:
#     bash ubuntu.sh
#   or change any of these default settings via command line:
#     bash ubuntu.sh -w nginx -p fpm -d mariadb -n aegir.local
#   usage tips:
#     bash ubuntu.sh -h
#
### The script does the following:
#   0) Change default settings like hostname, webserver & PHP run.mode, database
#   1) Update OS & install packages
#   2) Install database server
#   3) Install webserver
#   4) Install postfix
#   5) Install PHP libraries and run-mode for Aegir
#   6) Install PHP composer
################################################################################

### Defauls settings for the script
### Hostname (and Aegir frontend)
#   any FQDN name, default is aegir.example.com
HOSTNAME="aegir.ubuntu.local"

### Database:
#   supported database flavors: mariadb or mysql
SUPPORTED_DATABASE_FLAVORS="mariadb|mysql"
#   default database in Ubuntu is mysql
DATABASE="mysql"

### Webserver
#   supported webserver flavors: nginx or apache2
SUPPORTED_WEBSERVER_FLAVORS="apache2|nginx"
#   default webserver flavor in Ubuntu is apache2
WEBSERVER="apache2"

### PHP run mode, must be aligned to the webserver!
#   supported PHP run modes: php-fpm or mod-php
#   php-fpm works with Apache & Nginx as well
#   mod-php runs with Apache only
SUPPORTED_PHP_RUNMODE="mod-php|fpm"
#   default PHP run-mode
PHP_RUNMODE="mod-php"

# PHP Composer version
# https://github.com/composer/getcomposer.org
COMPOSER_VERSION="55e3ac0516cf01802649468315cd863bcd46a73f"   # 2020-08-03 build 1.10.10

# Postfix mailer type
mailer_type='Internet Site'

################################################################################
### Parse command line arguments to change the default settings
#   https://wiki.bash-hackers.org/howto/getopts_tutorial
usage() {
  echo "$0 arguments to use:
  $0 -n <hostname> -p <PHP run-mode> -d <database> -w <webserver>" \
  && grep " .)\ #" $0; exit 0;
}
# exit if there is an argument without option
[[ ($# -ne 0) && (${1:0:1} != "-") ]] && usage && exit 1
# parse options & arguments
while getopts ":hn:p:d:w:" arg; do
  case $arg in
    n) # Specify hostname as any FQDN phrase you want!
      fqdn=`echo ${OPTARG} | grep -P '(?=^.{1,254}$)(^(?>(?!\d+\.)[a-zA-Z0-9_\-]{1,63}\.?)+(?:[a-zA-Z]{2,})$)'`
      # check valid FQDN syntax: https://stackoverflow.com/questions/32909454/evaluation-of-a-valid-fqdn-on-bash-regex
      [[ -z "$fqdn" ]] \
        && echo "Hostname needs to be an FQDN, but ${OPTARG} found instead." \
        || HOSTNAME=$fqdn
      ;;
    p) # Specify PHP run-mode: fpm or mod-php, or leave empty for default (mod-php)!
      [[ ${OPTARG} =~ ${SUPPORTED_PHP_RUNMODE} ]] && PHP_RUNMODE=${OPTARG} \
         || (echo "It needs to be one of $SUPPORTED_PHP_RUNMODE, but ${OPTARG} found instead" && exit 1)
       ;;
    d) # Specify database, either mysql or mariadb!
      [[ ${OPTARG} =~ ${SUPPORTED_DATABASE_FLAVORS} ]] && DATABASE=${OPTARG} \
         || (echo "It needs to be one of $SUPPORTED_DATABASE_FLAVORS, but ${OPTARG} found instead" && exit 1)
      ;;
    w) # Specify webserver, either apache2 or nginx!
      [[ ${OPTARG} =~ ${SUPPORTED_WEBSERVER_FLAVORS} ]] && WEBSERVER=${OPTARG} \
         || (echo "It needs to be one of $SUPPORTED_WEBSERVER_FLAVORS, but ${OPTARG} found instead" && exit 1)
      ;;
    h | *) # Display help.
      usage
      exit 0
      ;;
  esac
done

# ask user for confirmation
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | Hostname will be: $HOSTNAME"
echo "ÆGIR | LAMP components to be installed for Aegir:"
echo "ÆGIR |    webserver:     $WEBSERVER"
echo "ÆGIR |    PHP run-mode:  $PHP_RUNMODE"
echo "ÆGIR |    database:      $DATABASE-server"
echo "ÆGIR | ------------------------------------------------------------------"
read -p "Press enter to continue with this configuration, or any other letter to exit!" -n 1 -r -s
echo
[[ $REPLY =~ ^[a-zA-Z] ]] && echo -e "\nBreak $0 script" && exit 0
echo "ÆGIR | ------------------------------------------------------------------"

# Exit if php-mod and nginx are configured
[[ (${PHP_RUNMODE} == "mod-php") && ($WEBSERVER == "nginx") ]] && (echo "ÆGIR | Inconsitent configuration, exit!" && exit 1)

################################################################################
# (re)set hostname
sudo hostnamectl set-hostname "$HOSTNAME"

################################################################################
# Install required OS packages for Aegir, except LAMP
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | 1) Installing & upgrading OS packages ..."
sudo apt update -y
sudo apt upgrade -y

# all aegir dependencies as per control file
#    (https://git.drupalcode.org/project/provision/blob/7.x-3.x/debian/control)
# sudo, adduser, ucf, curl, git-core, unzip, lsb-base, rsync, nfs-client
# packages being part of the standard Ubuntu image:
#    sudo, adduser, ucf, curl, lsb-base, rsync, git-core, openssl
# packages to be installed on Ubuntu:
echo "ÆGIR | Installing packages for Aegir..."
sudo apt install unzip  -y
echo "ÆGIR | OS packages installed & upgraded."

# Install database server
echo "ÆGIR | 2) Installing database server for Aegir ..."
sudo apt install -y "$DATABASE-server" "$DATABASE-client"

# Install webserver
echo "ÆGIR | 3) Installing the webserver for Aegir ..."
sudo apt install -y $WEBSERVER

# Postfix install
echo "ÆGIR | 4) Postfix install & config ..."
# TBC: move to lamp config
sudo debconf-set-selections <<< "postfix postfix/mailname string $HOSTNAME"
sudo debconf-set-selections <<< "postfix postfix/main_mailer_type string $mailer_type"
sudo apt install postfix -y

################################################################################
# Install and configure PHP packages for Drupal & Aegir
#  - prepare PHP install for 3 PHP run-modes
#  - install required PHP packages for Aegir
#  - install required PHP packages for CiviCRM
echo "ÆGIR | 5) Installing PHP libraries ..."

# prepare PHP install for 3 PHP run-modes, and exit if php-mod and nginx are configured
#  - nginx with php-fpm
#  - apache with mod_php
#  - apache with php-fpm (TBC: not yet tested)

# PHP run-mode for Apache with PHP-FPM
[[ (${PHP_RUNMODE} == "fpm") && ($WEBSERVER == "apache2") ]] && WEBSERVER="apache2-php-fpm"

# PHP config per cases
case "$WEBSERVER" in
  nginx) # Nginx with PHP-FPM
    PHP_PKG=php-fpm
    ;;
  apache2) # Apache with mod_php
    PHP_PKG=libapache2-mod-php
    sudo a2enmod rewrite
    ;;
  apache2-php-fpm) # Apache with PHP-FPM
    # TBC: not yet tested
    # https://community.aegirproject.org/content/content/administrator/post-install-configuration/experimental-aegir-2-ubuntu-1204-apache-php/index.html
    # https://tecadmin.net/install-apache-php-fpm-ubuntu-18-04/
    # enable PHP FPM in Apache2
    PHP_PKG=php-fpm
    sudo apt install -y libapache2-mod-fcgid
    sudo a2enmod proxy_fcgi rewrite
    # TBD: move it after php-fpm install, into lamp-config: sudo a2enconf php-fpm
    ;;
esac

# install PHP libraries for Drupal & Aegir
sudo apt install php-mysql php-xml php-gd $PHP_PKG -y
# install PHP libraries for CiviCRM
sudo apt install php-mbstring php-curl php-zip -y
echo "ÆGIR | PHP libraries installed."

# Install Composer
echo "ÆGIR | 6) Installing PHP Composer ..."
curl -s https://raw.githubusercontent.com/composer/getcomposer.org/$COMPOSER_VERSION/web/installer | php -- --quiet > ./composer.phar
sudo mv ./composer.phar /usr/bin/composer

################################################################################
# clean up
sudo apt autoremove -y
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | Hostname is now: $HOSTNAME"
echo "ÆGIR | LAMP components installed for Aegir:"
echo "ÆGIR |    webserver:     $WEBSERVER"
echo "ÆGIR |    PHP run-mode:  $PHP_RUNMODE"
echo "ÆGIR |    database:      $DATABASE-server"
V=`php -v | awk '/PHP 7/ {print $2}' |  cut -d. -f1-3`
echo "ÆGIR |    PHP version:   $V"
echo "ÆGIR |    Composer:"
composer --version
echo "ÆGIR | ------------------------------------------------------------------"

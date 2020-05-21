#! /bin/bash
#
# Aegir 3.x install scripts for Debian / Ubuntu
#
# on Github: https://github.com/argopecten/aegir-composer
#
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
source "$DIR/../../aegir.cfg"
source "$DIR/../../php.cfg"

###########################################################
# Install and configure PHP packages for Aegir
#  - set PHP repo
#  - install required PHP packages
#  - PHP configurations: memory size, upload, ...
###########################################################

V=$PHP_VERSION
echo PHP=$V

# using the PHP repo https://packages.sury.org/php/
sudo LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/php -y
sudo apt update -y

case "$PHP_MOD" in
fpm)   echo "PHP: FPM"
    PHP_PKG=php$V-fpm
    ;;
mod-php)  echo "PHP: mod-php"
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

#  - PHP configurations: memory size, upload, ...
case "$WEBSERVER" in
nginx)   echo "Configuring PHP for Nginx..."
    # upload_max_filesize
    sudo sed -i -e "/^upload_max_filesize/s/^.*$/upload_max_filesize = $PHP_UPLOAD_MAX_FILESIZE/" /etc/php/$V/cli/php.ini
    sudo sed -i -e "/^upload_max_filesize/s/^.*$/upload_max_filesize = $PHP_UPLOAD_MAX_FILESIZE/" /etc/php/$V/fpm/php.ini
    # post_max_size
    sudo sed -i -e "/^post_max_size/s/^.*$/post_max_size = $PHP_POST_MAX_SIZE/" /etc/php/$V/cli/php.ini
    sudo sed -i -e "/^post_max_size/s/^.*$/post_max_size = $PHP_POST_MAX_SIZE/" /etc/php/$V/fpm/php.ini
    # memory_limit
    sudo sed -i -e "/^memory_limit/s/^.*$/memory_limit = $PHP_MEMORY_LIMIT/" /etc/php/$V/fpm/php.ini
    ;;
apache2)  echo "Configuring PHP for Apache ..."
    # upload_max_filesize
    sudo sed -i -e "/^upload_max_filesize/s/^.*$/upload_max_filesize = $PHP_UPLOAD_MAX_FILESIZE/" /etc/php/$V/cli/php.ini
    sudo sed -i -e "/^upload_max_filesize/s/^.*$/upload_max_filesize = $PHP_UPLOAD_MAX_FILESIZE/" /etc/php/$V/apache2/php.ini
    # post_max_size
    sudo sed -i -e "/^post_max_size/s/^.*$/post_max_size = $PHP_POST_MAX_SIZE/" /etc/php/$V/cli/php.ini
    sudo sed -i -e "/^post_max_size/s/^.*$/post_max_size = $PHP_POST_MAX_SIZE/" /etc/php/$V/apache2/php.ini
    # memory_limit
    sudo sed -i -e "/^memory_limit/s/^.*$/memory_limit = $PHP_MEMORY_LIMIT/" /etc/php/$V/apache2/php.ini
    ;;
*) echo "No webserver defined, aborting!"
   exit 1
   ;;
esac

# Composer
wget https://raw.githubusercontent.com/composer/getcomposer.org/$COMPOSER_VERSION/web/installer -O - -q | php -- --quiet
sudo mv composer.phar /usr/bin/composer
# composer --version

# TODO:
# - reload services
# - clean up

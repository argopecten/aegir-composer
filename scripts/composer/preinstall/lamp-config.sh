#! /bin/bash
#
# Aegir 3.x install scripts for Debian / Ubuntu
#
# on Github: https://github.com/argopecten/aegir-composer
#
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
CONFIGDIR="$DIR/../../config"
source "$CONFIGDIR/aegir.cfg"
source "$CONFIGDIR/mariadb.cfg"
source "$CONFIGDIR/php.cfg"
source "$CONFIGDIR/postfix.cfg"

###########################################################
# Configure LAMP for Aegir
#
#  only activies not relying on location of aegir home!
#
# 1) setting up a basic firewall
# 2) securing database server
# 3) configure webserver
#  - link Aegir config file
#  - enable modules
#  - PHP configurations: memory size, upload, ...
#  - firewall settings
# 4) configure Postfix
# 5) clean up & reload services
###########################################################

###########################################################
# 1) setting up a basic firewall
# TBD

###########################################################
# 2) securing database server
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | Securing database server ..."
echo "ÆGIR | ------------------------------------------------------------------"
# Set root password in database, aegir still requires it in that way
# prompt user for database root password
unset dbpwd
unset dbpwd2
while true; do
    read -sp "Set database root password: " dbpwd
    echo
    read -sp "Database root password (again): " dbpwd2
    echo
    [ "$dbpwd" = "$dbpwd2" ] && break
    echo "Please try again!"
done
echo "ÆGIR | Running mysql_secure_installation ..."
echo -e "\n\n$dbpwd\n$dbpwd\n\n\nn\n\n " | sudo mysql_secure_installation &>/dev/null
unset dbpwd
unset dbpwd2
echo "ÆGIR | Database server secured."
echo "ÆGIR | ------------------------------------------------------------------"

###########################################################
# 3) configure webserver
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | Configuring webserver & PHP ..."
echo "ÆGIR | ------------------------------------------------------------------"

# fetch PHP version
V=`php -v | awk '/PHP 7/ {print $2}' |  cut -d. -f1-2`
echo "ÆGIR | PHP version: $V"

# fetch the running webserver
if [[ `ps -acx | grep apache | wc -l` > 0 ]]; then
    WEBSERVER="apache2"
fi
if [[ `ps -acx | grep nginx | wc -l` > 0 ]]; then
    WEBSERVER="nginx"
fi
# TODO: check variable and exit is empty
echo "ÆGIR | Server has $WEBSERVER as webserver."
echo "WEBSERVER=$WEBSERVER" >> $CONFIGDIR/aegir.cfg

case "$WEBSERVER" in
  nginx)   echo "ÆGIR | Configuring nginx..."
      # upload_max_filesize
      sudo sed -i -e "/^upload_max_filesize/s/^.*$/upload_max_filesize = $PHP_UPLOAD_MAX_FILESIZE/" /etc/php/$V/cli/php.ini
      sudo sed -i -e "/^upload_max_filesize/s/^.*$/upload_max_filesize = $PHP_UPLOAD_MAX_FILESIZE/" /etc/php/$V/fpm/php.ini
      # post_max_size
      sudo sed -i -e "/^post_max_size/s/^.*$/post_max_size = $PHP_POST_MAX_SIZE/" /etc/php/$V/cli/php.ini
      sudo sed -i -e "/^post_max_size/s/^.*$/post_max_size = $PHP_POST_MAX_SIZE/" /etc/php/$V/fpm/php.ini
      # memory_limit
      sudo sed -i -e "/^memory_limit/s/^.*$/memory_limit = $PHP_MEMORY_LIMIT/" /etc/php/$V/fpm/php.ini
      ;;

  apache2)  echo "ÆGIR | Configuring up Apache ..."
      # enable modules
      sudo a2enmod ssl rewrite
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

###########################################################
# 4) configure Postfix
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | Postfix config ..."
echo "ÆGIR | ------------------------------------------------------------------"
sudo debconf-set-selections <<< "postfix postfix/mailname string $myhostname"
sudo debconf-set-selections <<< "postfix postfix/main_mailer_type string $mailer_type"

###########################################################
# 5) clean up & reload services
# - reload LAMP services
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | Reloading LAMP services ..."
echo "ÆGIR | ------------------------------------------------------------------"
# cron
echo "ÆGIR | Reloading cron ..."
sudo systemctl restart cron

# database
echo "ÆGIR | Reloading database ..."
sudo systemctl restart mysql
# Returns true once mysql can connect.
while ! mysqladmin ping -h"$AEGIR_DB_HOST" --silent; do
  sleep 3
  echo "ÆGIR | Waiting for database on $AEGIR_DB_HOST ..."
done
echo "ÆGIR | Database is active!"

# webserver & PHP
# do not restart webserver here, aegir.conf is not yet in place!
case "$WEBSERVER" in
    nginx) echo "ÆGIR | Reloading Nginx..."
        sudo systemctl restart php$V-fpm
        ;;
    apache2)  echo "ÆGIR | Reloading  Apache ..."
        # TODO: php-fpm
        ;;
    *) echo "No webserver defined, aborting!"
        exit 1
        ;;
esac

# Postfix
echo "ÆGIR | Reloading postfix ..."
sudo systemctl reload postfix

# - clean up
echo "ÆGIR | Cleaning up ..."
sudo apt autoremove -y 2>/dev/null
# fetch the running webserver
if [ -d "$TMPDIR_AEGIR" ]; then
    suro rm -rf $TMPDIR_AEGIR
fi

echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | LAMP/LEMP configuration has been done for Aegir."
echo "ÆGIR | ------------------------------------------------------------------"

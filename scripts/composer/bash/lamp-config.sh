#! /bin/bash
#
# Aegir 3.x install/update scripts for Debian / Ubuntu
#
# on Github: https://github.com/argopecten/aegir-composer
#
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
source "$DIR/common-functions.sh"
CONFIGDIR="$DIR/../config"
source "$CONFIGDIR/aegir.cfg"
source "$CONFIGDIR/mariadb.cfg"
source "$CONFIGDIR/php.cfg"
source "$CONFIGDIR/postfix.cfg"

###############################################################################
# This script runs when the post-install-cmd event is fired by composer via
# "composer create-project" or "composer install".
#
# functions:
# - call subsequent scripts depending on which scenario is there:
#   1) There is an existing Aegir setup, no configuration is necessary
#   2) fresh install of Aegir, configure LÆMP accordingly for Aegir
#
###############################################################################

echo "ÆGIR | ------------------------------------------------------------------"
# check current setup
if aegir_is_there ; then
  # aegir home and aegir user exists --> skip, it's an update scenario
  # we assume the first Aegir install has configured these components properly
  echo "ÆGIR | Aegir user & home exists."
  echo "ÆGIR | Assuming all LÆMP components are configured for Aegir."
else
  # no aegir home --> fresh install
  echo "ÆGIR | Configuring LÆMP for Aegir ..."

  ###########################################################
  # 1) setting up a basic firewall
  # TBD

  ###########################################################
  # 2) securing database server
  echo "ÆGIR | Securing database server ..."
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

  ###########################################################
  # 3) configure webserver
  echo "ÆGIR | Configuring webserver & PHP ..."

  # fetch PHP version and the running webserver
  V=$(fetch_php_version)
  WEBSERVER=$(fetch_webserver)
  echo "ÆGIR | Server has $WEBSERVER as webserver with PHP $V"

  case "$WEBSERVER" in
    nginx)   echo "ÆGIR | Configuring nginx..."
        # delete default config file
        sudo rm /etc/nginx/sites-enabled/default
        # upload_max_filesize
        sudo sed -i -e "/^upload_max_filesize/s/^.*$/upload_max_filesize = $PHP_UPLOAD_MAX_FILESIZE/" /etc/php/$V/cli/php.ini
        sudo sed -i -e "/^upload_max_filesize/s/^.*$/upload_max_filesize = $PHP_UPLOAD_MAX_FILESIZE/" /etc/php/$V/fpm/php.ini
        # post_max_size
        sudo sed -i -e "/^post_max_size/s/^.*$/post_max_size = $PHP_POST_MAX_SIZE/" /etc/php/$V/cli/php.ini
        sudo sed -i -e "/^post_max_size/s/^.*$/post_max_size = $PHP_POST_MAX_SIZE/" /etc/php/$V/fpm/php.ini
        # memory_limit
        sudo sed -i -e "/^memory_limit/s/^.*$/memory_limit = $PHP_MEMORY_LIMIT/" /etc/php/$V/fpm/php.ini
        ;;

    apache)  echo "ÆGIR | Configuring up Apache ..."
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
  echo "ÆGIR | Postfix config ..."
  # TBD
  sudo debconf-set-selections <<< "postfix postfix/mailname string $myhostname"
  sudo debconf-set-selections <<< "postfix postfix/main_mailer_type string $mailer_type"

  ###########################################################
  # 5) clean up & reload services
  # - reload LAMP services
  echo "ÆGIR | Reloading LAMP services ..."

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
      apache)  echo "ÆGIR | Reloading  Apache ..."
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

  echo "ÆGIR | LÆMP configuration has been done for Aegir."

fi
echo "ÆGIR | ------------------------------------------------------------------"

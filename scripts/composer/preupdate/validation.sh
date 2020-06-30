#! /bin/bash
#
# Aegir 3.x install/update scripts for Debian / Ubuntu
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
# 1) check database server
# 2) check webserver
# 3) check PHP
# 4) clean up & reload services
###########################################################

###########################################################
# 1) setting up aegir code
#  - move downloaded stuff to aegir home
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | Preparing aegir home at $AEGIR_HOME ..."
#  - move composer downloads into aegir home
cd $TMPDIR_AEGIR
sudo cp -R . $AEGIR_HOME/
# rename hostmaster directory
sudo mv $AEGIR_HOME/hostmaster $AEGIR_HOSTMASTER

ACTUALDRUSHVERSION=`drush --version | awk '/Drush Version/ {print $4}' |  cut -d. -f1-3`
echo "ÆGIR | Drush version before upgrade: $ACTUALDRUSHVERSION"
echo "ACTUALDRUSHVERSION=$ACTUALDRUSHVERSION" >> $CONFIGDIR/aegir.cfg

###########################################################
# 2) securing database server
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | Checking database server ..."
# Returns true once mysql can connect.
while ! mysqladmin ping -h"$AEGIR_DB_HOST" --silent; do
  sleep 3
  echo "ÆGIR | Waiting for database on $AEGIR_DB_HOST ..."
done
echo "ÆGIR | Database server is OK."
echo "ÆGIR | ------------------------------------------------------------------"

###########################################################
# 3) configure webserver
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | Checking webserver & PHP ..."

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
# TODO: compare to seeting in config file and abort if mismatch
echo "ÆGIR | Server has $WEBSERVER as webserver."

# webserver & PHP
# TODO: check service status
case "$WEBSERVER" in
    nginx) echo "ÆGIR | Checking Nginx..."
        ;;
    apache2)  echo "ÆGIR | Checking  Apache ..."
        # TODO: php-fpm
        ;;
    *) echo "No webserver defined, aborting!"
        exit 1
        ;;
esac

###########################################################
# 4) configure Postfix
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | Checking Postfix config ..."
echo "ÆGIR | ------------------------------------------------------------------"


echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | LAMP/LEMP config check has been done before Aegir upgrade!"
echo "ÆGIR | ------------------------------------------------------------------"

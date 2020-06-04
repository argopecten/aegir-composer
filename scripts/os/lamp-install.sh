#! /bin/bash
#
# Aegir 3.x install scripts for Debian / Ubuntu
#
# on Github: https://github.com/argopecten/aegir-composer
#
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
source "$DIR/../aegir.cfg"

###########################################################
# Install required dependencies for Aegir
#
#   - system packages and Aegir user
#   - database server
#   - webserver
#   - PHP libraries and composer
#   - install and configure Aegir
###########################################################


# Install required OS packages for Aegir
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | 1) Installing system packages ..."
# echo $DIR/$OS/$FLAVOR/packages.sh
bash $DIR/$OS/$FLAVOR/packages.sh

# Install & config database server
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | 2) Installing database server for Aegir ..."
echo "ÆGIR | ------------------------------------------------------------------"
sudo apt install -y mariadb-server mariadb-client
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | Database server installed."
echo "ÆGIR | ------------------------------------------------------------------"

# Install & config webserver
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | 3) Installing the webserver for Aegir ..."
echo "ÆGIR | ------------------------------------------------------------------"
case "$WEBSERVER" in
  nginx)
      sudo apt install nginx -y
      ;;

  apache2)
      sudo apt install apache2 -y
      sudo a2enmod rewrite
      sudo a2enconf aegir
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
sudo debconf-set-selections <<< "postfix postfix/mailname string $hostname"
sudo debconf-set-selections <<< "postfix postfix/main_mailer_type string $mailer_type"
sudo apt install postfix -y
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | Postfix installed."
echo "ÆGIR | ------------------------------------------------------------------"

# Install & config PHP libraries
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | 5) Installing PHP libraries ..."
bash $DIR/$OS/$FLAVOR/php.sh
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | PHP libraries installed."
echo "ÆGIR | ------------------------------------------------------------------"

# Install Composer
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | 6) Installing PHP Composer ..."
echo "ÆGIR | ------------------------------------------------------------------"
wget https://raw.githubusercontent.com/composer/getcomposer.org/$COMPOSER_VERSION/web/installer -O - -q | php -- --quiet
sudo mv composer.phar /usr/bin/composer
composer --version
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | PHP Composer installed."
echo "ÆGIR | ------------------------------------------------------------------"

#  - create Aegir user with permission to restart webserver
#    this runs with root privileges
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | 7) Creating aegir user ..."
echo "ÆGIR | ------------------------------------------------------------------"
sudo su -c "bash $DIR/$OS/$FLAVOR/aegir-user.sh"
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | aegir user installed."
echo "ÆGIR | ------------------------------------------------------------------"

#! /bin/bash
#
# Aegir 3.x install scripts for Debian / Ubuntu
#
# on Github: https://github.com/argopecten/aegir-composer
#
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
source "$DIR/../../aegir.cfg"


###########################################################
# Install and configure Nginx or Apache2 for Aegir
#  - install webserver
#  - link Aegir config file
#  - enable modules
###########################################################

case "$WEBSERVER" in

nginx)   echo "Setup Nginx..."
    sudo apt install nginx -y
    sudo ln -s /var/aegir/config/nginx.conf /etc/nginx/conf.d/aegir.conf
    sudo ufw allow 'Nginx Full'
    ;;
apache2)  echo "Setup Apache ..."
    sudo apt install apache2 -y
    sudo ln -s /var/aegir/config/apache.conf /etc/apache2/conf-available/aegir.conf
    sudo a2enmod rewrite
    sudo a2enconf aegir
    sudo ufw allow 'APACHE Full'
    ;;
*) echo "No webserver defined, aborting!"
   exit 1
   ;;
esac

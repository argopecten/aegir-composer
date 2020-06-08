#! /bin/bash
#
# Aegir 3.x install scripts for Debian / Ubuntu
#
# on Github: https://github.com/argopecten/aegir-composer
#
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
source "$DIR/../../aegir.cfg"
source "$DIR/../../os/config/php.cfg"

###########################################################
# Configure LAMP for Aegir
###########################################################

# set hostname
# TBC: is it OK here????
sudo hostnamectl set-hostname "$AEGIR_HOST"

#  - securing MariaDB
echo -e "\n\n$MYSQL_ROOT_PASSWORD\n$MYSQL_ROOT_PASSWORD\n\n\nn\n\n " | sudo mysql_secure_installation 2>/dev/null
sudo service mysql restart
echo "select host, user, password from mysql.user;" |  sudo mysql

###########################################################
# Install and configure Nginx or Apache2 for Aegir
#  - link Aegir config file
#  - enable modules
#  - PHP configurations: memory size, upload, ...
###########################################################
V=$PHP_VERSION
case "$WEBSERVER" in
  nginx)   echo "Setup Nginx..."
      sudo ln -s $AEGIR_HOME/hostmaster/config/nginx.conf /etc/nginx/conf.d/aegir.conf
      # remove /etc/nginx/sites-enabled/default ???
      # service nginx reload
      sudo ufw allow 'Nginx Full'
      # upload_max_filesize
      sudo sed -i -e "/^upload_max_filesize/s/^.*$/upload_max_filesize = $PHP_UPLOAD_MAX_FILESIZE/" /etc/php/$V/cli/php.ini
      sudo sed -i -e "/^upload_max_filesize/s/^.*$/upload_max_filesize = $PHP_UPLOAD_MAX_FILESIZE/" /etc/php/$V/fpm/php.ini
      # post_max_size
      sudo sed -i -e "/^post_max_size/s/^.*$/post_max_size = $PHP_POST_MAX_SIZE/" /etc/php/$V/cli/php.ini
      sudo sed -i -e "/^post_max_size/s/^.*$/post_max_size = $PHP_POST_MAX_SIZE/" /etc/php/$V/fpm/php.ini
      # memory_limit
      sudo sed -i -e "/^memory_limit/s/^.*$/memory_limit = $PHP_MEMORY_LIMIT/" /etc/php/$V/fpm/php.ini
      ;;

  apache2)  echo "Setup Apache ..."
      # sudo ln -sf $AEGIR_HOME/config/apache.conf /etc/apache2/conf-available/aegir.conf
      sudo a2enconf aegir
      sudo a2enmod ssl rewrite
      sudo ufw allow 'APACHE Full'
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

# Postfix install & config
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | Postfix config ..."
#    TODO: does it really needed?
sudo debconf-set-selections <<< "postfix postfix/mailname string $hostname"
sudo debconf-set-selections <<< "postfix postfix/main_mailer_type string $mailer_type"

# TODO
# sudo ufw allow 'Postfix'
# sudo ufw app info 'Postfix'
#  Postfix SMTPS
#  Postfix Submission

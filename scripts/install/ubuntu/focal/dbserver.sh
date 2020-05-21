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
# Install and configure MariaDB database server for Aegir
#  - TODO: use MariaDB repo
#  - install MariaDB
#  - securing MariaDB
#  - misc
###########################################################


#  - install mariadb
sudo apt install mariadb-server mariadb-client

#  - securing MariaDB
echo -e "\n\n$MYSQL_ROOT_PASSWORD\n$MYSQL_ROOT_PASSWORD\n\n\nn\n\n " | sudo mysql_secure_installation 2>/dev/null


# TODO: create user aegir_root
# mysql --user="root" --password="$MYSQL_ROOT_PASSWORD" --execute="GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_AEGIR_DB_USER'@'%' IDENTIFIED BY '$MYSQL_AEGIR_DB_PASSWORD' WITH GRANT OPTION;"

# enable all IP addresses to bind, not just localhost
# TODO: locate .cnf file: sed -i 's/bind-address/#bind-address/' /etc/mysql/my.cnf

sudo service mysql restart

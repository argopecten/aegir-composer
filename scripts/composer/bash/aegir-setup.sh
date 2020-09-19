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
source "$CONFIGDIR/database.cfg"

###############################################################################
# This script runs when the post-update-cmd event is fired by composer:
#
# Functionality:
#   - composer create-project: install Aegir on fresh OS
#   - composer update: update the vendor packages and drupal core to their
#      latest supported version, acoording to composer.json
#   - composer install: upgrades Aegir to a newer version
###############################################################################

# fetch the running webserver
WEBSERVER=$(fetch_webserver)
# fetch new aegir version
AEGIR_VERSION=$(new_aegir_version)
# new hostmaster directory
AEGIR_HOSTMASTER="$AEGIR_HOME/hostmaster-$AEGIR_VERSION"

echo "ÆGIR | ------------------------------------------------------------------"
# check current Aegir setup
if aegir_is_there ; then
  # fetch current aegir version
  HM_VERSION=`drush site:alias @hm | grep root | cut -d"'" -f4 | awk -F \- {'print $2'}`
  if [ "$HM_VERSION" != "$AEGIR_VERSION" ];  then
      # composer install: upgrades Aegir to a newer version
      SCENARIO="aegir-upgrade"
  else
      # composer update: update the vendor packages and drupal core
      SCENARIO="vendor-update"
  fi
else
    # no aegir home --> fresh install, do something
    echo "ÆGIR | Installing Aegir $AEGIR_VERSION ..."
    SCENARIO="fresh-install"
fi

###############################################################################
# prepare content of aegir directory and the aegir user
case $SCENARIO in
    fresh-install) # composer create-project: install Aegir on fresh OS

        #  create user and add to webserver group
        echo "ÆGIR | Setting up the Aegir user ..."
        if ! getent passwd aegir >/dev/null ; then
            sudo adduser --quiet --system --no-create-home --group \
                --home "$AEGIR_HOME" \
                --shell '/bin/bash' \
                --gecos 'Aegir user,,,' \
                aegir
            sudo adduser --quiet aegir www-data
        fi
        #  grant passwordless sudo rights for everything
        echo 'aegir ALL=(ALL) NOPASSWD:ALL     # no password' > /tmp/aegir
        sudo chmod 0440 /tmp/aegir
        sudo chown root:root /tmp/aegir
        sudo mv /tmp/aegir /etc/sudoers.d/aegir
        echo "ÆGIR | The aegir user and its permsisions have been setup."

        # prepare directories and set permissions
        echo "ÆGIR | Preparing aegir home at $AEGIR_HOME ..."
        TMPDIR="$HOME/$INSTALL_DIR"
        # move downloaded stuff to aegir home and set permissions
        sudo cp -R $TMPDIR $AEGIR_HOME/
        # grant user permissions on all directories downloaded by composer
        sudo chown aegir:aegir -R "$AEGIR_HOME"
        ;;

    vendor-update) # composer update: update vendor packages and drupal core
        echo "ÆGIR | Updating Aegir vendor packages and drupal core ..."
        echo "ÆGIR | There is no new Aegir version to upgrade."
        echo "ÆGIR | Current version: $AEGIR_VERSION"

        # maintain content of hostmaster "sites" directory
        sudo su - aegir -c "cp -r $AEGIR_HOSTMASTER/sites/$SITE_URI $AEGIR_HOME/hostmaster/sites"

        # move old hostmaster into backups directory
        sudo mv $AEGIR_HOSTMASTER "$AEGIR_HOME/backups/hostmaster-$HM_VERSION-`date +'%y%m%d-%H%M'`"
        ;;

    aegir-upgrade) # composer install: upgrades Aegir to a newer version
        echo "ÆGIR | Upgrading Aegir from $HM_VERSION to $AEGIR_VERSION ..."
        ;;
esac
# the new hostmaster directory has to be renamed like hostmaster-3.186
sudo mv $AEGIR_HOME/hostmaster $AEGIR_HOSTMASTER
echo "ÆGIR | New hostmaster directory is: $AEGIR_HOSTMASTER"

###############################################################################
# (re)configure Aegir backend:
# - configure webserver to use aegir settings
# - deploy fix ownership & permissions scripts
# - drush is only initialized during fresh install
# - configure provision commands with drush

#  - webserver config to use aegir settings
config_webserver

#  Deploy "fix ownership & permissions" scripts
deploy_fix_scripts

# setup drush
setup_drush

# Configure the Provision module https://www.drupal.org/project/provision/
config_provision

###############################################################################
# setup Aegir frontend
case $SCENARIO in
    fresh-install) # composer create-project: install Aegir on fresh OS
        # random database password for aegir user will be stored in
        #    /var/aegir/.drush/server_localhost.alias.drushrc.php
        AEGIR_DB_PASS=$(openssl rand -base64 12)
        # Create db-user for Aegir, aligned to changes in MySQL 8.0
        # https://www.drupal.org/project/provision/issues/3145881
        sudo /usr/bin/mysql -e "CREATE USER IF NOT EXISTS '$AEGIR_DB_USER'@'$AEGIR_DB_HOST'"
        sudo /usr/bin/mysql -e "ALTER USER '$AEGIR_DB_USER'@'$AEGIR_DB_HOST' IDENTIFIED BY '$AEGIR_DB_PASS'"
        sudo /usr/bin/mysql -e "GRANT ALL ON *.* TO '$AEGIR_DB_USER'@'$AEGIR_DB_HOST' WITH GRANT OPTION"

        #  Install Aegir frontend via drush hostmaster-install
        echo "ÆGIR | We will install Aegir frontend with the following options:"
        echo "ÆGIR | "
        echo "ÆGIR | Aegir URI:      $SITE_URI"
        echo "ÆGIR | Aegir server:   $AEGIR_HOST"
        echo "ÆGIR | Aegir root:     $AEGIR_HOME"
        echo "ÆGIR | Admin name:     $AEGIR_CLIENT_NAME"
        echo "ÆGIR | Web group:      www-data"
        echo "ÆGIR | Webserver:      $WEBSERVER"
        echo "ÆGIR | Webserver port: 80"
        echo "ÆGIR | Database host:  $AEGIR_DB_HOST"
        echo "ÆGIR | Database user:  $AEGIR_DB_USER"
        echo "ÆGIR | Database pwd:   stored in $AEGIR_HOME/.drush/server_localhost.alias.drushrc.php"
        echo "ÆGIR | Database port:  3306"
        echo "ÆGIR | Aegir version:  $AEGIR_VERSION"
        echo "ÆGIR | Hostmaster dir: $AEGIR_HOSTMASTER"
        echo "ÆGIR | Admin email:    $AEGIR_CLIENT_EMAIL"
        echo "ÆGIR | Aegir profile:  hostmaster"
        echo "ÆGIR | "

        echo "ÆGIR | Running: drush hostmaster-install:"
        sudo su - aegir -c " \
        drush hostmaster-install -y --strict=0 $SITE_URI \
          --aegir_db_host=$AEGIR_DB_HOST \
          --aegir_db_pass=$AEGIR_DB_PASS \
          --aegir_db_port='3306' \
          --aegir_db_user=$AEGIR_DB_USER \
          --aegir_host=$AEGIR_HOST \
          --aegir_root=$AEGIR_HOME \
          --client_name=$AEGIR_CLIENT_NAME \
          --client_email=$AEGIR_CLIENT_EMAIL \
          --http_service_type=$WEBSERVER \
          --root=$AEGIR_HOSTMASTER \
          --version=$AEGIR_VERSION \
        "

        # just to be sure :)
        sleep 3
        # Flush the drush cache to find new commands
        sudo su - aegir -c "drush cache:clear drush"

        # install hosting-queued daemon
        echo "ÆGIR | Install hosting-queued daemon..."
        # Install the init script
        sudo cp $AEGIR_HOSTMASTER/sites/all/modules/contrib/hosting/queued/init.d.example /etc/init.d/hosting-queued
        sudo chmod 755 /etc/init.d/hosting-queued
        sudo systemctl daemon-reload
        sudo systemctl enable hosting-queued

        #  - Enable Aegir modules: hosting_civicrm, hosting_civicrm_cron, ...
        echo "ÆGIR | Enabling hosting modules for CiviCRM ..."
        sudo su - aegir -c "drush @hostmaster pm:enable -y hosting_queued"
        sudo su - aegir -c "drush @hostmaster pm:enable -y fix_ownership fix_permissions"
        # sudo su - aegir -c "drush @hostmaster pm:enable -y hosting_civicrm hosting_civicrm_cron"

        echo "ÆGIR | -----------------------------------------------------------------"
        echo "ÆGIR | Aegir $AEGIR_VERSION has been installed via Composer ..."
        echo "ÆGIR | -----------------------------------------------------------------"
        ;;

    vendor-update) # composer update: update vendor packages and drupal core
        # update database for drupal core modules, if necessary
        sudo su - aegir -c "drush @platform_hostmaster provision-verify"
        sudo su - aegir -c "drush @hostmaster provision-verify"
        sudo su - aegir -c "drush @hostmaster updatedb"
        sudo su - aegir -c "drush @platform_hostmaster provision-verify"
        echo "ÆGIR | ------------------------------------------------------------------"
        ;;

    aegir-upgrade) # composer install: upgrades Aegir to a newer version
        # we'll upgrade Aegir frontend by migrating into new hostmaster platform
        sudo su - aegir -c "drush @hostmaster hostmaster-migrate $HOSTNAME $AEGIR_HOSTMASTER -y"
        echo "ÆGIR | -----------------------------------------------------------------"
        echo "ÆGIR | $SITE_URI has been updated, and now runs on Aegir $AEGIR_VERSION."
        echo "ÆGIR | ------------------------------------------------------------------"
        ;;
esac

# restart webserver now, after aegir.conf file has been generated
case $WEBSERVER in
    nginx)
        sudo systemctl restart nginx
        ;;
    apache)
        sudo systemctl restart apache2
        ;;
esac
# restart queued daemon
sudo systemctl restart hosting-queued

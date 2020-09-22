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

# show debug info by setting AEGIR_DEBUG="show"
if [ "$AEGIR_DEBUG" = "show" ]; then
    set -x
fi

###############################################################################
# The script runs when the post-update-cmd event is fired by composer:
# This is the case when:
#  - "composer create-project" is executed, which implies a "composer install"
#    without a composer.lock file), or
#  - "composer update" is executed
#
# Functionality:
#   - composer create-project: install Aegir on fresh OS
#   - composer update: update the vendor packages and drupal core to their
#      latest supported version, acoording to composer.json
###############################################################################

# fetch the running webserver
WEBSERVER=$(fetch_webserver)
# fetch new aegir version
AEGIR_VERSION=$(new_aegir_version)
# new hostmaster directory
AEGIR_HOSTMASTER=$(get_hostmaster_dir)

echo "ÆGIR | ------------------------------------------------------------------"
# check current Aegir setup
if aegir_is_there ; then
    # update vendor and drupal core, but remain on actual Aegir version
    # fetch current aegir version
    HM_VERSION=`drush site:alias @hm | grep root | cut -d"'" -f4 | awk -F \- {'print $2'}`
    if [ "$HM_VERSION" != "$AEGIR_VERSION" ];  then
        # there is a new Aegir version
        # notify user to upgrade Aegir via 'composer install'
        echo "ÆGIR | There is a new Aegir version to upgrade."
        echo "ÆGIR |   - current version: $HM_VERSION"
        echo "ÆGIR |   - new version: $AEGIR_VERSION"
        echo "ÆGIR | Run later 'composer install' to upgrade Aegir to $AEGIR_VERSION!"
        echo "ÆGIR | Aegir version now remains $HM_VERSION, only vendor packages are being updated."
        echo "ÆGIR | ------------------------------------------------------------------"
    fi
    # composer update: update the vendor packages and drupal core
    echo "ÆGIR | Updating vendor packages and drupal core ..."
    SCENARIO="vendor-update"
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
        echo "ÆGIR | Preparing folders in Aegir home directory ..."

        # maintain content of hostmaster "sites" directory
        sudo su - aegir -c "cp -r $AEGIR_HOSTMASTER/sites/$SITE_URI $AEGIR_HOME/hostmaster/sites"

        # move old hostmaster into backups directory
        sudo mv $AEGIR_HOSTMASTER "$AEGIR_HOME/backups/hostmaster-$HM_VERSION-`date +'%y%m%d-%H%M'`"
        ;;

esac
# the new hostmaster directory has to be renamed like hostmaster-3.186
sudo mv $AEGIR_HOME/hostmaster $AEGIR_HOSTMASTER
echo "ÆGIR | Hostmaster directory is: $AEGIR_HOSTMASTER"

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

# Configure the Provision module
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
        echo "ÆGIR | Enabling hosting modules: hosting-queued daemon, fix ownership & permissions ..."
        sudo su - aegir -c "drush @hostmaster pm:enable -y hosting_queued"
        sudo su - aegir -c "drush @hostmaster pm:enable -y fix_ownership fix_permissions"
        # sudo su - aegir -c "drush @hostmaster pm:enable -y hosting_civicrm hosting_civicrm_cron"

        # user message if status is OK
        RESULT="ÆGIR | Aegir $AEGIR_VERSION has been installed via Composer ..."
        ;;

    vendor-update) # composer update: update vendor packages and drupal core
        # update database for drupal core modules, if necessary
        sudo su - aegir -c "drush @platform_hostmaster provision-verify"
        sudo su - aegir -c "drush @hostmaster provision-verify"
        sudo su - aegir -c "drush @hostmaster updatedb"
        sudo su - aegir -c "drush @platform_hostmaster provision-verify"

        # user message if status is OK
        RESULT="ÆGIR | Vendor packages and Drupal core of $SITE_URI has been updated."
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

echo "ÆGIR | -----------------------------------------------------------------"
if site_status_is_ok ; then
    echo $RESULT
else
    echo "ÆGIR | Something went wrong!"
    echo "ÆGIR | Look at the log above for clues or run with AEGIR_DEBUG=show"
    exit 1
fi
echo "ÆGIR | -----------------------------------------------------------------"

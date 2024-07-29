#! /bin/bash
#
# Aegir 3.x install/update scripts Ubuntu
#
# on Github: https://github.com/argopecten/aegir-composer
#
echo "ÆGIR | post-create script is running..."
# occurs after the create-project command has been executed

# reload services
echo " - ÆGIR | systemctl restart nginx"
# sudo systemctl restart nginx

# restart queued daemon
echo " - ÆGIR | systemctl restart hosting-queued"
# sudo systemctl restart hosting-queued

echo " - ÆGIR | drush uli"
# drush uli ?

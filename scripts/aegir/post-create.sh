#! /bin/bash
#
# Aegir 3.x install/update scripts Ubuntu
#
# on Github: https://github.com/argopecten/aegir-hostmaster
#
echo "post-create script" | tee -a log.txt
# occurs after the create-project command has been executed

# reload services
echo " - ÆGIR | systemctl restart nginx" | tee -a log.txt
# sudo systemctl restart nginx

# restart queued daemon
echo " - ÆGIR | systemctl restart hosting-queued" | tee -a log.txt
# sudo systemctl restart hosting-queued

echo " - ÆGIR | drush uli" | tee -a log.txt
# drush uli ?

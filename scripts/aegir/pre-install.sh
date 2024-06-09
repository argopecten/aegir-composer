#! /bin/bash
#
# Aegir 3.x install/update scripts Ubuntu
#
# on Github: https://github.com/argopecten/aegir-composer
#
echo "ÆGIR | pre-install script is running..." | tee -a log.txt
# before the install command is executed with a lock file present
# before any files downloaded by composer

# to be sure it does not exists
[[ -d /tmp/aegir-composer ]] && sudo su -c "rm -rf /tmp/aegir-composer"

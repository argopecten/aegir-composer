#! /bin/bash
#
# Aegir 3.x install/update scripts Ubuntu
#
# on Github: https://github.com/argopecten/aegir-composer
#
echo "ÆGIR | post-root-package-install script is running..." | tee -a log.txt
# occurs after the root package has been installed during the create-project
# command (but before its dependencies are installed).

echo " - ÆGIR | Hi there, install is starting ..." | tee -a log.txt

#! /bin/bash
#
# Aegir 3.x install/update scripts Ubuntu
#
# on Github: https://github.com/argopecten/aegir-hostmaster
#
echo "post-root-package-install script" | tee -a log.txt
# occurs after the root package has been installed during the create-project
# command (but before its dependencies are installed).

echo " - ÆGIR | Hi there, install is starting ..." | tee -a log.txt

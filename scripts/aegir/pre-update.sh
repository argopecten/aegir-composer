#! /bin/bash
#
# Aegir 3.x install/update scripts Ubuntu
#
# on Github: https://github.com/argopecten/aegir-hostmaster
#
echo "pre-update script" | tee -a log.txt
# occurs before the update command is executed,
# or before the install command is executed without a lock file present.

echo " - ÆGIR | backup maybe?" | tee -a log.txt

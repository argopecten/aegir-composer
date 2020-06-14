#! /bin/bash
#
# Aegir 3.x install scripts for Debian / Ubuntu
#
# on Github: https://github.com/argopecten/aegir-composer
#
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
source "$DIR/aegir.cfg"

###########################################################
# Install required dependencies for Aegir
#
#   - system packages and Aegir user
#   - database server
#   - webserver
#   - PHP libraries and composer
#   - install and configure Aegir
###########################################################

Aegir version
AEGIR_VERSION="3.185"  # 2020-06-06
#AEGIR_VERSION="3.184"  # 2019-12-18

# v: aegir version: 3.185
# w: webserver, nginx or apache2
# p: PHP version: 7.3
# m: PHP mod: FPM or lib...

while getopts 'v:w:p:m:' OPTION; do
 case "$OPTION" in
   v)
     echo "aegir version"
     AEGIR_VERSION="$OPTARG"
     echo "The value provided is $OPTARG"
     ;;

   w)
     echo "webserver"
     WEBSERVER=="$OPTARG"
     echo "The value provided is $OPTARG"
     ;;

   p)
   PHP_VERSION="7.3"
     echo "PHP version"
     WEBSERVER=="$OPTARG"
     echo "The value provided is $OPTARG"

     avalue="$OPTARG"
     echo "The value provided is $OPTARG"
     ;;
   ?)
     echo "script usage: $(basename $0) [-l] [-h] [-a somevalue]" >&2
     exit 1
     ;;
 esac
done


# Install LAMP components for Aegir
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | A) Installing LAMP ..."
bash $DIR/os/lamp-install.sh
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR"
echo "ÆGIR"
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | B) Installing Aegir with Composer ..."

composer create-project argopecten/aegir-composer \
         --stability dev \
         --no-interaction \
         --repository '{"type": "vcs","url":  "https://github.com/argopecten/aegir-composer"}' \
         aegir-$AEGIR_VERSION $AEGIR_VERSION

#! /bin/bash
#
###########################################################
# Aegir 3.x install scripts for Debian / Ubuntu
# on Github: https://github.com/argopecten/aegir-composer
#
# This script installs Aegir on a LAMP/LEMP server.
#
# The server must have up&running:
#   - database server (mysql, mariadb)
#   - webserver (apache2, nginx)
#   - PHP libraries as required by aegir
#
# This script install and configure
#   - drush
#   - Aegir backend (provision)
#   - Aegir frontend (via hostmaster profile)
#   - Aegir modules
###########################################################

# Aegir version
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

echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | Aegir version to be installed is $AEGIR_VERSION"
read -p "Continue with this version? (Y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1

read -p "Enter fullname: " AEGIR_VERSION
# user="USER INPUT"
read -p "Enter user: " user


# Install LAMP components for Aegir
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | A) Checking LAMP components ..."
echo "ÆGIR | ------------------------------------------------------------------"
# TODO: check DB, webserver & PHP services & packages
echo "ÆGIR"
echo "ÆGIR"
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | B) Installing Aegir with Composer ..."

composer create-project argopecten/aegir-composer \
         --stability dev \
         --no-interaction \
         --repository '{"type": "vcs","url":  "https://github.com/argopecten/aegir-composer"}' \
         aegir-$AEGIR_VERSION $AEGIR_VERSION

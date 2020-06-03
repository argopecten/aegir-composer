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

# Install LAMP components for Aegir
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | A) Installing LAMP ..."
bash $DIR/os/lamp-install.sh
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR"
echo "ÆGIR"
echo "ÆGIR | ------------------------------------------------------------------"
echo "ÆGIR | B) Installing Aegir with Composer ..."

AEGIR_VERSION="dev-proba"    # should come from aegir.cfg!

composer create-project argopecten/aegir-composer \
         --stability dev \
         --no-interaction \
         --repository '{"type": "vcs","url":  "https://github.com/argopecten/aegir-composer"}' \
         aegir-$AEGIR_VERSION $AEGIR_VERSION

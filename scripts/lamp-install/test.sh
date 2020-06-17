#! /bin/bash
#
# Hostname and default for Aegir frontend
AEGIR_HOST="aegir.local"

# (re)set hostname
echo "ÆGIR | 0) Setting hostname ..."
unset fqdn
unset result
echo "ÆGIR | Default hostname is $AEGIR_HOST ..."
# read -p "Enter your FQDN hostname here (or press enter to continue with default): " fqdn
fqdn=$1
if [[ -z "$fqdn" ]]
then
    echo "No user input, using default hostname: $AEGIR_HOST"
else
    echo "User input is: $fqdn"
   # check valid FQDN syntax: https://stackoverflow.com/questions/32909454/evaluation-of-a-valid-fqdn-on-bash-regex
   result=`echo $fqdn | grep -P '(?=^.{1,254}$)(^(?>(?!\d+\.)[a-zA-Z0-9_\-]{1,63}\.?)+(?:[a-zA-Z]{2,})$)'`
   if [[ -z "$result" ]]
   then
    echo "User error: $fqdn is NOT a FQDN. Exiting ..."
    exit 1
   else
       # $fqdn is a FQDN
       AEGIR_HOST=$fqdn
   fi
fi
echo "ÆGIR | Continuing with hostname: $AEGIR_HOST"

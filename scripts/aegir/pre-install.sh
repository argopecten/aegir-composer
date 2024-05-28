#! /bin/bash
#
# Aegir 3.x install/update scripts Ubuntu
#
# on Github: https://github.com/argopecten/aegir-hostmaster
#
echo "pre-install script" | tee -a log.txt
# occurs before the install command is executed with a lock file present.

echo "ÆGIR | Installing Aegir ..."

echo " - ÆGIR | Setup Aegir user" | tee -a log.txt
# - name: aegir
#  sudo: ALL=(ALL) NOPASSWD:ALL    # Nginx only: ALL=NOPASSWD: /etc/init.d/nginx
#  gecos: Aegir user
#  shell: /bin/bash
#  homedir: /var/aegir
#  groups: www-data
#  ssh_authorized_keys:
#  - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID09z51ipgcztAMqDlqlrn97y3eT5MgqPxl3kjq786st aegir
# setup aegir homedir
#  - chmod 755 /var/aegir

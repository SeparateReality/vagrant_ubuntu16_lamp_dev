#!/bin/bash

echo "================= START ${0} $(date +"%r") ================="
# some final housekeeping
sudo apt-get -y update --fix-missing > /dev/null
sudo apt-get -y autoremove > /dev/null
sudo apt-get -y clean > /dev/null

echo " "
echo "VM Name: $1"
echo " "
echo "========================================================================"
echo " "
echo "http://$2 ($3)"
echo " "
echo "SSH Login (use for tunneling mysql requests)"
echo "Server: $2"
echo "user: vagrant        pass: vagrant"
echo " "
echo "MySQL Connection"
echo "Port: 3306"
echo "Host: localhost"
echo "User: root"
echo "Password: $4"
echo " "
echo "MailHog (check Mails from this machine)"
echo "Running on Port: 8025"
echo "Usage: Open in Browser http://$2:8025"
echo " "
echo "================= FINISH ${0} $(date +"%r") ================="
echo " "
# echo " ATTENTION: Now Rebooting System..."
echo " "
# sudo reboot


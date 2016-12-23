#!/bin/bash

echo "================= START ${0} $(date +"%r") ================="
echo "BEGIN Set VM timezone and perform some cleanup pre-install ..."
echo " "

# set server timezone
sudo timedatectl set-timezone $1

# set locals
sudo locale-gen de_DE.UTF-8
sudo update-locale LANG=de_DE.UTF-8 LANGUAGE=de_DE.UTF-8 LC_ALL=de_DE.UTF-8
sudo dpkg-reconfigure -f noninteractive locales

# a little housekeeping
echo "... Doing a little housekeeping ..."
echo "..... update packages"
sudo apt-get -qq update --fix-missing
echo "..... upgrade packages"
sudo apt-get -qq upgrade
echo "..... upgrade dist"
sudo apt-get -qq dist-upgrade
echo "..... update again"
sudo apt-get -qq update

echo "... END Set VM timezone and perform some cleanup pre-install."
echo "================= FINISH ${0} $(date +"%r") ================="
echo " "
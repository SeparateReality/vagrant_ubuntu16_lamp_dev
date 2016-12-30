#!/bin/bash

echo "================= START ${0} $(date +"%r") ================="
echo "BEGIN installing utilities"
echo " "

# install some common utilities
echo "... Installing miscellaneous/common utilities ..."

sudo apt-get -qq install htop > /dev/null
sudo apt-get -qq install wget > /dev/null
sudo apt-get -qq install curl > /dev/null
sudo apt-get -qq install zip > /dev/null
sudo apt-get -qq install unzip > /dev/null
sudo apt-get -qq install iptables > /dev/null
sudo apt-get -qq install debconf-utils > /dev/null
sudo apt-get -qq install software-properties-common > /dev/null
sudo apt-get -qq install jq /dev/null  # json handling with bash
sudo apt-get -y update > /dev/null

# my profile settings (for vagrant and root user)
MYBASH=$(cat <<EOF
alias ..="cd .."
alias untar="tar -xvf"
alias ram="/usr/bin/free -m"
alias h="history"
PS1="\[\e[1;36m\]\u@\h\[\e[m\]\[\e[1;30m\]\w\[\e[m\]\[\e[1;36m\]#\[\e[m\]\[\e[0;30m\] "
EOF
)
echo "${MYBASH}" >> /home/vagrant/.bashrc
echo "${MYBASH}" >> /root/.bashrc

echo "... END installing utilities."
echo " "
echo "================= FINISH ${0} $(date +"%r") ================="
echo " "

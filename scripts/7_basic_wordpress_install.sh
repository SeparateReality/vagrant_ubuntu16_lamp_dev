#!/bin/bash

# db_root_password=$1
# vm_naked_hostname=$2

echo "================= START ${0} $(date +"%r") ================="
echo " "
echo "Installing generic wordpress to basic.host ..."
echo " "
echo "prepare DB ..."

sudo mysql --user="root" --password=$1 -e "CREATE DATABASE basicwpdb;"
sudo mysql --user="root" --password=$1 -e "CREATE USER wpuser@localhost IDENTIFIED BY '$1';"
sudo mysql --user="root" --password=$1 -e "GRANT ALL PRIVILEGES ON basicwpdb.* TO wpuser@localhost;"
sudo mysql --user="root" --password=$1 -e "FLUSH PRIVILEGES;"

sudo service apache2 restart
sudo service mysql restart

echo "Install latest Wordpress version..."

wget http://wordpress.org/latest.zip
mkdir /var/www/basic/
unzip -q latest.zip -d /var/www/basic
sudo chown -R vagrant:vagrant /var/www/basic/
rm -f latest.zip

echo "===================================================================="
echo "   Basic Wordpress page installed. Go to http://basic.${2}/wordpress to configure"
echo "   DB: basicwpdb"
echo "   DB user: wpuser"
echo "   DB pass: ${1}"
echo "================= FINISH ${0} $(date +"%r") ================="

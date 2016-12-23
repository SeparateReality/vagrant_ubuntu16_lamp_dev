#!/bin/bash

vm_hostname=$1
vm_ip_address=$2

echo "================= START ${0} $(date +"%r") ================="
echo " "

# install apache2
echo "... Installing Apache and PHP packages ..."
sudo apt-get -qq install apache2
sudo apt-get -qq install php7.0
sudo apt-get -qq install php7.0-mysql php7.0-curl php7.0-gd php7.0-fpm php7.0-xml
sudo apt-get -qq install php7.0-mbstring php7.0-mcrypt php7.0-zip php7.0-intl
# install xdebug - (including php7 support)
sudo apt-get -qq install php-xdebug
# generate ssl certificates for https
sudo mkdir /etc/apache2/ssl
sudo openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout /etc/apache2/ssl/apache.key -out /etc/apache2/ssl/apache.crt -subj "/CN=*.${vm_hostname}"

echo "... Configuring Apache ..."
# clean-up
sudo a2dissite 000-default.conf
sudo rm -f /etc/apache2/sites-available/*
sudo rm -rf /var/www/html
# new setup
sudo cp -f /vagrant/www/www_sites_config/*.conf /etc/apache2/sites-available/
sudo cp -rf /vagrant/www/www_folder/* /var/www
# loop through sites, add real hostname, enable in apache
for f in /etc/apache2/sites-available/*.conf; do
	sudo sed -i "s/PLACEHOLDER_NAME_FOR_SCRIPT_3/${vm_hostname}/" ${f}
	sudo sed -i "s/PLACEHOLDER_IP_FOR_SCRIPT_3/${vm_ip_address}/" ${f}
	sudo a2ensite "$(basename ${f})"
done

sudo a2enmod rewrite actions
# needed to use automatic virtual hosts
sudo a2enmod vhost_alias
sudo a2enmod ssl
# use fpm conf and module
sudo a2enconf php7.0-fpm
sudo a2enmod proxy_fcgi
# set apache user to 'vagrant' for convenience in /var/www with ssl and sftp (new files via phpstorm etc.)
sudo sed -i "s/export APACHE_RUN_USER=.*/export APACHE_RUN_USER=vagrant/" /etc/apache2/envvars
sudo sed -i "s/export APACHE_RUN_GROUP=.*/export APACHE_RUN_GROUP=vagrant/" /etc/apache2/envvars
# change every www_host user to vagrant
sudo chown -R vagrant:vagrant /var/www

echo "... Configuring PHP7 ..."
# tune some php.ini settings
sudo sed -i "s/memory_limit.*/memory_limit = 512M/" /etc/php/7.0/fpm/php.ini
sudo sed -i "s/post_max_size.*/post_max_size = 256M/" /etc/php/7.0/fpm/php.ini
sudo sed -i "s/upload_max_filesize.*/upload_max_filesize = 250M/" /etc/php/7.0/fpm/php.ini

# php-fpm settings
sudo sed -i "s/user =.*/user = vagrant/" /etc/php/7.0/fpm/pool.d/www.conf
sudo sed -i "s/listen.owner =.*/listen.owner = vagrant/" /etc/php/7.0/fpm/pool.d/www.conf
sudo sed -i "s/group =.*/group = vagrant/" /etc/php/7.0/fpm/pool.d/www.conf
sudo sed -i "s/listen =.*/listen = 127.0.0.1:9000/" /etc/php/7.0/fpm/pool.d/www.conf

# activate Xdebug remote debugging
sudo bash -c "cat > /etc/php/7.0/mods-available/xdebug.ini << EOF
zend_extension=xdebug.so
xdebug.remote_enable=On
xdebug.remote_connect_back=On
xdebug.remote_autostart=Off
xdebug.remote_log=/tmp/xdebug.log
EOF"

echo "... Restarting Services for Apache2 and PHP7 ..."
sudo service apache2 restart
sudo service php7.0-fpm restart

echo "... END setting up Apache2 and PHP7"
echo " "
echo "================= FINISH ${0} $(date +"%r") ================="
echo " "

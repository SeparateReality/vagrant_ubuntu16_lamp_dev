#!/bin/bash

echo "================= START ${0} $(date +"%r") ================="
echo " "
echo "... Installing WP-CLI ..."
curl -sSOf --compressed https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
sudo mv wp-cli.phar /usr/local/bin/wp

echo "... Installing Composer ..."
export COMPOSER_HOME=/home/vagrant/.composer
sudo apt-get -y install composer
echo "... Installing PHP CodeSniffer ..."
composer global require "squizlabs/php_codesniffer=*"
# make it available in $PATH
ap1=$(cat <<EOF
	# added for PHP CodeSniffer
  PATH="\$PATH:/home/vagrant/.composer/vendor/bin/"
EOF
)
echo "${ap1}" >> /home/vagrant/.profile
sudo echo "${ap1}" >> /home/root/.profile
# load new profil with path right away
source .profile

echo "... Installing WordPress Coding Standards ..."
git clone -b master https://github.com/WordPress-Coding-Standards/WordPress-Coding-Standards.git \
		/home/vagrant/.composer/vendor/squizlabs/php_codesniffer/CodeSniffer/Standards/wpcs

#Add WordPress standards to PHPCS config
phpcs --config-set installed_paths /home/vagrant/.composer/vendor/squizlabs/php_codesniffer/CodeSniffer/Standards/wpcs
phpcs -i #shows the libraries installed

echo "================= FINISH ${0} $(date +"%r") ================="

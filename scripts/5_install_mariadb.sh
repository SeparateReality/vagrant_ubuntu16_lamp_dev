#!/bin/bash

echo "================= START ${0} $(date +"%r") ================="
echo " "
echo "BEGIN Database server setup ..."

echo "... Installing MariaDB Server ..."
# install mariadb
sudo apt-get -qq install mariadb-server

echo "... Configuring MariaDB ..."
# set pass for root
sudo mysql -e "UPDATE mysql.user SET authentication_string = PASSWORD('$1'), plugin = 'mysql_native_password' WHERE User = 'root' AND Host = 'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"
# from here on mysql can only be used with user and pass

# uncomment those lines if you want to use the machine without ssh tunnel...whyever you would do so...
#sudo sed -i '/^bind-address/s/bind-address.*=.*/bind-address = 0.0.0.0/'  /etc/mysql/mariadb.conf.d/50-server.cnf
#sudo mysql --user="root" --password=$1 -e "GRANT ALL ON *.* TO 'root'@'%' IDENTIFIED BY '$1' WITH GRANT OPTION;"
#sudo mysql --user="root" --password=$1 -e "FLUSH PRIVILEGES;"

# comment default query cache values
sudo sed -i "/^ *\t*query_cache_limit/s/query_cache_limit/# query_cache_limit/" /etc/mysql/mariadb.conf.d/50-server.cnf
sudo sed -i "/^ *\t*query_cache_size/s/query_cache_size/# query_cache_size/" /etc/mysql/mariadb.conf.d/50-server.cnf
# add new values
sudo sed -i "/# query_cache_size/a #\\
# added by vagrant provisioning \\
query_cache_limit = 8M	\\
query_cache_size = 64M	\\
max_heap_table_size = 1G	\\
tmp_table_size = 512M" /etc/mysql/mariadb.conf.d/50-server.cnf

sudo service mysql restart

echo "... END Database server setup."
echo " "
echo "================= FINISH ${0} $(date +"%r") ================="

#!/bin/bash

echo "... install mailhog and mhsendmail ..."
echo "    USAGE: ssh into your machine. just call 'mailhog'"
echo "    Read Emails: Open in browser 'http://[your-host-name]:8025'"

echo "... Downloading mailhog & mhsendmail, installing in path ..."
# get redirect to URL with latest releases
location=`curl -w "%{url_effective}\n" -I -L -s -S https://github.com/mailhog/MailHog/releases/latest -o /dev/null`
# replace 'tag' in URL with 'download' to have correct download location
location="${location/tag/download}"
wget -nv ${location}/MailHog_linux_amd64
location=`curl -w "%{url_effective}\n" -I -L -s -S https://github.com/mailhog/mhsendmail/releases/latest -o /dev/null`
location="${location/tag/download}"
wget -nv ${location}/mhsendmail_linux_amd64

chmod +x MailHog_linux_amd64
chmod +x mhsendmail_linux_amd64
sudo mv MailHog_linux_amd64 /usr/local/bin/mailhog
sudo mv mhsendmail_linux_amd64 /usr/local/bin/mhsendmail

echo "... Re-configuring PHP7-FPM ..."
sudo sed -i "s/;* *sendmail_path.*=/sendmail_path  = \/usr\/local\/bin\/mhsendmail/" /etc/php/7.0/fpm/php.ini

echo "... Restarting php7.0-fpm Service ..."
sudo service php7.0-fpm restart

echo "... Copying mailhog daemon service file ..."
sudo cp -f /vagrant/scripts/resources/mailhog.service /lib/systemd/system/
sudo chmod 644 /lib/systemd/system/mailhog.service
sudo chown root:root /lib/systemd/system/mailhog.service

echo "... Starting mailhog as a daemon service ..."
sudo systemctl enable mailhog
# reload daemon list right away
sudo systemctl daemon-reload
# to be able to start service now
sudo systemctl start mailhog

echo "... END setting up MailHog"
echo " "
echo "================= FINISH ${0} $(date +"%r") ================="
echo " "

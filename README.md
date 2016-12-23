#### --- useful with VirtualBox 5.1.10 or higher ---

### LAMP Development Environment [using basic vagrant box (thanks to bento) and provision everything else]
- Ubuntu 16.04
- Apache2 w/ own SSL cert
- PHP7 w/ xdebug (running as php7.0-fpm)
- MySQL (MariaDB)
- FTP-Server (use FTP client - e.g. filezilla, choose sftp-protocol [ftp via SSH], use user and pass 'vagrant')
- Wordpress Stuff: wp-cli, php code sniffer with wp coding standards
#### ! ONLY for local development. never use in production. no security measurements taken. !

## QUICK START

- requirement: VirtualBox (virtualbox.org) and vagrant (vagrantup.com) installed
- recommended: 'vagrant plugin install vagrant-hostsupdater'  (updates hosts file to use automatic vhosts in browser - e.g. test.mydev.local)
- throw this git contend in any folder you like to use for this dev machine
- go to this folder
- adapt 'vagrantfile' to your liking (hostname, IP, ...)
- call 'vagrant up'  (Attention: with windows: OPEN CMD AS ADMIN!)
- look at the strange lines going by and hope everything goes fine...
- if no error msg appears: you are done!

## USING PuTTY?
- Easiest way: SSH to the IP of your box with Port 22. Use 'vagrant' as user and 'vagrant' as passwort. You are in!
- Automate this with SSL key:
    + Execute PuTTYgen
    + Open Menu Conversions/Import Key. Choose file '[your_vagrant_dev_folder]\.vagrant\machines\default\virtualbox\private_key'
    + Click on 'Save private key'. Save it in the same place e.g. as 'my_insecure_private_key.ppk'
    + Execute PuTTY
    + Enter your host and port (e.g. '192.168.2.56' and port '22')
    + Go to 'Connection/Data' (on the left) - Enter 'vagrant' as auto-login user
    + Go to 'Connection/SSH/Auth' - Choose 'Browse'. choose the key you saved before (e.g. 'my_insecure_private_key.ppk')
    + Go to 'Session' - Enter a name in 'Saved Sessions' - Press 'Save'
    + Whenever you doubleclick on this name you should automatically get logged in.
    + There is a way to use the same key for all your machines. see http://stackoverflow.com/questions/28471542/cant-ssh-to-vagrant-vms-using-the-insecure-private-key-vagrant-1-7-2

## Using PHP CodeSniffer (with Wordpress Coding Standards)?
- 'phpcs' is globally available (in ~/.composer/vendor/bin)

## Basic Wordpress installation
- Browse to 'basic.[yourhost]' (e.g. 'basic.mydev.local') to start configuring wordpress
- Database name:  basicwpdb
- DB Wordpress user: wpuser     pass: root

##### What does that mean???

The following is explained on the assumption that you started with the given preset.

- You will find a new Virtual Box called "my_dev" in VirtualBox which already started.
- An Apache2 Webserver with PHP and mySQL will be present
- Have a look further down for more details

## What's in the box?

- A virtual ubuntu machine with 8GB RAM, 4 CPUs
- An IP address visible to your Host (192.168.5.5) and another IP network visible to other VMs
- Apache2, PHP5, mySQL5.5 installed
- xdebug is installed and configured.
- php5 comes with mcrypt, as well (needed for prestashop for instance)
- some php.ini settings changed. feel free to add yours
- Apache runs a virtual host at /var/www/html/staging (your project folder)
  which is shared with the folder from where you called 'vagrant up'

### user, passwords, connections

#### users and passwords

###### SYSTEM
user: root -> no password
user: vagrant -> pass: vagrant

###### MYSQL
user: root -> pass: root

#### connect to MYSQL from the outside world

easiest way is to use a tool like Navicat for MySQL
setup a connection through a SSH tunnel.
For the tunnel use:
Host: 192.168.5.5, Port: 22, User: vagrant, Pass: vagrant
For the mySQL connection on top of it use:
Host: localhost, Port: 3306, User: root, Pass: root

#### use SSH
user: vagrant -> pass: vagrant
(do 'sudo -s' if you need root access)

#### call apache webpage
from your host: call '192.168.5.5' in your browser

## What else can I do?

You could change the files to your needs:
- bootstrap.sh: change the password and/or the name of the project folder
- vagrantfile: change the hostname and/or the ip address
- change whatever you want and be so kind and share as well


#
# @ToDo: integrate every config subdir as hosts entry (to make automatic virtual hosts possible)
#
# INFO: apache user set to "vagrant" to easily use vagrant user in /var/www with ssl and sftp
#

# server configuration
vm_current_version = "v04"
vm_ip_address = "192.168.2.104"
vm_naked_hostname = "wp_#{vm_current_version}.local"
vm_hostaliases = ["test.#{vm_naked_hostname}", "serverscripts.#{vm_naked_hostname}", "basic.#{vm_naked_hostname}"]
vm_name = "dev_#{vm_current_version}(#{vm_ip_address})"
vm_timezone  = "Europe/Berlin"
vm_max_memory = 8192
vm_num_cpus = 4
vm_max_host_cpu_cap = "80"

# database configuration
db_root_password = "root"

# synced folder configuration
#synced_webroot_local = "../webroot"
#synced_webroot_box = "/var/www/sites/default"

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-16.04"
  config.vm.boot_timeout = 300
  config.vm.network "public_network", ip: vm_ip_address, auto_correct: true
#  config.vm.synced_folder synced_webroot_local, synced_webroot_box, :nfs => { :mount_options => ["dmode=777","fmode=666"] }

  config.ssh.username = "vagrant"
  config.ssh.password = "vagrant"
  # if you are using ssh without password (ssh key) and you want to use one ssh key for all machines uncomment the following (use ~/.vagrant.d/insecure_private_key e.g. in PuTTY)
  config.ssh.insert_key = false

  config.vm.provider "virtualbox" do |v|
  	# use virtualbox gui to see if any input is required and whatever happens in case boot process does not work
		#v.gui = true
    # set name of vm
    v.name = vm_name
    # no matter how much cpu is used in vm, use no more than vm_max_host_cpu_cap amount
    v.customize ["modifyvm", :id, "--cpuexecutioncap", vm_max_host_cpu_cap]
    v.customize ["modifyvm", :id, "--memory", vm_max_memory]
    v.customize ["modifyvm", :id, "--cpus", vm_num_cpus]
    # the next two settings enable using the host computer's dns inside the vagrant box
    # enable dns proxy in nat mode
    v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    # use the host's resolver as a dns proxy in nat mode
    v.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
  end

  # set vm hostname and aliases if plugin exists
  config.vm.hostname = vm_naked_hostname
  if defined?(VagrantPlugins::HostsUpdater)
    config.hostsupdater.aliases = vm_hostaliases
  end

  # set vm timezone and do some cleanup before installations
  config.vm.provision :shell, :path => "scripts/1_set_vm_timezone_and_cleanup.sh", :privileged => true, :args => vm_timezone

  # install miscellaneous utilities
  config.vm.provision :shell, :path => "scripts/2_install_utilities.sh", :privileged => true

  # install/configure apache and php7
  config.vm.provision :shell, :path => "scripts/3_install_apache_and_php.sh", :privileged => true, :args => [
  vm_naked_hostname, vm_ip_address
	]

  # install mailhog and mhsendmail to use it with php (in dev. environment)
  config.vm.provision :shell, :path => "scripts/4_install_mailhog.sh", :privileged => true

  # install/configure database server
  config.vm.provision :shell, :path => "scripts/5_install_mariadb.sh", :privileged => true, :args => db_root_password

  # confirm setup is complete and output connection info
  config.vm.provision :shell, :path => "scripts/6_wordpress_stuff.sh", :privileged => true

  # confirm setup is complete and output connection info
#  config.vm.provision :shell, :path => "scripts/7_basic_wordpress_install.sh", :privileged => true, :args => [
#    db_root_password, vm_naked_hostname
#  ]

  # confirm setup is complete and output connection info
  config.vm.provision :shell, :path => "scripts/8_final_output.sh", :privileged => true, :args => [
    vm_name, vm_naked_hostname, vm_ip_address, db_root_password
  ]

end

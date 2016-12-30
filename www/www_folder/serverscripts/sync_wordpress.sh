#!/usr/bin/env bash
# v1.1
# changelog:
# - added option local_mail, no_files, no_db
# - 'local_mail' will change wp option from postman-smtp plugin to use local smtp (e.g. with MailHog)
# - Remotesync resolves Symlinks

# define needed input vars
must_input_vars=( "source_domain" "source_path" "source_db_host" "source_db" "source_db_user"
									"source_db_password" "target_db_host" "target_domain" "target_path"
									"target_db" "target_db_user" "target_db_password" "ERR_LOG")

config_file="${1%.*}"
break="$2"

function contains() {
    local n=$#
    local value=${!n}
    for ((i=1;i < $#;i++)) {
        if [ "${!i}" == "${value}" ]; then
            echo "y"
            return 0
        fi
    }
    echo "n"
    return 1
}

function usage() {
	echo "---"
	echo "Usage:        $0 [config_file]"
	echo "              where [config_file] has to be the name of the config file e.g. 'vagrant' for vagrant.cfg"
	echo "Example:      $0 vagrant"
	echo "Alternative:  $0 vagrant break"
	echo "              This will stop the execution after reading and showing the config"
	echo "---"
	exit 1;
}

function echo_now() {
# echo "+++++++++++++++++++++++++++++"
echo "DATE/TIME $(date +%Y_%m_%d-%H_%M_%S)"
}

function h1() {
count=$((${#1} + 8))
echo
printf "@"'%.s' $(seq 1 $count); echo
echo "@@  ${1}  @@"
printf "@"'%.s' $(seq 1 $count); echo
unset count
}

function spinner() {
    local pid=$!
    local delay=0.75
    local spinstr='|/-\'
    	echo "  process $pid: this may take a while, please be patient while $1 is running!"
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# delete old log file
rm -f ${ERR_LOG}

# check if config_file attribute has been set
if [ -n "$config_file" ]; then
  echo "Config file set"
else
	echo "ERROR: No config file attribute set!" 1>&2
	usage
fi

VARS="`set -o posix ; set`"
echo "Reading config file...."
if [ -f ${config_file}.cfg ]; then
	source ${config_file}.cfg
else
	if [ -f ${config_file} ]; then
		source ${config_file}
	else
    echo "ERROR: Config file not found. There needs to be an attribute to a file called [config_file].cfg" 1>&2
    usage
	fi
fi

# GENERAL PREPARATION
# - check for input errors
# - read config file
#
h1 "General preparation"

# compare existing vars before and after sourcing the config file
SCRIPT_VARS="`grep -vFe "$VARS" <<<"$(set -o posix ; set)" | grep -v ^VARS=`"; unset VARS;

# change to location of script
# DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# cd ${DIR}

echo_now
echo "Check if necessary vars are set in config file"
for index in ${!must_input_vars[*]}
do
	var=${must_input_vars[$index]}
  eval erg=\$$var
	if [ -n "${erg}" ]; then
		echo "$var is set to: ${erg}"
	else
		echo "$var is NOT set. Please set it in the config file!" 1>&2
		usage
	fi
done
echo "  check done."
echo "ALL Input variables from config file:"
# echo -e ${SCRIPT_VARS//'\x20'/'\n   '}    # not working....
# only fu... possibility to make the indent work:
echo -n "    "; echo ${SCRIPT_VARS} | sed 's/\x20/\n    /g'

if [ "${2}" == "break" ]; then
	echo "break due to break argument. *lol*"
	exit 0;
fi


if [ -n "$no_db" ]; then
	echo "'no_db' is set. Omitting database operation"
else
	# DATABASE OPERATION
	# - read db from source
	# - write in target db
	# - adapt db to local settings
	#
	h1 "Database operation"

	echo_now
	output=$(mysql --user=${target_db_user} --password="${target_db_password}" -s -N -e "SELECT schema_name FROM information_schema.schemata WHERE schema_name = '${target_db}'" information_schema)
	if [[ -z "${output}" ]]; then
		# does not exist, try to generate with user/pass=root
		echo "INFO: target db and/or user DO NOT exit. Try to create: ${target_db_user} @ $target_db"
		if ! mysql --user=root --password=root --host=${target_db_host} -e "CREATE DATABASE IF NOT EXISTS ${target_db};"; then
			# no way to generate target db. something terribly wrong. stop right here.
			echo "SERIOUS ERROR. STOP SCRIPT:"
			echo "  Target database or user does not exist and could not be created since standard setting (db user/pass = root) does not work. Please create manually before next execution!"
			exit 1;
		fi
		mysql --user=root --password=root --host=${target_db_host} ${target_db} -e "CREATE USER ${target_db_user}@${target_db_host} IDENTIFIED BY '${target_db_password}';" # /dev/null  # will throw error in case user exists
		mysql --user=root --password=root --host=${target_db_host} ${target_db} -e "GRANT ALL PRIVILEGES ON $target_db.* TO ${target_db_user}@${target_db_host} WITH GRANT OPTION;"  # 2>>${ERR_LOG}
		echo "  Database/User created successfully ($target_db_user @ $target_db)"
	fi

	echo_now
	echo "--  get dump from source db: ($source_db) --"
	rm -f ${source_db}.sql    # just in case its somehow left over

	if [ -n "$sshhost" ]; then
		echo "Info: 'sshhost' is set to '${sshhost}'. Dumping Db from there"
		ssh -C $sshhost "mysqldump --user='${source_db_user}' --password='${source_db_password}' --host=${source_db_host} --add-drop-table ${source_db} --log-error=${ERR_LOG}" > ${source_db}.sql 2>>${ERR_LOG} & spinner "DATABASE DUMP"
	else
		echo "Info: 'sshhost' is not set. Dumping Db from local mySQL installation"
		mysqldump --user=${source_db_user} --password="${source_db_password}" --host=${source_db_host} --add-drop-table ${source_db} --log-error=${ERR_LOG} > ${source_db}.sql & spinner "DATABASE DUMP"
	fi

	echo_now
		echo "-- Import db dump in target db: ($target_db) --"
		mysql --user=${target_db_user} --password="${target_db_password}" --host=${target_db_host} --default-character-set=utf8 ${target_db} < ${source_db}.sql  2>>${ERR_LOG} & spinner "DATABASE IMPORT"
	rm -f ${source_db}.sql

	echo_now
	  echo "--  Update wp_options - new domain: ${target_domain}"
	  mysql --user=${target_db_user} --password=${target_db_password} --host=${target_db_host} ${target_db} -e "UPDATE wp_options SET option_value = REPLACE(option_value, '${source_domain}', '${target_domain}') WHERE option_value LIKE '%${source_domain}%'"  2>>${ERR_LOG}
	  echo "--  Update wp_options - set blog to private (tell search engines not to show this page)"
	  mysql --user=${target_db_user} --password=${target_db_password} --host=${target_db_host} ${target_db} -e "update wp_options set option_value=0 where option_name='blog_public';" 2>>${ERR_LOG}
fi


if [ -n "$no_files" ]; then
	echo "'no_files' is set. Omitting file sync (but not file operation!)"
else
	# FILE SYNC
	# - sync source files to target system
	#
	h1 "File syncronisation"

	echo_now
	echo "--  Starting file sync from ${source_path} TO ${target_path}"
	# use -n for dry run

	if [ -n "$sshhost" ]; then
		echo "Info: 'sshhost' is set to '${sshhost}'. Syncing from remote host"
		rsync -rLptzv --delete --exclude 'cache/*' -e ssh $sshhost:${source_path}/wordpress ${target_path}/  2>>${ERR_LOG}
		rsync -rLptzv --delete -e ssh $sshhost:${source_path}/wp-config.php ${target_path}/ 2>>${ERR_LOG}
	else
		echo "Info: 'sshhost' is not set. Syncing from local host"
		rsync -rlptv --delete --exclude 'cache/*' ${source_path}/wordpress ${target_path}/ 2>>${ERR_LOG}
		rsync -rlptv --delete ${source_path}/wp-config.php ${target_path}/ 2>>${ERR_LOG}
	fi
	echo ""

	echo_now
	echo "-- starting file sync of all git repo plugins"
	if [ -n "$plugin_gitrepo_path" ]; then
		echo "Info: 'plugin_gitrepo_path' is set to '${plugin_gitrepo_path}'. Syncing git repo from there."
		if [ -n "$sshhost" ]; then
			echo "Info: 'sshhost' is set to '${sshhost}'"
			for gitplugin in `ssh $sshhost "cd ${plugin_gitrepo_path}; git ls-tree -r master --name-only plugins | cut -d '/' -f 2 | uniq"`; do
				echo "Syncing from remote host: $gitplugin"
				rsync -rLptzv --delete -e ssh $sshhost:${plugin_gitrepo_path}/plugins/$gitplugin ${target_path}/wordpress/wp-content/plugins/ 2>>${ERR_LOG}
				echo
			done
			for gittheme in `ssh $sshhost "cd ${plugin_gitrepo_path}; git ls-tree -r master --name-only themes | cut -d '/' -f 2 | uniq"`; do
				echo "Syncing from remote host: $gittheme"
				rsync -rLptzv --delete -e ssh $sshhost:${plugin_gitrepo_path}/themes/$gittheme ${target_path}/wordpress/wp-content/themes/ 2>>${ERR_LOG}
				echo
			done
		else
			echo "Info: 'sshhost' is not set. Syncing from local host: $gitplugin"
			savepath=`pwd`
			cd ${plugin_gitrepo_path}
			for gitplugin in `git ls-tree -r master --name-only plugins | cut -d '/' -f 2 | uniq`; do
				echo "Syncing from local host: $gitplugin"
				rsync -rlptv --delete plugins/$gitplugin ${target_path}/wordpress/wp-content/plugins/
				echo
			done
			for gittheme in `git ls-tree -r master --name-only themes | cut -d '/' -f 2 | uniq`; do
				echo "Syncing from local host: $gittheme"
				rsync -rlptv --delete themes/$gittheme ${target_path}/wordpress/wp-content/themes/
				echo
			done
			cd $savepath
		fi
	else
		echo "Info: 'plugin_gitrepo_path' is NOT set. No additional sync with git repo."
		echo
	fi
fi

# FILE OPERATION
# - adapt target config to local settings
#
h1 "Local file operation"

echo_now
	echo "--  Change wp-config.php: DB_NAME, DB_USER, DB_PASSWORD"
	sed -i "/DB_NAME/s/'[^']*'/'${target_db}'/2" ${target_path}/wp-config.php  2>>${ERR_LOG}
	sed -i "/DB_USER/s/'[^']*'/'${target_db_user}'/2" ${target_path}/wp-config.php
	sed -i "/DB_PASSWORD/s/'[^']*'/'${target_db_password//\//\/}'/2" ${target_path}/wp-config.php
	sed -i "/DB_HOST/s/'[^']*'/'${target_db_host//\//\/}'/2" ${target_path}/wp-config.php

	echo "--  Change wp-config.php: DEBUG settings"
	echo "    set WP_DEBUG=true, WP_DEBUG_DISPLAY=false, WP_DEBUG_LOG=true"
	# see http://sed.sourceforge.net/sed1line_de.html
	sed -i "/WP_DEBUG/s/false/true/1" ${target_path}/wp-config.php

	if grep -q "WP_DEBUG_DISPLAY" ${target_path}/wp-config.php
	then
		sed -i "/WP_DEBUG_DISPLAY/s/true/false/1;/WP_DEBUG_DISPLAY/s/false/false/1" ${target_path}/wp-config.php
	else
		sed -i "/WP_DEBUG'/a define( 'WP_DEBUG_DISPLAY', false );" ${target_path}/wp-config.php
	fi

	if grep -q "WP_DEBUG_LOG" ${target_path}/wp-config.php
	then
		sed -i "/WP_DEBUG_LOG/s/true/true/1;/WP_DEBUG_LOG/s/false/true/1" ${target_path}/wp-config.php
	else
		sed -i "/WP_DEBUG_DISPLAY'/a define( 'WP_DEBUG_LOG', true );" ${target_path}/wp-config.php
	fi
	echo

echo_now
	echo "--  Change file ownership"
	if [ -n "$localuser" ]; then
		echo "\$localuser set in config file. changing wordpress dir ownership to $localuser:$localuser"
		chown -R $localuser:$localuser $target_path/wordpress
		chown $localuser:$localuser $target_path/wp-config.php
	else
		echo "\$localuser not set. Leaving wordpress file ownership as is."
	fi

# WORDPRESS
# - sync source files to target system
# - adapt target config to local settings
#
h1 "Using wp-cli for further operation"

echo_now
#  type wpi >/dev/null 2>&1 || { echo >&2 "wp-cli not installed. command 'wp' not working." >> ${ERR_LOG}; exit 1 }

  echo "--  switch off some plugins (jetpack, google-analytics, wp-rocket)"
  echo "    e.g. to avoid using the distributed network of wp (which would not work on testing...)"
	if [ -n "$wp" ]; then
		echo "\$wp set in config file. using wp='$wp'"
		wp+=" --allow-root --path=${target_path}/wordpress"
		echo "  added attributes: wp='$wp'"
	else
	  wp="wp --allow-root --path=${target_path}/wordpress"
		echo "\$wp not set. using standard: $wp"
	fi

  $wp plugin deactivate jetpack 2>>${ERR_LOG}
  $wp plugin deactivate google-analytics-for-wordpress 2>>${ERR_LOG}
  $wp plugin deactivate wp-rocket 2>>${ERR_LOG}

	if [ -n "$local_mail" ]; then
		$wp plugin is-installed postman-smtp
		if [ $? == 0 ]; then
			if hash jq 2>/dev/null; then
		    echo "Wordpress postman-smtp plugin installed. changing smtp settings."
		    a1=$($wp option get --format=json postman_options)
		    a2=$(echo $a1 | jq '.enc_type="none" | .hostname="localhost" | .port=1025 | .auth_type="none" | .sender_email="dev@my-testserver.com" | .envelope_sender="dev@my-testserver.com"')
				$wp option update --format=json postman_options "$a2"
			else
				echo "WARNING: The wordpress postman-smtp plugin is installed but 'jq' is not! It is needed to manipulate json in bash - e.g. change wordpress options...)"
				echo "   Ether install jq with 'apt-get -y install jq'"
				echo "   or change smtp values yourself: 'Settings/Postman SMTP'"
				echo "      outgoing mail server: localhost, port: 1025, auth_type: none, enc_type: none"
			fi
	  else
	    echo "Wordpress plugin postman-smtp not installed."
		fi
	fi

h1 "DONE"
echo_now
	echo "Wordpress copy is now ready to be used."
	echo "  see ${ERR_LOG} if something is not working as expected! Good luck :-)"

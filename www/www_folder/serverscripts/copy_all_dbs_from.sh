#!/usr/bin/env bash

if [ -n "$1" ] || [ -n "$2" ] || [ -n "$3" ] ; then
	echo "Info: 'sshhost' is set to '${1}'. Dumping all Dbs from there with given user and pw"
else
	echo "Info: arguments not set. Please specifiy where to get all Dbs from and what user/pw to use"
	echo "      Usage in case datebase user and pw on remote and local machine are equal:"
	echo "     		$0 vagrant@mydev.local user pw"
	echo "      Usage in case database user and pw on remote and local machine are different:"
	echo "     		$0 vagrant@mydev.local remote_user remote_pw local_user remote_pw"
	exit 1
fi

echo "dumping all Dbs from remote system"

ssh -C $1 "mysqldump --user='${2}' --password='${3}' --all-databases" > alldb.sql

echo "importing .sql file in local mysql server"
if [ -n "$4" ] || [ -n "$5" ] ; then
	mysql --user="${2}" --password="${3}" < alldb.sql
else
	mysql --user="${4}" --password="${5}" < alldb.sql
fi


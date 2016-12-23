#!/usr/bin/env bash

if [ -n "$1" ]; then
  echo "to-machine set. initiate key generation (to ~/.ssh)"
else
	echo "Please enter user@machine  (e.g. 'vagrant@mydev.local')" 1>&2
	exit 1
fi

ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa

ssh-copy-id -i ~/.ssh/id_rsa.pub $1

#!/usr/bin/ksh

ivm_ip=$1
ivm_user=$2

DateNow=$(date +%Y%m%d%H%M%S)

if [ "$ivm_ip" == "" ]
then
	echo "IP is null" >&2
	exit 1
fi

if [ "$ivm_user" == "" ]
then
	echo "User name is null" >&2
	exit 1
fi

ssh_key=$(cat ~/.ssh/id_dsa.pub 2> /dev/null)
if [ "$ssh_key" != "" ]
then
	ssh ${ivm_user}@${ivm_ip} "mkauthkeys -r \"$ssh_key\""
fi

known_host=$(cat ~/.ssh/known_hosts | sed -e '/'$ivm_ip'/d')
echo "$known_host" > ~/.ssh/known_hosts
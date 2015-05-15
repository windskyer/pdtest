#!/usr/bin/ksh

hmc_ip=$1
hmc_user=$2

DateNow=$(date +%Y%m%d%H%M%S)

if [ "$hmc_ip" == "" ]
then
	echo "IP is null" >&2
	exit 1
fi

if [ "$hmc_user" == "" ]
then
	echo "User name is null" >&2
	exit 1
fi

ssh_key=$(cat ~/.ssh/id_dsa.pub 2> /dev/null)
if [ "$ssh_key" != "" ]
then
	ssh ${hmc_user}@${hmc_ip} "mkauthkeys -r \"$ssh_key\""
fi
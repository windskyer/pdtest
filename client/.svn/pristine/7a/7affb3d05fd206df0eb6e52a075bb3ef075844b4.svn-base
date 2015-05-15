#!/usr/bin/ksh

ivm_ip=$1
ivm_user=$2
nfs_path=$3
template_path=$4

DateNow=$(date +%Y%m%d%H%M%S)

#mount_info=$(expect ssh.exp ${ivm_user} ${ivm_ip} "oem_setup_env|showmount -e 2> /dev/null")
#mount_info=$(echo "$mount_info" | sed -n '/showmount -e/,/#/p' | grep -v "showmount" | grep -v '#' | grep -v "export list" | awk '{print $1}')
#if [ "$mount_info" != "" ]
#then
#	for mount_path in $mount_info
#	do
#		if [ "$mount_path" == "$nfs_path" ]
#		then
#			flag=1
#		fi
#	done
#fi
#
#if [ "$flag" != "1" ]
#then
#	ssh ${ivm_user}@${ivm_ip} "umount ${template_path}"
#fi

ssh_key=$(cat ~/.ssh/id_dsa.pub 2> /dev/null)
if [ "$ssh_key" != "" ]
then
#	expect ssh.exp ${ivm_user} ${ivm_ip} "oem_setup_env|grep -v $hostname ~/.ssh/authorized_keys2 > authorized_keys2.${DateNow}.bak|mv authorized_keys2.${DateNow}.bak ~/.ssh/authorized_keys2"
	ssh ${ivm_user}@${ivm_ip} "mkauthkeys -r \"$ssh_key\""
fi
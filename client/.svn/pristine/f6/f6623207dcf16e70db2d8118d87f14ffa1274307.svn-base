#!/usr/bin/ksh

formatPath() {

	path=$1
	
	last_char=$(echo $path | awk '{print substr($0,length($0))}')
	while [ "$last_char" == "/" ]
	do
		path=$(echo $path | awk '{print substr($0,0,length($0)-1)}')
		last_char=$(echo $path | awk '{print substr($0,length($0)-1,length($0))}')
	done
	
}

ivm_ip=$1
ivm_user=$2
nfs_ip=$3
nfs_path=$4
template_path=$5

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

if [ "$nfs_ip" == "" ]
then
	echo "NFS ip is null" >&2
	exit 1
fi

if [ "$nfs_path" == "" ]
then
	echo "NFS path is null" >&2
	exit 1
fi

if [ "$template_path" == "" ]
then
	echo "Template path is null" >&2
	exit 1
fi

formatPath $nfs_path
nfs_path=$path
formatPath $template_path
template_path=$path

DateNow=$(date +%Y%m%d%H%M%S)

mount_info=$(ssh ${ivm_user}@${ivm_ip} "ioscli mount" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	echo "$mount_info" >&2
	exit 1
fi

if [ "$mount_info" != "" ]
then
	check=$(echo "$mount_info" | awk '{if($1==nfs_ip && $2==nfs_path && $3==template_path) print $0}' nfs_ip="$nfs_ip" nfs_path="$nfs_path" template_path="$template_path")
	if [ "$check" != "" ]
	then
		info=$(expect ./ssh.exp ${ivm_user} ${ivm_ip} "oem_setup_env|umount -f ${template_path}|echo \$?|exit|exit" 2>&1)
		if [ "$(echo $?)" != "0" ]
		then
			echo "$info" >&2
			exit 1
		fi
		exe_judge=$(echo "$info" | sed -n '/'"echo \$?"'/,/#/p' | grep -v "echo \$?" | grep -v '#' | awk '{print substr($0,0,length($0)-1)}')
		if [ "$exe_judge" != "0" ]
		then
			echo "Unmount nfs failed, please check template path." >&2
			exit 1
		fi
	fi
fi

expect ./ssh.exp ${ivm_user} ${ivm_ip} "oem_setup_env|/usr/sbin/rmitab mountnfs" > /dev/null 2>&1



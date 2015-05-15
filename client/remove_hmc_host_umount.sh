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

hmc_ip=$1
hmc_user=$2
host_id=$3
nfs_ip=$4
nfs_path=$5
template_path=$6

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

log_flag=$(cat scrpits.properties 2> /dev/null | grep "LOG=" | awk -F"=" '{print $2}')
if [ "$log_flag" == "" ]
then
	log_flag=0
fi

DateNow=$(date +%Y%m%d%H%M%S)
out_log="out_remove_hmc_host_umount_${DateNow}.log"

vios_ids=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m $host_id -r lpar -F lpar_id:lpar_env:state" | awk -F":" '{if($2=="vioserver" && $3=="Running") print $1}')
if [ "$vios_ids" != "" ]
then
	for vios_id in $vios_ids
	do
		rmc_ip=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -r lpar -m $host_id --filter lpar_ids=$vios_id -F rmc_ipaddr")
		if [ "$rmc_ip" != "$nfs_ip" ]
		then
			mount_check=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id $vios_id -c mount" | awk '{if($1==nfs_ip && $2==nfs_path && $3==tmp_path) print 1}' nfs_ip="$nfs_ip" nfs_path="$nfs_path" tmp_path="$template_path")
			if [ "$mount_check" == "1" ]
			then
				ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id $vios_id -c \"oem_setup_env && umount -f ${template_path}\"" > $out_log 2>&1
			fi
			ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id $vios_id -c \"oem_setup_env && /usr/sbin/rmitab mountnfs\"" > $out_log 2>&1
		fi
	done
else
	continue
fi
	





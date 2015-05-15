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
nfs_ip=$3
nfs_path=$4
template_path=$5

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

DateNow=$(date +%Y%m%d%H%M%S)

managed_system=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -r sys -F name:state" | awk -F":" '{if($2=="Operating") print $1}')
if [ "$managed_system" != "" ]
then
	for machine in $managed_system
	do
		vios_ids=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m $machine -r lpar -F lpar_id:lpar_env:state" | awk -F":" '{if($2=="vioserver" && $3=="Running") print $1}')
		if [ "$vios_ids" != "" ]
	  	then
			for vios_id in $vios_ids
			do
				rmc_ip=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -r lpar -m $machine --filter lpar_ids=$vios_id -F rmc_ipaddr")
				if [ "$rmc_ip" != "$nfs_ip" ]
				then
					mount_check=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $machine --id $vios_id -c mount" | awk '{if($1==nfs_ip && $2==nfs_path && $3==tmp_path) print 1}' nfs_ip="$nfs_ip" nfs_path="$nfs_path" tmp_path="$template_path")
					if [ "$mount_check" == "1" ]
					then
						ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $machine --id $vios_id -c \"oem_setup_env && umount -f ${template_path}\"" > /dev/null 2>&1
					fi
				fi
			done
		else
	  		continue
	  	fi
	done
fi





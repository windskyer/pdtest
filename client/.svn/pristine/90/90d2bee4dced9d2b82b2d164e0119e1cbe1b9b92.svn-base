#!/usr/bin/ksh

catchException() {
        
	error_result=$(cat $1 | grep "spawn id" | grep "not open")
	          
}

throwException() {
            
	result=$1
	           
	if [ "$result" != "" ]
	then
		echo "ERROR: NFS server unable to connect." >&2
		exit 1
	fi

}

formatPath() {

	path=$1
	
	last_char=$(echo $path | awk '{print substr($0,length($0))}')
	while [ "$last_char" == "/" ]
	do
		path=$(echo $path | awk '{print substr($0,0,length($0)-1)}')
		last_char=$(echo $path | awk '{print substr($0,length($0)-1,length($0))}')
	done
	
}

info_length=0
echo $1 |awk -F"|" '{for(i=1;i<=NF;i++) print $i}' | while read param
do
		case $info_length in
		0)
		        info_length=1;
		        hmc_ip=$param;;
		1)
		        info_length=2;
		        hmc_user=$param;;
		2)
				info_length=3;
				host_id=$param;;
        3)      
        		info_length=4;
                nfs_ip=$param;;
        4)      
        		info_length=5;
                nfs_name=$param;;
        5)      
        		info_length=6;
                nfs_passwd=$param;;
        6)      
        		info_length=7;
                nfs_path=$param;;                
        7)      
        		info_length=8;
                tmp_path=$param;;                        	
    esac
done

if [ "$nfs_ip" != "" ]&&[ "$nfs_path" != "" ]&&[ "$tmp_path" != "" ]
then
	managed_state=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m $host_id -r sys -F state" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		echo "$managed_system" >&2
		exit 1
	fi
	if [ "$managed_state" != "Operating" ]
	then
		echo "Mount failed, host $host_id state is $managed_state."
	fi

	echo "host_id===$host_id"
	lpar_info=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m $host_id -r lpar -F lpar_id:lpar_env:state" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		echo "$lpar_info" >&2
		exit 1
	fi
	vios_ids=$(echo "$lpar_info" | awk -F":" '{if($2=="vioserver" && $3=="Running") print $1}')
	if [ "$vios_ids" == "" ]
	then
		continue
	fi
	echo "vios_ids==$vios_ids"
	for vios_id in $vios_ids
	do
		rmc_ip=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -r lpar -m $host_id --filter lpar_ids=$vios_id -F rmc_ipaddr")
		if [ "$(echo $?)" != "0" ]
		then
			echo "$rmc_ip" >&2
			exit 1
		fi
		echo "rmc_ip==$rmc_ip"
		if [ "$rmc_ip" != "$nfs_ip" ]
		then
			mount_check=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id $vios_id -c mount" 2>&1)
			if [ "$(echo $?)" != "0" ]
			then
				echo "$mount_check" >&2
				exit 1
			fi
			mount_check=$(echo "$mount_check" | awk '{if($1==nfs_ip && $2==nfs_path && $3==tmp_path) print 1}' nfs_ip="$nfs_ip" nfs_path="$nfs_path" tmp_path="$tmp_path")
			echo "mount_check==$mount_check"
			if [ "$mount_check" != "1" ]
			then
				path_check=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id $vios_id -c \"oem_setup_env && ls $tmp_path\"" > /dev/null 2>&1)
				if [ "$(echo $?)" != "0" ]
				then
					ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id $vios_id -c \"oem_setup_env && mkdir $tmp_path\""
				fi
			
				mnt_client_name=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id $vios_id -c hostname")
				if [ "$(echo $?)" != "0" ]
				then
					echo "$mnt_client_name" >&2
					exit 1
				fi
				echo "mnt_client_name==$mnt_client_name"
				hosts_check=$(expect ./ssh_password.exp ${nfs_ip} ${nfs_name} ${nfs_passwd} "cat /etc/hosts" 2>&1)
				if [ "$(echo $?)" != "0" ]
				then
					throwException "$hosts_check"
				fi
				hosts_check=$(echo "$hosts_check" | awk '{print substr($0,0,length($0)-1)}' | awk '{if($1==rmc_ip && $2==mnt_client_name) print 1}' rmc_ip="$rmc_ip" mnt_client_name="$mnt_client_name")
				if [ "$hosts_check" != "1" ]
				then
					result=$(expect ./ssh_password.exp ${nfs_ip} ${nfs_name} ${nfs_passwd} "echo \"${rmc_ip} ${mnt_client_name}\" >> /etc/hosts " 2>&1)
					if [ "$(echo $?)" != "0" ]
					then
						throwException "$result"
					fi
				fi
				mount_result=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id $vios_id -c \"mount ${nfs_ip}:${nfs_path} ${tmp_path}\"")
				if [ "$(echo $?)" != "0" ]
				then
					echo "$mount_result" >&2
					exit 1
				fi
			fi
			ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id $vios_id -c \"oem_setup_env && /usr/sbin/mkitab mountnfs:2:once:'/usr/sbin/mount ${nfs_ip}:${nfs_path} ${tmp_path}'\"" > /dev/null 2>&1
		fi
	done
fi
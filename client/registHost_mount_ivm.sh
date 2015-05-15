#!/usr/bin/ksh

catchException() {
        
	error_result=$(cat $1 | grep "spawn id" | grep "not open")
	          
}

throwException() {
            
	result=$1
	           
	if [ "$result" != "" ]
	then
		echo "ERROR: $result." >&2
		rm -f $error_log
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
				        ivm_ip=$param;;
				1)
				        info_length=2;
				        ivm_user=$param;;
				2)
				        info_length=3;
				        ivm_passwd=$param;;
				        
				3)      info_length=4;
                local_path=$param;;
                                
        4)      info_length=5;
                nfs_ip=$param;;
        
        5)      info_length=6;
                nfs_name=$param;;
                                
        6)      info_length=7;
                nfs_passwd=$param;;
                                
        7)      info_length=8;
                nfs_path=$param;;
		esac
done

ping -c 3 $nfs_ip > /dev/null 2>&1
if [ "$(echo $?)" != "0" ]
then
	echo "ERROR: NFS server unable to connect." >&2
	exit 1
fi

DateNow=$(date +%Y%m%d%H%M%S)
random=$(perl -e 'my $random = int(rand(9999)); print "$random";')
error_log="error_reg_mount_${DateNow}_${random}.log"

formatPath "$local_path"
local_path=$path
formatPath "$nfs_path"
nfs_path=$path

#local_path=$(formatPath "$local_path")
#nfs_path=$(formatPath "$nfs_path")


if [ "$nfs_ip" != "" -a "$nfs_path" != "" -a "$local_path" != "" ]
then
    mntClient_host=$(ssh ${ivm_user}@${ivm_ip} "ioscli hostname")
    ls_check=$(ssh ${ivm_user}@${ivm_ip} "ls $local_path" 2> /dev/null)
    if [ "$ls_check" == "" ]
    then
        new_path=$(expect ./ssh.exp ${ivm_user} ${ivm_ip} "oem_setup_env|mkdir $local_path|exit")
    fi
    
    
#		mount_info=$(expect ssh.exp ${ivm_user} ${ivm_ip} "oem_setup_env|showmount -e 2> /dev/null")
#		mount_info=$(echo "$mount_info" | sed -n '/showmount -e/,/#/p' | grep -v "showmount" | grep -v '#' | grep -v "export list" | awk '{print $1}')
#		if [ "$mount_info" != "" ]
#		then
#			for mount_path in $mount_info
#			do
#				if [ "$mount_path" == "$nfs_path" ]
#				then
#					exit 0
#				fi
#			done
#		fi

	if [ "$ivm_ip" != "$nfs_ip" ]
	then
		mount_check=$(ssh ${ivm_user}@${ivm_ip} "ioscli mount")
		echo "mount_check==$mount_check"
		mount_check=$(echo "$mount_check" | awk '{if($1==nfs_ip && $2==nfs_path && $3==local_path) print $0}' nfs_ip="$nfs_ip" local_path="$local_path" nfs_path="$nfs_path")
		echo "mount_check==$mount_check"
		if [ "$mount_check" == "" ]
		then
			hosts_check=$(expect ./ssh_password.exp ${nfs_ip} ${nfs_name} ${nfs_passwd} "cat /etc/hosts|exit" 2> $error_log)
			catchException "$error_log"
			throwException "$error_result"
			hosts_check=$(echo "$hosts_check" | awk '{print substr($0,0,length($0)-1)}' | awk '{if($1==ivm_ip && $2==mntClient_host) print $0}' ivm_ip="$ivm_ip" mntClient_host="$mntClient_host")
			# hosts_check=$(echo "$hosts_check" | grep $ivm_ip | grep $mntClient_host)	
			if [ "$hosts_check" == "" ]
			then
				expect ./ssh_password.exp ${nfs_ip} ${nfs_name} ${nfs_passwd} "echo \"${ivm_ip} $mntClient_host\" >> /etc/hosts|exit" 2> $error_log
				catchException "$error_log"
				throwException "$error_result"
			fi
		
			mount_result=$(ssh ${ivm_user}@${ivm_ip} "ioscli mount ${nfs_ip}:${nfs_path} ${local_path}" 2>&1)
#		    mount_result=$(echo "$mount_result" | sed -n '/'"mount ${nfs_ip}"'/,/#/p' | grep -v "mount ${nfs_ip}" | grep -v '#' | awk '{print substr($0,0,length($0)-1)}')
	#	    echo "mount_result==$mount_result"
			if [ "$mount_result" != "" ]
			then
				echo "ERROR: NFS client ${nfs_ip} mount failed." >&2
			fi
		fi
		expect ./ssh.exp ${ivm_user} ${ivm_ip} "oem_setup_env|/usr/sbin/mkitab mountnfs:2:once:'/usr/sbin/mount ${nfs_ip}:${nfs_path} ${local_path}'|exit" > /dev/null 2>&1
	fi    
fi

rm -f $error_log
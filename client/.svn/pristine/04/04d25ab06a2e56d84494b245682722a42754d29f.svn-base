#!/usr/bin/ksh

catchException() {
        
	error_result=$(cat $1 | grep "spawn id" | grep "not open")
	          
}

throwException() {
            
	result=$1
	           
	if [ "$result" != "" ]
	then
		echo "ERROR: NFS server unable to connect." >&2
		rm -f $error_log
		exit 1
	fi

}

info_length=0
echo $1 |awk -F"|" '{for(i=1;i<=NF;i++) print $i}' | while read param
do
	case $info_length in
		0)
		        info_length=1;
		        nfs_ip=$param;;
		1)
		        info_length=2;
		        nfs_user=$param;;
		2)
		        info_length=3;
		        nfs_passwd=$param;;
	  3)      
	       		info_length=4;
	          nfs_path=$param;;
	  4)      
	      		info_length=5;
	          tmp_path=$param;;
	esac
done

DateNow=$(date +%Y%m%d%H%M%S)
random=$(perl -e 'my $random = int(rand(9999)); print "$random";')
error_log="error_pc_mount_${DateNow}_${random}.log"

ping -c 3 $nfs_ip > /dev/null 2>&1
if [ "$(echo $?)" != "0" ]
then
	echo "ERROR: NFS server unable to connect." >&2
	exit 1
fi

if [ "$nfs_ip" != "" ]&&[ "$nfs_path" != "" ]&&[ "$tmp_path" != "" ]
then
	for i in $(ifconfig -a| grep -v 'LOOPBACK' |grep -v 'be|dman|lpfc' | grep '^[a-z,A-z]' | sed 's/: flags/ /g' | awk '{print $1}')
	do
		ifaddr=$(ifconfig $i | grep inet | awk '{print $2}');
	done
	#echo "ifaddr==$ifaddr"
	hostname=$(hostname)
	#echo "hostname==$hostname"
  if [ ! -d $tmp_path ]
  then
  	mkdir $tmp_path
  fi
  hosts=$(expect ./ssh_password.exp ${nfs_ip} ${nfs_user} ${nfs_passwd} "cat /etc/hosts" 2> $error_log)
  catchException "$error_log"
  throwException "$error_result"
  mount=$(df -k | grep ${ifaddr}":"${nfs_path} | grep ${tmp_path})
	if [ "$(echo "$hosts" | grep -v '#' | grep $ifaddr | grep $hostname)" == "" ]
	then
		expect ./ssh_password.exp ${nfs_ip} ${nfs_user} ${nfs_passwd} "oem_setup_env|echo $ifaddr	$hostname >> /etc/hosts" 2> $error_log
		catchException "$error_log"
  	throwException "$error_result"
	fi
  if [ "$mount" == "" ]
  then
    mount ${nfs_ip}:${nfs_path} ${tmp_path}
  fi
fi

rm -f $error_log
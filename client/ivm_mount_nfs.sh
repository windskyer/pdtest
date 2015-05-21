#!/usr/bin/ksh

. ./ivm_function.sh

j=0
for nfs_info in $(echo $1 |awk -F"|" '{for(i=1;i<=NF;i++) print $i}')
do
		case $j in
			0)
					j=1;
					nfs_ip=$nfs_info;;
			1)
					j=2;        
					nfs_name=$nfs_info;;
			2)
					j=3;
					nfs_passwd=$nfs_info;;
			3)
					j=4;
					nfs_path=$nfs_info;;
		esac
done

log_flag=$(cat scrpits.properties 2> /dev/null | grep "LOG=" | awk -F"=" '{print $2}')
if [ "$log_flag" == "" ]
then
	log_flag=0
fi

DateNow=$(date +%Y%m%d%H%M%S)
random=$(perl -e 'my $random = int(rand(999)); print "$random";')
out_log="${path_log}/out_ivm_create_vm_iso_v2.0_${lpar_name}_${DateNow}_${random}.log"
error_log="${path_log}/error_ivm_create_vm_iso_v2.0_${lpar_name}_${DateNow}_${random}.log"

log_debug $LINENO "$0 $*"

#check NFSServer status and restart that had stop NFSServer proc
nfs_server_check ${nfs_ip} ${nfs_name} ${nfs_passwd}

ping -c 3 $nfs_ip > /dev/null 2>&1
if [ $? -ne 0 ]
then
	print_error "Unable to connect nfs server."
fi

ent=$(ifconfig -a| grep -v 'LOOPBACK' |grep -v 'be|dman|lpfc' | grep '^[a-z,A-z]' | sed 's/: flags/ /g' | awk '{print $1}'|head -1)
pd_ip=$(ifconfig $ent | grep inet | awk '{print $2}'|head -1)


formatPath "$nfs_path"
nfs_path=$path

if [ "$nfs_ip" != "" -a "$nfs_path" != "" ]
then
	if [ "$pd_ip" != "$nfs_ip" ]
	then
		template_path=$pd_nfs"/nfs_${DateNow}_${random}"
		
		mntClient_host=$(hostname 2>&1)
		if [ $? -ne 0 ]
		then
			print_error "$mntClient_host"
		fi
		
		hosts_check=$(expect ./ssh_password.exp ${nfs_ip} ${nfs_name} ${nfs_passwd} "exportfs -a|cat /etc/hosts|exit" 2>&1)
		if [ $? -ne 0 ]
		then
			print_error "$hosts_check"
		fi
		
		hosts_check=$(echo "$hosts_check" | awk '{print substr($0,0,length($0)-1)}' | awk '{if($1==pd_ip && $2==mntClient_host) print $0}' pd_ip="$pd_ip" mntClient_host="$mntClient_host")
		# hosts_check=$(echo "$hosts_check" | grep $ivm_ip | grep $mntClient_host)	
		if [ "$hosts_check" == "" ]
		then
			write_hosts=$(expect ./ssh_password.exp ${nfs_ip} ${nfs_name} ${nfs_passwd} "echo \"${pd_ip} $mntClient_host\" >> /etc/hosts|exit" 2>&1)
			if [ $? -ne 0 ]
			then
				print_error "$write_hosts"
			fi
		fi

		ls_check=$(ls $template_path 2>&1)
		if [ $? -ne 0 ]
		then
			new_path=$(mkdir -p $template_path)
		fi
		# echo "new_path==$new_path"
		sleep 1
		mount_result=$(mount ${nfs_ip}:${nfs_path} ${template_path} 2>&1)
		if [ $? -ne 0 ]
		then
			template_info=$(ls ${template_path} 2>&1)
			if [ "$template_info" == "" ]
			then
				rm -Rf ${template_path}
			fi
			print_error "Mount ${nfs_ip}:${nfs_path} failed."
		fi
	else
		template_path=$nfs_path
	fi
else
	print_error "NFS server parameters is error."
fi

echo "[{\"template_path\":\"$template_path\"}]"
	
if [ "$log_flag" == "0" ]
then
	rm -f "${error_log}" 2> /dev/null
	rm -f "$out_log" 2> /dev/null
fi

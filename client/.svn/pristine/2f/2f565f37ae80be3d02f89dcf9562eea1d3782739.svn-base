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
					nfs_path=$nfs_info;;
			2)
					j=3;
					template_path=$nfs_info;;
		esac
done

formatPath $nfs_path
nfs_path=$path
formatPath $template_path
template_path=$path

mount_info=$(mount 2>&1)
if [ $? != 0 ]
then
	print_error "$mount_info"
fi

for ent in $(ifconfig -a| grep -v 'Loopback' |grep -v 'be|dman|lpfc' | egrep '(^[a-z])|(^[A-Z])' | sed 's/: flags/ /g' | awk '{print $1}')
do
	pd_ip=$(ifconfig $ent | grep inet | grep -v inet6 | awk '{print $2}' | awk -F":" '{print $2}');
done

if [ "$pd_ip" != "$nfs_ip" ]
then
	if [ "$mount_info" != "" ]
	then
		check=$(echo "$mount_info" | awk '{if($1==mount_node && $3==template_path) print $0}' mount_node="$nfs_ip:$nfs_path" template_path="$template_path")
		if [ "$check" != "" ]
		then
			info=$(umount -f ${template_path} 2>&1)
			if [ $? == 0 ]
			then
				rm -Rf ${template_path} > /dev/null 2>&1
			fi
		fi
	fi
fi

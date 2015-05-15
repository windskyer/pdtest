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

ent=$(ifconfig -a| grep -v 'LOOPBACK' |grep -v 'be|dman|lpfc' | grep '^[a-z,A-z]' | sed 's/: flags/ /g' | awk '{print $1}'|head -1)
pd_ip=$(ifconfig $ent | grep inet | awk '{print $2}'|head -1)

if [ "$pd_ip" != "$nfs_ip" ]
then
	if [ "$mount_info" != "" ]
	then
		check=$(echo "$mount_info" | awk '{if($1==nfs_ip && $2==nfs_path && $3==template_path) print $0}' nfs_ip="$nfs_ip" nfs_path="$nfs_path" template_path="$template_path")
		if [ "$check" != "" ]
		then
			info=$(umount -f ${template_path} 2>&1)
			if [ $? == 0 ]
			then
				template_info=$(ls ${template_path} 2>&1)
				if [ "$template_info" == "" ]
				then
					rm -Rf ${template_path} > /dev/null 2>&1
				fi
			fi
		fi
	fi
fi
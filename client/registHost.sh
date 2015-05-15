#!/usr/bin/ksh

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
		esac
done

if [ ! -f ~/.ssh/id_dsa ]
then
	echo "no"
#	ssh-keygen -f ~/.ssh/id_dsa -q -t dsa -N ""
fi

#expect ./registSSHKey.sh ${ivm_ip} ${ivm_user} ${ivm_passwd}

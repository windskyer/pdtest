#!/usr/bin/ksh

info_length=0
for param in $(echo $1 |awk -F"|" '{for(i=1;i<=NF;i++) print $i}')
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
					lpar_id=$param;;
			3)
					info_length=4;
					auto_start=$param;;
		esac
done

result=$(ssh ${ivm_user}@${ivm_ip} "chsyscfg -r prof -i auto_start=${auto_start},lpar_id=${lpar_id}" 2>&1)
if [ $? -ne 0 ]
then
	echo "$result" >&2
	exit 1
fi

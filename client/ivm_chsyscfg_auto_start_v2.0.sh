#!/usr/bin/ksh

. ./ivm_function.sh

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

log_flag=$(cat scrpits.properties 2> /dev/null | grep "LOG=" | awk -F"=" '{print $2}')
if [ "$log_flag" == "" ]
then
	log_flag=0
fi

DateNow=$(date +%Y%m%d%H%M%S)
random=$(perl -e 'my $random = int(rand(9999)); print "$random";')
out_log="${path_log}/out_ivm_create_vm_iso_v2.0_${lpar_name}_${DateNow}_${random}.log"
error_log="${path_log}/error_ivm_create_vm_iso_v2.0_${lpar_name}_${DateNow}_${random}.log"

log_debug $LINENO "$0 $*"

# check authorized and repair error authorized
check_authorized ${ivm_ip} ${ivm_user}
result=$(ssh ${ivm_user}@${ivm_ip} "chsyscfg -r prof -i auto_start=${auto_start},lpar_id=${lpar_id}" 2>&1)
if [ $? -ne 0 ]
then
	echo "$result" >&2
	exit 1
fi

if [ "$log_flag" == "0" ]
then
	rm -f "${error_log}" 2> /dev/null
	rm -f "$out_log" 2> /dev/null
fi

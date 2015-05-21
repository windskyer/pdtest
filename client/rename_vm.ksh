#!/usr/bin/ksh

. ./ivm_function.sh

ivm_ip=$1
ivm_user=$2
lpar_id=$3
new_name=$4

log_flag=$(cat scrpits.properties 2> /dev/null | grep "LOG=" | awk -F"=" '{print $2}')
if [ "$log_flag" == "" ]
then
	log_flag=0
fi

DateNow=$(date +%Y%m%d%H%M%S)
random=$(perl -e 'my $random = int(rand(9999)); print "$random";')
out_log="${path_log}/out_rename_vm_${lpar_name}_${DateNow}_${random}.log"
error_log="${path_log}/error_rename_vm_${lpar_name}_${DateNow}_${random}.log"

log_debug $LINENO "$0 $*"

# check authorized and repair error authorized
check_authorized ${ivm_ip} ${ivm_user}

ssh ${ivm_user}@${ivm_ip} "chsyscfg -r lpar -i new_name=\"${new_name}\",lpar_id=${lpar_id}"

if [ "$log_flag" == "0" ]
then
	rm -f "${error_log}" 2> /dev/null
	rm -f "$out_log" 2> /dev/null
fi


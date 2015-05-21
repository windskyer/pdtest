#!/usr/bin/ksh

. ./ivm_function.sh

catchException() {
        
	error_result=$(cat $1)
	          
}

throwException() {
            
	result=$1
	error_code=$2
	           
	if [ "${result}" != "" ]
	then
		if [ "$(echo "$result" | grep "VIOSE" | sed 's/ //g')" != "" ]
		then
			echo "ERROR-${error_code}:"$(echo "$result" | awk -F']' '{print $2}') >&2
		else
			echo "ERROR-${error_code}: $result" >&2
		fi
		
		if [ "$log_flag" == "0" ]
		then
			rm -f "${error_log}" 2> /dev/null
			rm -f "$out_log" 2> /dev/null
		fi
		exit 1
	fi

}

log_flag=$(cat scrpits.properties 2> /dev/null | grep "LOG=" | awk -F"=" '{print $2}')
if [ "$log_flag" == "" ]
then
	log_flag=0
fi

ivm_ip=$1
ivm_user=$2
lpar_id=$3
slot_num=$4

if [ "$ivm_ip" == "" ]
then
	throwException "IP is null" "105053"
fi

if [ "$ivm_user" == "" ]
then
	throwException "User name is null" "105053"
fi

if [ "$lpar_id" == "" ]
then
	throwException "Lpar id is null" "105053"
fi

log_flag=$(cat scrpits.properties 2> /dev/null | grep "LOG=" | awk -F"=" '{print $2}')
if [ "$log_flag" == "" ]
then
	log_flag=0
fi

DateNow=$(date +%Y%m%d%H%M%S)
random=$(perl -e 'my $random = int(rand(9999)); print "$random";')
out_log="${path_log}/out_ivm_vm_del_eth_${DateNow}_${random}.log"
error_log="${path_log}/error_ivm_vm_del_eth_${DateNow}_${random}.log"

log_debug $LINENO "$0 $*"
# check authorized and repair error authorized
check_authorized ${ivm_ip} ${ivm_user}

log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"lssyscfg -r lpar -F state --filter lpar_ids=$lpar_id\""
lpar_state=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar -F state --filter lpar_ids=$lpar_id")
log_debug $LINENO "lpar_state=${lpar_state}"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"lssyscfg -r lpar -F rmc_state,dlpar_io_capable --filter lpar_ids=${lpar_id}\""
rmc_state=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar -F rmc_state,dlpar_io_capable --filter lpar_ids=${lpar_id}")
log_debug $LINENO "rmc_state=${rmc_state}"

if [ "$lpar_state" != "Not Activated" ]&&[ "$rmc_state" != "active,1" ]
then
	throwException "Lpar does not support dynamic modification, please shutdown first." "105068"
fi

log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"lssyscfg -r prof -F virtual_eth_adapters --filter lpar_ids=${lpar_id}\""
eth_info=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r prof -F virtual_eth_adapters --filter lpar_ids=${lpar_id}" 2> $error_log | sed 's/"//g' | awk -F"," '{for(i=1;i<=NF;i++) print $i}' | awk -F"/" '{if($1==slot_num) print $0}' slot_num="$slot_num")
log_debug $LINENO "eth_info=${eth_info}"
catchException "${error_log}"
throwException "$error_result" "105080"
# echo "eth_info==$eth_info"

if [ "$lpar_state" == "Not Activated" ]
then
	log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"chsyscfg -r prof -i virtual_eth_adapters-=${eth_info},lpar_id=${lpar_id}\""
	ssh ${ivm_user}@${ivm_ip} "chsyscfg -r prof -i virtual_eth_adapters-=${eth_info},lpar_id=${lpar_id}" 2> $error_log
	catchException "${error_log}"
	throwException "$error_result" "105081"
else
	if [ "$rmc_state" == "active,1" ]
	then
		log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"chhwres -r virtualio --rsubtype eth -o r -s $slot_num --id $lpar_id\""
		ssh ${ivm_user}@${ivm_ip} "chhwres -r virtualio --rsubtype eth -o r -s $slot_num --id $lpar_id" > /dev/null 2> $error_log
		catchException "${error_log}"
		throwException "$error_result" "105081"
	else
		throwException "Lpar does not support dynamic modification, please shutdown first." "105068"
	fi
fi

if [ "$log_flag" == "0" ]
then
	rm -f "${error_log}" 2> /dev/null
	rm -f "$out_log" 2> /dev/null
fi

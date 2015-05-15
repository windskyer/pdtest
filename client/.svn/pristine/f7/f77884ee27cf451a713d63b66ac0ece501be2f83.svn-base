#!/usr/bin/ksh
#./hmc_vm_del_eth.sh 172.30.126.19 hscroot p730-2 3 5
# lssyscfg -r prof -m p730-2 --filter lpar_ids=3
. ./hmc_function.sh

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

hmc_ip=$1
hmc_user=$2
host_id=$3
lpar_id=$4
slot_num=$5

if [ "$hmc_ip" == "" ]
then
	throwException "IP is null" "105401"
fi

if [ "$hmc_user" == "" ]
then
	throwException "User name is null" "105402"
fi

if [ "$host_id" == "" ]
then
	throwException "host id is null" "105433"
fi

if [ "$lpar_id" == "" ]
then
	throwException "Lpar id is null" "105434"
fi

DateNow=$(date +%Y%m%d%H%M%S)
random=$(perl -e 'my $random = int(rand(9999)); print "$random";')
out_log="out_vm_add_eth_${DateNow}_${random}.log"
error_log="error_vm_add_eth_${DateNow}_${random}.log"

lpar_name=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -r prof -m $host_id -F name --filter lpar_ids=$lpar_id" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	echoError "$lpar_name" "105474"
fi

lpar_state=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -r lpar -m $host_id -F state --filter lpar_ids=$lpar_id" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	echoError "$lpar_state" "105435"
fi

rmc_state=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -r lpar -m $host_id -F rmc_state,dlpar_io_capable --filter lpar_ids=${lpar_id}" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	echoError "$rmc_state" "105475"
fi

if [ "$lpar_state" != "Not Activated" ]&&[ "$rmc_state" != "active,1" ]
then
	throwException "Lpar does not support dynamic modification, please shutdown first." "105468"
fi


eth_info=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -r prof -m $host_id -F virtual_eth_adapters --filter lpar_ids=${lpar_id}" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	echoError "$eth_info" "105471"
fi
eth_info=$(echo "$eth_info" | sed 's/"//g' | awk -F"," '{for(i=1;i<=NF;i++) print $i}' | awk -F"/" '{if($1==slot_num) print $0}' slot_num="$slot_num")
# echo "eth_info==$eth_info"
if [ "$eth_info" == "" ]
then
	exit 0
fi

if [ "$lpar_state" == "Not Activated" ]
then
	result=$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -r prof -m $host_id -i virtual_eth_adapters-=${eth_info},lpar_id=${lpar_id},name=${lpar_name}" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		echoError "$result" "105472"
	fi
else
	if [ "$rmc_state" == "active,1" ]
	then
		result=$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -r prof -m $host_id -i virtual_eth_adapters-=${eth_info},lpar_id=${lpar_id},name=${lpar_name}" 2>&1)
		if [ "$(echo $?)" != "0" ]
		then
			echoError "$result" "105472"
		fi
		
		result=$(ssh ${hmc_user}@${hmc_ip} "chhwres -r virtualio -m $host_id --rsubtype eth -o r -s $slot_num --id $lpar_id" 2>&1)
		if [ "$(echo $?)" != "0" ]
		then
			echoError "$result" "105473"
		fi
	else
		throwException "Lpar does not support dynamic modification, please shutdown first." "105468"
	fi
fi

if [ "$log_flag" == "0" ]
then
	rm -f "${error_log}" 2> /dev/null
	rm -f "$out_log" 2> /dev/null
fi

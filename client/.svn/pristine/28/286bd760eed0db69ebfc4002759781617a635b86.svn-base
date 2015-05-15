#!/usr/bin/ksh

. ../ivm_function.sh

pd_error() {
	err=$1
	error_code=$2
	echo "0|0|ERROR-${err}: ${error_code}"
	exit 1
}

get_param() {
	j=0 
	echo $1 |awk -F"|" '{for(i=1;i<=NF;i++) print $i}' | while read param
do
	case $j in
		0)  
			j=1;
			ivm_ip=$param;;
		1)  
			j=2;     
			ivm_user=$param;;
		2)  
			j=3;
			ieee_virtual_eth=$param;;
		3)  
			j=4;
			port_vlan_id=$param;;
		4)  
			j=5;
			addl_vlan_ids=$param;;
		5)  
			j=6;
			is_trunk=$param;;
		6)  
			j=7;
			trunk_priority=$param;;
	esac
done

if [ "$ivm_ip" == "" -o "$ivm_user" == "" -o "$ieee_virtual_eth" == "" -o "$port_vlan_id" == "" ]
then
	pd_error "param error" "100000"
fi  

}


ivm_create_virtual_eth()
{
	#vios's lpar_id
	lpar_id=1

	#get parameters
	get_param $1

	#find an unused slot
	current_max_slot=$(ssh ${ivm_user}@${ivm_ip}  "lshwres -r virtualio --rsubtype slot --level slot --filter lpar_ids=$lpar_id" | tail -1 | awk -F '[=,]' '{print $2}')
	((slot_num=current_max_slot+1))
	
	#create the virtual eth
	log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip}  \"chhwres -r virtualio --rsubtype eth -o a -s $slot_num --id $lpar_id -a ieee_virtual_eth=$ieee_virtual_eth,port_vlan_id=$port_vlan_id,is_trunk=$is_trunk,trunk_priority=$trunk_priority,\\\"addl_vlan_ids=$addl_vlan_ids\\\"\""
	output=$(ssh ${ivm_user}@${ivm_ip}  "chhwres -r virtualio --rsubtype eth -o a -s $slot_num --id $lpar_id -a ieee_virtual_eth=$ieee_virtual_eth,port_vlan_id=$port_vlan_id,is_trunk=$is_trunk,trunk_priority=$trunk_priority,\\\"addl_vlan_ids=$addl_vlan_ids\\\"" 2>&1)
	if [ $? != 0 ]
	then
		echo "0|0|ERROR-$output: 1100009"
		exit 1
	fi
	log_debug $LINENO "output=${output}"
	locationCode=$(echo $output|awk '{print $8}')
	ethName=$(ssh ${ivm_user}@${ivm_ip}  "ioscli lsmap -all -net" | grep "$locationCode" | awk '{print $1}')
	status=$(ssh ${ivm_user}@${ivm_ip}  "ioscli lsdev" | grep "$ethName" | awk '{print $2}')
	isRequired=$(ssh ${ivm_user}@${ivm_ip}  "lshwres -r virtualio --rsubtype eth --level lpar --filter lpar_ids=$lpar_id" | grep "$slot_num" | awk -F '[=]' '{print $11}' | awk -F ',' '{print $1}')
	mac_addr=$(ssh ${ivm_user}@${ivm_ip}  "lshwres -r virtualio --rsubtype eth --level lpar --filter lpar_ids=$lpar_id" | grep "$slot_num" | awk -F '=' '{print $12}')
	#add : to format the mac_addr
	mac_addr=$(echo $mac_addr|sed 's,\(.\{2\}\)\(.\{2\}\)\(.\{2\}\)\(.\{2\}\)\(.\{2\}\)\(.\{2\}\),\1:\2:\3:\4:\5:\6,')
	echo "[{\"trunkMode\":\"$is_trunk\",\"trunk_priority\":\"$trunk_priority\",\"ethName\":\"$ethName\",\"slotNum\":\"$slot_num\",\"locationCode\":\"$locationCode\",\"pvid\":\"$port_vlan_id\",\"ieeeCompatible\":\"$ieee_virtual_eth\",\"status\":\"$status\",\"vids\":[$addl_vlan_ids],\"isRequired\":\"$isRequired\",\"macAddr\":\"$mac_addr\"}]"

}

log_flag=$(cat ../scrpits.properties 2> /dev/null | grep "LOG=" | awk -F"=" '{print $2}')
if [ "$log_flag" == "" ]
then
	log_flag=0
fi

DateNow=$(date +%Y%m%d%H%M%S)
random=$(perl -e 'my $random = int(rand(9999)); print "$random";')
out_log="${path_log}/out_ivm_create_virtual_eth_${DateNow}_${random}.log"
error_log="${path_log}/error_ivm_create_virtual_eth_${DateNow}_${random}.log"

log_debug $LINENO "$0 $*"

ivm_create_virtual_eth $1

if [ "$log_flag" == "0" ]
then
	rm -f "${error_log}" 2> /dev/null
	rm -f "$out_log" 2> /dev/null
fi

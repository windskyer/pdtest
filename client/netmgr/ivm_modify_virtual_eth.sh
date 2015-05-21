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
			slot_num=$param;;
	esac
done

if [ "$ivm_ip" == "" -o "$ivm_user" == "" -o "$ieee_virtual_eth" == "" -o "$port_vlan_id" == "" ]
then
	pd_error "param error" "100000"
fi  

}

ivm_modify_virtual_eth()
{
	get_param $1
	
	check_authorized ${ivm_ip} ${ivm_user}
	
	
	./ivm_delete_virtual_eth.sh "$ivm_ip|$ivm_user|$slot_num"
	if [ $? != 0 ]
	then
		exit 1
	fi
	./ivm_create_virtual_eth.sh "$ivm_ip|$ivm_user|$ieee_virtual_eth|$port_vlan_id|$addl_vlan_ids|$is_trunk"
	if [ $? != 0 ]
	then
		exit 1
	fi
}



DateNow=$(date +%Y%m%d%H%M%S)
random=$(perl -e 'my $random = int(rand(9999)); print "$random";')
out_log="${path_log}/out_ivm_modify_sea_${DateNow}_${random}.log"
error_log="${path_log}/error_ivm_modify_sea_${DateNow}_${random}.log"

log_debug $LINENO "$0 $*"

ivm_modify_virtual_eth $1

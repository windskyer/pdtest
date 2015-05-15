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
			slot_num=$param;;
	esac
done

if [ "$ivm_ip" == "" -o "$ivm_user" == "" -o "$slot_num" == "" ]
then
	pd_error "param error" "100000"
fi  

}

ivm_delete_virtual_eth()
{
	#vios's lpar_id
	lpar_id=1

	#get parameters
	get_param $1
	
	#delete the virtual eth
	log_debug $LINENO "CMD:ssh "$ivm_user"@"$ivm_ip" \"chhwres -r virtualio --rsubtype eth -o r -s $slot_num --id $lpar_id\""
	ret=$(ssh "$ivm_user"@"$ivm_ip" "chhwres -r virtualio --rsubtype eth -o r -s $slot_num --id $lpar_id" 2>&1)
	if [ $? != 0 ]
	then
		pd_error "$ret" "1100008"
	fi
	log_debug $LINENO "ret=${ret}"
}

log_flag=$(cat ../scrpits.properties 2> /dev/null | grep "LOG=" | awk -F"=" '{print $2}')
if [ "$log_flag" == "" ]
then
	log_flag=0
fi

DateNow=$(date +%Y%m%d%H%M%S)
random=$(perl -e 'my $random = int(rand(9999)); print "$random";')
out_log="${path_log}/out_ivm_delete_virtual_eth_${DateNow}_${random}.log"
error_log="${path_log}/error_ivm_delete_virtual_eth_${DateNow}_${random}.log"

log_debug $LINENO "$0 $*"

ivm_delete_virtual_eth $1

if [ "$log_flag" == "0" ]
then
	rm -f "${error_log}" 2> /dev/null
	rm -f "$out_log" 2> /dev/null
fi

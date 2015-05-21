#!/usr/bin/ksh

echo "1|0|SUCCESS"
. ./ivm_function.sh

throwException() {
            
	result=$1
	error_code=$2
	           
	if [ "${result}" != "" ]
	then
		if [ "$(echo "$result" | grep "VIOSE" | sed 's/ //g')" != "" ]
		then
			echo "0|0|ERROR-${error_code}:"$(echo "$result" | awk -F']' '{print $2}')
		else
			echo "0|0|ERROR-${error_code}: ${result}"
		fi
		
		exit 1
	fi

}

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

lpar_info=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar -F lpar_id,lpar_env,state" 2>&1)
if [ $? -ne 0 ]
then
	throwException "$lpar_info" "105301"
fi

len=0
echo "$lpar_info" | while read lpar_info
do
	# echo "lpar_info==$lpar_info"
	lpar_env=$(echo "$lpar_info" | awk -F"," '{print $2}')
	if [ "$lpar_env" != "vioserver" ]
	then
		lpar_id[$len]=$(echo "$lpar_info" | awk -F"," '{print $1}')
		lpar_state=$(echo "$lpar_info" | awk -F"," '{print $3}')
		# echo "lpar_state===$lpar_state"
		if [ "$lpar_state" != "Not Activated" ]
		then
			cli=$cli"chsysstate -r lpar -o shutdown --id ${lpar_id[$len]} --immed ;"
			len=$(expr $len + 1)
		fi
	else
		vios_id=$(echo "$lpar_info" | awk -F"," '{print $1}')
	fi
done

# echo "len==$len"

if [ $len -ne 0 ]
then
	cli=$(echo $cli | awk '{print substr($0,0,length($0)-1)}')
	result=$(ssh ${ivm_user}@${ivm_ip} "$cli" 2>&1)
	if [ $? -ne 0 ]
	then
		throwException "$result" "105302"
	fi
fi
echo "1|20|SUCCESS"

step=$(echo 70 | awk '{print $0/len}' len="$len")

i=0
time=0
process=20
while [ $i -lt $len ]
do
	lpar_state=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar --filter lpar_ids=${lpar_id[$i]} -F state" 2>&1)
	if [ $? -ne 0 ]
	then
		echo "$lpar_state" >&2
		exit 1
	fi
	# echo "${lpar_id[$i]} $lpar_state"
	
	if [ "$lpar_state" == "Not Activated" ]
	then
		time=0
		process=$(echo $process $step | awk '{print $1+$2}')
		echo "1|${process%.*}|SUCCESS"
		i=$(expr $i + 1)
	fi
	
	sleep 1
	time=$(expr $time + 1)
	if [ $time -gt 20 ]
	then
		time=0
		process=$(echo $process $step | awk '{print $1+$2}')
		echo "1|${process%.*}|SUCCESS"
		continue
	fi
done

if [ "$log_flag" == "0" ]
then
	rm -f "${error_log}" 2> /dev/null
	rm -f "$out_log" 2> /dev/null
fi

echo "1|100|SUCCESS"

result=$(ssh ${ivm_user}@${ivm_ip} "chsysstate -r lpar -o shutdown --id ${vios_id}" 2>&1)
if [ $? -ne 0 ]
then
	echo "$result" >&2
	exit 1
fi

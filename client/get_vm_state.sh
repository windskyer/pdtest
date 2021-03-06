#!/usr/bin/ksh
#./get_all_vm_state.sh 172.30.126.12 padmin
#./get_all_vm_state.sh 172.30.126.12 padmin 3

. ./ivm_function.sh

ivm_ip=$1
ivm_user=$2
lpar_id=$3

log_flag=$(cat scrpits.properties 2> /dev/null | grep "LOG=" | awk -F"=" '{print $2}')
if [ "$log_flag" == "" ]
then
	log_flag=0
fi

DateNow=$(date +%Y%m%d%H%M%S)
random=$(perl -e 'my $random = int(rand(9999)); print "$random";')
out_log="${path_log}/out_get_vg_info_v2.0_${DateNow}_${random}.log"
error_log="${path_log}/error_get_vg_info_v2.0_${DateNow}_${random}.log"

log_debug $LINENO "$0 $*"
# check authorized and repair error authorized
check_authorized ${ivm_ip} ${ivm_user}


throwException() {
            
	result=$1
	error_code=$2
	           
	if [ "${result}" != "" ]
	then
		echo "0|0|ERROR-${error_code}: ${result}"
		exit 1
	fi

}

aix_getinfo() {
	i=0
	echo  "[\c"
	while [ $i -lt $length ]
	do
		echo  "{\c"
		echo  "\"lpar_name\":\"${vm_name[$i]}\",\c"
		echo  "\"lpar_id\":\"${vm_id[$i]}\",\c"
		echo  "\"lpar_env\":\"${vm_env[$i]}\",\c"
		echo  "\"lpar_state\":\"${vm_state[$i]}\",\c"
		echo  "\"lpar_rmcstate\":\"${vm_rmcstate[$i]}\"\c"
		
		i=$(expr $i + 1)
		if [ "$i" == "$length" ]
		then
			echo  "}]"
		else
			echo  "},\c"
		fi
	done
}

linux_getinfo() {
	i=0
	echo -e "[\c"
	while [ $i -lt $length ]
	do
		echo -e "{\c"
		echo -e "\"lpar_name\":\"${vm_name[$i]}\", \c"
		echo -e "\"lpar_id\":\"${vm_id[$i]}\", \c"
		echo -e "\"lpar_env\":\"${vm_env[$i]}\", \c"
		echo -e "\"lpar_state\":\"${vm_state[$i]}\", \c"
		echo -e "\"lpar_rmcstate\":\"${vm_rmcstate[$i]}\"\c"
		
		i=$(expr $i + 1)
		if [ "$i" == "$length" ]
		then
			echo -e "}]"
		else
			echo -e "},\c"
		fi
	done
}

ping -c 3 $ivm_ip > /dev/null 2>&1
if [ $? -ne 0 ]
then
	throwException "Unable to connect IVM server." "105005"
fi

if [ "$lpar_id" == "" ]
then
	log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"lssyscfg -r lpar -F name,lpar_id,lpar_env,state,rmc_state\""
	vm_sys_info=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar -F name,lpar_id,lpar_env,state,rmc_state")
else
	log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"lssyscfg -r lpar -F name,lpar_id,lpar_env,state,rmc_state --filter lpar_ids=$lpar_id\""
	vm_sys_info=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar -F name,lpar_id,lpar_env,state,rmc_state --filter lpar_ids=$lpar_id")
fi
log_debug $LINENO "vm_sys_info=${vm_sys_info}"

length=0
if [ "${vm_sys_info}" != "" ]
then
	echo "${vm_sys_info}" | while read sys_info
	do
		index=0
		if [ "$sys_info" != "" ]
		then
       vm_name[${length}]=$(echo "${sys_info}" | awk -F"," '{print $1}')
       vm_id[${length}]=$(echo "${sys_info}" | awk -F"," '{print $2}')
       vm_env[${length}]=$(echo "${sys_info}" | awk -F"," '{print $3}')
       vm_state[${length}]=$(echo "${sys_info}" | awk -F"," '{print $4}')       
       vm_rmcstate[${length}]=$(echo "${sys_info}" | awk -F"," '{print $5}')
			
       length=$(expr $length + 1)
		fi
	done
else
	echo "[]"
	exit 1
fi

case $(uname -s) in
	AIX)
		aix_getinfo;;
	Linux)
		linux_getinfo;;
	*BSD)
		bsd_getinfo;;
	SunOS)
		sun_getinfo;;
	HP-UX)
		hp_getinfo;;
	*) echo "unknown";;
esac

if [ "$log_flag" == "0" ]
then
	rm -f "${error_log}" 2> /dev/null
	rm -f "${out_log}" 2> /dev/null
fi
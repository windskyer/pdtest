#!/usr/bin/ksh

echo "1|35|SUCCESS"

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
			result=$(echo "$result" | awk -F']' '{print $2}')
		fi
		echo "0|0|ERROR-${error_code}: $result"
		rm -f "${error_log}" 2> /dev/null
		rm -f "$out_log" 2> /dev/null
		exit 1
	fi

}

waitRunning() {
#	echo "waitRunning"
	while [ "${lpar_state}" != "Running" ]
	do
		sleep 10
		lpar_state=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar --filter lpar_ids=${lpar_id} -F state")
	done
}

waitOpenFirmware() {
#	echo "waitOpenFirmware"
	while [ "${lpar_state}" != "Open Firmware" ]
	do
		sleep 10
		lpar_state=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar --filter lpar_ids=${lpar_id} -F state")
	done
}

waitShutDown() {
#	echo "waitShutDown"
	while [ "${lpar_state}" != "Not Activated" ]
	do
		sleep 10
		lpar_state=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar --filter lpar_ids=${lpar_id} -F state")
	done
}

shutDown() {
#	echo "shutDown"
	ssh ${ivm_user}@${ivm_ip} "chsysstate -r lpar -o shutdown --id ${lpar_id} --immed" 2> ${error_log}
	catchException ${error_log}
	throwException "$error_result" "105035"
	rm -f ${error_log}
}

startupSms() {
#	echo "startupSms"
	ssh ${ivm_user}@${ivm_ip} "chsysstate -r lpar -o on -b sms --id ${lpar_id}" 2> ${error_log}
	waitOpenFirmware
	catchException ${error_log}
	throwException "$error_result" "105030"
	rm -f ${error_log}
}

ivm_ip=$1
ivm_user=$2
lpar_id=$3

if [ "$ivm_ip" == "" ]
then
	throwException "IP is null" "105030"
fi

if [ "$ivm_user" == "" ]
then
	throwException "User name is null" "105030"
fi

if [ "$lpar_id" == "" ]
then
	throwException "Lpar id is null" "105030"
fi

log_flag=$(cat scrpits.properties 2> /dev/null | grep "LOG=" | awk -F"=" '{print $2}')
if [ "$log_flag" == "" ]
then
	log_flag=0
fi

DateNow=$(date +%Y%m%d%H%M%S)
random=$(perl -e 'my $random = int(rand(9999)); print "$random";')
out_log="${path_log}/out_startup_vm_sms_${DateNow}_${random}.log"
error_log="${path_log}/error_startup_vm_sms_${DateNow}_${random}.log"

log_debug $LINENO "$0 $*"

# check authorized and repair error authorized
check_authorized ${ivm_ip} ${ivm_user}

lpar_state=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar --filter lpar_ids=${lpar_id} -F state" 2> /dev/null)

if [ "$lpar_state" == "" ]
then
	throwException "No results were found." "105068"
fi

echo "1|50|SUCCESS"

desc="The vm state is "$lpar_state

while [ "$lpar_state" != "Open Firmware" ]
do
		lpar_state=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar --filter lpar_ids=${lpar_id} -F state")
		case $lpar_state in
				Starting)
							desc=$desc", wait running state";
							waitRunning;;
				Running)
							desc=$desc", shutdown";
							shutDown;;
				"Shutting Down")
							desc=$desc", wait shutdown";
							waitShutDown;;
				"Open Firmware")
							echo "1|100|SUCCESS: $desc";
							exit 0;;
				Error)
							throwException "Virtual machine state is error." "105068";;
				"Not Available")
							throwException "Virtual machine state is not available." "105068";;
				"Not Activated")
							desc=$desc", startup with sms";
							startupSms;;
		esac
done

if [ "$log_flag" == "0" ]
then
	rm -f "${error_log}" 2> /dev/null
	rm -f "$out_log" 2> /dev/null
fi

echo "1|100|SUCCESS: $desc"
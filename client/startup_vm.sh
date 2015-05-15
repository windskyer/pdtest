#!/usr/bin/ksh

catchException() {
        
	error_result=$(cat $1)
	          
}

throwException() {
            
	result=$1
	           
	if [ "${result}" != "" ]
	then
		if [ "$(echo "$result" | grep "]" | sed 's/ //g')" != "" ]
		then
			result=$(echo "$result" | awk -F']' '{print $2}')
		fi
		echo "0|0|ERROR:$result"
		exit 1
	fi

}

ivm_ip=$1
ivm_user=$2
lpar_id=$3

DateNow=$(date +%Y%m%d%H%M%S)
out_log="out_startup_${DateNow}.log"
error_log="error_startup_${DateNow}.log"

echo "1|50|SUCCESS"

lpar_state=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar --filter lpar_ids=${lpar_id} -F state")
if [ "${lpar_state}" == "Running" ]
then
	echo "1|100|SUCCESS"
	exit 1
fi

if [ "${lpar_state}" == "Starting" ]
then
	while [ "${lpar_state}" != "Running" ]
	do
		sleep 10
		lpar_state=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar --filter lpar_ids=${lpar_id} -F state")
	done
	echo "1|100|SUCCESS"
	exit 1
fi

if [ "${lpar_state}" == "Shutting Down" ]
then
	while [ "${lpar_state}" != "Not Activated" ]
	do
		sleep 10
		lpar_state=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar --filter lpar_ids=${lpar_id} -F state")
	done
fi

#echo "$(date) : startup vm , lpar id is ${lpar_id}" > ${out_log}
ssh ${ivm_user}@${ivm_ip} "chsysstate -r lpar -o on -b norm --id ${lpar_id}" 2> ${error_log}
catchException ${error_log}
throwException "$error_result"

while [ "${lpar_state}" != "Running" ]
do
	sleep 30
	lpar_state=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar --filter lpar_ids=${lpar_id} -F state")
#	echo "lpar_state=$lpar_state"
done
#echo "startup lpar ${lpar_id} ok" >> ${out_log}
echo "1|100|SUCCESS"
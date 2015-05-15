#!/usr/bin/ksh

. ./ivm_function.sh

echo "1|10|SUCCESS"

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
		if [ "$log_flag" == "0" ]
		then
			rm -f "${error_log}" 2> /dev/null
			rm -f "$out_log" 2> /dev/null
		fi
		echo "0|0|ERROR-${error_code}: $result"
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

waitShutDown() {
#	echo "waitShutDown"
	while [ "${lpar_state}" != "Not Activated" ]
	do
		sleep 3
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

ivm_ip=$1
ivm_user=$2
lpar_id=$3

if [ "$ivm_ip" == "" ]
then
	throwException "IP is null" "105055"
fi

if [ "$ivm_user" == "" ]
then
	throwException "User name is null" "105055"
fi

if [ "$lpar_id" == "" ]
then
	throwException "Lpar id is null" "105055"
fi

DateNow=$(date +%Y%m%d%H%M%S)
random=$(perl -e 'my $random = int(rand(9999)); print "$random";')
out_log="${path_log}/out_remove_vm_${DateNow}_${random}.log"
error_log="${path_log}/error_remove_vm_${DateNow}_${random}.log"

log_flag=$(cat scrpits.properties 2> /dev/null | grep "LOG=" | awk -F"=" '{print $2}')
if [ "$log_flag" == "" ]
then
	log_flag=0
fi

log_debug $LINENO "$0 $*"

log_info $LINENO "get lpar state"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"lssyscfg -r lpar --filter lpar_ids=${lpar_id} -F state\""
lpar_state=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar --filter lpar_ids=${lpar_id} -F state" 2> $error_log)
log_debug $LINENO "lpar_state=${lpar_state}"
catchException "$error_log"
if [ "$(echo $error_result | grep "No results were found")" != "" ]
then
	echo "1|100|SUCCESS"
	exit 0
fi

if [ "$lpar_state" != "Not Activated" ]
then
	shutDown
	waitShutDown
fi

# while [ "$lpar_state" != "Not Activated" ]
# do
		# lpar_state=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar --filter lpar_ids=${lpar_id} -F state")
		# echo "lpar_state==$lpar_state"
		# case $lpar_state in
				# Starting)
							# waitRunning;;
				# Running)
							# shutDown;;
				# "Shutting Down")
							# waitShutDown;;
				# "Open Firmware")
							# shutDown;;
				# Error)
							# throwException "Virtual machine state is error." "105068";;
				# "Not Available")
							# throwException "Virtual machine state is not available." "105068";;
				# "Not Activated")
							# echo "1|40|SUCCESS";;
		# esac
# done

#####################################################################################
#####                                                                           #####
#####                  get virtual_scsi_adapters server id                      #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "Get virtual_scsi_adapters server id"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"lssyscfg -r prof --filter lpar_ids=${lpar_id} -F virtual_scsi_adapters\" | awk -F'/' '{print \$5}'"
server_vscsi_id=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r prof --filter lpar_ids=${lpar_id} -F virtual_scsi_adapters" | awk -F'/' '{print $5}' 2> ${error_log})
log_debug $LINENO "server_vscsi_id=${server_vscsi_id}"
catchException ${error_log}
throwException "$error_result" "105063"

#####################################################################################
#####                                                                           #####
#####                            get vios' adapter                              #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "get vios' adapter"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli lsmap -all -fmt :\" | grep "C${server_vscsi_id}:" | awk -F":" '{print \$1}'"
vadapter_vios=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -all -fmt :" | grep "C${server_vscsi_id}:" | awk -F":" '{print $1}' 2> ${error_log})
log_debug $LINENO "vadapter_vios=${vadapter_vios}"
catchException ${error_log}
throwException "$error_result" "105064"

#####################################################################################
#####                                                                           #####
#####                               get vm's lv                                 #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "get vm's lv"
log_debug $LINENO "CMD:"
vm_lvs=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -vadapter ${vadapter_vios} -type lv -field backing -fmt :" 2> ${error_log})
log_debug $LINENO "vm_lvs=${vm_lvs}"
catchException ${error_log}
throwException "$error_result" "105065"

#####################################################################################
#####                                                                           #####
#####                               get vm's lu                                 #####
#####                                                                           #####
#####################################################################################
# echo "$(date) : get vm's lu" >> ${out_log}
# clustername=$(ssh ${ivm_user}@${ivm_ip} "ioscli cluster -list|grep -E 'CLUSTER_NAME'|awk '{print \$2}'")
# spname=$(ssh ${ivm_user}@${ivm_ip} 2>/dev/null "ioscli lssp -clustername $clustername|grep -E 'POOL_NAME'|awk '{print \$2}'")

# vm_lus=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -vadapter ${vadapter_vios} -type cl_disk -field backing -fmt :" 2> ${error_log})
# catchException ${error_log}
# throwException "$error_result" "105065"
# echo "vm_lvs=${vm_lvs}" >> ${out_log}


#####################################################################################
#####                                                                           #####
#####                           delete vm's profile                             #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "delete vm's profile, lpar id is ${lpar_id}"
log_debug $LINENO "CMD:${ivm_user}@${ivm_ip} \"rmsyscfg -r lpar --id ${lpar_id}\""
ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}" 2> ${error_log}
catchException ${error_log}
throwException "$error_result" "105055"

#####################################################################################
#####                                                                           #####
#####                             delete vm's lv                                #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "delete vm's lv"
for lv in $(echo "${vm_lvs}" | awk -F":" '{for(i=1;i<=NF;i++) print $i}')
do
	if [ "$lv" != "" ]
	then
		log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli rmlv -f ${lv}\""
		ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv}" > /dev/null 2>&1
		# catchException ${error_log}
		# if [ "$(echo "$error_result" | grep "Unable to find")" != "" ]
		# then
			# continue
		# fi
		
		# throwException "$error_result" "105056"
	fi
done

#####################################################################################
#####                                                                           #####
#####                             delete vm's lu                                #####
#####                                                                           #####
#####################################################################################
# for lu in $(echo "${vm_lus}" | awk -F":" '{for(i=1;i<=NF;i++) print $i}')
# do
	# if [ "$lu" != "" ]
	# then
		# luudid=$(echo "${lu}"|awk -F"." '{print $NF}')
		# ssh ${ivm_user}@${ivm_ip} "ioscli rmbdsp -clustername ${clustername} -sp ${spname} -luudid ${luudid}" > /dev/null 2>&1
	# fi
# done

if [ "$log_flag" == "0" ]
then
	rm -f "${error_log}" 2> /dev/null
	rm -f "$out_log" 2> /dev/null
fi

echo "1|100|SUCCESS"
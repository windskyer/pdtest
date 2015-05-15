#!/usr/bin/ksh

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
		echo "0|0|ERROR-${error_code}: $result"
		
		if [ "$log_flag" == "0" ]
		then
			rm -f "${error_log}" 2> /dev/null
			rm -f "$out_log" 2> /dev/null
		fi
		exit 1
	fi

}

waitRunning() {
#	echo "waitRunning"
	while [ "${lpar_state}" != "Running" ]
	do
		sleep 10
		lpar_state=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m $host_id -r lpar --filter lpar_ids=${lpar_id} -F state")
	done
}

waitShutDown() {
#	echo "waitShutDown"
	while [ "${lpar_state}" != "Not Activated" ]
	do
		sleep 10
		lpar_state=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m $host_id -r lpar --filter lpar_ids=${lpar_id} -F state")
	done
}

shutDown() {
#	echo "shutDown"
	ssh ${hmc_user}@${hmc_ip} "chsysstate -m $host_id -r lpar -o shutdown --id ${lpar_id} --immed" 2> ${error_log}
	catchException ${error_log}
	throwException "$error_result" "105035"
	sleep 6
	rm -f ${error_log}
}

hmc_ip=$1
hmc_user=$2
host_id=$3
lpar_id=$4

if [ "$hmc_ip" == "" ]
then
	throwException "IP is null" "105055"
fi

if [ "$hmc_user" == "" ]
then
	throwException "User name is null" "105055"
fi

if [ "$host_id" == "" ]
then
	throwException "Host id is null" "105055"
fi

if [ "$lpar_id" == "" ]
then
	throwException "Lpar id is null" "105055"
fi

log_flag=$(cat scrpits.properties 2> /dev/null | grep "LOG=" | awk -F"=" '{print $2}')
if [ "$log_flag" == "" ]
then
	log_flag=0
fi

DateNow=$(date +%Y%m%d%H%M%S)
out_log="out_remove_${DateNow}.log"
error_log="error_remove_${DateNow}.log"


lpar_state=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m $host_id -r lpar --filter lpar_ids=${lpar_id} -F state" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	if [ "$(echo $lpar_state | grep "was not found")" != "" ]
	then
		echo "1|100|SUCCESS"
		exit 0
	else
		throwException "$lpar_state" "105055"
	fi
fi

while [ "$lpar_state" != "Not Activated" ]
do
		lpar_state=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m $host_id -r lpar --filter lpar_ids=${lpar_id} -F state")
		case $lpar_state in
				Starting)
							waitRunning;;
				Running)
							shutDown;;
				"Shutting Down")
							waitShutDown;;
				"Open Firmware")
							shutDown;;
				Error)
							throwException "Virtual machine state is error.";;
				"Not Available")
							throwException "Virtual machine state is not available.";;
				"Not Activated")
							echo "1|40|SUCCESS";;
		esac
done

#####################################################################################
#####                                                                           #####
#####                   get virtual_scsi_adapters server id                     #####
#####                                                                           #####
#####################################################################################
echo "$(date) : Get virtual_scsi_adapters server id" > ${out_log}
server_vscsi_info=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m $host_id -r prof --filter lpar_ids=${lpar_id} -F virtual_scsi_adapters" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	throwException "$server_vscsi_info" "105063"
fi

if [ "$server_vscsi_info" == "none" ]
then
	#####################################################################################
	#####                                                                           #####
	#####                          remove lpar's prof                               #####
	#####                                                                           #####
	#####################################################################################
	echo "$(date) : Remove lpar's prof" >> ${out_log}
	result=$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -m ${host_id} -r lpar --id ${lpar_id}" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		throwException "$result" "105065"
	fi
	echo "1|100|SUCCESS"
	exit 0
fi
vscsi_id=$(echo "$server_vscsi_info" | awk -F'/' '{print $5}')
vios_id=$(echo "$server_vscsi_info" | awk -F'/' '{print $3}')
echo "vscsi_id=${vscsi_id}" >> ${out_log}
echo "vios_id=${vios_id}" >> ${out_log}
echo "1|45|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                               get vios name                               #####
#####                                                                           #####
#####################################################################################
echo "$(date) : Get vios name" >> ${out_log}
vios_prof_name=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m $host_id -r prof --filter lpar_ids=${vios_id} -F name" 2>&1)
if [ "$(echo $?)" != "0" ]
then
		if [ "$vios_prof_name" != "" ]
		then
			throwException "$vios_prof_name" "105063"
		else
			catchException "${error_log}"
			throwException "$error_result" "105063"
		fi
fi
echo "1|50|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                            get vios' adapter                              #####
#####                                                                           #####
#####################################################################################
echo "$(date) : get vios' adapter" >> ${out_log}
vadapter_vios=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id ${vios_id} -c \"lsmap -all -fmt :\"" 2> $error_log)
# if [ "$(echo $?)" != "0" ]||[ "$(echo $?)" != "1" ]
# then
		# if [ "$vadapter_vios" != "" ]
		# then
			# throwException "$vadapter_vios" "105064"
		# else
			# catchException "${error_log}"
			# throwException "$error_result" "105064"
		# fi
# fi
#echo "vadapter_vios==$vadapter_vios"
vadapter_vios=$(echo "$vadapter_vios" | grep "C${vscsi_id}:" | awk -F":" '{print $1}')
if [ "$vadapter_vios" == "" ]
then
	throwException "$vadapter_vios" "105064"
fi
#echo "vadapter_vios==$vadapter_vios"
echo "vadapter_vios=${vadapter_vios}" >> ${out_log}
echo "1|60|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                               get vm's lv                                 #####
#####                                                                           #####
#####################################################################################
echo "$(date) : get vm's lv" >> ${out_log}
if [ "$vadapter_vios" != "" ]
then
	vm_lvs=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id ${vios_id} -c \"lsmap -vadapter ${vadapter_vios} -type lv -field backing -fmt :\"" 2> ${error_log})
	if [ "$(echo $?)" != "0" ]
	then
			if [ "$vm_lvs" != "" ]
			then
				throwException "$vm_lvs" "105065"
			else
				catchException "${error_log}"
				throwException "$error_result" "105065"
			fi
	fi
	#echo "vm_lvs=${vm_lvs}"
	echo "vm_lvs=${vm_lvs}" >> ${out_log}
	echo "1|65|SUCCESS"
fi

#####################################################################################
#####                                                                           #####
#####                              unmapping lv                                 #####
#####                                                                           #####
#####################################################################################
echo "$(date) : unmapping lv" >> ${out_log}
for lv in $(echo "${vm_lvs}" | awk -F":" '{for(i=1;i<=NF;i++) print $i}')
do
	ssh_result=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmvdev -vdev $lv\"" 2> ${error_log})
	if [ "$(echo $?)" != "0" ]
	then
			if [ "$ssh_result" != "" ]
			then
				throwException "$ssh_result" "105065"
			else
				catchException "${error_log}"
				throwException "$error_result" "105065"
			fi
	fi
done
echo "1|70|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                  remove vios' virtual scsi adapters                       #####
#####                                                                           #####
#####################################################################################
echo "$(date) : Remove vios' virtual scsi adapters" >> ${out_log}
result=$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -m ${host_id} -r prof -i \"virtual_scsi_adapters-=${vscsi_id}/server/${lpar_id}//2/0,name=${vios_prof_name},lpar_id=${vios_id}\"" 2> ${error_log})
if [ "$(echo $?)" != "0" ]
then
		if [ "$result" != "" ]
		then
			if [ "$(echo "$result" | grep "not found")" == "" ]
			then
				throwException "$result" "105065"
			fi
		else
			catchException "${error_log}"
			throwException "$error_result" "105065"
		fi
fi
echo "1|75|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                            remove dev                                     #####
#####                                                                           #####
#####################################################################################
echo "$(date) : Remove dev" >> ${out_log}
if [ "$vadapter_vios" != "" ]
then
	vtd=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"lsmap -vadapter ${vadapter_vios} -field vtd backing -fmt :\"" 2> ${error_log})
	if [ "$(echo $?)" != "0" ]
	then
		if [ "$vtd" != "" ]
		then
				throwException "$vtd" "105065"
		else
				catchException "${error_log}"
				throwException "$error_result" "105065"
		fi
	fi
	if [ "$(echo "$vtd" | sed 's/://' | sed 's/ //')" != "" ]
	then
		echo "$vtd" | awk -F":" '{for(i=1;i<=NF;i++) {if(i%2==0) { print $i } else { printf $i"," }}}' | while read line
		do
			if [ "$line" != "" ]
			then
				target_dev=$(echo $line | awk -F"," '{print $1}')
				back_dev=$(echo $line | awk -F"," '{print $2}')
				if [ "$back_dev" != "" ]
				then
					if [ "$(echo $target_dev | grep vtopt)" != "" ]
					then
						ssh_result=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"unloadopt -release -vtd ${target_dev}\"" 2> ${error_log})
						if [ "$(echo $?)" != "0" ]
						then
							if [ "$ssh_result" != "" ]
							then
								throwException "$ssh_result" "105065"
							else
								catchException "${error_log}"
								throwException "$error_result" "105065"
							fi
						fi
					fi
				fi
				if [ "$target_dev" != "" ]
				then
					ssh_result=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmvdev -vtd $target_dev\"" 2> ${error_log})
					if [ "$(echo $?)" != "0" ]
					then
						if [ "$ssh_result" != "" ]
						then
							throwException "$ssh_result" "105065"
						else
							catchException "${error_log}"
							throwException "$error_result" "105065"
						fi
					fi
				fi
			fi
		done
		
		echo "1|77|SUCCESS"
	fi
	
	result=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmdev -dev ${vadapter_vios}\"" 2> ${error_log})
	if [ "$(echo $?)" != "0" ]
	then
			if [ "$result" != "" ]
			then
				throwException "$result" "105065"
			else
				catchException "${error_log}"
				throwException "$error_result" "105065"
			fi
	fi
	echo "1|80|SUCCESS"
fi

#####################################################################################
#####                                                                           #####
#####                  Dynamic remove vios' virtualio                           #####
#####                                                                           #####
#####################################################################################
echo "$(date) : Dynamic remove vios' virtualio" >> ${out_log}
result=$(ssh ${hmc_user}@${hmc_ip} "chhwres -r virtualio -m ${host_id} -o r --id ${vios_id} --rsubtype scsi -s ${vscsi_id}" 2> ${error_log})
if [ "$(echo $?)" != "0" ]
then
		if [ "$vm_lvs" != "" ]
		then
			throwException "$vm_lvs" "105065"
		else
			catchException "${error_log}"
			throwException "$error_result" "105065"
		fi
fi
echo "1|85|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                   remove lpar's virtual terminal                          #####
#####                                                                           #####
#####################################################################################
echo "$(date) : Remove lpar's virtual terminal" >> ${out_log}
result=$(ssh ${hmc_user}@${hmc_ip} "rmvterm -m ${host_id} --id ${lpar_id}" 2> $error_log)
if [ "$(echo $?)" != "0" ]
then
		if [ "$result" != "" ]
		then
			throwException "$result" "105065"
		else
			catchException "${error_log}"
			throwException "$error_result" "105065"
		fi
fi
echo "1|87|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                          remove lpar's prof                               #####
#####                                                                           #####
#####################################################################################
echo "$(date) : Remove lpar's prof" >> ${out_log}
result=$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -m ${host_id} -r lpar --id ${lpar_id}" 2> ${error_log})
if [ "$(echo $?)" != "0" ]
then
		if [ "$result" != "" ]
		then
			throwException "$result" "105065"
		else
			catchException "${error_log}"
			throwException "$error_result" "105065"
		fi
fi
echo "1|90|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                             delete vm's lv                                #####
#####                                                                           #####
#####################################################################################
for lv in $(echo "${vm_lvs}" | awk -F":" '{for(i=1;i<=NF;i++) print $i}')
do
	if [ "$lv" != "" ]
	then
		if [ "$(echo $lv | grep '/var/vio/VMLibrary')" != "" ]
		then
			continue
		else
			ssh_result=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id ${vios_id} -c \"lslv $lv\"" 2> ${error_log})
			if [ "$(echo $?)" == "0" ]
			then
				if [ "$(echo "$ssh_result" | grep "Unable to find")" != "" ]
				then
					continue
				fi
				ssh_result=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id ${vios_id} -c \"rmlv -f ${lv}\"" 2> ${error_log})
				if [ "$(echo $?)" != "0" ]
				then
					if [ "$ssh_result" != "" ]
					then
						throwException "$ssh_result" "105056"
					else
						catchException "${error_log}"
						throwException "$error_result" "105056"
					fi
				fi
			fi
		fi
	fi
done

if [ "$log_flag" == "0" ]
then
	rm -f "${error_log}" 2> /dev/null
	rm -f "$out_log" 2> /dev/null
fi

echo "1|100|SUCCESS"

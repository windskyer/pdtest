#!/usr/bin/ksh

test_fun() {
	return 10
}

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
			echo "0|0|ERROR-${error_code}:"$(echo "$result" | awk -F']' '{print $2}')
		else
			echo "0|0|ERROR-${error_code}: ${result}"
		fi
		
		# if [ "$log_flag" == "0" ]
		# then
			# rm -f "$error_log" 2> /dev/null
			# rm -f "$out_log" 2> /dev/null
		# fi
		if [ "$cdrom_path" != "" ]&&[ "$config_iso" != "" ]
		then
			ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"oem_setup_env && rm -f ${cdrom_path}/${config_iso}\"" > /dev/null 2>&1
		fi
		rm -f ${cdrom_path}/${config_iso} 2> /dev/null
		rm -f ${ovf_xml} 2> /dev/null
		rm -f ${template_path}/${config_iso} 2> /dev/null
		exit 1
	fi

}

echoError() {
            
	result=$1
	errorCode=$2
	
	log_flag=$(cat scrpits.properties 2> /dev/null | grep "LOG=" | awk -F"=" '{print $2}')
	if [ "$log_flag" == "" ]
	then
		log_flag=0
	fi
	           
	if [ "${result}" != "" ]
	then
		echo "ERROR-"${errorCode}":$result" >&2
				
		if [ "$log_flag" == "0" ]
		then
			rm -f "$error_log" 2> /dev/null
			rm -f "$out_log" 2> /dev/null
		fi

		exit 1
	fi

}

waitRunning() {
	# echo "waitRunning"
	while [ "${lpar_state}" != "Running" ]
	do
		sleep 10
		lpar_state=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m $host_id -r lpar --filter lpar_ids=${lpar_id} -F state" 2>&1)
		if [ "$(echo $?)" != "0" ]
		then
			throwException "$lpar_state" "105435"
		fi
	done
}

waitShutDown() {
	# echo "waitShutDown"
	while [ "${lpar_state}" != "Not Activated" ]
	do
		sleep 10
		lpar_state=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m $host_id -r lpar --filter lpar_ids=${lpar_id} -F state" 2>&1)
		if [ "$(echo $?)" != "0" ]
		then
			throwException "$lpar_state" "105435"
		fi
	done
}

waitOpenFirmware() {
#	echo "waitOpenFirmware"
#	echo "lpar_state==$lpar_state"
	while [ "${lpar_state}" != "Open Firmware" ]
	do
		sleep 10
		lpar_state=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m $host_id -r lpar --filter lpar_ids=${lpar_id} -F state" 2>&1)
		if [ "$(echo $?)" != "0" ]
		then
			throwException "$lpar_state" "105435"
		fi
	done
}

shutDown() {
	# echo "shutDown"
	ssh_result=$(ssh ${hmc_user}@${hmc_ip} "chsysstate -m $host_id -r lpar -o shutdown --id ${lpar_id} --immed" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		throwException "$ssh_result" "105476"
	fi
	sleep 6
}

shutDownOS() {
#	echo "shutDown"
	ssh_result=$(ssh ${hmc_user}@${hmc_ip} "chsysstate -m $host_id -r lpar -o osshutdown --id ${lpar_id} --immed" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		throwException "$ssh_result" "105477"
	fi
	sleep 3
	waitShutDown
}

startupNorm() {
	# echo "startupNorm"
	ssh_result=$(ssh ${hmc_user}@${hmc_ip} "chsysstate -m $host_id -r lpar -o on -b norm --id ${lpar_id} -f $lpar_name" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		throwException "$ssh_result" "105478"
	fi
}

startupSms() {
#	echo "startupSms"
#	echo "lpar_state==$lpar_state"
	ssh_result=$(ssh ${hmc_user}@${hmc_ip} "chsysstate -m $host_id -r lpar -o on -b sms --id ${lpar_id} -f $lpar_name" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		throwException "$ssh_result" "105479"
	fi
	sleep 5
	waitOpenFirmware
}

get_hmc_vios() {
	
	getHmcViosErrorMsg=""
	lpars=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m $host_id -r lpar -F name:lpar_id:lpar_env:state" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		getHmcViosErrorMsg="$lpars"
		return 1
	fi
	vioses_ids=$(echo "$lpars" | awk -F":" '{if($3=="vioserver" && $4=="Running") print $2}')

	if [ $(echo $vioses_ids | awk '{print NF}') -ge 2 ]
	then
		multi_vios_flag=1
	fi

	vios_len=0
	for vios_id in $vioses_ids
	do
		active=0
		vioses=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -r lpar -m $host_id --filter lpar_ids=$vios_id -F name:lpar_id:lpar_env:state:rmc_ipaddr" 2>&1)
		if [ "$(echo $?)" != "0" ]
		then
			getHmcViosErrorMsg="$vioses"
			return 1
		fi
		if [ "$multi_vios_flag" == "1" ]
		then
			sea_info=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id $vios_id -c \"lsdev -type sea -field name -fmt :\"" 2>&1)
			if [ "$(echo $?)" != "0" ]
			then
				getHmcViosErrorMsg="$sea_info"
				return 1
			fi
			for sea in $sea_info
			do
				flag=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id $vios_id -c \"entstat -all $sea\"" 2>&1)
				if [ "$(echo $?)" != "0" ]
				then
					getHmcViosErrorMsg="$flag"
					return 1
				fi
				flag=$(echo "$flag" | grep Active | awk '{print $4}')
				if [ "$flag" == "True" ]
				then
					active=1
				fi
				# fi
			done
		else
			active=1
		fi
		viosId[$vios_len]=$vios_id
		viosName[$vios_len]=$(echo $vioses | awk -F":" '{print $1}')
		viosState[$vios_len]=$(echo $vioses | awk -F":" '{print $4}')
		viosActive[$vios_len]=$active
		viosIp[$vios_len]=$(echo $vioses | awk -F":" '{print $5}')
		vios_len=$(expr $vios_len + 1)
	done
}

ddcopyCheck() {
	#####################################################################################
	#####                                                                           #####
	#####                               check cp                                    #####
	#####                                                                           #####
	#####################################################################################
	progress=$1
	
	sleep 1

	pid=$(ssh ${hmc_user}@${hmc_ip} 'for proc in $(ls -d /proc/[0-9]* | sed '"'"'s/\/proc\///g'"'"'); do cmdline=$(cat /proc/$proc/cmdline); if [ "$(echo $cmdline | grep "viosvrcmd-m'${host_id}'--id'${vios_id}'-coem_setup_env && cp '${template_path}'/'${template_name}' '${cdrom_path}'" | grep -v grep)" != "" ]; then echo $proc; fi done' 2> /dev/null)
	
	if [ "$pid" != "" ]
	then
		ssh ${hmc_user}@${hmc_ip} "kill $pid"
	else
		echoError "The process of dd copy not found." "105424"
	fi
	
	while [ 1 ]
	do
		sleep 20
		ps_rlt=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"oem_setup_env && ps -ef\"" 2>&1)
		if [ "$(echo $?)" != "0" ]
		then
			echoError "$ps_rlt" "105424"
		fi
		ps_rlt=$(echo "$ps_rlt" | grep -v grep | grep "cp ${template_path}/${template_name} ${cdrom_path}")
		echo "ps_rlt==$ps_rlt" >> $out_log
		if [ "$ps_rlt" == "" ]
		then
			break
		fi
		progress=$(expr $progress + 1)
		echo "1|${progress}|SUCCESS"
	done
	
	# sleep 10
	# ps_rlt=$(ps -ef | grep "cp ${template_path}/${template_name} ${cdrom_path}" | grep -v grep)
	# while [ "${ps_rlt}" != "" ]
	# do
		# sleep 10
		# ps_rlt=$(ps -ef | grep "cp ${template_path}/${template_name} ${cdrom_path}" | grep -v grep)
		# if [ "$ps_rlt" == "" ]
		# then
			# catchException "$error_log"
			# if [ "$(echo "$error_result" | grep "time limit")" != "" ]
			# then
				# ps_rlt=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id $vios_id -c \"oem_setup_env && ps -ef\"")
				# ps_rlt=$(echo "$ps_rlt" | grep "cp ${template_path}/${template_name} ${cdrom_path}" | grep -v grep)
			# elif [ "$(echo "$error_result" | sed 's/ //g' | sed 's/://g')" != "" ]
			# then
					# echoError "$error_result" "105424"
			# fi
		# fi

		# progress=$(expr $progress + 1)
		# echo "1|${progress}|SUCCESS"
	# done
}


crt_iso_copyCheck() {
	#####################################################################################
	#####                                                                           #####
	#####                               check cp                                    #####
	#####                                                                           #####
	#####################################################################################
	progress=$1
	
	sleep 1

	pid=$(ssh ${hmc_user}@${hmc_ip} 'for proc in $(ls -d /proc/[0-9]* | sed '"'"'s/\/proc\///g'"'"'); do cmdline=$(cat /proc/$proc/cmdline); if [ "$(echo $cmdline | grep "viosvrcmd-m'${host_id}'--id'${vios_id}'-coem_setup_env && cp '${template_path}'/'${template_name}' '${cdrom_path}'" | grep -v grep)" != "" ]; then echo $proc; fi done' 2> /dev/null)
	
	if [ "$pid" != "" ]
	then
		ssh ${hmc_user}@${hmc_ip} "kill $pid"
	else
		while [ $j -lt $length ]
		do
			if [ "${lv_vg[$j]}" != "" ]
			then
				echo "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmvdev -vdev ${lv_name[$j]}\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmvdev -vdev ${lv_name[$j]}\"") >> "$out_log" 2>&1
				echo "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmlv -f ${lv_name[$j]}\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmlv -f ${lv_name[$j]}\"") >> "$out_log" 2>&1
			else
				echo "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmvdev -vdev ${pv_name[$j]}\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmvdev -vdev ${pv_name[$j]}\"") >> "$out_log" 2>&1
			fi
			j=$(expr $j + 1)
		done
		echo "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\"") >> "$out_log" 2>&1
		echo "chsyscfg -m ${host_id} -r prof -i \"virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id}\" :"$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -m ${host_id} -r prof -i \"virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id}\"") >> "$out_log" 2>&1
		echo "chhwres -r virtualio -m ${host_id} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot} :"$(ssh ${hmc_user}@${hmc_ip} "chhwres -r virtualio -m ${host_id} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot}") >> "$out_log" 2>&1
		echo "rmsyscfg -r lpar -m ${host_id} -n \"${lpar_name}\" :"$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_id} -n \"${lpar_name}\"") >> "$out_log" 2>&1	
		throwException "The process of dd copy not found." "105424"
	fi
	
	while [ 1 ]
	do
		sleep 20
		ps_rlt=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"oem_setup_env && ps -ef\"" 2>&1)
		if [ "$(echo $?)" != "0" ]
		then
			while [ $j -lt $length ]
			do
				if [ "${lv_vg[$j]}" != "" ]
				then
					echo "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmvdev -vdev ${lv_name[$j]}\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmvdev -vdev ${lv_name[$j]}\"") >> "$out_log" 2>&1
					echo "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmlv -f ${lv_name[$j]}\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmlv -f ${lv_name[$j]}\"") >> "$out_log" 2>&1
				else
					echo "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmvdev -vdev ${pv_name[$j]}\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmvdev -vdev ${pv_name[$j]}\"") >> "$out_log" 2>&1
				fi
				j=$(expr $j + 1)
			done
			echo "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\"") >> "$out_log" 2>&1
			echo "chsyscfg -m ${host_id} -r prof -i \"virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id}\" :"$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -m ${host_id} -r prof -i \"virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id}\"") >> "$out_log" 2>&1
			echo "chhwres -r virtualio -m ${host_id} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot} :"$(ssh ${hmc_user}@${hmc_ip} "chhwres -r virtualio -m ${host_id} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot}") >> "$out_log" 2>&1
			echo "rmsyscfg -r lpar -m ${host_id} -n \"${lpar_name}\" :"$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_id} -n \"${lpar_name}\"") >> "$out_log" 2>&1	
			throwException "$ps_rlt" "105424"
		fi
		ps_rlt=$(echo "$ps_rlt" | grep -v grep | grep "cp ${template_path}/${template_name} ${cdrom_path}")
		echo "ps_rlt==$ps_rlt" >> $out_log
		if [ "$ps_rlt" == "" ]
		then
			break
		fi
		progress=$(expr $progress + 1)
		echo "1|${progress}|SUCCESS"
	done
	
	# sleep 10
	# ps_rlt=$(ps -ef | grep "cp ${template_path}/${template_name}" | grep -v grep)
	# while [ "${ps_rlt}" != "" ]
	# do
		# echo "=========================================================start==============================================================="
		# sleep 10
		# ps_rlt=$(ps -ef | grep "cp ${template_path}/${template_name}" | grep -v grep)
		
		# if [ "$ps_rlt" == "" ]
		# then
			# catchException "$error_log"
			# if [ "$(echo "$error_result" | grep "time limit")" != "" ]
			# then
				# ps_rlt=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id $vios_id -c \"oem_setup_env && ps -ef\"")
				# ps_rlt=$(echo "$ps_rlt" | grep "cp ${template_path}/${template_name} ${cdrom_path}" | grep -v grep)
			# elif [ "$(echo "$error_result" | sed 's/ //g' | sed 's/://g')" != "" ]
			# then
				# while [ $j -lt $length ]
				# do
					# if [ "${lv_vg[$j]}" != "" ]
					# then
						# echo "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmvdev -vdev ${lv_name[$j]}\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmvdev -vdev ${lv_name[$j]}\"") >> "$out_log" 2>&1
						# echo "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmlv -f ${lv_name[$j]}\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmlv -f ${lv_name[$j]}\"") >> "$out_log" 2>&1
					# else
						# echo "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmvdev -vdev ${pv_name[$j]}\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmvdev -vdev ${pv_name[$j]}\"") >> "$out_log" 2>&1
					# fi
					# j=$(expr $j + 1)
				# done
				# echo "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\"") >> "$out_log" 2>&1
				# echo "chsyscfg -m ${host_id} -r prof -i \"virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id}\" :"$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -m ${host_id} -r prof -i \"virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id}\"") >> "$out_log" 2>&1
				# echo "chhwres -r virtualio -m ${host_id} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot} :"$(ssh ${hmc_user}@${hmc_ip} "chhwres -r virtualio -m ${host_id} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot}") >> "$out_log" 2>&1
				# echo "rmsyscfg -r lpar -m ${host_id} -n \"${lpar_name}\" :"$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_id} -n \"${lpar_name}\"") >> "$out_log" 2>&1
				# throwException "$error_result" "105424"
			# fi
		# fi

		# progress=$(expr $progress + 1)
		# echo "1|${progress}|SUCCESS"

		# echo "===========================================================end================================================================="
	# done
}


rollback_dvios() {
	case $1 in
		1)
			echo "rmsyscfg -r lpar -m ${host_id} -n \"${lpar_name}\" :"$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_id} -n \"${lpar_name}\"") >> $out_log 2>&1;;
		2)
			echo "chhwres -r virtualio -m ${host_id} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot} :"$(ssh ${hmc_user}@${hmc_ip} "chhwres -r virtualio -m ${host_id} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot}") >> $out_log 2>&1;
			echo "chsyscfg -m ${host_id} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id} :"$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -m ${host_id} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id}") >> $out_log 2>&1;
			echo "rmsyscfg -r lpar -m ${host_id} -n \"${lpar_name}\" :"$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_id} -n \"${lpar_name}\"") >> $out_log 2>&1;;
		3)
			echo "chhwres -r virtualio -m ${host_id} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot} :"$(ssh ${hmc_user}@${hmc_ip} "chhwres -r virtualio -m ${host_id} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot}") >> $out_log 2>&1;
			echo "chhwres -r virtualio -m ${host_id} -o r --id ${dvios_vios_id} --rsubtype scsi -s ${dvios_max_slot} :"$(ssh ${hmc_user}@${hmc_ip} "chhwres -r virtualio -m ${host_id} -o r --id ${dvios_vios_id} --rsubtype scsi -s ${dvios_max_slot}") >> $out_log 2>&1;
			echo "chsyscfg -m ${host_id} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id} :"$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -m ${host_id} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id}") >> $out_log 2>&1;
			echo "rmsyscfg -r lpar -m ${host_id} -n \"${lpar_name}\" :"$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_id} -n \"${lpar_name}\"") >> $out_log 2>&1;;
		4)
			echo "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\"") >> $out_log 2>&1;
			echo "viosvrcmd -m ${host_id} --id ${dvios_vios_id} -c \"rmdev -dev $dvios_vadapter_vios\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${dvios_vios_id} -c \"rmdev -dev $dvios_vadapter_vios\"") >> $out_log 2>&1;
			echo "chhwres -r virtualio -m ${host_id} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot} :"$(ssh ${hmc_user}@${hmc_ip} "chhwres -r virtualio -m ${host_id} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot}") >> $out_log 2>&1;
			echo "chhwres -r virtualio -m ${host_id} -o r --id ${dvios_vios_id} --rsubtype scsi -s ${dvios_max_slot} :"$(ssh ${hmc_user}@${hmc_ip} "chhwres -r virtualio -m ${host_id} -o r --id ${dvios_vios_id} --rsubtype scsi -s ${dvios_max_slot}") >> $out_log 2>&1;
			echo "chsyscfg -m ${host_id} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id} :"$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -m ${host_id} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id}") >> $out_log 2>&1;
			echo "chsyscfg -m ${host_id} -r prof -i virtual_scsi_adapters-=${dvios_max_slot}/server/${lpar_id}//3/0,name=${dvios_vios_name},lpar_id=${dvios_vios_id} :"$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -m ${host_id} -r prof -i virtual_scsi_adapters-=${dvios_max_slot}/server/${lpar_id}//3/0,name=${dvios_vios_name},lpar_id=${dvios_vios_id}") >> $out_log 2>&1;
			echo "rmsyscfg -r lpar -m ${host_id} -n \"${lpar_name}\" :"$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_id} -n \"${lpar_name}\"") >> $out_log 2>&1;;
		5)
			j=0;
			while [ $j -lt $length ]
			do
				echo "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmvdev -vdev ${pv_name[$j]}\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmvdev -vdev ${pv_name[$j]}\"") >> $out_log 2>&1;
				echo "viosvrcmd -m ${host_id} --id ${dvios_vios_id} -c \"rmvdev -vdev ${dvios_pv_name[$j]}\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${dvios_vios_id} -c \"rmvdev -vdev ${dvios_pv_name[$j]}\"") >> $out_log 2>&1;
				j=$(expr $j + 1);
			done
			echo "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\"") >> $out_log 2>&1;
			echo "viosvrcmd -m ${host_id} --id ${dvios_vios_id} -c \"rmdev -dev $dvios_vadapter_vios\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${dvios_vios_id} -c \"rmdev -dev $dvios_vadapter_vios\"") >> $out_log 2>&1;
			echo "chhwres -r virtualio -m ${host_id} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot} :"$(ssh ${hmc_user}@${hmc_ip} "chhwres -r virtualio -m ${host_id} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot}") >> $out_log 2>&1;
			echo "chhwres -r virtualio -m ${host_id} -o r --id ${dvios_vios_id} --rsubtype scsi -s ${dvios_max_slot} :"$(ssh ${hmc_user}@${hmc_ip} "chhwres -r virtualio -m ${host_id} -o r --id ${dvios_vios_id} --rsubtype scsi -s ${dvios_max_slot}") >> $out_log 2>&1;
			echo "chsyscfg -m ${host_id} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id} :"$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -m ${host_id} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id}") >> $out_log 2>&1;
			echo "chsyscfg -m ${host_id} -r prof -i virtual_scsi_adapters-=${dvios_max_slot}/server/${lpar_id}//3/0,name=${dvios_vios_name},lpar_id=${dvios_vios_id} :"$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -m ${host_id} -r prof -i virtual_scsi_adapters-=${dvios_max_slot}/server/${lpar_id}//3/0,name=${dvios_vios_name},lpar_id=${dvios_vios_id}") >> $out_log 2>&1;
			echo "rmsyscfg -r lpar -m ${host_id} -n \"${lpar_name}\" :"$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_id} -n \"${lpar_name}\"") >> $out_log 2>&1;;
		6)
			echo "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmvdev -vtd ${vadapter_vcd}\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmvdev -vtd ${vadapter_vcd}\"") >> $out_log 2>&1;
			j=0;
			while [ $j -lt $length ]
			do
				echo "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmvdev -vdev ${pv_name[$j]}\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmvdev -vdev ${pv_name[$j]}\"") >> $out_log 2>&1;
				echo "viosvrcmd -m ${host_id} --id ${dvios_vios_id} -c \"rmvdev -vdev ${dvios_pv_name[$j]}\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${dvios_vios_id} -c \"rmvdev -vdev ${dvios_pv_name[$j]}\"") >> $out_log 2>&1;
				j=$(expr $j + 1);
			done
			echo "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\"") >> $out_log 2>&1;
			echo "viosvrcmd -m ${host_id} --id ${dvios_vios_id} -c \"rmdev -dev $dvios_vadapter_vios\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${dvios_vios_id} -c \"rmdev -dev $dvios_vadapter_vios\"") >> $out_log 2>&1;
			echo "chhwres -r virtualio -m ${host_id} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot} :"$(ssh ${hmc_user}@${hmc_ip} "chhwres -r virtualio -m ${host_id} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot}") >> $out_log 2>&1;
			echo "chhwres -r virtualio -m ${host_id} -o r --id ${dvios_vios_id} --rsubtype scsi -s ${dvios_max_slot} :"$(ssh ${hmc_user}@${hmc_ip} "chhwres -r virtualio -m ${host_id} -o r --id ${dvios_vios_id} --rsubtype scsi -s ${dvios_max_slot}") >> $out_log 2>&1;
			echo "chsyscfg -m ${host_id} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id} :"$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -m ${host_id} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id}") >> $out_log 2>&1;
			echo "chsyscfg -m ${host_id} -r prof -i virtual_scsi_adapters-=${dvios_max_slot}/server/${lpar_id}//3/0,name=${dvios_vios_name},lpar_id=${dvios_vios_id} :"$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -m ${host_id} -r prof -i virtual_scsi_adapters-=${dvios_max_slot}/server/${lpar_id}//3/0,name=${dvios_vios_name},lpar_id=${dvios_vios_id}") >> $out_log 2>&1;
			echo "rmsyscfg -r lpar -m ${host_id} -n \"${lpar_name}\" :"$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_id} -n \"${lpar_name}\"") >> $out_log 2>&1;;
	esac
}

wait_viosvrcmd() {
	hmc_ip=$1
	hmc_user=$2
	host_id=$3
	vios_id=$4
	timeout_flag=0
	
	timeout=$(cat scrpits.properties 2> /dev/null | grep "VIOSVRCMD_TIMEOUT=" | awk -F"=" '{print $2}')
	
	if [ "$timeout" == "" ]
	then
		timeout=1800
	fi
	
	while [ 1 ]
	do
		ps=$(ps -ef | grep "ssh ${hmc_user}@${hmc_ip}" | grep "viosvrcmd -m $host_id --id $vios_id")
		if [ "$ps" == "" ]
		then
			break
		fi
		sleep 1
		time=$(expr $time + 1)
		if [ $time -gt $timeout ]
		then
			timeout_flag=1
			break
		fi
	done
}


# case $1 in
	# "catchException")
		# catchException $2;;
	# "throwException")
		# echo "111111111";
		# throwException "$2" "$3";;
	# "echoError")
		# echoError "$2";;
	# "get_hmc_vios")
		# get_hmc_vios;;
# esac
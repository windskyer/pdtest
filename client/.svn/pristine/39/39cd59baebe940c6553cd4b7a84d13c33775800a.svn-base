#!/usr/bin/ksh

aix_getinfo() {
	i=0
	echo  "[\c"
	while [ $i -lt $length ]
	do
		echo  "{\c"
		echo  "\"lpar_id\":\"${vm_id[$i]}\", \c"
		echo  "\"lpar_name\":\"${vm_name[$i]}\", \c"
		echo  "\"lpar_env\":\"${vm_env[$i]}\", \c"
		echo  "\"lpar_state\":\"${vm_state[$i]}\", \c"
		echo  "\"lpar_ostype\":\"${vm_os_type[$i]}\", \c"
		echo  "\"lpar_osversion\":\"${vm_osversion[$i]}\", \c"
		echo  "\"lpar_profile\":\"${vm_profile[$i]}\", \c"
		echo  "\"lpar_bootmode\":\"${vm_bootmode[$i]}\", \c"
		echo  "\"lpar_autostart\":\"${vm_autostart[$i]}\", \c"
		echo  "\"lpar_hamode\":\"${vm_ha_mode[$i]}\", \c"
		#echo  "\"lpar_uptime\":\"${vm_uptime[$i]}\", \c"
		echo  "\"lpar_rmcstate\":\"${vm_rmcstate[$i]}\", \c"
		echo  "\"lpar_proc_mode\":\"${vm_proc_mode[$i]}\", \c"
		echo  "\"lpar_mem\":{\c"
		echo  "\"min_mem\":\"${vm_min_mem[$i]}\", \c"
		echo  "\"desired_mem\":\"${vm_desired_mem[$i]}\", \c"
		echo  "\"max_mem\":\"${vm_max_mem[$i]}\"\c"
		echo  "}, \c"
		echo  "\"lpar_proc\":{\c"
		echo  "\"proc_mode\":\"${vm_proc_mode[$i]}\", \c"
		echo  "\"min_proc_units\":\"${vm_min_proc_units[$i]}\", \c"
		echo  "\"desired_proc_units\":\"${vm_desired_proc_units[$i]}\", \c"
		echo  "\"max_proc_units\":\"${vm_max_proc_units[$i]}\", \c"
		echo  "\"min_procs\":\"${vm_min_procs[$i]}\", \c" 
		echo  "\"desired_procs\":\"${vm_desired_procs[$i]}\", \c"
		echo  "\"max_procs\":\"${vm_max_procs[$i]}\", \c"
		echo  "\"sharing_mode\":\"${vm_sharing_mode[$i]}\", \c"
		echo  "\"uncap_weight\":\"${vm_uncap_weight[$i]}\"\c"
		echo  "}, \c"
		echo  "\"network\":[\c"
		j=0
		for eth in ${vm_eth[$i]}
		do
			if [ "$eth" != "" ]
			then
				eth_slot=$(echo "$eth" | awk -F"/" '{print $1}')
				if [ "$eth_slot" != "none" ]
				then
					eth_id=$(expr $j + 1)
					# mac_address=$(ssh ${hmc_user}@${hmc_ip} "lshwres -r virtualio --rsubtype eth -m ${host_id} --level lpar --filter lpar_ids=${lpar_id},slots=15 -F mac_addr" 2>&1)
					echo  "{\c"
					echo  "\"eth_id\":\"${eth_id}\", \c"
					echo  "\"eth_slot\":\"${eth_slot}\", \c"
					echo  "\"eth_name\":\"eth$j\", \c"
					vm_pvid=$(echo "$eth" | awk -F"/" '{print $3}')
					echo  "\"eth_pvid\":\"$vm_pvid\", \c"
					num=0
					while [ $num -lt $sea_length ]
					do
						if [ "$vm_pvid" == "${vlan_ids[$num]}" ]
						then
							vm_physloc=$(echo "${sea_physloc[$num]}" | sed 's/ //g')
							break
						fi
						num=$(expr $num + 1)
					done
					echo  "\"eth_physloc\":\"$vm_physloc\"\c"
					echo  "}\c"
					j=$(expr $j + 1)
					if [ "$j" != "${vm_eth_num[$i]}" ]
					then
						echo  ", \c"
					fi
				fi
			fi
		done
		echo  "], \c"
		
		# echo "vm_vscsi_num[$i]==${vm_vscsi_num[$i]}"
		
		if [ "${vm_vscsi_num[$i]}" != "0" ]
		then
			lv_len=0
			pv_len=0
			# echo "vm_vscsi_info[$i]==${vm_vscsi_info[$i]}"
			for lv_vscsi_info in ${vm_vscsi_info[$i]}
			do
				vios_scsi_slot=$(echo "${lv_vscsi_info}" | awk -F"/" '{print $5}')
				vm_scsi_slot=$(echo "${lv_vscsi_info}" | awk -F"/" '{print $1}')
				vm_vios_id=$(echo "${lv_vscsi_info}" | awk -F"/" '{print $3}')
				
				# echo "vios_scsi_slot==$vios_scsi_slot"
				# echo "vm_scsi_slot==$vm_scsi_slot"
				# echo "vm_vios_id==$vm_vios_id"
				# echo "vm_name[$i]==${vm_name[$i]}"
				
				# echo "vios_test=="$vios_scsi_slot"/server/"${vm_id[$i]}"/"${vm_name[$i]}"/"$vm_scsi_slot"/0"
				vm_vios_vscsi=$(echo "${vios_prof_vscsi[$vm_vios_id]}" | awk -F"," '{for(i=1;i<=NF;i++) print $i}')
				# echo "vm_vios_vscsi==$vm_vios_vscsi"
 
				vios_scsi_slots=$(echo "$vm_vios_vscsi" | awk -F"/" '{if(($1==vios_scsi_slot && $3==vm_id && $4==vm_name && $5==vm_scsi_slot) || ($1==vios_scsi_slot && $3=="any")) print $1}' vm_id="${vm_id[$i]}" vm_name="${vm_name[$i]}" vios_scsi_slot="$vios_scsi_slot" vm_scsi_slot="$vm_scsi_slot")
				
				# echo "vios_scsi_slots==$vios_scsi_slots"
				# echo "lv_map_info[$vm_vios_id]==${lv_map_info[$vm_vios_id]}"
				# echo "disk_map_info[$vm_vios_id]==${disk_map_info[$vm_vios_id]}"
				if [ "$vios_scsi_slots" == "" ]
				then
					continue
				fi
				
				for vios_scsi_slot in $vios_scsi_slots
				do
					if [ "${lv_map_info[$vm_vios_id]}" != "" ]
					then
						# vm_lv_num[$lv_len]=$(echo "${lv_map_info[$vm_vios_id]}" | grep "C${vios_scsi_slot}" | awk -F":" '{print NF-1}')
						vm_lv[$lv_len]=$(echo "${lv_map_info[$vm_vios_id]}" | grep "C${vios_scsi_slot}:" | awk -F":" '{for(i=2;i<=NF;i++) print $i}')
						vm_lv_num[$lv_len]=$(echo "${lv_map_info[$vm_vios_id]}" | grep "C${vios_scsi_slot}:" | awk -F":" '{print NF-1}')
						lv_vios_id[$lv_len]=$vm_vios_id
						if [ "${vm_lv[$lv_len]}" != "" ]
						then
							lv_len=$(expr $lv_len + 1)
						fi
					fi
					
					if [ "${disk_map_info[$vm_vios_id]}" != "" ]
					then
						# echo "disk_map_info[$vm_vios_id]==${disk_map_info[$vm_vios_id]}"
						# vm_disk_num[$pv_len]=$(echo "${disk_map_info[$vm_vios_id]}" | grep "C${vios_scsi_slot}" | awk -F":" '{print NF-1}')
						vm_disk[$pv_len]=$(echo "${disk_map_info[$vm_vios_id]}" | grep "C${vios_scsi_slot}:" | awk -F":" '{for(i=2;i<=NF;i++) print $i}')
						# echo "vm_disk[$pv_len]==${vm_disk[$pv_len]}"
						vm_disk_num[$pv_len]=$(echo "${disk_map_info[$vm_vios_id]}" | grep "C${vios_scsi_slot}:" | awk -F":" '{print NF-1}')
						# echo "vm_disk_num[$pv_len]==${vm_disk_num[$pv_len]}"
						pv_vios_id[$pv_len]=$vm_vios_id
						if [ "${vm_disk[$pv_len]}" != "" ]
						then
							pv_len=$(expr $pv_len + 1)
						fi
					fi
				done
			done
		fi
		
		# echo "lv_len==$lv_len"
		# echo "pv_len==$pv_len"
		
		echo  "\"lv\":[\c"
		if [ "$lv_len" != "0" ]
		then
			j=0
			while [ $j -lt $lv_len ]
			do
				num=0
				for lv in ${vm_lv[$j]}
				do
					if [ "$lv" != "" ]
					then
						vm_lv_info=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id ${lv_vios_id[$j]} -c \"lslv $lv -field lvid vgname ppsize pps lvstate -fmt :\"")
						if [ "$vm_lv_info" == "" ]
						then
									continue
						fi
						ppsize=$(echo "${vm_lv_info}" | awk -F":" '{print $3}' | awk '{print $1}')
						echo  "{\c"
						echo  "\"vios_id\":\"${lv_vios_id[$j]}\", \c"
						echo  "\"lv_id\":\"$(echo "${vm_lv_info}" | awk -F":" '{print $1}')\", \c"
						echo  "\"lv_name\":\"$lv\", \c"
						echo  "\"lv_vg\":\"$(echo "${vm_lv_info}" | awk -F":" '{print $2}')\", \c"
						lv_state=$(echo "${vm_lv_info}" | awk -F":" '{print $5}')
						case $lv_state in
								"opened/syncd")
												lv_state=1;;
								"closed/syncd")
												lv_state=2;;
								*)
												lv_state=3;;
						esac
						echo  "\"lv_state\":\"${lv_state}\", \c"
						echo  "\"lv_size\":\"$(echo "${vm_lv_info}" | awk -F":" '{print ppsize*$4}' ppsize="$ppsize")\"\c"
						echo  "}\c"
					fi
					num=$(expr $num + 1)
					if [ "$num" != "${vm_lv_num[$j]}" ]
					then
						echo  ", \c"
					fi
				done
				j=$(expr $j + 1)
				if [ "$j" != "$lv_len" ]
				then
					echo  ", \c"
				fi
			done
		fi
		echo  "], \c"
		
		echo  "\"pv\":[\c"
		if [ "$pv_len" != "0" ]
		then
			j=0
			while [ $j -lt $pv_len ]
			do
				num=0
				print_flag=0
				for disk in ${vm_disk[$j]}
				do
					if [ "$disk" != "" ]
					then
						pv_info=$(echo "${lspv_info[${pv_vios_id[$j]}]}" | grep -w $disk)
						if [ "$pv_info" != "" ]
						then
							pv_id=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id ${pv_vios_id[$j]} -c \"lsdev -dev $disk -attr pvid\"" | grep -v value | grep -v ^$)
							disk_id=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id ${pv_vios_id[$j]} -c \"lsdev -dev $disk -attr unique_id\"" | grep -v value | grep -v ^$)
							disk_size=$(echo "$pv_info" | awk -F":" '{print $2}')
							disk_state=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id ${pv_vios_id[$j]} -c \"lsdev -dev $disk -field status -fmt :\"")
							
							if [ "${pv_id}" == "none" ]
							then
								pv_id=""
							fi
							
							if [ "${disk_id}" == "none" ]
							then
								disk_id=""
							fi
							
							# echo "disk_id==$disk_id"
							# echo "disk_size==$disk_size"
							# echo "disk_state==$disk_state"
							
							if [ "$disk_id" == "" ]||[ "$disk_size" == "" ]||[ "$disk_state" == "" ]
							then
										continue
							fi
							
							# if [ "$disk_state" == "Defined" ]||[ "$disk_state" == "Available" ]
							# then
									# disk_state=1
							# else
									# disk_state=2
							# fi
							
							echo  "{\c"
							echo  "\"vios_id\":\"${pv_vios_id[$j]}\", \c"
							echo  "\"unique_id\":\"$disk_id\", \c"
							echo  "\"pv_id\":\"$pv_id\", \c"
							echo  "\"pv_name\":\"$disk\", \c"
							echo  "\"pv_size\":\"$disk_size\", \c"
							echo  "\"pv_status\":\"$disk_state\"\c"
							echo  "}\c"
					
							num=$(expr $num + 1)
							if [ "$num" != "${vm_disk_num[$j]}" ]
							then
								echo  ", \c"
							fi
						else
							print_flag=$(expr $print_flag + 1)
						fi
					else
						print_flag=$(expr $print_flag + 1)
					fi
				done
				j=$(expr $j + 1)
				if [ "$print_flag" != "${vm_disk_num[$j]}" ]
				then
					if [ "$j" != "$pv_len" ]
					then
						echo  ", \c"
					fi
				fi
			done
		fi
		
		echo  "]\c"
		
		i=$(expr $i + 1)
		if [ "$i" == "$length" ]
		then
			echo  "}]"
		else
			echo  "}, \c"
		fi
	done
}

linux_getinfo() {
	i=0
	echo -e "[\c"
	while [ $i -lt $length ]
	do
		echo -e "{\c"
		echo -e "\"lpar_id\":\"${vm_id[$i]}\", \c"
		echo -e "\"lpar_name\":\"${vm_name[$i]}\", \c"
		echo -e "\"lpar_env\":\"${vm_env[$i]}\", \c"
		echo -e "\"lpar_state\":\"${vm_state[$i]}\", \c"
		echo -e "\"lpar_ostype\":\"${vm_os_type[$i]}\", \c"
		echo -e "\"lpar_osversion\":\"${vm_osversion[$i]}\", \c"
		echo -e "\"lpar_profile\":\"${vm_profile[$i]}\", \c"
		echo -e "\"lpar_bootmode\":\"${vm_bootmode[$i]}\", \c"
		echo -e "\"lpar_autostart\":\"${vm_autostart[$i]}\", \c"
		echo -e "\"lpar_hamode\":\"${vm_ha_mode[$i]}\", \c"
		#echo -e "\"lpar_uptime\":\"${vm_uptime[$i]}\", \c"
		echo -e "\"lpar_rmcstate\":\"${vm_rmcstate[$i]}\", \c"
		echo -e "\"lpar_proc_mode\":\"${vm_proc_mode[$i]}\", \c"
		echo -e "\"lpar_mem\":{\c"
		echo -e "\"min_mem\":\"${vm_min_mem[$i]}\", \c"
		echo -e "\"desired_mem\":\"${vm_desired_mem[$i]}\", \c"
		echo -e "\"max_mem\":\"${vm_max_mem[$i]}\"\c"
		echo -e "}, \c"
		echo -e "\"lpar_proc\":{\c"
		echo -e "\"proc_mode\":\"${vm_proc_mode[$i]}\", \c"
		echo -e "\"min_proc_units\":\"${vm_min_proc_units[$i]}\", \c"
		echo -e "\"desired_proc_units\":\"${vm_desired_proc_units[$i]}\", \c"
		echo -e "\"max_proc_units\":\"${vm_max_proc_units[$i]}\", \c"
		echo -e "\"min_procs\":\"${vm_min_procs[$i]}\", \c" 
		echo -e "\"desired_procs\":\"${vm_desired_procs[$i]}\", \c"
		echo -e "\"max_procs\":\"${vm_max_procs[$i]}\", \c"
		echo -e "\"sharing_mode\":\"${vm_sharing_mode[$i]}\", \c"
		echo -e "\"uncap_weight\":\"${vm_uncap_weight[$i]}\"\c"
		echo -e "}, \c"
		echo -e "\"network\":[\c"
		j=0
		for eth in ${vm_eth[$i]}
		do
			if [ "$eth" != "" ]
			then
				eth_id=$(echo "$eth" | awk -F"/" '{print $1}')
				if [ "$eth_id" != "none" ]
				then
					echo -e "{\c"
					echo -e "\"eth_id\":\"${eth_id}\", \c"
					echo -e "\"eth_name\":\"eth$j\", \c"
					vm_pvid=$(echo "$eth" | awk -F"/" '{print $3}')
					echo -e "\"eth_pvid\":\"$vm_pvid\", \c"
					num=0
					while [ $num -lt $sea_length ]
					do
						if [ "$vm_pvid" == "${vlan_ids[$num]}" ]
						then
							vm_physloc=$(echo "${sea_physloc[$num]}" | sed 's/ //g')
							break
						fi
						num=$(expr $num + 1)
					done
					echo -e "\"eth_physloc\":\"$vm_physloc\"\c"
					echo -e "}\c"
					j=$(expr $j + 1)
					if [ "$j" != "${vm_eth_num[$i]}" ]
					then
						echo -e ", \c"
					fi
				fi
			fi
		done
		echo -e "], \c"
		
		if [ "${vm_vscsi_num[$i]}" != "0" ]
		then
			lv_len=0
			pv_len=0
			# echo "vm_vscsi_info[$i]==${vm_vscsi_info[$i]}"
			for lv_vscsi_info in ${vm_vscsi_info[$i]}
			do
				vios_scsi_slot=$(echo "${lv_vscsi_info}" | awk -F"/" '{print $5}')
				vm_scsi_slot=$(echo "${lv_vscsi_info}" | awk -F"/" '{print $1}')
				vm_vios_id=$(echo "${lv_vscsi_info}" | awk -F"/" '{print $3}')
				
				# echo "vios_scsi_slot==$vios_scsi_slot"
				# echo "vm_scsi_slot==$vm_scsi_slot"
				# echo "vm_vios_id==$vm_vios_id"
				
				vm_vios_vscsi=$(echo "${vios_prof_vscsi[$vm_vios_id]}" | awk -F"," '{for(i=1;i<=NF;i++) print $i}')
				# echo "vm_vios_vscsi==$vm_vios_vscsi"
				vios_scsi_slots=$(echo "$vm_vios_vscsi" | awk -F"/" '{if(($1==vios_scsi_slot && $3==vm_id && $4==vm_name && $5==vm_scsi_slot) || ($1==vios_scsi_slot && $3=="any")) print $1}' vm_id="${vm_id[$i]}" vm_name="${vm_name[$i]}" vios_scsi_slot="$vios_scsi_slot" vm_scsi_slot="$vm_scsi_slot")
				# echo "vm_profile[$i]==${vm_profile[$i]}"
				# echo "lv_vscsi_info==$lv_vscsi_info"
				# echo "vios_scsi_slots==$vios_scsi_slots"
				# echo "lv_map_info[$vm_vios_id]==${lv_map_info[$vm_vios_id]}"
				# echo "disk_map_info[$vm_vios_id]==${disk_map_info[$vm_vios_id]}"
				if [ "$vios_scsi_slots" == "" ]
				then
					continue
				fi
				
				for vios_scsi_slot in $vios_scsi_slots
				do
					if [ "${lv_map_info[$vm_vios_id]}" != "" ]
					then
						# vm_lv_num[$lv_len]=$(echo "${lv_map_info[$vm_vios_id]}" | grep "C${vios_scsi_slot}" | awk -F":" '{print NF-1}')
						vm_lv[$lv_len]=$(echo "${lv_map_info[$vm_vios_id]}" | grep "C${vios_scsi_slot}:" | awk -F":" '{for(i=2;i<=NF;i++) print $i}')
						vm_lv_num[$lv_len]=$(echo "${lv_map_info[$vm_vios_id]}" | grep "C${vios_scsi_slot}:" | awk -F":" '{print NF-1}')
						lv_vios_id[$lv_len]=$vm_vios_id
						if [ "${vm_lv[$lv_len]}" != "" ]
						then
							lv_len=$(expr $lv_len + 1)
						fi
					fi
					
					if [ "${disk_map_info[$vm_vios_id]}" != "" ]
					then
						# vm_disk_num[$pv_len]=$(echo "${disk_map_info[$vm_vios_id]}" | grep "C${vios_scsi_slot}" | awk -F":" '{print NF-1}')
						vm_disk[$pv_len]=$(echo "${disk_map_info[$vm_vios_id]}" | grep "C${vios_scsi_slot}:" | awk -F":" '{for(i=2;i<=NF;i++) print $i}')
						# echo "vm_disk[$pv_len]==${vm_disk[$pv_len]}"
						vm_disk_num[$pv_len]=$(echo "${disk_map_info[$vm_vios_id]}" | grep "C${vios_scsi_slot}:" | awk -F":" '{print NF-1}')
						pv_vios_id[$pv_len]=$vm_vios_id
						if [ "${vm_disk[$pv_len]}" != "" ]
						then
							pv_len=$(expr $pv_len + 1)
						fi
					fi
				done
			done
		fi
		
		echo -e "\"lv\":[\c"
		if [ "$lv_len" != "0" ]
		then
			j=0
			while [ $j -lt $lv_len ]
			do
				num=0
				for lv in ${vm_lv[$j]}
				do
					if [ "$lv" != "" ]
					then
						vm_lv_info=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id ${lv_vios_id[$j]} -c \"lslv $lv -field lvid vgname ppsize pps lvstate -fmt :\"")
						if [ "$vm_lv_info" == "" ]
						then
									continue
						fi
						ppsize=$(echo "${vm_lv_info}" | awk -F":" '{print $3}' | awk '{print $1}')
						echo -e "{\c"
						echo -e "\"vios_id\":\"${lv_vios_id[$j]}\", \c"
						echo -e "\"lv_id\":\"$(echo "${vm_lv_info}" | awk -F":" '{print $1}')\", \c"
						echo -e "\"lv_name\":\"$lv\", \c"
						echo -e "\"lv_vg\":\"$(echo "${vm_lv_info}" | awk -F":" '{print $2}')\", \c"
						lv_state=$(echo "${vm_lv_info}" | awk -F":" '{print $5}')
						case $lv_state in
								"opened/syncd")
												lv_state=1;;
								"closed/syncd")
												lv_state=2;;
								*)
												lv_state=3;;
						esac
						echo -e "\"lv_state\":\"${lv_state}\", \c"
						echo -e "\"lv_size\":\"$(echo "${vm_lv_info}" | awk -F":" '{print ppsize*$4}' ppsize="$ppsize")\"\c"
						echo -e "}\c"
					fi
					num=$(expr $num + 1)
					if [ "$num" != "${vm_lv_num[$j]}" ]
					then
						echo -e ", \c"
					fi
				done
				j=$(expr $j + 1)
				if [ "$j" != "$lv_len" ]
				then
					echo  ", \c"
				fi
			done
		fi
		echo -e "], \c"
		
		echo -e "\"pv\":[\c"
		if [ "$pv_len" != "0" ]
		then
			j=0
			while [ $j -lt $pv_len ]
			do
				num=0
				print_flag=0
				for disk in ${vm_disk[$j]}
				do
					if [ "$disk" != "" ]
					then
						pv_info=$(echo "${lspv_info[${pv_vios_id[$j]}]}" | grep -w $disk)
						if [ "$pv_info" != "" ]
						then
							pv_id=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id ${pv_vios_id[$j]} -c \"lsdev -dev $disk -attr pvid\"" | grep -v value | grep -v ^$)
							disk_id=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id ${pv_vios_id[$j]} -c \"lsdev -dev $disk -attr unique_id\"" | grep -v value | grep -v ^$)
							disk_size=$(echo "$pv_info" | awk -F":" '{print $2}')
							disk_state=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id ${pv_vios_id[$j]} -c \"lsdev -dev $disk -field status -fmt :\"")
							
							if [ "${pv_id}" == "none" ]
							then
								pv_id=""
							fi
							
							if [ "${disk_id}" == "none" ]
							then
								disk_id=""
							fi
							
							# echo "disk_id==$disk_id"
							# echo "disk_size==$disk_size"
							# echo "disk_state==$disk_state"
							
							if [ "$disk_id" == "" ]||[ "$disk_size" == "" ]||[ "$disk_state" == "" ]
							then
										continue
							fi
							
							# if [ "$disk_state" == "Defined" ]||[ "$disk_state" == "Available" ]
							# then
									# disk_state=1
							# else
									# disk_state=2
							# fi
							
							echo -e "{\c"
							echo -e "\"vios_id\":\"${pv_vios_id[$j]}\", \c"
							echo -e "\"unique_id\":\"$disk_id\", \c"
							echo -e "\"pv_id\":\"$pv_id\", \c"
							echo -e "\"pv_name\":\"$disk\", \c"
							echo -e "\"pv_size\":\"$disk_size\", \c"
							echo -e "\"pv_status\":\"$disk_state\"\c"
							echo -e "}\c"
					
							num=$(expr $num + 1)
							if [ "$num" != "${vm_disk_num[$j]}" ]
							then
								echo  ", \c"
							fi
						else
							print_flag=$(expr $print_flag + 1)
						fi
					else
						print_flag=$(expr $print_flag + 1)
					fi
				done
				j=$(expr $j + 1)
				if [ "$print_flag" != "${vm_disk_num[$j]}" ]
				then
					if [ "$j" != "$pv_len" ]
					then
						echo  ", \c"
					fi
				fi
			done
		fi
		
		echo -e "]\c"
		
		i=$(expr $i + 1)
		if [ "$i" == "$length" ]
		then
			echo -e "}]"
		else
			echo -e "}, \c"
		fi
	done
}

hmc_ip=$1
hmc_user=$2
host_id=$3
lpar_name=$4

DateNow=$(date +%Y%m%d%H%M%S)
out_log="out_hmc_get_vm_info_${DateNow}.log"
error_log="error_startup_${DateNow}.log"

if [ "${lpar_name}" == "" ]
then
	vm_sys_info=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m $host_id -r lpar -F name:lpar_id:lpar_env:state:os_version:default_profile:boot_mode:auto_start:rmc_state" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		echo "$vm_sys_info" >&2
		exit 1
	fi
	vm_sys_info=$(echo "$vm_sys_info" | awk -F":" '{if($3!="vioserver") print $0}')
	vm_prof_info=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m $host_id -r prof -F lpar_id:os_type:min_mem:desired_mem:max_mem:proc_mode:min_proc_units:desired_proc_units:max_proc_units:min_procs:desired_procs:max_procs:sharing_mode:uncap_weight:virtual_scsi_adapters:virtual_eth_adapters:lpar_env" | awk -F":" '{if($NF!="vioserver") print $0}')
	if [ "$(echo $?)" != "0" ]
	then
		echo "$vm_prof_info" >&2
		exit 1
	fi
else
	vm_sys_info=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m $host_id -r lpar -F name:lpar_id:lpar_env:state:os_version:default_profile:boot_mode:auto_start:rmc_state --filter lpar_names=\"${lpar_name}\"" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		echo "$vm_sys_info" >&2
		exit 1
	fi
	vm_prof_info=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m $host_id -r prof -F lpar_id:os_type:min_mem:desired_mem:max_mem:proc_mode:min_proc_units:desired_proc_units:max_proc_units:min_procs:desired_procs:max_procs:sharing_mode:uncap_weight:virtual_scsi_adapters:virtual_eth_adapters --filter lpar_names=\"${lpar_name}\"")
fi

lpars=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m $host_id -r lpar -F lpar_id:lpar_env:state")
vioses=$(echo "$lpars" | awk -F":" '{if($2=="vioserver" && $3=="Running") print $1}')
vios_num=$(echo $vioses | awk '{print NF}')

sea_length=0
for vios_id in $vioses
do
		vios_prof_vscsi[$vios_id]=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -r prof -m $host_id --filter lpar_ids=${vios_id} -F virtual_scsi_adapters" | sed 's/"//g')
		
		# echo "vios_prof_vscsi[$vios_id]==${vios_prof_vscsi[$vios_id]}"
		sea_names[$vios_id]=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id $vios_id -c \"lsdev -type sea\"" | grep Available | awk '{print $1}')
		sea_map_info=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id $vios_id -c \"lsmap -all -net -field svea physloc bdphysloc -fmt :\"")
		
		lv_map_info[$vios_id]=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id $vios_id -c \"lsmap -all -type lv -field physloc backing -fmt :\"" | awk '{if(substr($0,length($0))==":") {print substr($0,0,length($0)-1)} else {print $0}}' | grep -v ^$)
		disk_map_info[$vios_id]=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id $vios_id -c \"lsmap -all -type disk -field physloc backing -fmt :\"" | awk '{if(substr($0,length($0))==":") {print substr($0,0,length($0)-1)} else {print $0}}' | grep -v ^$)
		
		lspv_info[$vios_id]=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id $vios_id -c \"lspv -size -field NAME SIZE -fmt :\"")
		# echo "vm_sys_info==$vm_sys_info"
		# echo "vm_prof_info==$vm_prof_info"
		# echo "sea_names[$vios_id]==${sea_names[$vios_id]}"
		# echo "sea_map_info==${sea_map_info}"
		# echo "lv_map_info[$vios_id]==${lv_map_info[$vios_id]}"
		# echo "disk_map_info[$vios_id]==${disk_map_info[$vios_id]}"
		
		for sea in ${sea_names[$vios_id]}
		do
			if [ "$sea" != "" ]
			then
				sea_name[$sea_length]=$sea
				if [ $vios_num -eq 2 ]
				then
					flag=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id $vios_id -c \"entstat -all $sea\"" | grep Active | awk '{print $4}')
					if [ "$flag" != "True" ]
					then
						continue
					fi
				fi
				sea_info=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id $vios_id -c \"lsdev -dev $sea -attr\"")
				# sea_pvid[$sea_length]=$(echo "$sea_info" | awk '{if($1=="pvid") print $2}')
				sea_pvid_ent=$(echo "$sea_info" | awk '{if($1=="pvid_adapter") print $2}')
				sea_virt_adapters=$(echo "$sea_info" | awk '{if($1=="virt_adapters") print $2}')
				# echo "sea_virt_adapters==$sea_virt_adapters"
				echo ${sea_virt_adapters} | awk -F"," '{for(i=1;i<=NF;i++) print $i}' | while read ent
				do
					if [ "$ent" != "" ]
					then
						if [ "$ent" == "$sea_pvid_ent" ]
						then
							echo "${sea_map_info}" | while read map
							do
								if [ "$sea_pvid_ent" == "$(echo "$map" | awk -F":" '{print $1}')" ]
								then
									sea_physloc[$sea_length]=$(echo "$map" | awk -F":" '{print $3}')
									slot_num=$(echo "$map" | awk -F":" '{print $2}' | awk -F"-" '{print $3}' | sed 's/C//g')
									# echo "slot_num==$slot_num"
									vlans=$(ssh ${hmc_user}@${hmc_ip} "lshwres -r virtualio -m $host_id --rsubtype eth --level lpar --filter lpar_ids=$vios_id,slots=$slot_num -F port_vlan_id,addl_vlan_ids" | sed 's/,none//g' | sed 's/"//g' | awk '{if(substr($0,length($0))==",") print substr($0,0,length($0)-1)}')","$vlans
									# echo "vlans==$vlans"
									break
								fi
							done
						else
							echo "${sea_map_info}" | while read map
							do
								if [ "$ent" == "$(echo "$map" | awk -F":" '{print $1}')" ]
								then
									slot_num=$(echo "$map" | awk -F":" '{print $2}' | awk -F"-" '{print $3}' | sed 's/C//g')
									# echo "slot_num==$slot_num"
									vlans=$(ssh ${hmc_user}@${hmc_ip} "lshwres -r virtualio -m $host_id --rsubtype eth --level lpar --filter lpar_ids=$vios_id,slots=$slot_num -F port_vlan_id,addl_vlan_ids"  | sed 's/,none//g' | sed 's/"//g' | awk '{if(substr($0,length($0))==",") print substr($0,0,length($0)-1)}')","$vlans
									# echo "vlans==$vlans"
									break
								fi
							done
						fi
					fi
				done
				# echo "vlans==$vlans"
				vlan_ids[$sea_length]=${vlans%,*}
				# echo "sea_name[$sea_length]==${sea_name[$sea_length]}"
				# echo "vlan_ids[$sea_length]==${vlan_ids[$sea_length]}"
				# echo "sea_physloc[$sea_length]==${sea_physloc[$sea_length]}"
				sea_length=$(expr $sea_length + 1)
			fi
		done
done


length=0
if [ "${vm_sys_info}" != "" ]
then
	echo "${vm_sys_info}" | while read sys_info
	do
		if [ "$sys_info" != "" ]
		then
			vm_name[${length}]=$(echo "${sys_info}" | awk -F":" '{print $1}')
			vm_id[${length}]=$(echo "${sys_info}" | awk -F":" '{print $2}')
			vm_env[${length}]=$(echo "${sys_info}" | awk -F":" '{print $3}')
			vm_state[${length}]=$(echo "${sys_info}" | awk -F":" '{print $4}')
			vm_osversion[${length}]=$(echo "${sys_info}" | awk -F":" '{print $5}')
			vm_profile[${length}]=$(echo "${sys_info}" | awk -F":" '{print $6}')
			vm_bootmode[${length}]=$(echo "${sys_info}" | awk -F":" '{print $7}')
			vm_autostart[${length}]=$(echo "${sys_info}" | awk -F":" '{print $8}')
			vm_rmcstate[${length}]=$(echo "${sys_info}" | awk -F":" '{print $9}')
			#vm_uptime[${length}]=$(echo "${sys_info}" | awk -F":" '{print $9}')
			
			echo "${vm_prof_info}" | while read prof_info
			do
				# echo "prof_info==$prof_info"
				if [ "${prof_info}" != "" ]
				then
					vid=$(echo "${prof_info}" | awk -F":" '{print $1}')
					if [ "${vm_id[${length}]}" == "${vid}" ]
					then
						vm_os_type[${length}]=$(echo "${prof_info}" | awk -F":" '{print $2}' | awk '{if($0!="null") print $0}')
						vm_min_mem[${length}]=$(echo "${prof_info}" | awk -F":" '{print $3}' | awk '{if($0!="null") print $0}')
						vm_desired_mem[${length}]=$(echo "${prof_info}" | awk -F":" '{print $4}' | awk '{if($0!="null") print $0}')
						vm_max_mem[${length}]=$(echo "${prof_info}" | awk -F":" '{print $5}' | awk '{if($0!="null") print $0}')
						vm_proc_mode[${length}]=$(echo "${prof_info}" | awk -F":" '{print $6}' | awk '{if($0!="null") print $0}')
						vm_min_proc_units[${length}]=$(echo "${prof_info}" | awk -F":" '{print $7}' | awk '{if($0!="null") print $0}')
						vm_desired_proc_units[${length}]=$(echo "${prof_info}" | awk -F":" '{print $8}' | awk '{if($0!="null") print $0}')
						vm_max_proc_units[${length}]=$(echo "${prof_info}" | awk -F":" '{print $9}' | awk '{if($0!="null") print $0}')
						vm_min_procs[${length}]=$(echo "${prof_info}" | awk -F":" '{print $10}' | awk '{if($0!="null") print $0}')
						vm_desired_procs[${length}]=$(echo "${prof_info}" | awk -F":" '{print $11}' | awk '{if($0!="null") print $0}')
						vm_max_procs[${length}]=$(echo "${prof_info}" | awk -F":" '{print $12}' | awk '{if($0!="null") print $0}')
						vm_sharing_mode[${length}]=$(echo "${prof_info}" | awk -F":" '{print $13}' | awk '{if($0!="null") print $0}')
						vm_uncap_weight[${length}]=$(echo "${prof_info}" | awk -F":" '{print $14}' | awk '{if($0!="null") print $0}')
						vm_vscsi_info[${length}]=$(echo "${prof_info}" | awk -F":" '{print $15}' | awk '{if($0!="null") print $0}' | sed 's/"//g')
						# echo "vm_vscsi_info[${length}]==${vm_vscsi_info[${length}]}"
						if [ "${vm_vscsi_info[${length}]}" != "" ]
						then
							vm_vscsi_num[${length}]=$(echo ${vm_vscsi_info[${length}]} | awk -F"," '{print NF}')
							if [ ${vm_vscsi_num[${length}]} -ge 2 ]
							then
								vm_ha_mode[${length}]=1
							else
								vm_ha_mode[${length}]=0
							fi
							vm_vscsi_info[${length}]=$(echo ${vm_vscsi_info[${length}]} | awk -F"," '{for(i=1;i<=NF;i++) print $i}')
						else
							vm_ha_mode[${length}]=0
							vm_vscsi_num[${length}]=0
						fi
						# vios_scsi_slot=$(echo "${prof_info}" | awk -F"," '{print $15}' | awk -F"/" '{print $5}' | awk '{if($0!="null") print $0}')
						# vm_vios_id[${length}]=$(echo "${prof_info}" | awk -F"," '{print $15}' | awk -F"/" '{print $3}' | awk '{if($0!="null") print $0}')
						
						# if [ "${lv_map_info[${vm_vios_id[${length}]}]}" != "" ]
						# then
							# vm_lv_num[${length}]=$(echo "${lv_map_info[${vm_vios_id[${length}]}]}" | grep "C${vios_scsi_slot}" | awk -F":" '{print NF-1}')
							# vm_lv[${length}]=$(echo "${lv_map_info[${vm_vios_id[${length}]}]}" | grep "C${vios_scsi_slot}" | awk -F":" '{for(i=2;i<=NF;i++) print $i}')
						# fi
						
						# if [ "${disk_map_info[${vm_vios_id[${length}]}]}" != "" ]
						# then
							# vm_disk_num[${length}]=$(echo "${disk_map_info[${vm_vios_id[${length}]}]}" | grep "C${vios_scsi_slot}" | awk -F":" '{print NF-1}')
							# vm_disk[${length}]=$(echo "${disk_map_info[${vm_vios_id[${length}]}]}" | grep "C${vios_scsi_slot}" | awk -F":" '{for(i=2;i<=NF;i++) print $i}')
						# fi
						
						vm_eth[${length}]=$(echo "${prof_info}" | awk -F":" '{print $16}' | awk '{if($0!="null") print $0}' | sed 's/"//g')
						if [ "${vm_eth[${length}]}" != "" ]
						then
							vm_eth_num[${length}]=$(echo ${vm_eth[${length}]} | awk -F"," '{print NF}')
							vm_eth[${length}]=$(echo ${vm_eth[${length}]} | awk -F"," '{print $NF;for(i=1;i<NF;i++) print $i}')
						else
							vm_eth_num[${length}]=0
						fi
					fi
				fi
			done
			
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

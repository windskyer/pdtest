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
		#echo  "\"lpar_uptime\":\"${vm_uptime[$i]}\", \c"
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
				eth_slot=$(echo "${vm_eth[${i}]}" | awk -F"/" '{print $1}')
				if [ "$eth_slot" != "none" ]
				then
					eth_id=$(expr $j + 1)
					echo  "{\c"
					echo  "\"eth_id\":\"${eth_id}\", \c"
					echo  "\"eth_name\":\"eth$j\", \c"
					vm_pvid=$(echo "${vm_eth[${i}]}" | awk -F"/" '{print $3}')
					echo  "\"eth_pvid\":\"$vm_pvid\", \c"
					num=0
					while [ $num -lt $sea_length ]
					do
						if [ "$vm_pvid" == "${sea_pvid[$num]}" ]
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
						echo  ",\c"
					fi
				fi
			fi
		done
		echo  "], \c"
		echo  "\"lv\":[\c"
		
		j=0
		for lv in ${vm_lv[$i]}
		do
			if [ "$lv" != "" ]
			then
				vm_lv_info=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id ${vm_vios_id[$i]} -c \"lslv $lv -field lvid vgname ppsize pps lvstate -fmt :\"")
				if [ "$vm_lv_info" == "" ]
				then
							continue
				fi
				ppsize=$(echo "${vm_lv_info}" | awk -F":" '{print $3}' | awk '{print $1}')
				echo  "{\c"
				echo  "\"vios_id\":\"${vm_vios_id[$i]}\", \c"
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
			j=$(expr $j + 1)
			if [ "$j" != "${vm_lv_num[$i]}" ]
			then
				echo  ",\c"
			fi
		done
		
		echo  "], \c"
		
		echo  "\"disk\":[\c"
		
		j=0
		for disk in ${vm_disk[$i]}
		do
			if [ "$disk" != "" ]
			then
				#echo "disk==$disk"
				disk_id=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id ${vm_vios_id[$i]} -c \"lsdev -dev $disk -attr unique_id\"" | grep -v value | awk '{if($0!="") print $0}')
				disk_size=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id ${vm_vios_id[$i]} -c \"oem_setup_env && bootinfo -s $disk\"")
				disk_state=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id ${vm_vios_id[$i]} -c \"lsdev -dev $disk -field status -fmt :\"")
				
				#echo "disk_id==$disk_id"
				#echo "disk_size==$disk_size"
				#echo "disk_state==$disk_state"
				
				if [ "$disk_id" == "" ]||[ "$disk_size" == "" ]||[ "$disk_state" == "" ]
				then
							continue
				fi
				
				if [ "$disk_state" == "Defined" ]||[ "$disk_state" == "Available" ]
				then
						disk_state=1
				else
						disk_state=2
				fi
				
				echo  "{\c"
				echo  "\"vios_id\":\"${vm_vios_id[$i]}\", \c"
				echo  "\"disk_id\":\"$disk_id\", \c"
				echo  "\"disk_name\":\"$disk\", \c"
				echo  "\"disk_size\":\"$disk_size\", \c"
				echo  "\"disk_state\":\"$disk_state\"\c"
				echo  "}\c"
			fi
			j=$(expr $j + 1)
			if [ "$j" != "${vm_disk_num[$i]}" ]
			then
				echo  ",\c"
			fi
		done
		
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
		#echo -e "\"lpar_uptime\":\"${vm_uptime[$i]}\", \c"
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
				eth_id=$(echo "${vm_eth[${i}]}" | awk -F"/" '{print $1}')
				if [ "$eth_id" != "none" ]
				then
					echo -e "{\c"
					echo -e "\"eth_id\":\"${eth_id}\", \c"
					echo -e "\"eth_name\":\"eth$j\", \c"
					vm_pvid=$(echo "${vm_eth[${i}]}" | awk -F"/" '{print $3}')
					echo -e "\"eth_pvid\":\"$vm_pvid\", \c"
					num=0
					while [ $num -lt $sea_length ]
					do
						if [ "$vm_pvid" == "${sea_pvid[$num]}" ]
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
						echo -e ",\c"
					fi
				fi
			fi
		done
		echo -e "], \c"
		echo -e "\"lv\":[\c"
		
		j=0
		for lv in ${vm_lv[$i]}
		do
			if [ "$lv" != "" ]
			then
				vm_lv_info=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id ${vm_vios_id[$i]} -c \"lslv $lv -field lvid vgname ppsize pps lvstate -fmt :\"")
				echo "vm_lv_info==$vm_lv_info"
				if [ "$vm_lv_info" == "" ]
				then
							continue
				fi
				ppsize=$(echo "${vm_lv_info}" | awk -F":" '{print $3}' | awk '{print $1}')
				echo -e "{\c"
				echo -e "\"vios_id\":\"${vm_vios_id[$i]}\", \c"
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
			j=$(expr $j + 1)
			if [ "$j" != "${vm_lv_num[$i]}" ]
			then
				echo -e ",\c"
			fi
		done
		
		echo -e "], \c"
		
		echo -e "\"disk\":[\c"
		
		j=0
		for disk in ${vm_disk[$i]}
		do
			if [ "$disk" != "" ]
			then
				#echo "disk==$disk"
				disk_id=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id ${vm_vios_id[$i]} -c \"lsdev -dev $disk -attr unique_id\"" | grep -v value | awk '{if($0!="") print $0}')
				disk_size=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id ${vm_vios_id[$i]} -c \"oem_setup_env && bootinfo -s $disk\"")
				disk_state=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id ${vm_vios_id[$i]} -c \"lsdev -dev $disk -field status -fmt :\"")
				
				#echo "disk_id==$disk_id"
				#echo "disk_size==$disk_size"
				#echo "disk_state==$disk_state"
				
				if [ "$disk_id" == "" ]||[ "$disk_size" == "" ]||[ "$disk_state" == "" ]
				then
							continue
				fi
				
				if [ "$disk_state" == "Defined" ]||[ "$disk_state"0 == "Available" ]
				then
						disk_state=1
				else
						disk_state=2
				fi
				
				echo -e "{\c"
				echo -e "\"vios_id\":\"${vm_vios_id[$i]}\", \c"
				echo -e "\"disk_id\":\"$disk_id\", \c"
				echo -e "\"disk_name\":\"$disk\", \c"
				echo -e "\"disk_size\":\"$disk_size\", \c"
				echo -e "\"disk_state\":\"$disk_state\"\c"
				echo -e "}\c"
			fi
			j=$(expr $j + 1)
			if [ "$j" != "${vm_disk_num[$i]}" ]
			then
				echo -e ",\c"
			fi
		done
		
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
out_log="out_startup_${DateNow}.log"
error_log="error_startup_${DateNow}.log"

if [ "${lpar_name}" != "" ]
then
	info=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m $host_id -r lpar --filter lpar_names=\"${lpar_name}\"" 2> /dev/null)
	if [ "$info" == "" ]
	then
		echo "No results were found." >&2
		exit 1
	fi
fi

if [ "${lpar_name}" == "" ]
then
	vm_sys_info=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m $host_id -r lpar -F name,lpar_id,lpar_env,state,os_version,default_profile,boot_mode,auto_start")
	vm_prof_info=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m $host_id -r prof -F lpar_id,os_type,min_mem,desired_mem,max_mem,proc_mode,min_proc_units,desired_proc_units,max_proc_units,min_procs,desired_procs,max_procs,sharing_mode,uncap_weight,virtual_scsi_adapters,virtual_eth_adapters")
else
	vm_sys_info=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m $host_id -r lpar -F name,lpar_id,lpar_env,state,os_version,default_profile,boot_mode,auto_start --filter lpar_names=\"${lpar_name}\"")
	vm_prof_info=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m $host_id -r prof -F lpar_id,os_type,min_mem,desired_mem,max_mem,proc_mode,min_proc_units,desired_proc_units,max_proc_units,min_procs,desired_procs,max_procs,sharing_mode,uncap_weight,virtual_scsi_adapters,virtual_eth_adapters --filter lpar_names=\"${lpar_name}\"")
fi

lpars=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m $host_id -r lpar -F lpar_id:lpar_env:state")
vioses=$(echo "$lpars" | awk -F":" '{if($2=="vioserver" && $3=="Running") print $1}')

sea_length=0
echo "$vioses" | while read vios_id
do
		sea_name[$vios_id]=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id $vios_id -c \"lsdev -type sea\"" | grep Available | awk '{print $1}')
		sea_map_info[$vios_id]=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id $vios_id -c \"lsmap -all -net -field sea bdphysloc -fmt :\"")
		
		lv_map_info[$vios_id]=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id $vios_id -c \"lsmap -all -type lv -field physloc backing -fmt :\"" | awk '{if(substr($0,length($0))==":") {print substr($0,0,length($0)-1)} else {print $0}}')
		disk_map_info[$vios_id]=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id $vios_id -c \"lsmap -all -type disk -field physloc backing -fmt :\"" | awk '{if(substr($0,length($0))==":") {print substr($0,0,length($0)-1)} else {print $0}}')
		
		#echo "vm_sys_info==$vm_sys_info"
		#echo "vm_prof_info==$vm_prof_info"
		#echo "sea_name==$sea_name"
		#echo "sea_map_info==$sea_map_info"
		#echo "lv_map_info[$vios_id]==${lv_map_info[$vios_id]}"
		#echo "disk_map_info[$vios_id]==${disk_map_info[$vios_id]}"
		
		echo "${sea_name[$vios_id]}" | while read sea
		do
			if [ "$sea" != "" ]
			then
				sea_name[$sea_length]=$sea
				sea_pvid[$sea_length]=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id $vios_id -c \"lsdev -dev $sea -attr\"" | awk '{if($1=="pvid") print $2}')
				echo ${sea_map_info[$vios_id]} | while read map
				do
					if [ "$sea" == "$(echo "$map" | awk -F":" '{print $1}')" ]
					then
						sea_physloc[$sea_length]=$(echo "$map" | awk -F":" '{print $2}')
						break
					fi
				done
				
			#	echo "sea_name[$sea_length]==${sea_name[$sea_length]}"
			#	echo "sea_pvid[$sea_length]==${sea_pvid[$sea_length]}"
			#	echo "sea_physloc[$sea_length]==${sea_physloc[$sea_length]}"
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
			vm_name[${length}]=$(echo "${sys_info}" | awk -F"," '{print $1}')
			vm_id[${length}]=$(echo "${sys_info}" | awk -F"," '{print $2}')
			vm_env[${length}]=$(echo "${sys_info}" | awk -F"," '{print $3}')
			vm_state[${length}]=$(echo "${sys_info}" | awk -F"," '{print $4}')
			vm_osversion[${length}]=$(echo "${sys_info}" | awk -F"," '{print $5}')
			vm_profile[${length}]=$(echo "${sys_info}" | awk -F"," '{print $6}')
			vm_bootmode[${length}]=$(echo "${sys_info}" | awk -F"," '{print $7}')
			vm_autostart[${length}]=$(echo "${sys_info}" | awk -F"," '{print $8}')
			#vm_uptime[${length}]=$(echo "${sys_info}" | awk -F"," '{print $9}')
			
			echo "${vm_prof_info}" | while read prof_info
			do
				if [ "${prof_info}" != "" ]
				then
					vid=$(echo "${prof_info}" | awk -F"," '{print $1}')
					if [ "${vm_id[${length}]}" ==  "${vid}" ]
					then
						vm_os_type[${length}]=$(echo "${prof_info}" | awk -F"," '{print $2}' | awk '{if($0!="null") print $0}')
						vm_min_mem[${length}]=$(echo "${prof_info}" | awk -F"," '{print $3}' | awk '{if($0!="null") print $0}')
						vm_desired_mem[${length}]=$(echo "${prof_info}" | awk -F"," '{print $4}' | awk '{if($0!="null") print $0}')
						vm_max_mem[${length}]=$(echo "${prof_info}" | awk -F"," '{print $5}' | awk '{if($0!="null") print $0}')
						vm_proc_mode[${length}]=$(echo "${prof_info}" | awk -F"," '{print $6}' | awk '{if($0!="null") print $0}')
						vm_min_proc_units[${length}]=$(echo "${prof_info}" | awk -F"," '{print $7}' | awk '{if($0!="null") print $0}')
						vm_desired_proc_units[${length}]=$(echo "${prof_info}" | awk -F"," '{print $8}' | awk '{if($0!="null") print $0}')
						vm_max_proc_units[${length}]=$(echo "${prof_info}" | awk -F"," '{print $9}' | awk '{if($0!="null") print $0}')
						vm_min_procs[${length}]=$(echo "${prof_info}" | awk -F"," '{print $10}' | awk '{if($0!="null") print $0}')
						vm_desired_procs[${length}]=$(echo "${prof_info}" | awk -F"," '{print $11}' | awk '{if($0!="null") print $0}')
						vm_max_procs[${length}]=$(echo "${prof_info}" | awk -F"," '{print $12}' | awk '{if($0!="null") print $0}')
						vm_sharing_mode[${length}]=$(echo "${prof_info}" | awk -F"," '{print $13}' | awk '{if($0!="null") print $0}')
						vm_uncap_weight[${length}]=$(echo "${prof_info}" | awk -F"," '{print $14}' | awk '{if($0!="null") print $0}')
						vios_scsi_slot=$(echo "${prof_info}" | awk -F"," '{print $15}' | awk -F"/" '{print $5}' | awk '{if($0!="null") print $0}')
						vm_vios_id[${length}]=$(echo "${prof_info}" | awk -F"," '{print $15}' | awk -F"/" '{print $3}' | awk '{if($0!="null") print $0}')
						
						if [ "${lv_map_info[${vm_vios_id[${length}]}]}" != "" ]
						then
							vm_lv_num[${length}]=$(echo "${lv_map_info[${vm_vios_id[${length}]}]}" | grep "C${vios_scsi_slot}" | awk -F":" '{print NF-1}')
							vm_lv[${length}]=$(echo "${lv_map_info[${vm_vios_id[${length}]}]}" | grep "C${vios_scsi_slot}" | awk -F":" '{for(i=2;i<=NF;i++) print $i}')
						fi
						
						if [ "${disk_map_info[${vm_vios_id[${length}]}]}" != "" ]
						then
							vm_disk_num[${length}]=$(echo "${disk_map_info[${vm_vios_id[${length}]}]}" | grep "C${vios_scsi_slot}" | awk -F":" '{print NF-1}')
							vm_disk[${length}]=$(echo "${disk_map_info[${vm_vios_id[${length}]}]}" | grep "C${vios_scsi_slot}" | awk -F":" '{for(i=2;i<=NF;i++) print $i}')
						fi
						
						vm_eth[${length}]=$(echo "${prof_info}" | awk -F"," '{print $16}' | awk '{if($0!="null") print $0}' | sed 's/"//g')
						if [ "${vm_eth[${length}]}" != "" ]
						then
							vm_eth_num[${length}]=$(echo ${vm_eth[${length}]} | awk -F"," '{print NF}')
							vm_eth[${length}]=$(echo ${vm_eth[${length}]} | awk -F"," '{for(i=1;i<=NF;i++) print $i}')
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

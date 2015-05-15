#!/usr/bin/ksh

. ./hmc_function.sh

echo "1|0|SUCCESS"

j=0
echo $1 |awk -F"|" '{for(i=1;i<=NF;i++) print $i}' | while read param
do
        case $j in
				0)
						j=1;
						hmc_ip=$param;;
				1)
						j=2;        
						hmc_user=$param;;
				2)
						j=3;
						host_id=$param;;
				3)
						j=4;
						vios_id=$param;;
				4)
						j=5;
						lpar_name=$param;;
				5)
						j=6;
						proc_mode=$param;;
				6)
						j=7;
						min_proc_units=$param;;
				7)
						j=8;
						desired_proc_units=$param;;
				8)
						j=9;
						max_proc_units=$param;;
				9)
						j=10;
						min_procs=$param;;
				10)
						j=11;
						desired_procs=$param;;
				11)
						j=12;
						max_procs=$param;;
				12)
						j=13;
						min_mem=$param;;
				13)
						j=14;
						desired_mem=$param;;
				14)
						j=15;
						max_mem=$param;;
				15)
						j=16;
						sharing_mode=$param;;
				16)
						j=17;
						template_path=$param;;
				17)
						j=18;
						template_name=$param;;
        esac
done

length=0
echo $2 |awk -F"|" '{for(i=1;i<=NF;i++) print $i}' | while read param
do
	num=$(echo $param | awk -F"," '{print NF}')
	if [ "$num" == "2" ]
	then
		lv_vg[$length]=$(echo $param | awk -F"," '{print $1}')
		lv_size[$length]=$(echo $param | awk -F"," '{print $2}')
		length=$(expr $length + 1)
	else
		if [ "$num" == "1" ]
		then
			pv_name[$length]=$param
			length=$(expr $length + 1)
		else
			throwException "Disk name is null." "105005"
		fi
	fi
done

vlan_len=0
echo $3 |awk -F"|" '{for(i=1;i<=NF;i++) print $i}' | while read param
do
	if [ "$param" != "" ]
	then
		vlan_id[$vlan_len]=$param
		vlan_len=$(expr $vlan_len + 1)
	fi
done


log_flag=$(cat scrpits.properties 2> /dev/null | grep "LOG=" | awk -F"=" '{print $2}')
if [ "$log_flag" == "" ]
then
	log_flag=0
fi

DateNow=$(date +%Y%m%d%H%M%S)
random=$(perl -e 'my $random = int(rand(9999)); print "$random";')
out_log="out_hmc_create_iso_${lpar_name}_${DateNow}_${random}.log"
error_log="error_hmc_create_iso_${lpar_name}_${DateNow}_${random}.log"
error_cp_log="error_create_iso_cp_${lpar_name}_${DateNow}_${random}.log"
cdrom_path="/var/vio/VMLibrary"


######################################################################################
######                                                                           #####
######                            get vios' name                                  #####
######                                                                           #####
######################################################################################
echo "$(date) : get vios' name" > "$out_log"
vios_info=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m ${host_id} -r prof --filter lpar_ids=${vios_id} -F name:max_virtual_slots" 2> "${error_log}")
if [ "$(echo $?)" != "0" ]
then
	if [ "$vios_name" != "" ]
	then
		throwException "Failure to get vios' name" "105404"
	else
		catchException "${error_log}"
		throwException "$error_result" "105404"
	fi
fi
vios_name=$(echo "$vios_info" | awk -F":" '{print $1}')
max_virtual_slots=$(echo "$vios_info" | awk -F":" '{print $2}')
echo "vios_name=${vios_name}" >> "$out_log"
echo "max_virtual_slots=${max_virtual_slots}" >> "$out_log"
echo "1|2|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                              check iso                                    #####
#####                                                                           #####
#####################################################################################
echo "$(date) : check template" >> $out_log
cat_result=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"oem_setup_env && cat ${template_path}/${template_name}/${template_name}.cfg\"" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	throwException "$cat_result" "105430"
fi
tmp_file=$(echo "$cat_result" | awk -F"=" '{if($1=="files") print $2}' | awk -F"|" '{print $1}')
template_name=${tmp_file##*/}
template_path=${tmp_file%/*}

template_name_len=$(echo "$template_name" | awk '{print length($0)}')
if [ $template_name_len -gt 37 ]
then
	s=$(expr $template_name_len - 37)
	new_template_name=$(echo "$template_name" | awk '{print substr($0,0,length($0)-s)}' s="$s")
fi
echo "1|3|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                       get host serial number                              #####
#####                                                                           #####
#####################################################################################
echo "$(date) : check host serial number" >> "$out_log"
serial_num=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -r sys -F serial_num -m ${host_id}" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	throwException "$serial_num" "105406"
fi
echo "serial_num=${serial_num}" >> "$out_log"

echo "1|4|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                              create lv                                    #####
#####                                                                           #####
#####################################################################################
echo "$(date) : create lv" >> $out_log
i=0
progress=5
while [ $i -lt $length ]
do
	if [ "${lv_vg[$i]}" != "" ]
	then
		echo "$(date) : Go to LV..." >> "$out_log"
		#####################################################################################
		#####                                                                           #####
		#####                              check vg                                     #####
		#####                                                                           #####
		#####################################################################################
		echo "$(date) : check vg" >> "$out_log"
		vg_free_size=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"lsvg ${lv_vg[$i]} -field freepps -fmt :\"" 2>&1)
		if [ "$(echo $?)" != "0" ]
		then
			time=0
			error_flag=1
			while [ "$(echo "${vg_free_size}" | grep "Volume group is locked")" != "" ]||[ "$(echo "${vg_free_size}" | grep "ODM lock")" != "" ]
			do
				sleep 1
				vg_free_size=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"lsvg ${vg_name} -field freepps -fmt :\"" 2>&1)
				if [ "$(echo $?)" == "0" ]
				then
					error_flag=0
					break
				fi
				time=$(expr $time + 1)
				if [ $time -gt 30 ]
				then
					break
				fi
			done
			if [ "$error_flag" != "0" ]
			then
				j=0
				while [ $j -lt $i ]
				do
					if [ "${lv_vg[$j]}" != "" ]
					then
						echo "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmlv -f ${lv_name[$j]}\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmlv -f ${lv_name[$j]}\"") >> "$out_log" 2>&1
					fi
					j=$(expr $j + 1)
				done
				throwException "$vg_free_size" "105418"
			fi
		fi
		vg_free_size=$(echo "$vg_free_size" | awk '{print substr($2,2,length($2))}')
		
		if [ $vg_free_size -lt ${lv_size[$i]} ]
		then
			j=0
			while [ $j -lt $i ]
			do
				if [ "${lv_vg[$j]}" != "" ]
				then
					echo "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmlv -f ${lv_name[$j]}\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmlv -f ${lv_name[$j]}\"") >> "$out_log" 2>&1
				fi
				j=$(expr $j + 1)
			done
			throwException "Storage ${lv_vg[$i]} is not enough !" "105418"
		fi
		progress=$(expr $progress + 1)
		echo "1|$progress|SUCCESS"
		
		#####################################################################################
		#####                                                                           #####
		#####                              create lv                                    #####
		#####                                                                           #####
		#####################################################################################
		echo "$(date) : create lv ${lpar_name}" >> "$out_log"
		lv_name[$i]=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"mklv ${lv_vg[$i]} ${lv_size[$i]}M\"" 2>&1)
		if [ "$(echo $?)" != "0" ]
		then
			time=0
			error_flag=1
			while [ "$(echo "${lv_name[$i]}" | grep "Volume group is locked")" != "" ]||[ "$(echo "${lv_name[$i]}" | grep "ODM lock")" != "" ]
			do
				sleep 1
				lv_name[$i]=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"lsvg ${vg_name} -field freepps -fmt :\"" 2>&1)
				if [ "$(echo $?)" == "0" ]
				then
					error_flag=0
					break
				fi
				time=$(expr $time + 1)
				if [ $time -gt 30 ]
				then
					break
				fi
			done
			if [ "$error_flag" != "0" ]
			then
				j=0
				while [ $j -lt $i ]
				do
					if [ "${lv_vg[$j]}" != "" ]
					then
						echo "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmlv -f ${lv_name[$j]}\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmlv -f ${lv_name[$j]}\"") >> "$out_log" 2>&1
					fi
					j=$(expr $j + 1)
				done
				throwException "${lv_name[$i]}" "105419"
			fi
		fi
		lv_name[$i]=$(echo "${lv_name[$i]}" | awk '{print substr($2,2,length($2))}')
		dd_name[$i]=${lv_name[$i]}
		progress=$(expr $progress + 1)
		echo "1|$progress|SUCCESS"
		echo "create lv ${dd_name[$i]} ok" >> "$out_log"
	else
		echo "$(date) : Go to PV..." >> "$out_log"
		#####################################################################################
		#####                                                                           #####
		#####                              check pv                                     #####
		#####                                                                           #####
		#####################################################################################
		echo "$(date) : check pv" >> "$out_log"
		lspv=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"lspv -avail -field name -fmt :\"" 2>&1)
		if [ "$(echo $?)" != "0" ]
		then
			j=0
			while [ $j -lt $i ]
			do
				if [ "${lv_vg[$j]}" != "" ]
				then
					echo "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmlv -f ${lv_name[$j]}\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmlv -f ${lv_name[$j]}\"") >> "$out_log" 2>&1
				fi
				j=$(expr $j + 1)
			done
			throwException "$lspv" "105420"
		fi
		pv_map=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"lsmap -all -type disk -field backing -fmt :\"" 2>&1)
		if [ "$(echo $?)" != "0" ]
		then
			j=0
			while [ $j -lt $i ]
			do
				if [ "${lv_vg[$j]}" != "" ]
				then
					echo "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmlv -f ${lv_name[$j]}\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmlv -f ${lv_name[$j]}\"") >> "$out_log" 2>&1
				fi
				j=$(expr $j + 1)
			done
			throwException "$lspv" "105420"
		fi
		pv_map=$(echo "$pv_map" | awk -F":" '{for(i=1;i<=NF;i++) print $i}')
		if [ "$(echo $pv_map | sed 's/://')" != "" ]
		then
			for line in $(echo "$pv_map" | awk -F":" '{for(i=1;i<=NF;i++) print $i}')
			do
				if [ "$line" != "" ]
				then
					lspv=$(echo $lspv | awk '{ for(i=1;i<=NF;i++) { if($i != pv_name) { print $i } } }' pv_name="$line")
				fi
			done
		fi
		
		flag=$(echo "$lspv" | awk '{if($1 == pv_name) print 1}' pv_name="${pv_name[$i]}")
		if [ "$flag" != "1" ]
		then
			j=0
			while [ $j -lt $i ]
			do
				if [ "${lv_vg[$j]}" != "" ]
				then
					echo "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmlv -f ${lv_name[$j]}\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmlv -f ${lv_name[$j]}\"") >> "$out_log" 2>&1
				fi
				j=$(expr $j + 1)
			done
			throwException "The ${lv_name[$j]} has been used" "105420"
		fi
		dd_name[$i]=${pv_name[$i]}
		progress=$(expr $progress + 1)
		echo "1|$progress|SUCCESS"
		echo "check pv ${dd_name[$i]} ok" >> "$out_log"
	fi
	i=$(expr $i + 1)
done



#####################################################################################
#####                                                                           #####
#####                               create vm                                   #####
#####                                                                           #####
#####################################################################################
echo "$(date) : create vm" >> "$out_log"
if [ "$proc_mode" != "ded" ]
then
	ssh_result=$(ssh ${hmc_user}@${hmc_ip} "mksyscfg -r lpar -m ${host_id} -i name=\"${lpar_name}\",lpar_env=aixlinux,auto_start=0,profile_name=\"${lpar_name}\",max_virtual_slots=20,proc_mode=${proc_mode},min_procs=${min_procs},min_proc_units=${min_proc_units},desired_procs=${desired_procs},desired_proc_units=${desired_proc_units},max_procs=${max_procs},max_proc_units=${max_proc_units},sharing_mode=${sharing_mode},uncap_weight=127,min_mem=${min_mem},desired_mem=${desired_mem},max_mem=${max_mem}" 2>&1)
else
	ssh_result=$(ssh ${hmc_user}@${hmc_ip} "mksyscfg -r lpar -m ${host_id} -i name=\"${lpar_name}\",lpar_env=aixlinux,auto_start=0,profile_name=\"${lpar_name}\",max_virtual_slots=20,proc_mode=${proc_mode},min_procs=${min_procs},desired_procs=${desired_procs},max_procs=${max_procs},sharing_mode=${sharing_mode},min_mem=${min_mem},desired_mem=${desired_mem},max_mem=${max_mem}" 2>&1)
fi

if [ "$(echo $?)" != "0" ]
then
	j=0
	while [ $j -lt $length ]
	do
		if [ "${lv_vg[$j]}" != "" ]
		then
			echo "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmlv -f ${lv_name[$j]}\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmlv -f ${lv_name[$j]}\"") >> "$out_log" 2>&1
		fi
		j=$(expr $j + 1)
	done
	throwException "$ssh_result" "105407"
fi
echo "1|15|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                             check lpar id                                 #####
#####                                                                           #####
#####################################################################################
echo "$(date) : check lpar id" >> "$out_log"
lpar_id=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -r lpar -m ${host_id} -F lpar_id --filter lpar_names=\"${lpar_name}\"" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	echo "rmsyscfg -r lpar -m ${host_id} -n \"${lpar_name}\" :"$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_id} -n \"${lpar_name}\"") >> "$out_log" 2>&1
	j=0
	while [ $j -lt $length ]
	do
		if [ "${lv_vg[$j]}" != "" ]
		then
			echo "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmlv -f ${lv_name[$j]}\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmlv -f ${lv_name[$j]}\"") >> "$out_log" 2>&1
		fi
		j=$(expr $j + 1)
	done
	throwException "$lpar_id" "105408"
fi
echo "$(date) : lpar_id : ${lpar_id}" >> "$out_log"
echo "1|16|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                 get vios scsi available slot number                       #####
#####                                                                           #####
#####################################################################################
echo "$(date) : get vios scsi available slot number" >> "$out_log"
slot_info=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"oem_setup_env && lsslot -c slot -F :\"" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	echo "rmsyscfg -r lpar -m ${host_id} -n \"${lpar_name}\" :"$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_id} -n \"${lpar_name}\"") >> "$out_log" 2>&1
	j=0
	while [ $j -lt $length ]
	do
		if [ "${lv_vg[$j]}" != "" ]
		then
			echo "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmlv -f ${lv_name[$j]}\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmlv -f ${lv_name[$j]}\"") >> "$out_log" 2>&1
		fi
		j=$(expr $j + 1)
	done
	throwException "$slot_info" "105409"
fi
echo "slot_info==$slot_info" >> $out_log

# slot_info=$(echo "$slot_info" | grep $serial_num)
if [ "$slot_info" != "" ]
then
	slot_num=11
	while [ "$(echo "$slot_info" | grep "C${slot_num}:")" != "" ]
	do
		slot_num=$(expr $slot_num + 1)
		slot_info=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"oem_setup_env && lsslot -c slot -F :\"" 2>&1)
		if [ "$(echo $?)" != "0" ]
		then
			echo "rmsyscfg -r lpar -m ${host_id} -n \"${lpar_name}\" :"$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_id} -n \"${lpar_name}\"") >> "$out_log" 2>&1
			j=0
			while [ $j -lt $length ]
			do
				if [ "${lv_vg[$j]}" != "" ]
				then
					echo "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmlv -f ${lv_name[$j]}\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmlv -f ${lv_name[$j]}\"") >> "$out_log" 2>&1
				fi
				j=$(expr $j + 1)
			done
			throwException "$slot_info" "105409"
		fi
		echo "slot_info==$slot_info" >> $out_log
	done
	if [ $slot_num -gt $max_virtual_slots ]
	then
		echo "rmsyscfg -r lpar -m ${host_id} -n \"${lpar_name}\" :"$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_id} -n \"${lpar_name}\"") >> "$out_log" 2>&1
		j=0
		while [ $j -lt $length ]
		do
			if [ "${lv_vg[$j]}" != "" ]
			then
				echo "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmlv -f ${lv_name[$j]}\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmlv -f ${lv_name[$j]}\"") >> "$out_log" 2>&1
			fi
			j=$(expr $j + 1)
		done
		throwException "The slot number more than ${max_virtual_slots}." "105409"
	fi
else
	echo "rmsyscfg -r lpar -m ${host_id} -n \"${lpar_name}\" :"$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_id} -n \"${lpar_name}\"") >> "$out_log" 2>&1
	j=0
	while [ $j -lt $length ]
	do
		if [ "${lv_vg[$j]}" != "" ]
		then
			echo "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmlv -f ${lv_name[$j]}\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmlv -f ${lv_name[$j]}\"") >> "$out_log" 2>&1
		fi
		j=$(expr $j + 1)
	done
	throwException "The vios' max slot number not found." "105409"
fi

max_slot=$slot_num
echo "$(date) : max_slot is $max_slot" >> "$out_log"

echo "1|17|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                       create virtual_scsi_adapters                        #####
#####                                                                           #####
#####################################################################################
echo "$(date) : create virtual_scsi_adapters" >> "$out_log"
ssh_result=$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -m ${host_id} -r prof -i \"virtual_scsi_adapters=2/client/${vios_id}//${max_slot}/0,name=${lpar_name},lpar_id=${lpar_id}\"" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	echo "rmsyscfg -r lpar -m ${host_id} -n \"${lpar_name}\" :"$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_id} -n \"${lpar_name}\"") >> "$out_log" 2>&1
	j=0
	while [ $j -lt $length ]
	do
		if [ "${lv_vg[$j]}" != "" ]
		then
			echo "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmlv -f ${lv_name[$j]}\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmlv -f ${lv_name[$j]}\"") >> "$out_log" 2>&1
		fi
		j=$(expr $j + 1)
	done
	throwException "$ssh_result" "105410"
fi

echo "1|18|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                        create vios scsi_adapters                          #####
#####                                                                           #####
#####################################################################################
echo "$(date) : create vios scsi_adapters" >> "$out_log"
ssh_result=$(ssh ${hmc_user}@${hmc_ip} "chhwres -r virtualio -m ${host_id} --rsubtype scsi -s ${max_slot} -o a --id ${vios_id} -a adapter_type=server,remote_lpar_id=${lpar_id},remote_slot_num=2 -w 1" 2> ${error_log})
if [ "$(echo $?)" != "0" ]
then
	echo "rmsyscfg -r lpar -m ${host_id} -n \"${lpar_name}\" :"$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_id} -n \"${lpar_name}\"") >> "$out_log" 2>&1
	j=0
	while [ $j -lt $length ]
	do
		if [ "${lv_vg[$j]}" != "" ]
		then
			echo "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmlv -f ${lv_name[$j]}\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmlv -f ${lv_name[$j]}\"") >> "$out_log" 2>&1
		fi
		j=$(expr $j + 1)
	done
	throwException "$ssh_result" "105411"
fi

ssh_result=$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -m ${host_id} -r prof -i virtual_scsi_adapters+=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id}" 2> ${error_log})
if [ "$(echo $?)" != "0" ]
then
	echo "chhwres -r virtualio -m ${host_id} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot} :"$(ssh ${hmc_user}@${hmc_ip} "chhwres -r virtualio -m ${host_id} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot}") >> "$out_log" 2>&1
	echo "rmsyscfg -r lpar -m ${host_id} -n \"${lpar_name}\" :"$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_id} -n \"${lpar_name}\"") >> "$out_log" 2>&1
	j=0
	while [ $j -lt $length ]
	do
		if [ "${lv_vg[$j]}" != "" ]
		then
			echo "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmlv -f ${lv_name[$j]}\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmlv -f ${lv_name[$j]}\"") >> "$out_log" 2>&1
		fi
		j=$(expr $j + 1)
	done
	throwException "$ssh_result" "105411"
fi

echo "1|19|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                              flush device                                 #####
#####                                                                           #####
#####################################################################################
echo "$(date) : flush device" >> "$out_log"
ssh_result=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id $vios_id -c cfgdev" 2> "${error_log}")
if [ "$(echo $?)" != "0" ]
then
	echo "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\"") >> "$out_log" 2>&1
	echo "chsyscfg -m ${host_id} -r prof -i \"virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id}\" :"$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -m ${host_id} -r prof -i \"virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id}\"") >> "$out_log" 2>&1
	echo "chhwres -r virtualio -m ${host_id} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot} :"$(ssh ${hmc_user}@${hmc_ip} "chhwres -r virtualio -m ${host_id} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot}") >> "$out_log" 2>&1
	echo "rmsyscfg -r lpar -m ${host_id} -n \"${lpar_name}\" :"$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_id} -n \"${lpar_name}\"") >> "$out_log" 2>&1
	j=0
	while [ $j -lt $length ]
	do
		if [ "${lv_vg[$j]}" != "" ]
		then
			echo "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmlv -f ${lv_name[$j]}\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmlv -f ${lv_name[$j]}\"") >> "$out_log" 2>&1
		fi
		j=$(expr $j + 1)
	done
	throwException "$ssh_result" "105412"
fi

echo "1|20|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                            get vios' adapter                              #####
#####                                                                           #####
#####################################################################################
echo "$(date) : get vios' adapter" >> "$out_log"
vadapter_vios=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"lsmap -all -fmt :\"" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	echo "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\"") >> "$out_log" 2>&1
	echo "chsyscfg -m ${host_id} -r prof -i \"virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id}\" :"$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -m ${host_id} -r prof -i \"virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id}\"") >> "$out_log" 2>&1
	echo "chhwres -r virtualio -m ${host_id} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot} :"$(ssh ${hmc_user}@${hmc_ip} "chhwres -r virtualio -m ${host_id} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot}") >> "$out_log" 2>&1
	echo "rmsyscfg -r lpar -m ${host_id} -n \"${lpar_name}\" :"$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_id} -n \"${lpar_name}\"") >> "$out_log" 2>&1
	j=0
	while [ $j -lt $length ]
	do
		if [ "${lv_vg[$j]}" != "" ]
		then
			echo "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmlv -f ${lv_name[$j]}\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmlv -f ${lv_name[$j]}\"") >> "$out_log" 2>&1
		fi
		j=$(expr $j + 1)
	done
	throwException "$vadapter_vios" "105413"
fi
vadapter_vios=$(echo "$vadapter_vios" | grep ${serial_num} | grep "C${max_slot}:" | awk -F":" '{print $1}')

echo "vadapter_vios=${vadapter_vios}" >> "$out_log"
echo "1|21|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                     check vios' adapter and clear                         #####
#####                                                                           #####
#####################################################################################
echo "$(date) : check vios' adapter and clear" >> "$out_log"
ls_map_vadapter=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"lsmap -vadapter $vadapter_vios -field vtd backing -fmt :\"" 2>&1)
if [ "$(echo $?)" != "0" ]
then
		echo "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\"") >> "$out_log" 2>&1
		echo "chsyscfg -m ${host_id} -r prof -i \"virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id}\" :"$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -m ${host_id} -r prof -i \"virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id}\"") >> "$out_log" 2>&1
		echo "chhwres -r virtualio -m ${host_id} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot} :"$(ssh ${hmc_user}@${hmc_ip} "chhwres -r virtualio -m ${host_id} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot}") >> "$out_log" 2>&1
		echo "rmsyscfg -r lpar -m ${host_id} -n \"${lpar_name}\" :"$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_id} -n \"${lpar_name}\"") >> "$out_log" 2>&1
		j=0
		while [ $j -lt $length ]
		do
			if [ "${lv_vg[$j]}" != "" ]
			then
				echo "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmlv -f ${lv_name[$j]}\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmlv -f ${lv_name[$j]}\"") >> "$out_log" 2>&1
			fi
			j=$(expr $j + 1)
		done
		throwException "$ls_map_vadapter" "105414"
fi
echo "ls_map_vadapter==$ls_map_vadapter" >> $out_log

for vtd_info in $(echo "$ls_map_vadapter" | awk -F":" '{for(i=1;i<=NF;i++) {if(i%2==0) print $i; else printf $i","}}')
do
	vtd=$(echo "$vtd_info" | awk -F"," '{print $1}')
	backing=$(echo "$vtd_info" | awk -F"," '{print $2}')
	
	if [ "$vtd" == "" ]
	then
		continue
	fi
	
	ssh_result=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmvdev -vtd $vtd\"" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		echo "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\"") >> "$out_log" 2>&1
		echo "chsyscfg -m ${host_id} -r prof -i \"virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id}\" :"$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -m ${host_id} -r prof -i \"virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id}\"") >> "$out_log" 2>&1
		echo "chhwres -r virtualio -m ${host_id} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot} :"$(ssh ${hmc_user}@${hmc_ip} "chhwres -r virtualio -m ${host_id} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot}") >> "$out_log" 2>&1
		echo "rmsyscfg -r lpar -m ${host_id} -n \"${lpar_name}\" :"$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_id} -n \"${lpar_name}\"") >> "$out_log" 2>&1
		j=0
		while [ $j -lt $length ]
		do
			if [ "${lv_vg[$j]}" != "" ]
			then
				echo "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmlv -f ${lv_name[$j]}\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmlv -f ${lv_name[$j]}\"") >> "$out_log" 2>&1
			fi
			j=$(expr $j + 1)
		done
		throwException "$ssh_result" "105414"
	fi
	
	if [ "$backing" != "" ]
	then
		ssh_result=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"lslv $backing\"" 2>&1)
		if [ "$(echo $?)" != "0" ]
		then
			continue
		fi
		ssh_result=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmlv -f $backing\"" 2>&1)
		if [ "$(echo $?)" != "0" ]
		then
			echo "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\"") >> "$out_log" 2>&1
			echo "chsyscfg -m ${host_id} -r prof -i \"virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id}\" :"$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -m ${host_id} -r prof -i \"virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id}\"") >> "$out_log" 2>&1
			echo "chhwres -r virtualio -m ${host_id} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot} :"$(ssh ${hmc_user}@${hmc_ip} "chhwres -r virtualio -m ${host_id} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot}") >> "$out_log" 2>&1
			echo "rmsyscfg -r lpar -m ${host_id} -n \"${lpar_name}\" :"$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_id} -n \"${lpar_name}\"") >> "$out_log" 2>&1
			j=0
			while [ $j -lt $length ]
			do
				if [ "${lv_vg[$j]}" != "" ]
				then
					echo "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmlv -f ${lv_name[$j]}\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmlv -f ${lv_name[$j]}\"") >> "$out_log" 2>&1
				fi
				j=$(expr $j + 1)
			done
			throwException "$ssh_result" "105414"
		fi
	fi
done
echo "1|22|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                       create virtual_eth_adapters                         #####
#####                                                                           #####
#####################################################################################
echo "$(date) : create virtual_eth_adapters" >> $out_log
sleep 1
i=0
slot=15
while [ $i -lt $vlan_len ]
do
	# echo "slot==$slot"
	if [ "$i" == "0" ]
	then
		ssh_result=$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -r prof -m ${host_id} -i virtual_eth_adapters=${slot}/0/${vlan_id[$i]}//0/1,name=${lpar_name},lpar_id=${lpar_id}" 2>&1)
	else
		ssh_result=$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -r prof -m ${host_id} -i virtual_eth_adapters+=${slot}/0/${vlan_id[$i]}//0/1,name=${lpar_name},lpar_id=${lpar_id}" 2>&1)
	fi
	if [ "$(echo $?)" != "0" ]
	then
		echo "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\"") >> "$out_log" 2>&1
		echo "chsyscfg -m ${host_id} -r prof -i \"virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id}\" :"$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -m ${host_id} -r prof -i \"virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id}\"") >> "$out_log" 2>&1
		echo "chhwres -r virtualio -m ${host_id} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot} :"$(ssh ${hmc_user}@${hmc_ip} "chhwres -r virtualio -m ${host_id} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot}") >> "$out_log" 2>&1
		echo "rmsyscfg -r lpar -m ${host_id} -n \"${lpar_name}\" :"$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_id} -n \"${lpar_name}\"") >> "$out_log" 2>&1
		j=0
		while [ $j -lt $length ]
		do
			if [ "${lv_vg[$j]}" != "" ]
			then
				echo "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmlv -f ${lv_name[$j]}\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmlv -f ${lv_name[$j]}\"") >> "$out_log" 2>&1
			fi
			j=$(expr $j + 1)
		done
		throwException "$ssh_result" "105415"
	fi
	i=$(expr $i + 1)
	slot=$(expr $slot + 1)
done

echo "1|23|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                             create mapping                                #####
#####                                                                           #####
#####################################################################################
echo "$(date) : create mapping" >> "$out_log"
i=0
while [ $i -lt $length ]
do
	mapping_name=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"mkvdev -f -vdev ${dd_name[$i]} -vadapter ${vadapter_vios}\"" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		time=0
		flag=1
		while [ "$(echo "${mapping_name}" | grep "Volume group is locked")" != "" ]||[ "$(echo "${mapping_name}" | grep "ODM lock")" != "" ]
		do
			sleep 1
			mapping_name=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"mkvdev -f -vdev ${dd_name[$i]} -vadapter ${vadapter_vios}\"" 2>&1)
			if [ "$mapping_name" == "0" ]
			then
				flag=0
				break
			fi
			time=$(expr $time + 1)
			if [ $time -gt 30 ]
			then
				break
			fi
		done
		
		if [ "$flag" != "0" ]
		then
			echo "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\"") >> "$out_log" 2>&1
			echo "chsyscfg -m ${host_id} -r prof -i \"virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id}\" :"$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -m ${host_id} -r prof -i \"virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id}\"") >> "$out_log" 2>&1
			echo "chhwres -r virtualio -m ${host_id} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot} :"$(ssh ${hmc_user}@${hmc_ip} "chhwres -r virtualio -m ${host_id} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot}") >> "$out_log" 2>&1
			echo "rmsyscfg -r lpar -m ${host_id} -n \"${lpar_name}\" :"$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_id} -n \"${lpar_name}\"") >> "$out_log" 2>&1
			j=0
			while [ $j -lt $length ]
			do
				if [ "${lv_vg[$j]}" != "" ]
				then
					echo "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmlv -f ${lv_name[$j]}\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmlv -f ${lv_name[$j]}\"") >> "$out_log" 2>&1
				fi
				j=$(expr $j + 1)
			done
			throwException "${mapping_name}" "105422"
		fi
	fi
	i=$(expr $i + 1)
done
echo "1|24|SUCCESS"

######################################################################################
######                                                                           #####
######                             	 copy iso                                 	 #####
######                                                                           #####
######################################################################################
echo "$(date) : copy iso" >> $out_log
iso_size=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"oem_setup_env && ls -l ${template_path}/${template_name} \"" 2>&1)  
if [ "$(echo $?)" != "0" ]
then
	j=0                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
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
	throwException "$iso_size" "105424"
fi
iso_size=$(echo $iso_size | awk '{print $5/1024/1024}')
cp_size=0
ls_result=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"oem_setup_env && ls -l ${cdrom_path}/${template_name}\"" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	if [ "$(echo "$ls_result" | grep "does not exist")" != "" ]
	then
		ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"oem_setup_env && cp ${template_path}/${template_name} ${cdrom_path}/$new_template_name\"" > ${error_log} 2>&1 &
		if [ "$(echo $?)" != "0" ]
		then
			j=0
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
			catchException "${error_log}"
			throwException "$error_result" "105424"
		fi
		crt_iso_copyCheck 25
	else
		j=0
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
		throwException "$ls_result" "105424"
	fi
else
	if [ "$(echo $ls_result | awk '{print $5/1024/1024}')" != "$iso_size" ]
	then
		ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"oem_setup_env && cp ${template_path}/${template_name} ${cdrom_path}/$new_template_name \"" > ${error_log} 2>&1 &
		if [ "$(echo $?)" != "0" ]
		then
			j=0
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
			catchException "${error_log}"
			throwException "$error_result" "105424"
		fi
		crt_iso_copyCheck 25
	fi
fi

if [ "$(echo $ls_result | awk '{print $1}')" != "-r--r--r--" ]
then
	chmod_result=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"oem_setup_env && chmod 444 ${cdrom_path}/${template_name}\"" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		j=0
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
		throwException "$chmod_result" "105424"
	fi
fi

echo "1|85|SUCCESS"

######################################################################################
######                                                                           #####
######                          create virtual cdrom                             #####
######                                                                           #####
######################################################################################
echo "$(date) : create virtual cdrom" >> $out_log
vadapter_vcd=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"mkvdev -fbo -vadapter ${vadapter_vios}\"" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	j=0
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
	throwException "$vadapter_vcd" "105425"
fi
vadapter_vcd=$(echo $vadapter_vcd  | awk '{print $1}')

echo "1|86|SUCCESS"

######################################################################################
######                                                                           #####
######                                mount iso                                	 #####
######                                                                           #####
######################################################################################
echo "$(date) : mount iso" >> $out_log
mount_result=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"loadopt -disk ${template_name} -vtd ${vadapter_vcd}\"" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	j=0
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
	throwException "$mount_result" "105426"
fi
echo "1|87|SUCCESS"

if [ "$log_flag" == "0" ]
then
	rm -f $error_log 2> /dev/null
	rm -f $out_log 2> /dev/null
	rm -f $error_cp_log 2> /dev/null
fi

echo "1|100|SUCCESS"

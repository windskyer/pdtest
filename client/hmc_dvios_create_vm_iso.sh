#!/usr/bin/ksh

echo "1|0|SUCCESS"

. ./hmc_function.sh

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
					lpar_name=$param;;
			4)
					j=5;
					proc_mode=$param;;
			5)
					j=6;
					min_proc_units=$param;;
			6)
					j=7;
					desired_proc_units=$param;;
			7)
					j=8;
					max_proc_units=$param;;
			8)
					j=9;
					min_procs=$param;;
			9)
					j=10;
					desired_procs=$param;;
			10)
					j=11;
					max_procs=$param;;
			11)
					j=12;
					min_mem=$param;;
			12)
					j=13;
					desired_mem=$param;;
			13)
					j=14;
					max_mem=$param;;
			14)
					j=15;
					sharing_mode=$param;;
			15)
					j=16;
					template_path=$param;;
			16)
					j=17;
					template_name=$param;;
        esac
done

length=0
echo $2 |awk -F"|" '{for(i=1;i<=NF;i++) print $i}' | while read param
do
	pv_name[$length]=$param
	length=$(expr $length + 1)
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

if [ "$hmc_ip" == "" ]
then
	throwException "HMC ip is null" "105401"
fi

if [ "$hmc_user" == "" ]
then
	throwException "User name is null" "105402"
fi

if [ "$lpar_name" == "" ]
then
	throwException "Lpar name is null" "105403"
fi

log_flag=$(cat scrpits.properties 2> /dev/null | grep "LOG=" | awk -F"=" '{print $2}')
if [ "$log_flag" == "" ]
then
	log_flag=0
fi

DateNow=$(date +%Y%m%d%H%M%S)
random=$(perl -e 'my $random = int(rand(9999)); print "$random";')
out_log="out_createvm_dvios_${lpar_name}_${DateNow}_${random}.log"
error_log="error_createvm_dvios_iso_${lpar_name}_${DateNow}_${random}.log"
error_tmp_log="error_tmp_dvios_iso_${lpar_name}_${DateNow}_${random}.log"
cdrom_path="/var/vio/VMLibrary"

######################################################################################
######                                                                           #####
######                           get vios info                                   #####
######                                                                           #####
######################################################################################
echo "$(date) : get active vios' id" > "$out_log"
get_hmc_vios
i=0
if [ "$vios_len" == "2" ]
then
	while [ $i -lt $vios_len ]
	do
		# echo "viosId[$i]==${viosId[$i]}"
		# echo "viosActive[$i]==${viosActive[$i]}"
		if [ "${viosActive[$i]}" == "1" ]
		then
			vios_id=${viosId[$i]}
			info=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m ${host_id} -r prof --filter lpar_ids=$vios_id -F name:max_virtual_slots" 2>&1)
			if [ "$(echo $?)" != "0" ]
			then
				throwException "$info" "105404"	
			fi
			vios_name=$(echo "$info" | awk -F":" '{print $1}')
			max_virtual_slots=$(echo "$info" | awk -F":" '{print $2}')
			# echo "max_virtual_slots==$max_virtual_slots"
		else
			dvios_vios_id=${viosId[$i]}
			info=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m ${host_id} -r prof --filter lpar_ids=$dvios_vios_id -F name:max_virtual_slots" 2>&1)
			if [ "$(echo $?)" != "0" ]
			then
				throwException "$info" "105404"	
			fi
			dvios_vios_name=$(echo "$info" | awk -F":" '{print $1}')
			dvios_max_virtual_slots=$(echo "$info" | awk -F":" '{print $2}')
			# echo "dvios_max_virtual_slots==$dvios_max_virtual_slots"
		fi
		i=$(expr $i + 1)
	done
else
	throwException "Host $host_id does not have double vios." "105404"
fi
echo "vios_id=${vios_id}" >> "$out_log"
echo "vios_name=${vios_name}" >> "$out_log"
echo "max_virtual_slots=${max_virtual_slots}" >> "$out_log"
echo "dvios_vios_id=${dvios_vios_id}" >> "$out_log"
echo "dvios_vios_name=${dvios_vios_name}" >> "$out_log"
echo "dvios_max_virtual_slots=${dvios_max_virtual_slots}" >> "$out_log"
echo "1|2|SUCCESS"

######################################################################################
######                                                                           #####
######                          get back pv name                                 #####
######                                                                           #####
######################################################################################
echo "$(date) : get back pv name" >> "$out_log"
pv_avail=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id $dvios_vios_id -c \"lspv -avail -field name -fmt :\"" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	throwException "$pv_avail" "105432"
fi

back_pv_length=0
for pv in $pv_avail
do
	back_pv_name[$back_pv_length]=$pv
	back_pv_uuid[$back_pv_length]=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id $dvios_vios_id -c \"lsdev -dev $pv -attr unique_id\"" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		throwException "${back_pv_uuid[$back_pv_length]}" "105432"
	fi
	back_pv_uuid[$back_pv_length]=$(echo "${back_pv_uuid[$back_pv_length]}" | grep -v ^$ | grep -v value)
	back_pv_length=$(expr $back_pv_length + 1)
done

i=0
while [ $i -lt $length ]
do
	echo "viosvrcmd -m $host_id --id $vios_id -c \"lsdev -dev ${pv_name[$i]} -attr unique_id\"" >> $out_log
	pv_uuid=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id $vios_id -c \"lsdev -dev ${pv_name[$i]} -attr unique_id\"" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		throwException "${pv_uuid}" "105432"
	fi
	pv_uuid=$(echo "$pv_uuid" | grep -v ^$ | grep -v value)
	j=0
	while [ $j -lt $back_pv_length ]
	do
		if [ "$pv_uuid" == "${back_pv_uuid[$j]}" ]
		then
			dvios_pv_name[$i]=${back_pv_name[$j]}
			break
		fi
		j=$(expr $j + 1)
	done
	if [ "${dvios_pv_name[$i]}" == "" ]
	then
		throwException "Not found pv's unique_id $pv_uuid in vios $dvios_vios_name." "105432"
	fi
	i=$(expr $i + 1)
done

echo "1|2|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                              check pv                                     #####
#####                                                                           #####
#####################################################################################
echo "$(date) : check pv" >> "$out_log"
i=0
while [ $i -lt $img_num ]
do
	######Back main check
	lspv=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"lspv -avail -field name size -fmt :\"" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		throwException "$lspv" "105420"
	fi
	pv_map=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"lsmap -all -type disk -field backing -fmt :\"" 2>&1 | grep -v ^$)
	if [ "$(echo $?)" != "0" ]
	then
		throwException "$pv_map" "105420"
	fi

	if [ "$(echo $pv_map | sed 's/://')" != "" ]
	then
		for line in $(echo "$pv_map" | awk -F":" '{for(i=1;i<=NF;i++) print $i}')
		do
			if [ "$line" != "" ]
			then
				lspv=$(echo "$lspv" | awk -F":" '{ if($1!=pv_name) print $0 }' pv_name="$line")
			fi
		done
	fi
	
	pv_size=$(echo "$lspv" | awk -F":" '{if($1==pv_name) print $2}' pv_name="${pv_name[$i]}")
	
	if [ "$pv_size" == "" ]
	then
		throwException "${pv_name[$i]} has been used in vios $vios_name" "105420"
	fi
	tmp_size=$(du -m ${img_[$i]} 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		throwException "$tmp_size" "105420"
	fi
	tmp_size=$(echo $tmp_size | awk '{print $1}')
	if [ $tmp_size -gt $pv_size ]
	then
		throwException "Size of ${img_[$i]} is greater than that of ${pv_name[$i]}." "105420"
	fi
	dd_name[$i]=${pv_name[$i]}
	echo "check pv ${pv_name[$i]} ok" >> "$out_log"
	
	######Back pv check
	lspv=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${dvios_vios_id} -c \"lspv -avail -field name size -fmt :\"" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		throwException "$lspv" "105420"
	fi
	pv_map=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${dvios_vios_id} -c \"lsmap -all -type disk -field backing -fmt :\"" 2>&1 | grep -v ^$)
	if [ "$(echo $?)" != "0" ]
	then
		throwException "$pv_map" "105420"
	fi

	if [ "$(echo $pv_map | sed 's/://')" != "" ]
	then
		for line in $(echo "$pv_map" | awk -F":" '{for(i=1;i<=NF;i++) print $i}')
		do
			if [ "$line" != "" ]
			then
				lspv=$(echo "$lspv" | awk -F":" '{ if($1!=pv_name) print $0 }' pv_name="$line")
			fi
		done
	fi
	
	pv_size=$(echo "$lspv" | awk -F":" '{if($1==pv_name) print $2}' pv_name="${dvios_pv_name[$i]}")
	
	if [ "$pv_size" == "" ]
	then
		throwException "${dvios_pv_name[$i]} has been used in vios $dvios_vios_name" "105420"
	fi
	tmp_size=$(du -m ${img_[$i]} 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		throwException "$tmp_size" "105420"
	fi
	tmp_size=$(echo $tmp_size | awk '{print $1}')
	if [ $tmp_size -gt $pv_size ]
	then
		throwException "Size of ${img_[$i]} is greater than that of ${dvios_pv_name[$i]}." "105420"
	fi
	
	i=$(expr $i + 1)
done
echo "1|3|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                           check template                                  #####
#####                                                                           #####
#####################################################################################
echo "$(date) : check template" >> "$out_log"
cat_result=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"oem_setup_env && cat ${template_path}/${template_name}/${template_name}.cfg\"" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	throwException "The iso file can not be found." "105405"
fi
tmp_file=$(echo "$cat_result" | awk -F"=" '{if($1=="files") print $2}' | awk -F"|" '{print $1}')
template_name=${tmp_file##*/}
template_path=${tmp_file%/*}

template_name_len=$(echo "$template_name" | awk '{print length($0)}')
if [ $template_name_len -gt 37 ]
then
	s=$(expr $template_name_len - 37)
	template_name=$(echo "$template_name" | awk '{print substr($0,0,length($0)-s)}' s="$s")
fi
echo "1|4|SUCCESS"

######################################################################################
######                                                                           #####
######                             	 copy iso                                 	 #####
######                                                                           #####
######################################################################################
echo "$(date) : copy iso" >> $out_log
iso_size=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"oem_setup_env && ls -l ${template_path}/${template_name} \"" 2>&1)  
if [ "$(echo $?)" != "0" ]
then
	throwException "$iso_size" "105424"
fi
iso_size=$(echo $iso_size | awk '{print $5/1024/1024}')
cp_size=0
ls_result=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"oem_setup_env && ls -l ${cdrom_path}/${template_name}\"" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	if [ "$(echo "$ls_result" | grep "does not exist")" != "" ]
	then
		ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"oem_setup_env && cp ${template_path}/${template_name} ${cdrom_path}\"" > /dev/null 2>&1 &
		catchException "${error_log}"
		throwException "$error_result" "105424"
		ddcopyCheck 5
	else
		throwException "$ls_result" "105424"
	fi
else
	if [ "$(echo $ls_result | awk '{print $5/1024/1024}')" != "$iso_size" ]
	then
		ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"oem_setup_env && cp ${template_path}/${template_name} ${cdrom_path} \"" > /dev/null 2>&1 &
		catchException "${error_log}"
		if [ "$error_result" != "" ]
		then
			throwException "$error_result" "105424"
		fi
		ddcopyCheck 5
	fi
fi


ls_result=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"oem_setup_env && ls -l ${cdrom_path}/${template_name}\"" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	throwException "$ls_result" "105424"
fi
if [ "$(echo $ls_result | awk '{print $1}')" != "-r--r--r--" ]
then
	chmod_result=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"oem_setup_env && chmod 444 ${cdrom_path}/${template_name}\"" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		throwException "$chmod_result" "105424"
	fi
fi

echo "1|80|SUCCESS"

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

echo "1|81|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                               create vm                                   #####
#####                                                                           #####
#####################################################################################
echo "$(date) : create vm" >> "$out_log"
if [ "$proc_mode" != "ded" ]
then
	ssh_result=$(ssh ${hmc_user}@${hmc_ip} "mksyscfg -r lpar -m ${host_id} -i name=\"${lpar_name}\",lpar_env=aixlinux,auto_start=0,profile_name=\"${lpar_name}\",max_virtual_slots=25,proc_mode=${proc_mode},min_procs=${min_procs},min_proc_units=${min_proc_units},desired_procs=${desired_procs},desired_proc_units=${desired_proc_units},max_procs=${max_procs},max_proc_units=${max_proc_units},sharing_mode=${sharing_mode},uncap_weight=127,min_mem=${min_mem},desired_mem=${desired_mem},max_mem=${max_mem}" 2>&1)
else
	ssh_result=$(ssh ${hmc_user}@${hmc_ip} "mksyscfg -r lpar -m ${host_id} -i name=\"${lpar_name}\",lpar_env=aixlinux,auto_start=0,profile_name=\"${lpar_name}\",max_virtual_slots=25,proc_mode=${proc_mode},min_procs=${min_procs},desired_procs=${desired_procs},max_procs=${max_procs},sharing_mode=${sharing_mode},min_mem=${min_mem},desired_mem=${desired_mem},max_mem=${max_mem}" 2>&1)
fi

if [ "$(echo $?)" != "0" ]
then
	throwException "$ssh_result" "105407"
fi
echo "1|82|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                             check lpar id                                 #####
#####                                                                           #####
#####################################################################################
echo "$(date) : check lpar id" >> "$out_log"
lpar_id=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -r lpar -m ${host_id} -F lpar_id --filter lpar_names=\"${lpar_name}\"" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	rollback_dvios 1
	throwException "$lpar_id" "105408"
fi
echo "$(date) : lpar_id : ${lpar_id}" >> "$out_log"
echo "1|83|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                 get vios scsi available slot number                       #####
#####                                                                           #####
#####################################################################################
echo "$(date) : get vios scsi available slot number" >> "$out_log"
slot_info=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"oem_setup_env && lsslot -c slot -F :\"" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	rollback_dvios 1
	throwException "$slot_info" "105409"
fi

slot_info=$(echo "$slot_info" | grep $serial_num)
if [ "$slot_info" != "" ]
then
		slot_num=10
		while [ "$(echo "$slot_info" | grep "C${slot_num}:")" != "" ]
		do
				slot_num=$(expr $slot_num + 1)
		done
		if [ $slot_num -gt $max_virtual_slots ]
		then
			rollback_dvios 1
			throwException "The slot number more than ${max_virtual_slots}." "105409"
		fi
else
		rollback_dvios 1
		throwException "The vios' max slot number not found." "105409"
fi

max_slot=$slot_num
echo "$(date) : max_slot is $max_slot" >> "$out_log"


slot_info=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${dvios_vios_id} -c \"oem_setup_env && lsslot -c slot -F :\"" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	rollback_dvios 1
	throwException "$slot_info" "105409"
fi

slot_info=$(echo "$slot_info" | grep $serial_num)
if [ "$slot_info" != "" ]
then
		slot_num=10
		while [ "$(echo "$slot_info" | grep "C${slot_num}:")" != "" ]
		do
				slot_num=$(expr $slot_num + 1)
		done
		if [ $slot_num -gt $dvios_max_virtual_slots ]
		then
			rollback_dvios 1
			throwException "The slot number more than ${max_virtual_slots}." "105409"
		fi
else
		rollback_dvios 1
		throwException "The vios' max slot number not found." "105409"
fi

dvios_max_slot=$slot_num
echo "$(date) : dvios_max_slot is $dvios_max_slot" >> "$out_log"

echo "1|87|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                       create virtual_scsi_adapters                        #####
#####                                                                           #####
#####################################################################################
echo "$(date) : create virtual_scsi_adapters" >> "$out_log"
ssh_result=$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -m ${host_id} -r prof -i \"virtual_scsi_adapters=2/client/${vios_id}//${max_slot}/0,name=${lpar_name},lpar_id=${lpar_id}\"" 2>&1)
if [ "$(echo $?)" != "0" ]
then
		rollback_dvios 1
		throwException "$ssh_result" "105410"
fi

ssh_result=$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -m ${host_id} -r prof -i \"virtual_scsi_adapters+=3/client/${dvios_vios_id}//${dvios_max_slot}/0,name=${lpar_name},lpar_id=${lpar_id}\"" 2>&1)
if [ "$(echo $?)" != "0" ]
then
		rollback_dvios 1
		throwException "$ssh_result" "105410"
fi

echo "1|88|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                        create vios scsi_adapters                          #####
#####                                                                           #####
#####################################################################################
echo "$(date) : create vios scsi_adapters" >> "$out_log"
ssh_result=$(ssh ${hmc_user}@${hmc_ip} "chhwres -r virtualio -m ${host_id} --rsubtype scsi -s ${max_slot} -o a --id ${vios_id} -a adapter_type=server,remote_lpar_id=${lpar_id},remote_slot_num=2 -w 1" 2>&1)
if [ "$(echo $?)" != "0" ]
then
		rollback_dvios 1
		throwException "$ssh_result" "105411"
fi


ssh_result=$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -m ${host_id} -r prof -i virtual_scsi_adapters+=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id}" 2>&1)
if [ "$(echo $?)" != "0" ]
then
		rollback_dvios 2
		throwException "$ssh_result" "105411"
fi


ssh_result=$(ssh ${hmc_user}@${hmc_ip} "chhwres -r virtualio -m ${host_id} --rsubtype scsi -s ${dvios_max_slot} -o a --id ${dvios_vios_id} -a adapter_type=server,remote_lpar_id=${lpar_id},remote_slot_num=3 -w 1" 2>&1)
if [ "$(echo $?)" != "0" ]
then
		rollback_dvios 3
		throwException "$ssh_result" "105411"
fi

ssh_result=$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -m ${host_id} -r prof -i virtual_scsi_adapters+=${dvios_max_slot}/server/${lpar_id}//3/0,name=${dvios_vios_name},lpar_id=${dvios_vios_id}" 2>&1)
if [ "$(echo $?)" != "0" ]
then
		rollback_dvios 3
		throwException "$ssh_result" "105411"
fi

echo "1|89|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                              flush device                                 #####
#####                                                                           #####
#####################################################################################
echo "$(date) : flush device, vios id: $vios_id" >> "$out_log"
ssh_result=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id $vios_id -c cfgdev" 2>&1)
if [ "$(echo $?)" != "0" ]
then
		rollback_dvios 4
		throwException "$ssh_result" "105412"
fi

echo "$(date) : flush device, vios id: $dvios_vios_id" >> "$out_log"
ssh_result=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id $dvios_vios_id -c cfgdev" 2> "${error_log}")
if [ "$(echo $?)" != "0" ]
then
		rollback_dvios 4
		throwException "$ssh_result" "105412"
fi
echo "1|90|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                            get vios' adapter                              #####
#####                                                                           #####
#####################################################################################
echo "$(date) : get vios' adapter, vios id: $vios_id" >> "$out_log"
vadapter_vios=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"lsmap -all -fmt :\"" 2>&1)
if [ "$(echo $?)" != "0" ]
then
		rollback_dvios 4
		throwException "$ssh_result" "105413"
fi
vadapter_vios=$(echo "$vadapter_vios" | grep ${serial_num} | grep "C${max_slot}:" | awk -F":" '{print $1}')
echo "vadapter_vios=${vadapter_vios}" >> "$out_log"

echo "$(date) : get vios' adapter, vios id: $dvios_vios_id" >> "$out_log"
dvios_vadapter_vios=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${dvios_vios_id} -c \"lsmap -all -fmt :\"" 2>&1)
if [ "$(echo $?)" != "0" ]
then
		rollback_dvios 4
		throwException "$ssh_result" "105413"
fi
dvios_vadapter_vios=$(echo "$dvios_vadapter_vios" | grep ${serial_num} | grep "C${dvios_max_slot}:" | awk -F":" '{print $1}')
echo "dvios_vadapter_vios=${dvios_vadapter_vios}" >> "$out_log"
echo "1|91|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                     check vios' adapter and clear                         #####
#####                                                                           #####
#####################################################################################
echo "$(date) : check vios' adapter and clear" >> "$out_log"
lsmap_a_vadapter=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"lsmap -vadapter $vadapter_vios -field vtd backing -fmt :\"" 2>&1)
if [ "$(echo $?)" != "0" ]
then
		rollback_dvios 4
		throwException "$lsmap_a_vadapter" "105414"
fi
echo "lsmap_a_vadapter==$lsmap_a_vadapter" >> $out_log

for vtd_info in $(echo "$lsmap_a_vadapter" | awk -F":" '{for(i=1;i<=NF;i++) {if(i%2==0) print $i; else printf $i","}}')
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
		rollback_dvios 4
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
			rollback_dvios 4
			throwException "$ssh_result" "105414"
		fi
	fi
done

lsmap_b_vadapter=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${dvios_vios_id} -c \"lsmap -vadapter $dvios_vadapter_vios -field vtd backing -fmt :\"" 2>&1)
if [ "$(echo $?)" != "0" ]
then
		rollback_dvios 4
		throwException "$lsmap_b_vadapter" "105414"
fi
echo "lsmap_b_vadapter==$lsmap_b_vadapter" >> $out_log

for vtd_info in $(echo "$lsmap_b_vadapter" | awk -F":" '{for(i=1;i<=NF;i++) {if(i%2==0) print $i; else printf $i","}}')
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
		rollback_dvios 4
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
			rollback_dvios 4
			throwException "$ssh_result" "105414"
		fi
	fi
done
echo "1|92|SUCCESS"



#####################################################################################
#####                                                                           #####
#####                       create virtual_eth_adapters                         #####
#####                                                                           #####
#####################################################################################
echo "$(date) : create virtual_eth_adapters" >> "$out_log"
sleep 1
i=0
slot=15
while [ $i -lt $vlan_len ]
do
	if [ "$i" == "0" ]
	then
		ssh_result=$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -r prof -m ${host_id} -i virtual_eth_adapters=${slot}/0/${vlan_id[$i]}//0/1,name=${lpar_name},lpar_id=${lpar_id}" 2>&1)
	else
		ssh_result=$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -r prof -m ${host_id} -i virtual_eth_adapters+=${slot}/0/${vlan_id[$i]}//0/1,name=${lpar_name},lpar_id=${lpar_id}" 2>&1)
	fi
	if [ "$(echo $?)" != "0" ]
	then
			rollback_dvios 4
			throwException "$ssh_result" "105415"
	fi
	i=$(expr $i + 1)
	slot=$(expr $slot + 1)
done
echo "1|93|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                             create mapping                                #####
#####                                                                           #####
#####################################################################################
echo "$(date) : create mapping" >> "$out_log"
i=0
while [ $i -lt $length ]
do
	# mapping main vios
	mapping_name=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"mkvdev -f -vdev ${pv_name[$i]} -vadapter ${vadapter_vios}\"" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		time=0
		error_flag=1
		while [ "$(echo "$mapping_name" | grep "Volume group is locked")" != "" ]||[ "$(echo "$mapping_name" | grep "ODM lock")" != "" ]
		do
			sleep 1
			mapping_name=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"mkvdev -f -vdev ${pv_name[$i]} -vadapter ${vadapter_vios}\"" 2>&1)
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
		if [ "${error_flag}" != "0" ]
		then
			rollback_dvios 5
			throwException "$mapping_name" "105422"
		fi
	fi
	
	# mapping back vios
	dvios_mapping_name=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${dvios_vios_id} -c \"mkvdev -f -vdev ${dvios_pv_name[$i]} -vadapter ${dvios_vadapter_vios}\"" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		time=0
		error_flag=1
		while [ "$(echo "$dvios_mapping_name" | grep "Volume group is locked")" != "" ]||[ "$(echo "$dvios_mapping_name" | grep "ODM lock")" != "" ]
		do
			sleep 1
			dvios_mapping_name=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${dvios_vios_id} -c \"mkvdev -f -vdev ${dvios_pv_name[$i]} -vadapter ${dvios_vadapter_vios}\"" 2>&1)
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
		if [ "${error_flag}" != "0" ]
		then
			rollback_dvios 5
			throwException "$dvios_mapping_name" "105422"
		fi
	fi
	i=$(expr $i + 1)
done

echo "1|95|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                          create virtual cdrom                            	#####
#####                                                                           #####
#####################################################################################
vadapter_vcd=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"mkvdev -fbo -vadapter ${vadapter_vios}\"" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	rollback_dvios 5
	throwException "$vadapter_vcd" "105425"
fi
vadapter_vcd=$(echo "$vadapter_vcd"	| awk '{print $1}')
echo "1|97|SUCCESS"

	
#####################################################################################
#####                                                                           #####
#####                                mount iso                                	#####
#####                                                                           #####
#####################################################################################
echo "$(date) : mount iso" >> "$out_log"
mount_result=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"loadopt -disk ${template_name} -vtd ${vadapter_vcd}\"" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	rollback_dvios 6
	throwException "$mount_result" "105426"
fi
echo "1|99|SUCCESS"
	
if [ "$log_flag" == "0" ]
then
	rm -f "${error_log}" 2> /dev/null
	rm -f "$out_log" 2> /dev/null
fi
rm -f ${cdrom_path}/${config_iso} 2> /dev/null
rm -f ${ovf_xml} 2> /dev/null
rm -f ${template_path}/${config_iso} 2> /dev/null

echo "1|100|SUCCESS"

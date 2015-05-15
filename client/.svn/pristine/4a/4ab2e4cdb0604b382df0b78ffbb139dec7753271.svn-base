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
			17)
					j=18;
					ip_address=$param;;
			18)
					j=19;
					netmask=$param;;
			19)
					j=20;
					gateway=$param;;
			20)
					j=21;
					machine_name=$param;;
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
error_log="error_createvm_dvios_${lpar_name}_${DateNow}_${random}.log"
error_tmp_log="error_tmp_dvios_${lpar_name}_${DateNow}_${random}.log"
ovf_xml="config_${DateNow}_${random}.xml"
config_iso="config_${DateNow}_${random}.iso"
cdrom_path="/var/vio/VMLibrary"

if [ "$machine_name" == "" ]
then
	machine_name=$lpar_name
fi

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
				throwException "$info" "105060"	
			fi
			vios_name=$(echo "$info" | awk -F":" '{print $1}')
			max_virtual_slots=$(echo "$info" | awk -F":" '{print $2}')
			# echo "max_virtual_slots==$max_virtual_slots"
		else
			dvios_vios_id=${viosId[$i]}
			info=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m ${host_id} -r prof --filter lpar_ids=$dvios_vios_id -F name:max_virtual_slots" 2>&1)
			if [ "$(echo $?)" != "0" ]
			then
				throwException "$info" "105060"	
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

echo "1|3|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                           check template                                  #####
#####                                                                           #####
#####################################################################################
echo "$(date) : check template" >> "$out_log"
img=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"oem_setup_env && cat ${template_path}/${template_name}/${template_name}.cfg\"" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	# echo "img==$img"
	throwException "The template file can not be found." "105405"
fi
img=$(echo "$img" | grep "files=" | awk -F"=" '{print $2}')
# img=$(echo "$tmp_details" | grep "files=" | awk -F"=" '{print $2}')
if [ "$img" != "" ]
then
	img_num=$(echo "$img" | awk -F"," '{print NF}')
	if [ "$length" != "$img_num" ]
	then
		throwException "The disk number is wrong." "105405"
	fi
	i=0
	echo "$img" | awk -F"," '{for(i=1;i<=NF;i++) print $i}' | while read line
	do
		if [ "X$line" != "X" ]
		then
			tmp_name=$(echo $line | awk -F"|" '{print $1}')
			result=$(ls $tmp_name 2>&1)
			if [ "$(echo $?)" != "0" ]
			then
				throwException "$result" "105405"
			fi
			img_[$i]=$tmp_name
			i=$(expr $i + 1)
		fi
	done
else
	throwException "The template file can not be found." "105405"
fi
echo "1|4|SUCCESS"

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

echo "1|5|SUCCESS"

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
echo "1|6|SUCCESS"

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
echo "1|7|SUCCESS"

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
					rollback_dvios 1
					throwException "$slot_info" "105409"
				fi
				# slot_info=$(echo "$slot_info" | grep $serial_num)
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

echo "1|8|SUCCESS"

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

echo "1|9|SUCCESS"


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

echo "1|10|SUCCESS"


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
echo "1|11|SUCCESS"

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
		throwException "$vadapter_vios" "105413"
fi
vadapter_vios=$(echo "$vadapter_vios" | grep ${serial_num} | grep "C${max_slot}:" | awk -F":" '{print $1}')
echo "vadapter_vios=${vadapter_vios}" >> "$out_log"

echo "$(date) : get vios' adapter, vios id: $dvios_vios_id" >> "$out_log"
dvios_vadapter_vios=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${dvios_vios_id} -c \"lsmap -all -fmt :\"" 2>&1)
if [ "$(echo $?)" != "0" ]
then
		rollback_dvios 4
		throwException "$dvios_vadapter_vios" "105413"
fi
dvios_vadapter_vios=$(echo "$dvios_vadapter_vios" | grep ${serial_num} | grep "C${dvios_max_slot}:" | awk -F":" '{print $1}')
echo "dvios_vadapter_vios=${dvios_vadapter_vios}" >> "$out_log"
echo "1|12|SUCCESS"


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
echo "1|13|SUCCESS"


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
echo "1|14|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                        startup lpar and shutdown                          #####
#####                                                                           #####
#####################################################################################
echo "$(date) : startup lpar and shutdown" >> "$out_log"
ssh_result=$(ssh ${hmc_user}@${hmc_ip} "chsysstate -m ${host_id} -r lpar -o on -b norm --id ${lpar_id} -f $lpar_name" 2>&1)
if [ "$(echo $?)" != "0" ]
then
		rollback_dvios 4
		throwException "$ssh_result" "105416"
fi
sleep 15
ssh_result=$(ssh ${hmc_user}@${hmc_ip} "chsysstate -m ${host_id} -r lpar -o shutdown --id ${lpar_id} --immed" 2>&1)
if [ "$(echo $?)" != "0" ]
then
		rollback_dvios 4
		throwException "$ssh_result" "105416"
fi
echo "1|15|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                            get eth mac address                            #####
#####                                                                           #####
#####################################################################################
echo "$(date) : get eth mac address" >> "$out_log"
echo "vlan_len==$vlan_len" >> "$out_log"
if [ $vlan_len -gt 0 ]
then
	mac_address=$(ssh ${hmc_user}@${hmc_ip} "lshwres -r virtualio --rsubtype eth -m ${host_id} --level lpar --filter lpar_ids=${lpar_id},slots=15 -F mac_addr" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
			rollback_dvios 4
			throwException "$ssh_result" "105417"
	fi

	mac_1=$(echo $mac_address | cut -c1-2)
	mac_2=$(echo $mac_address | cut -c3-4)
	mac_3=$(echo $mac_address | cut -c5-6)
	mac_4=$(echo $mac_address | cut -c7-8)
	mac_5=$(echo $mac_address | cut -c9-10)
	mac_6=$(echo $mac_address | cut -c11-12)
	mac_address=${mac_1}":"${mac_2}":"${mac_3}":"${mac_4}":"${mac_5}":"${mac_6}
	echo "mac_address==$mac_address" >> "$out_log"
fi
echo "1|16|SUCCESS"



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
		rollback_dvios 4
		throwException "$lspv" "105420"
	fi
	pv_map=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"lsmap -all -type disk -field backing -fmt :\"" 2>&1 | grep -v ^$)
	if [ "$(echo $?)" != "0" ]
	then
		rollback_dvios 4
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
		rollback_dvios 4
		throwException "${pv_name[$i]} has been used in vios $vios_name" "105420"
	fi
	tmp_size=$(du -m ${img_[$i]} 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		rollback_dvios 4
		throwException "$tmp_size" "105420"
	fi
	tmp_size=$(echo $tmp_size | awk '{print $1}')
	if [ $tmp_size -gt $pv_size ]
	then
		rollback_dvios 4
		throwException "Size of ${img_[$i]} is greater than that of ${pv_name[$i]}." "105420"
	fi
	dd_name[$i]=${pv_name[$i]}
	echo "check pv ${pv_name[$i]} ok" >> "$out_log"
	
	######Back pv check
	lspv=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${dvios_vios_id} -c \"lspv -avail -field name size -fmt :\"" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		rollback_dvios 4
		throwException "$lspv" "105420"
	fi
	pv_map=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${dvios_vios_id} -c \"lsmap -all -type disk -field backing -fmt :\"" 2>&1 | grep -v ^$)
	if [ "$(echo $?)" != "0" ]
	then
		rollback_dvios 4
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
		rollback_dvios 4
		throwException "${dvios_pv_name[$i]} has been used in vios $dvios_vios_name" "105420"
	fi
	tmp_size=$(du -m ${img_[$i]} 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		rollback_dvios 4
		throwException "$tmp_size" "105420"
	fi
	tmp_size=$(echo $tmp_size | awk '{print $1}')
	if [ $tmp_size -gt $pv_size ]
	then
		rollback_dvios 4
		throwException "Size of ${img_[$i]} is greater than that of ${dvios_pv_name[$i]}." "105420"
	fi
	
	i=$(expr $i + 1)
done
echo "1|20|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                                 dd copy                                   #####
#####                                                                           #####
#####################################################################################
progress=20
i=0
while [ $i -lt $img_num ]
do

	echo "$(date) : dd copy" >> "$out_log"
	ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"oem_setup_env && dd if=${img_[$i]} of=/dev/r${dd_name[$i]} bs=10M\"" > /dev/null 2>&1 &
	
	sleep 1

	pid=$(ssh ${hmc_user}@${hmc_ip} 'for proc in $(ls -d /proc/[0-9]* | sed '"'"'s/\/proc\///g'"'"'); do cmdline=$(cat /proc/$proc/cmdline); if [ "$(echo $cmdline | grep "viosvrcmd-m'${host_id}'--id'${vios_id}'-coem_setup_env && dd if=${img_[$i]} of=/dev/r${dd_name[$i]} bs=10M" | grep -v grep)" != "" ]; then echo $proc; fi done' 2> /dev/null)
	
	if [ "$pid" != "" ]
	then
		ssh ${hmc_user}@${hmc_ip} "kill $pid"
	else
		rollback_dvios 4
		throwException "The process of dd copy not found." "105421"
	fi
	
	while [ 1 ]
	do
		sleep 60
		ps_rlt=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"oem_setup_env && ps -ef\"" 2>&1)
		if [ "$(echo $?)" != "0" ]
		then
			rollback_dvios 4
			throwException "$ps_rlt" "105421"
		fi
		ps_rlt=$(echo "$ps_rlt" | grep -v grep | grep "dd if=${img_[$i]} of=/dev/r${dd_name[$i]}")
		echo "ps_rlt==$ps_rlt" >> $out_log
		if [ "$ps_rlt" == "" ]
		then
			break
		fi
		progress=$(expr $progress + 1)
		echo "1|${progress}|SUCCESS"
	done
	
	
	# ps_rlt=$(ps -ef | grep "dd if=${img_[$i]} of=/dev/r${dd_name[$i]}" | grep -v grep)
	# while [ "${ps_rlt}" != "" ]
	# do
		# echo "ps_rlt=$ps_rlt" >> "$out_log"
		# sleep 45
		# ps_rlt=$(ps -ef | grep "dd if=${img_[$i]} of=/dev/r${dd_name[$i]}" | grep -v grep)
		# progress=$(expr $progress + 1)
		# echo "1|${progress}|SUCCESS"
	# done

	# catchException $error_tmp_log
	# echo "error_result==$error_result" >> "$out_log"
	# error_result=$(echo "$error_result" | sed 's/://g')
	# if [ "$(echo "$error_result" | grep "time limit")" != "" ]
	# then
		# ps_rlt=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"oem_setup_env && ps -ef\"")
		# ps_rlt=$(echo "$ps_rlt" | grep "dd if=${img_[$i]} of=/dev/r${dd_name[$i]}" | grep -v grep)
		# while [ "$ps_rlt" != "" ]
		# do
			# sleep 30
			# ps_rlt=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"oem_setup_env && ps -ef\"")
			# ps_rlt=$(echo "$ps_rlt" | grep "dd if=${img_[$i]} of=/dev/r${dd_name[$i]}" | grep -v grep)
			# progress=$(expr $progress + 1)
			# echo "1|${progress}|SUCCESS"
		# done
	# fi
	
	# if [ "$(echo "$error_result" | grep -v "records in" | grep -v "records out")" != "" ]&&[ "$(echo "$error_result" | grep "time limit")" == "" ]
	# then
		# rollback_dvios 4
		# throwException "$(echo "$error_result" | grep -v "records in" | grep -v "records out")" "105421"
	# fi
	
	i=$(expr $i + 1)
done
echo "1|76|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                             create mapping                                #####
#####                                                                           #####
#####################################################################################
echo "$(date) : create mapping" >> "$out_log"
i=0
while [ $i -lt $img_num ]
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

echo "1|77|SUCCESS"


if [ "$ip_address" != "" ]&&[ "$netmask" != "" ]&&[ "$gateway" != "" ]
then
	#####################################################################################
	#####                                                                           #####
	#####                             	create xml                             	    #####
	#####                                                                           #####
	#####################################################################################
	echo "devno=0" > ${ovf_xml}
	echo "slotno=19" >> ${ovf_xml}
	echo "ipaddress=${ip_address}" >> ${ovf_xml}
	echo "ipgw=${gateway}" >> ${ovf_xml}
	echo "netmask=${netmask}" >> ${ovf_xml}
	echo "hostname=${machine_name}" >> ${ovf_xml}
	echo "macaddr=${mac_address}" >> ${ovf_xml}
	echo "1|79|SUCCESS"
	
	#####################################################################################
	#####                                                                           #####
	#####                             	create iso                                	#####
	#####                                                                           #####
	#####################################################################################
	echo "$(date) : create iso" >> "$out_log"
	ssh_result=$(mkisofs -r -o ${template_path}/${config_iso} ${ovf_xml} 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		rollback_dvios 5
		throwException "$ssh_result" "105423"
	fi
	echo "1|80|SUCCESS"
	
	#####################################################################################
	#####                                                                           #####
	#####                             	 copy iso                                 	#####
	#####                                                                           #####
	#####################################################################################
	echo "$(date) : copy iso" >> "$out_log"
	if [ "${template_path}" != "${cdrom_path}" ]
	then
		ssh_result=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"oem_setup_env && cp ${template_path}/${config_iso} ${cdrom_path}\"" 2>&1)
		if [ "$(echo $?)" != "0" ]
		then
			rollback_dvios 5
			throwException "$ssh_result" "105424"
		fi
	fi
	echo "1|81|SUCCESS"
	
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
	echo "1|82|SUCCESS"
	
	#####################################################################################
	#####                                                                           #####
	#####                                mount iso                                	#####
	#####                                                                           #####
	#####################################################################################
	echo "$(date) : mount iso" >> "$out_log"
	mount_result=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"loadopt -disk ${config_iso} -vtd ${vadapter_vcd}\"" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		rollback_dvios 6
		throwException "$mount_result" "105426"
	fi
	echo "1|83|SUCCESS"
	
	#####################################################################################
	#####                                                                           #####
	#####                                startup vm                                 #####
	#####                                                                           #####
	#####################################################################################
	lpar_state=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m ${host_id} -r lpar --filter lpar_ids=${lpar_id} -F state" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		rollback_dvios 6
		throwException "$lpar_state" "105427"
	fi
	
	if [ "$lpar_state" != "Running" ]
	then
		ssh_result=$(ssh ${hmc_user}@${hmc_ip} "chsysstate -m ${host_id} -r lpar -o on -b norm --id ${lpar_id} -f $lpar_name" 2>&1)
		if [ "$(echo $?)" != "0" ]
		then
			rollback_dvios 6
			throwException "$ssh_result" "105427"
		fi
		
		while [ "${lpar_state}" != "Running" ]
		do
			sleep 30
			lpar_state=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m ${host_id} -r lpar --filter lpar_ids=${lpar_id} -F state")
			if [ "$lpar_state" == "Error" ]
			then
				rollback_dvios 6
				throwException "The lpar state is error, please check ${host_id} resources." "105427"
			fi
			echo "lpar_state=$lpar_state" >> "$out_log"
		done
	fi
	
	date >> "$out_log"
	time=0
	lpar_state=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m ${host_id} -r lpar --filter lpar_ids=${lpar_id} -F state")
	while [ "${lpar_state}" != "Not Activated" ]
	do
		sleep 15
		time=$(expr $time + 15)
		if [ $time -gt 600 ]
		then
			break
		fi
		lpar_state=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m ${host_id} -r lpar --filter lpar_ids=${lpar_id} -F state")
		echo "time==$time" >> "$out_log"
		echo "lpar_state=$lpar_state" >> "$out_log"
	done
	date >> "$out_log"
	
	echo "1|90|SUCCESS"
	
	#####################################################################################
	#####                                                                           #####
	#####                               shutdown vm                                	#####
	#####                                                                           #####
	#####################################################################################
	lpar_state=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m ${host_id} -r lpar --filter lpar_ids=${lpar_id} -F state")
	if [ "$lpar_state" != "Not Activated" ]
	then
		ssh ${hmc_user}@${hmc_ip} "chsysstate -m ${host_id} -r lpar -o shutdown --id ${lpar_id} --immed"
	fi
	echo "1|92|SUCCESS"
	
	#####################################################################################
	#####                                                                           #####
	#####                               umount iso                                	#####
	#####                                                                           #####
	#####################################################################################
	ssh_result=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"unloadopt -release -vtd ${vadapter_vcd}\"" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		rollback_dvios 6
		throwException "$ssh_result" "105429"
	fi
	echo "1|95|SUCCESS"
fi

if [ "$log_flag" == "0" ]
then
	rm -f "${error_log}" 2> /dev/null
	rm -f "$out_log" 2> /dev/null
fi
ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"oem_setup_env && rm -f ${cdrom_path}/${config_iso}\"" > /dev/null 2>&1
rm -f ${ovf_xml} 2> /dev/null
rm -f ${template_path}/${config_iso} 2> /dev/null

echo "1|100|SUCCESS"

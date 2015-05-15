#!/usr/bin/ksh

echo "1|0|SUCCESS"

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
		
		if [ "$log_flag" == "0" ]
		then
			rm -f "${error_log}" 2> /dev/null
			rm -f "$out_log" 2> /dev/null
		fi
		ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"oem_setup_env && rm -f ${cdrom_path}/${config_iso}\"" > /dev/null 2>&1
		rm -f ${ovf_xml} 2> /dev/null
		rm -f ${template_path}/${config_iso} 2> /dev/null
		exit 1
	fi

}

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
					host_name=$param;;
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
					min_procs=$param;;
			7)
					j=8;
					desired_procs=$param;;
			8)
					j=9;
					max_procs=$param;;
			9)
					j=10;
					min_proc_units=$param;;
			10)
					j=11;
					desired_proc_units=$param;;
			11)
					j=12;
					max_proc_units=$param;;
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
			18)
					j=19;
					ip_address=$param;;
			19)
					j=20;
					netmask=$param;;
			20)
					j=21;
					gateway=$param;;
			21)
					j=22;
					machine_name=$param;;
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
out_log="out_createvm_${lpar_name}_${DateNow}_${random}.log"
error_log="error_createvm_${lpar_name}_${DateNow}_${random}.log"
error_tmp_log="error_tmp_${lpar_name}_${DateNow}_${random}.log"
ovf_xml="config_${DateNow}_${random}.xml"
config_iso="config_${DateNow}_${random}.iso"
cdrom_path="/var/vio/VMLibrary"

if [ "$machine_name" == "" ]
then
	machine_name=$lpar_name
fi

######################################################################################
######                                                                           #####
######                            get vios' name                                 #####
######                                                                           #####
######################################################################################
echo "$(date) : get vios' name" >> "$out_log"
vios_info=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m ${host_name} -r prof --filter lpar_ids=${vios_id} -F name:max_virtual_slots" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	throwException "$vios_info" "105404"
fi
vios_name=$(echo "$vios_info" | awk -F":" '{print $1}')
max_virtual_slots=$(echo "$vios_info" | awk -F":" '{print $2}')
echo "vios_name=${vios_name}" >> "$out_log"
echo "max_virtual_slots=${max_virtual_slots}" >> "$out_log"
echo "1|2|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                           check template                                  #####
#####                                                                           #####
#####################################################################################
echo "$(date) : check template" > $out_log
img=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"oem_setup_env && cat ${template_path}/${template_name}/${template_name}.cfg\"" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	throwException "$img" "105405"
fi
img=$(echo "$img" | grep "files=" | awk -F"=" '{print $2}')

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
			ls $tmp_name > /dev/null 2> $error_log
			catchException "${error_log}"
			throwException "$error_result" "105405"
			img_[$i]=$tmp_name
			i=$(expr $i + 1)
		fi
	done
else
	throwException "The disk can not be found." "105405"
fi

echo "1|3|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                       get host serial number                              #####
#####                                                                           #####
#####################################################################################
echo "$(date) : check host serial number" >> "$out_log"
serial_num=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -r sys -F serial_num -m ${host_name}" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	throwException "$serial_num" "105406"
fi
echo "serial_num=${serial_num}" >> "$out_log"

echo "1|4|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                               create vm                                   #####
#####                                                                           #####
#####################################################################################
echo "$(date) : create vm" >> "$out_log"
if [ "$proc_mode" != "ded" ]
then
	ssh_result=$(ssh ${hmc_user}@${hmc_ip} "mksyscfg -r lpar -m ${host_name} -i name=\"${lpar_name}\",lpar_env=aixlinux,auto_start=0,profile_name=\"${lpar_name}\",max_virtual_slots=25,proc_mode=${proc_mode},min_procs=${min_procs},min_proc_units=${min_proc_units},desired_procs=${desired_procs},desired_proc_units=${desired_proc_units},max_procs=${max_procs},max_proc_units=${max_proc_units},sharing_mode=${sharing_mode},uncap_weight=127,min_mem=${min_mem},desired_mem=${desired_mem},max_mem=${max_mem}" 2>&1)
else
	ssh_result=$(ssh ${hmc_user}@${hmc_ip} "mksyscfg -r lpar -m ${host_name} -i name=\"${lpar_name}\",lpar_env=aixlinux,auto_start=0,profile_name=\"${lpar_name}\",max_virtual_slots=25,proc_mode=${proc_mode},min_procs=${min_procs},desired_procs=${desired_procs},max_procs=${max_procs},sharing_mode=${sharing_mode},min_mem=${min_mem},desired_mem=${desired_mem},max_mem=${max_mem}" 2>&1)
fi

if [ "$(echo $?)" != "0" ]
then
	throwException "$ssh_result" "105407"
fi
echo "1|5|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                             check lpar id                                 #####
#####                                                                           #####
#####################################################################################
echo "$(date) : check lpar id" >> "$out_log"
lpar_id=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -r lpar -m ${host_name} -F lpar_id --filter lpar_names=\"${lpar_name}\"" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	echo "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\" : "$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\"") >> $out_log 2>&1
	throwException "$lpar_id" "105408"
fi
echo "$(date) : lpar_id : ${lpar_id}" >> "$out_log"
echo "1|6|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                 get vios scsi available slot number                       #####
#####                                                                           #####
#####################################################################################
echo "$(date) : get vios scsi available slot number" >> "$out_log"
slot_info=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"oem_setup_env && lsslot -c slot -F :\"" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	echo "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\" : "$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\"") >> $out_log 2>&1
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
			slot_info=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"oem_setup_env && lsslot -c slot -F :\"" 2>&1)
			if [ "$(echo $?)" != "0" ]
			then
				echo "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\" : "$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\"") >> $out_log 2>&1
				throwException "$slot_info" "105409"
			fi
			echo "slot_info==$slot_info" >> $out_log
		done
		if [ $slot_num -gt $max_virtual_slots ]
		then
			echo "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\" : "$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\"") >> $out_log 2>&1
			throwException "The slot number more than ${max_virtual_slots}." "105409"
		fi
else
		echo "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\" : "$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\"") >> $out_log 2>&1
		throwException "The vios' max slot number not found." "105409"
fi

max_slot=$slot_num
echo "$(date) : max_slot is $max_slot" >> "$out_log"

echo "1|7|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                       create virtual_scsi_adapters                        #####
#####                                                                           #####
#####################################################################################
echo "$(date) : create virtual_scsi_adapters" >> "$out_log"
ssh_result=$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -m ${host_name} -r prof -i \"virtual_scsi_adapters=2/client/${vios_id}//${max_slot}/0,name=${lpar_name},lpar_id=${lpar_id}\"" 2>&1)
if [ "$(echo $?)" != "0" ]
then
		echo "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\" : "$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\"") >> $out_log 2>&1
		throwException "$ssh_result" "105410"
fi

echo "1|8|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                        create vios scsi_adapters                          #####
#####                                                                           #####
#####################################################################################
echo "$(date) : create vios scsi_adapters" >> "$out_log"
ssh_result=$(ssh ${hmc_user}@${hmc_ip} "chhwres -r virtualio -m ${host_name} --rsubtype scsi -s ${max_slot} -o a --id ${vios_id} -a adapter_type=server,remote_lpar_id=${lpar_id},remote_slot_num=2 -w 1" 2>&1)
if [ "$(echo $?)" != "0" ]
then
		echo "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\" : "$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\"") >> $out_log 2>&1
		throwException "$ssh_result" "105411"
fi

ssh_result=$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters+=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id}" 2>&1)
if [ "$(echo $?)" != "0" ]
then
		
		echo "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot} : "$(ssh ${hmc_user}@${hmc_ip} "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot}") >> $out_log 2>&1
		echo "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\" : "$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\"") >> $out_log 2>&1
		if [ "$ssh_result" != "" ]
		then
			throwException "$ssh_result" "105411"
		else
			catchException "${error_log}"
			throwException "$error_result" "105411"
		fi
fi

echo "1|9|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                              flush device                                 #####
#####                                                                           #####
#####################################################################################
echo "$(date) : flush device" >> "$out_log"
ssh_result=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_name --id $vios_id -c cfgdev" 2>&1)
if [ "$(echo $?)" != "0" ]
then
		echo "chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id} : "$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id}") >> $out_log 2>&1
		echo "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot} : "$(ssh ${hmc_user}@${hmc_ip} "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot}") >> $out_log 2>&1
		echo "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\" : "$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\"") >> $out_log 2>&1
		throwException "$ssh_result" "105412"
fi

echo "1|10|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                            get vios' adapter                              #####
#####                                                                           #####
#####################################################################################
echo "$(date) : get vios' adapter" >> "$out_log"
vadapter_vios=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"lsmap -all -fmt :\"" 2>&1)
if [ "$(echo $?)" != "0" ]
then
		echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\"") >> $out_log 2>&1
		echo "chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id} : "$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id}") >> $out_log 2>&1
		echo "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot} : "$(ssh ${hmc_user}@${hmc_ip} "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot}") >> $out_log 2>&1
		echo "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\" : "$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\"") >> $out_log 2>&1
		throwException "$vadapter_vios" "105413"
fi
vadapter_vios=$(echo "$vadapter_vios" | grep ${serial_num} | grep "C${max_slot}:" | awk -F":" '{print $1}')

echo "vadapter_vios=${vadapter_vios}" >> "$out_log"
echo "1|11|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                     check vios' adapter and clear                         #####
#####                                                                           #####
#####################################################################################
echo "$(date) : check vios' adapter and clear" >> "$out_log"
ls_map_vadapter=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"lsmap -vadapter $vadapter_vios -field vtd backing -fmt :\"" 2>&1)
if [ "$(echo $?)" != "0" ]
then
		echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\"") >> $out_log 2>&1
		echo "chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id} : "$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id}") >> $out_log 2>&1
		echo "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot} : "$(ssh ${hmc_user}@${hmc_ip} "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot}") >> $out_log 2>&1
		echo "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\" : "$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\"") >> $out_log 2>&1
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
	
	ssh_result=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmvdev -vtd $vtd\"" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\"") >> $out_log 2>&1
		echo "chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id} : "$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id}") >> $out_log 2>&1
		echo "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot} : "$(ssh ${hmc_user}@${hmc_ip} "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot}") >> $out_log 2>&1
		echo "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\" : "$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\"") >> $out_log 2>&1
		throwException "$ssh_result" "105414"
	fi
	
	if [ "$backing" != "" ]
	then
		ssh_result=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"lslv $backing\"" 2>&1)
		if [ "$(echo $?)" != "0" ]
		then
			continue
		fi
		ssh_result=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmlv -f $backing\"" 2>&1)
		if [ "$(echo $?)" != "0" ]
		then
			echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\"") >> $out_log 2>&1
			echo "chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id} : "$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id}") >> $out_log 2>&1
			echo "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot} : "$(ssh ${hmc_user}@${hmc_ip} "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot}") >> $out_log 2>&1
			echo "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\" : "$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\"") >> $out_log 2>&1
			throwException "$ssh_result" "105414"
		fi
	fi
done
echo "1|12|SUCCESS"

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
		ssh_result=$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -r prof -m ${host_name} -i virtual_eth_adapters=${slot}/0/${vlan_id[$i]}//0/1,name=${lpar_name},lpar_id=${lpar_id}" 2>&1)
	else
		ssh_result=$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -r prof -m ${host_name} -i virtual_eth_adapters+=${slot}/0/${vlan_id[$i]}//0/1,name=${lpar_name},lpar_id=${lpar_id}" 2>&1)
	fi
	if [ "$(echo $?)" != "0" ]
	then
		echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\"") >> $out_log 2>&1
		echo "chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id} : "$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id}") >> $out_log 2>&1
		echo "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot} : "$(ssh ${hmc_user}@${hmc_ip} "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot}") >> $out_log 2>&1
		echo "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\" : "$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\"") >> $out_log 2>&1
		throwException "$ssh_result" "105415"
	fi
	i=$(expr $i + 1)
	slot=$(expr $slot + 1)
done
echo "1|13|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                        startup lpar and shutdown                          #####
#####                                                                           #####
#####################################################################################
echo "$(date) : startup lpar and shutdown" >> "$out_log"
ssh_result=$(ssh ${hmc_user}@${hmc_ip} "chsysstate -m ${host_name} -r lpar -o on -b norm --id ${lpar_id} -f $lpar_name" 2>&1)
if [ "$(echo $?)" != "0" ]
then
		echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\"") >> $out_log 2>&1
		echo "chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id} : "$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id}") >> $out_log 2>&1
		echo "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot} : "$(ssh ${hmc_user}@${hmc_ip} "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot}") >> $out_log 2>&1
		echo "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\" : "$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\"") >> $out_log 2>&1
		throwException "$ssh_result" "105416"
fi
sleep 15
ssh_result=$(ssh ${hmc_user}@${hmc_ip} "chsysstate -m ${host_name} -r lpar -o shutdown --id ${lpar_id} --immed" 2>&1)
if [ "$(echo $?)" != "0" ]
then
		echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\"") >> $out_log 2>&1
		echo "chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id} : "$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id}") >> $out_log 2>&1
		echo "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot} : "$(ssh ${hmc_user}@${hmc_ip} "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot}") >> $out_log 2>&1
		echo "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\" : "$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\"") >> $out_log 2>&1
		throwException "$ssh_result" "105416"
fi
echo "1|14|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                            get eth mac address                            #####
#####                                                                           #####
#####################################################################################
echo "$(date) : get eth mac address" >> "$out_log"
echo "vlan_len==$vlan_len" >> "$out_log"
if [ $vlan_len -gt 0 ]
then
	sleep 3
	mac_address=$(ssh ${hmc_user}@${hmc_ip} "lshwres -r virtualio --rsubtype eth -m ${host_name} --level lpar --filter lpar_ids=${lpar_id},slots=15 -F mac_addr" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
			echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\"") >> $out_log 2>&1
			echo "chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id} : "$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id}") >> $out_log 2>&1
			echo "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot} : "$(ssh ${hmc_user}@${hmc_ip} "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot}") >> $out_log 2>&1
			echo "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\" : "$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\"") >> $out_log 2>&1
			throwException "$mac_address" "105417"
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
echo "1|15|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                                dd copy                                    #####
#####                                                                           #####
#####################################################################################
i=0
progress=15
while [ $i -lt $img_num ]
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
		vg_free_size=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"lsvg ${lv_vg[$i]} -field freepps -fmt :\"" 2>&1)
		time=0
		error_flag=0
		while [ "$(echo ${vg_free_size} | grep "Volume group is locked")" != "" ]||[ "$(echo ${vg_free_size} | grep "ODM lock")" != "" ]
		do
			sleep 1
			vg_free_size=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"lsvg ${lv_vg[$i]} -field freepps -fmt :\"" 2>&1)
			if [ "$(echo $?)" != "0" ]
			then
				error_flag=1
			else
				error_flag=0
			fi
			time=$(expr $time + 1)
			if [ $time -gt 30 ]
			then
				break
			fi
		done
		if [ "$error_flag" != "0" ]
		then
			dd_len=0
			while [ $dd_len -lt $i ]
			do
				echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmvdev -vdev ${dd_name[$dd_len]}\" : "$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmvdev -vdev ${dd_name[$dd_len]}\"") >> $out_log 2>&1
				if [ "${lv_vg[$dd_len]}" != "" ]
				then
					echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmlv -f ${dd_name[$dd_len]}\" : "$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmlv -f ${dd_name[$dd_len]}\"") >> $out_log 2>&1
				fi
				dd_len=$(expr $dd_len + 1)
			done
			echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\"") >> $out_log 2>&1
			echo "chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id} : "$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id}") >> $out_log 2>&1
			echo "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot} : "$(ssh ${hmc_user}@${hmc_ip} "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot}") >> $out_log 2>&1
			echo "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\" : "$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\"") >> $out_log 2>&1
			throwException "$vg_free_size" "105418"
		fi
		vg_free_size=$(echo "$vg_free_size" | awk '{print substr($2,2,length($2))}')
			
		if [ $vg_free_size -lt ${lv_size[$i]} ]
		then
			dd_len=0
			while [ $dd_len -lt $i ]
			do
				echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmvdev -vdev ${dd_name[$dd_len]}\" : "$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmvdev -vdev ${dd_name[$dd_len]}\"") >> $out_log 2>&1
				if [ "${lv_vg[$dd_len]}" != "" ]
				then
					echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmlv -f ${dd_name[$dd_len]}\" : "$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmlv -f ${dd_name[$dd_len]}\"") >> $out_log 2>&1
				fi
				dd_len=$(expr $dd_len + 1)
			done
			echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\"") >> $out_log 2>&1
			echo "chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id} : "$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id}") >> $out_log 2>&1
			echo "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot} : "$(ssh ${hmc_user}@${hmc_ip} "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot}") >> $out_log 2>&1
			echo "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\" : "$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\"") >> $out_log 2>&1
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
		lv_name[$i]=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"mklv ${lv_vg[$i]} ${lv_size[$i]}M\"" 2>&1)
		if [ "$(echo $?)" != "0" ]
		then
			time=0
			error_flag=1
			while [ "$(echo ${lv_name[$i]} | grep "Volume group is locked")" != "" ]||[ "$(echo ${lv_name[$i]} | grep "ODM lock")" != "" ]
			do
				sleep 1
				lv_name[$i]=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"mklv ${lv_vg[$i]} ${lv_size[$i]}M\"" 2>&1)
				if [ "$(echo $?)" != "0" ]
				then
					error_flag=1
				else
					error_flag=0
				fi
				time=$(expr $time + 1)
				if [ $time -gt 30 ]
				then
					break
				fi
			done

			if [ "$error_flag" != "0" ]
			then
				dd_len=0
				while [ $dd_len -lt $i ]
				do
					echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmvdev -vdev ${dd_name[$dd_len]}\" : "$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmvdev -vdev ${dd_name[$dd_len]}\"") >> $out_log 2>&1
					if [ "${lv_vg[$dd_len]}" != "" ]
					then
						echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmlv -f ${dd_name[$dd_len]}\" : "$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmlv -f ${dd_name[$dd_len]}\"") >> $out_log 2>&1
					fi
					dd_len=$(expr $dd_len + 1)
				done
				echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\"") >> $out_log 2>&1
				echo "chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id} : "$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id}") >> $out_log 2>&1
				echo "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot} : "$(ssh ${hmc_user}@${hmc_ip} "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot}") >> $out_log 2>&1
				echo "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\" : "$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\"") >> $out_log 2>&1
				throwException "${lv_name[$i]}" "105419"
			fi
		fi
		dd_name[$i]=${lv_name[$i]}
		progress=$(expr $progress + 1)
		echo "1|$progress|SUCCESS"
	else
		echo "$(date) : Go to PV..." >> "$out_log"
		#####################################################################################
		#####                                                                           #####
		#####                              check pv                                     #####
		#####                                                                           #####
		#####################################################################################
		echo "$(date) : check pv" >> "$out_log"
		dd_name[$i]=${pv_name[$i]}
		lspv_name=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"lspv -avail -field name -fmt :\"" 2>&1)
		if [ "$(echo $?)" != "0" ]
		then
			dd_len=0
			while [ $dd_len -lt $i ]
			do
				echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmvdev -vdev ${dd_name[$dd_len]}\" : "$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmvdev -vdev ${dd_name[$dd_len]}\"") >> $out_log 2>&1
				if [ "${lv_vg[$dd_len]}" != "" ]
				then
					echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmlv -f ${dd_name[$dd_len]}\" : "$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmlv -f ${dd_name[$dd_len]}\"") >> $out_log 2>&1
				fi
				dd_len=$(expr $dd_len + 1)
			done
			echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\"") >> $out_log 2>&1
			echo "chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id} : "$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id}") >> $out_log 2>&1
			echo "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot} : "$(ssh ${hmc_user}@${hmc_ip} "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot}") >> $out_log 2>&1
			echo "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\" : "$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\"") >> $out_log 2>&1
			throwException "$lspv_name" "105420"
		fi
		pv_map=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"lsmap -all -type disk -field backing -fmt :\"" 2>&1)
		if [ "$(echo $?)" != "0" ]
		then
			dd_len=0
			while [ $dd_len -lt $i ]
			do
				echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmvdev -vdev ${dd_name[$dd_len]}\" : "$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmvdev -vdev ${dd_name[$dd_len]}\"") >> $out_log 2>&1
				if [ "${lv_vg[$dd_len]}" != "" ]
				then
					echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmlv -f ${dd_name[$dd_len]}\" : "$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmlv -f ${dd_name[$dd_len]}\"") >> $out_log 2>&1
				fi
				dd_len=$(expr $dd_len + 1)
			done
			echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\"") >> $out_log 2>&1
			echo "chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id} : "$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id}") >> $out_log 2>&1
			echo "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot} : "$(ssh ${hmc_user}@${hmc_ip} "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot}") >> $out_log 2>&1
			echo "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\" : "$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\"") >> $out_log 2>&1
			throwException "$lspv_name" "105420"
		fi
		pv_map=$(echo "$pv_map" | awk -F":" '{for(i=1;i<=NF;i++) print $i}')
		if [ "$(echo $pv_map | sed 's/://')" != "" ]
		then
			for line in $(echo "$pv_map" | awk -F":" '{for(i=1;i<=NF;i++) print $i}')
			do
				if [ "$line" != "" ]
				then
					lspv_name=$(echo $lspv_name | awk '{ for(i=1;i<=NF;i++) { if($i != pv_name) { print $i } } }' pv_name="$line")
				fi
			done
		fi
		
		flag=$(echo "$lspv_name" | awk '{if($1 == pv_name) print 1}' pv_name="${pv_name[$i]}")
		
		if [ "$flag" != "1" ]
		then
			dd_len=0
			while [ $dd_len -lt $i ]
			do
				echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmvdev -vdev ${dd_name[$dd_len]}\" : "$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmvdev -vdev ${dd_name[$dd_len]}\"") >> $out_log 2>&1
				if [ "${lv_vg[$dd_len]}" != "" ]
				then
					echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmlv -f ${dd_name[$dd_len]}\" : "$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmlv -f ${dd_name[$dd_len]}\"") >> $out_log 2>&1
				fi
				dd_len=$(expr $dd_len + 1)
			done
			echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\"") >> $out_log 2>&1
			echo "chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id} : "$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id}") >> $out_log 2>&1
			echo "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot} : "$(ssh ${hmc_user}@${hmc_ip} "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot}") >> $out_log 2>&1
			echo "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\" : "$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\"") >> $out_log 2>&1
			throwException "The ${pv_name[$i]} is in used." "105420"
		fi
		progress=$(expr $progress + 1)
		echo "1|$progress|SUCCESS"
	fi
	
	i=$(expr $i + 1)
done


#####################################################################################
#####                                                                           #####
#####                                 dd copy                                   #####
#####                                                                           #####
#####################################################################################
echo "$(date) : dd copy" >> "$out_log"
i=0
while [ $i -lt $img_num ]
do
	ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"oem_setup_env && dd if=${img_[$i]} of=/dev/r${dd_name[$i]} bs=10M\"" > /dev/null 2>&1 &
	
	sleep 1

	pid=$(ssh ${hmc_user}@${hmc_ip} 'for proc in $(ls -d /proc/[0-9]* | sed '"'"'s/\/proc\///g'"'"'); do cmdline=$(cat /proc/$proc/cmdline); if [ "$(echo $cmdline | grep "viosvrcmd-m'${host_name}'--id'${vios_id}'-coem_setup_env && dd if=${img_[$i]} of=/dev/r${dd_name[$i]} bs=10M" | grep -v grep)" != "" ]; then echo $proc; fi done' 2> /dev/null)
	
	if [ "$pid" != "" ]
	then
		ssh ${hmc_user}@${hmc_ip} "kill $pid"
	else
		dd_len=0
		while [ $dd_len -lt $i ]
		do
			echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmvdev -vdev ${dd_name[$dd_len]}\" : "$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmvdev -vdev ${dd_name[$dd_len]}\"") >> $out_log 2>&1
			if [ "${lv_vg[$dd_len]}" != "" ]
			then
				echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmlv -f ${dd_name[$dd_len]}\" : "$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmlv -f ${dd_name[$dd_len]}\"") >> $out_log 2>&1
			fi
			dd_len=$(expr $dd_len + 1)
		done
		echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\"") >> $out_log 2>&1
		echo "chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id} : "$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id}") >> $out_log 2>&1
		echo "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot} : "$(ssh ${hmc_user}@${hmc_ip} "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot}") >> $out_log 2>&1
		echo "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\" : "$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\"") >> $out_log 2>&1
		throwException "The process of dd copy not found." "105421"
	fi
	
	while [ 1 ]
	do
		sleep 60
		ps_rlt=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"oem_setup_env && ps -ef\"" 2>&1)
		if [ "$(echo $?)" != "0" ]
		then
			dd_len=0
			while [ $dd_len -lt $i ]
			do
				echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmvdev -vdev ${dd_name[$dd_len]}\" : "$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmvdev -vdev ${dd_name[$dd_len]}\"") >> $out_log 2>&1
				if [ "${lv_vg[$dd_len]}" != "" ]
				then
					echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmlv -f ${dd_name[$dd_len]}\" : "$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmlv -f ${dd_name[$dd_len]}\"") >> $out_log 2>&1
				fi
				dd_len=$(expr $dd_len + 1)
			done
			echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\"") >> $out_log 2>&1
			echo "chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id} : "$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id}") >> $out_log 2>&1
			echo "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot} : "$(ssh ${hmc_user}@${hmc_ip} "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot}") >> $out_log 2>&1
			echo "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\" : "$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\"") >> $out_log 2>&1
			throwException "$ps_rlt" "105421"
		fi
		ps_rlt=$(echo "$ps_rlt" | grep -v grep | grep "dd if=${img_[$i]} of=/dev/r${dd_name[$i]} bs=10M")
		echo "ps_rlt==$ps_rlt" >> $out_log
		if [ "$ps_rlt" == "" ]
		then
			break
		fi
		progress=$(expr $progress + 1)
		echo "1|${progress}|SUCCESS"
	done
	
	# while [ 1 ]
	# do
		# ps_rlt=$(ps -ef | grep ${hmc_user} | grep ${hmc_ip} | grep "dd if=${img_[$i]} of=/dev/r${dd_name[$i]} bs=10M" | grep -v grep)
		# echo "ps_rlt==$ps_rlt" >> "$out_log"
		# if [ "$ps_rlt" == "" ]
		# then
			# break
		# fi
		# sleep 45
		# progress=$(expr $progress + 1)
		# echo "1|${progress}|SUCCESS"
	# done

	# catchException $error_log
	# echo "error_result==$error_result" >> "$out_log"
	# error_result=$(echo "$error_result" | sed 's/://')
	# if [ "$(echo "$error_result" | grep "time limit")" != "" ]
	# then
		# while [ 1 ]
		# do
			# ps_rlt=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"ps -ef\"" 2>&1)
			# ps_rlt=$(echo "$ps_rlt" | grep "dd if=${img_[$i]} of=/dev/r${dd_name[$i]}" | grep -v grep)
			# echo "hmc_ps_rlt=$ps_rlt" >> "$out_log"
			# if [ "$ps_rlt" == "" ]
			# then
				# break
			# fi
			# sleep 30
		# done
	# fi

	# if [ "$(echo "$error_result" | grep -v "records in" | grep -v "records out")" != "" ]&&[ "$(echo "$error_result" | grep "time limit")" == "" ]
	# then
		# dd_len=0
		# while [ $dd_len -lt $i ]
		# do
			# echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmvdev -vdev ${dd_name[$dd_len]}\" : "$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmvdev -vdev ${dd_name[$dd_len]}\"") >> $out_log 2>&1
			# if [ "${lv_vg[$dd_len]}" != "" ]
			# then
				# echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmlv -f ${dd_name[$dd_len]}\" : "$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmlv -f ${dd_name[$dd_len]}\"") >> $out_log 2>&1
			# fi
			# dd_len=$(expr $dd_len + 1)
		# done
		# echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\"") >> $out_log 2>&1
		# echo "chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id} : "$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id}") >> $out_log 2>&1
		# echo "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot} : "$(ssh ${hmc_user}@${hmc_ip} "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot}") >> $out_log 2>&1
		# echo "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\" : "$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\"") >> $out_log 2>&1
		# throwException "$error_result" "105421"
	# fi
	i=$(expr $i + 1)
done



echo "1|76|SUCCESS"

i=0
while [ $i -lt $img_num ]
do
	echo "dd_name[$i]==${dd_name[$i]}" >> $out_log
	i=$(expr $i + 1)
done

#####################################################################################
#####                                                                           #####
#####                             create mapping                                #####
#####                                                                           #####
#####################################################################################
echo "$(date) : create mapping" >> "$out_log"
i=0
while [ $i -lt $img_num ]
do
	echo "dd_name[$i]==${dd_name[$i]}" >> $out_log
	mapping_name=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"mkvdev -f -vdev ${dd_name[$i]} -vadapter ${vadapter_vios}\"" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		time=0
		error_flag=1
		echo "mapping_name==$mapping_name" >> $out_log
		while [ "$(echo "${mapping_name}" | grep "Volume group is locked")" != "" ]||[ "$(echo ${error_result} | grep "ODM lock")" != "" ]
		do
			sleep 1
			mapping_name=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"mkvdev -f -vdev ${dd_name[$i]} -vadapter ${vadapter_vios}\"" 2>&1)
			if [ "$(echo $?)" != "0" ]
			then
				error_flag=1
			else
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
			dd_len=0
			while [ $dd_len -lt $img_num ]
			do
				echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmvdev -vdev ${dd_name[$dd_len]}\" : "$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmvdev -vdev ${dd_name[$dd_len]}\"") >> $out_log 2>&1
				if [ "${lv_vg[$dd_len]}" != "" ]
				then
					echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmlv -f ${dd_name[$dd_len]}\" : "$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmlv -f ${dd_name[$dd_len]}\"") >> $out_log 2>&1
				fi
				dd_len=$(expr $dd_len + 1)
			done
			echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\"") >> $out_log 2>&1
			echo "chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id} : "$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id}") >> $out_log 2>&1
			echo "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot} : "$(ssh ${hmc_user}@${hmc_ip} "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot}") >> $out_log 2>&1
			echo "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\" : "$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\"") >> $out_log 2>&1
			throwException "$mapping_name" "105422"
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
	echo "slotno=15" >> ${ovf_xml}
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
		dd_len=0
		while [ $dd_len -lt $img_num ]
		do
			echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmvdev -vdev ${dd_name[$dd_len]}\" : "$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmvdev -vdev ${dd_name[$dd_len]}\"") >> $out_log 2>&1
			if [ "${lv_vg[$dd_len]}" != "" ]
			then
				echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmlv -f ${dd_name[$dd_len]}\" : "$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmlv -f ${dd_name[$dd_len]}\"") >> $out_log 2>&1
			fi
			dd_len=$(expr $dd_len + 1)
		done
		echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\"") >> $out_log 2>&1
		echo "chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id} : "$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id}") >> $out_log 2>&1
		echo "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot} : "$(ssh ${hmc_user}@${hmc_ip} "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot}") >> $out_log 2>&1
		echo "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\" : "$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\"") >> $out_log 2>&1
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
		ssh_result=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"oem_setup_env && cp ${template_path}/${config_iso} ${cdrom_path}\"" 2>&1)
		if [ "$(echo $?)" != "0" ]
		then
			dd_len=0
			while [ $dd_len -lt $img_num ]
			do
				echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmvdev -vdev ${dd_name[$dd_len]}\" : "$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmvdev -vdev ${dd_name[$dd_len]}\"") >> $out_log 2>&1
				if [ "${lv_vg[$dd_len]}" != "" ]
				then
					echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmlv -f ${dd_name[$dd_len]}\" : "$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmlv -f ${dd_name[$dd_len]}\"") >> $out_log 2>&1
				fi
				dd_len=$(expr $dd_len + 1)
			done
			echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\"") >> $out_log 2>&1
			echo "chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id} : "$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id}") >> $out_log 2>&1
			echo "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot} : "$(ssh ${hmc_user}@${hmc_ip} "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot}") >> $out_log 2>&1
			echo "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\" : "$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\"") >> $out_log 2>&1
			throwException "$ssh_result" "105424"
		fi
	fi
	echo "1|81|SUCCESS"
	
	#####################################################################################
	#####                                                                           #####
	#####                          create virtual cdrom                            	#####
	#####                                                                           #####
	#####################################################################################
	vadapter_vcd=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"mkvdev -fbo -vadapter ${vadapter_vios}\"" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		dd_len=0
		while [ $dd_len -lt $img_num ]
		do
			echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmvdev -vdev ${dd_name[$dd_len]}\" : "$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmvdev -vdev ${dd_name[$dd_len]}\"") >> $out_log 2>&1
			if [ "${lv_vg[$dd_len]}" != "" ]
			then
				echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmlv -f ${dd_name[$dd_len]}\" : "$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmlv -f ${dd_name[$dd_len]}\"") >> $out_log 2>&1
			fi
			dd_len=$(expr $dd_len + 1)
		done
		echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\"") >> $out_log 2>&1
		echo "chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id} : "$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id}") >> $out_log 2>&1
		echo "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot} : "$(ssh ${hmc_user}@${hmc_ip} "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot}") >> $out_log 2>&1
		echo "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\" : "$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\"") >> $out_log 2>&1
		throwException "$vadapter_vcd" "105425"
	fi
	vadapter_vcd=$(echo "$vadapter_vcd" | awk '{print $1}')
	echo "1|82|SUCCESS"
	
	#####################################################################################
	#####                                                                           #####
	#####                                mount iso                                	#####
	#####                                                                           #####
	#####################################################################################
	echo "$(date) : mount iso" >> "$out_log"
	mount_result=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"loadopt -disk ${config_iso} -vtd ${vadapter_vcd}\"" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		dd_len=0
		while [ $dd_len -lt $img_num ]
		do
			echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmvdev -vdev ${dd_name[$dd_len]}\" : "$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmvdev -vdev ${dd_name[$dd_len]}\"") >> $out_log 2>&1
			if [ "${lv_vg[$dd_len]}" != "" ]
			then
				echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmlv -f ${dd_name[$dd_len]}\" : "$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmlv -f ${dd_name[$dd_len]}\"") >> $out_log 2>&1
			fi
			dd_len=$(expr $dd_len + 1)
		done
		echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\"") >> $out_log 2>&1
		echo "chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id} : "$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id}") >> $out_log 2>&1
		echo "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot} : "$(ssh ${hmc_user}@${hmc_ip} "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot}") >> $out_log 2>&1
		echo "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\" : "$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\"") >> $out_log 2>&1
		throwException "$mount_result" "105426"
	fi
	echo "1|83|SUCCESS"
	
	#####################################################################################
	#####                                                                           #####
	#####                                startup vm                                 #####
	#####                                                                           #####
	#####################################################################################
	lpar_state=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m ${host_name} -r lpar --filter lpar_ids=${lpar_id} -F state" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		dd_len=0
		while [ $dd_len -lt $img_num ]
		do
			echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmvdev -vdev ${dd_name[$dd_len]}\" : "$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmvdev -vdev ${dd_name[$dd_len]}\"") >> $out_log 2>&1
			if [ "${lv_vg[$dd_len]}" != "" ]
			then
				echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmlv -f ${dd_name[$dd_len]}\" : "$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmlv -f ${dd_name[$dd_len]}\"") >> $out_log 2>&1
			fi
			dd_len=$(expr $dd_len + 1)
		done
		echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\"") >> $out_log 2>&1
		echo "chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id} : "$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id}") >> $out_log 2>&1
		echo "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot} : "$(ssh ${hmc_user}@${hmc_ip} "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot}") >> $out_log 2>&1
		echo "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\" : "$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\"") >> $out_log 2>&1
		throwException "$lpar_state" "105427"
	fi
	
	if [ "$lpar_state" != "Running" ]
	then
		ssh_result=$(ssh ${hmc_user}@${hmc_ip} "chsysstate -m ${host_name} -r lpar -o on -b norm --id ${lpar_id} -f $lpar_name" 2>&1)
		if [ "$(echo $?)" != "0" ]
		then
			dd_len=0
			while [ $dd_len -lt $img_num ]
			do
				echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmvdev -vdev ${dd_name[$dd_len]}\" : "$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmvdev -vdev ${dd_name[$dd_len]}\"") >> $out_log 2>&1
				if [ "${lv_vg[$dd_len]}" != "" ]
				then
					echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmlv -f ${dd_name[$dd_len]}\" : "$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmlv -f ${dd_name[$dd_len]}\"") >> $out_log 2>&1
				fi
				dd_len=$(expr $dd_len + 1)
			done
			echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\"") >> $out_log 2>&1
			echo "chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id} : "$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id}") >> $out_log 2>&1
			echo "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot} : "$(ssh ${hmc_user}@${hmc_ip} "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot}") >> $out_log 2>&1
			echo "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\" : "$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\"") >> $out_log 2>&1
			throwException "$ssh_result" "105427"
		fi
		
		while [ "${lpar_state}" != "Running" ]
		do
			sleep 30
			lpar_state=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m ${host_name} -r lpar --filter lpar_ids=${lpar_id} -F state")
			if [ "$lpar_state" == "Error" ]
			then
				dd_len=0
				while [ $dd_len -lt $img_num ]
				do
					echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmvdev -vdev ${dd_name[$dd_len]}\" : "$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmvdev -vdev ${dd_name[$dd_len]}\"") >> $out_log 2>&1
					if [ "${lv_vg[$dd_len]}" != "" ]
					then
						echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmlv -f ${dd_name[$dd_len]}\" : "$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmlv -f ${dd_name[$dd_len]}\"") >> $out_log 2>&1
					fi
					dd_len=$(expr $dd_len + 1)
				done
				echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\"") >> $out_log 2>&1
				echo "chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id} : "$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id}") >> $out_log 2>&1
				echo "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot} : "$(ssh ${hmc_user}@${hmc_ip} "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot}") >> $out_log 2>&1
				echo "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\" : "$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\"") >> $out_log 2>&1
				throwException "The lpar state is error, please check the host resources condition." "105427"
			fi
			echo "lpar_state=$lpar_state" >> "$out_log"
		done
	fi
	
	date >> "$out_log"
	time=0
	lpar_state=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m ${host_name} -r lpar --filter lpar_ids=${lpar_id} -F state" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		dd_len=0
		while [ $dd_len -lt $img_num ]
		do
			echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmvdev -vdev ${dd_name[$dd_len]}\" : "$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmvdev -vdev ${dd_name[$dd_len]}\"") >> $out_log 2>&1
			if [ "${lv_vg[$dd_len]}" != "" ]
			then
				echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmlv -f ${dd_name[$dd_len]}\" : "$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmlv -f ${dd_name[$dd_len]}\"") >> $out_log 2>&1
			fi
			dd_len=$(expr $dd_len + 1)
		done
		echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\"") >> $out_log 2>&1
		echo "chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id} : "$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id}") >> $out_log 2>&1
		echo "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot} : "$(ssh ${hmc_user}@${hmc_ip} "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot}") >> $out_log 2>&1
		echo "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\" : "$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\"") >> $out_log 2>&1
		throwException "$ssh_result" "105427"
	fi
	while [ "${lpar_state}" != "Not Activated" ]
	do
		sleep 15
		time=$(expr $time + 15)
		if [ $time -gt 600 ]
		then
			break
		fi
		lpar_state=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m ${host_name} -r lpar --filter lpar_ids=${lpar_id} -F state" 2>&1)
		if [ "$(echo $?)" != "0" ]
		then
			dd_len=0
			while [ $dd_len -lt $img_num ]
			do
				echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmvdev -vdev ${dd_name[$dd_len]}\" : "$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmvdev -vdev ${dd_name[$dd_len]}\"") >> $out_log 2>&1
				if [ "${lv_vg[$dd_len]}" != "" ]
				then
					echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmlv -f ${dd_name[$dd_len]}\" : "$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmlv -f ${dd_name[$dd_len]}\"") >> $out_log 2>&1
				fi
				dd_len=$(expr $dd_len + 1)
			done
			echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\"") >> $out_log 2>&1
			echo "chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id} : "$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id}") >> $out_log 2>&1
			echo "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot} : "$(ssh ${hmc_user}@${hmc_ip} "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot}") >> $out_log 2>&1
			echo "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\" : "$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\"") >> $out_log 2>&1
			throwException "$ssh_result" "105428"
		fi
		echo "time==$time" >> "$out_log"
		echo "lpar_state=$lpar_state" >> "$out_log"
	done
	date >> "$out_log"
	
	echo "1|90|SUCCESS"
	
	#####################################################################################
	#####                                                                           #####
	#####                               umount iso                                	#####
	#####                                                                           #####
	#####################################################################################
	ssh_result=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"unloadopt -release -vtd ${vadapter_vcd}\"" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		dd_len=0
		while [ $dd_len -lt $img_num ]
		do
			echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmvdev -vdev ${dd_name[$dd_len]}\" : "$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmvdev -vdev ${dd_name[$dd_len]}\"") >> $out_log 2>&1
			if [ "${lv_vg[$dd_len]}" != "" ]
			then
				echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmlv -f ${dd_name[$dd_len]}\" : "$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmlv -f ${dd_name[$dd_len]}\"") >> $out_log 2>&1
			fi
			dd_len=$(expr $dd_len + 1)
		done
		echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\"") >> $out_log 2>&1
		echo "chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id} : "$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id}") >> $out_log 2>&1
		echo "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot} : "$(ssh ${hmc_user}@${hmc_ip} "chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot}") >> $out_log 2>&1
		echo "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\" : "$(ssh ${hmc_user}@${hmc_ip} "rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\"") >> $out_log 2>&1
		throwException "$ssh_result" "105429"
	fi
	echo "1|95|SUCCESS"
	
	#####################################################################################
	#####                                                                           #####
	#####                               shutdown vm                                	#####
	#####                                                                           #####
	#####################################################################################
	echo "chsysstate -m ${host_name} -r lpar -o shutdown --id ${lpar_id} --immed : "$(ssh ${hmc_user}@${hmc_ip} "chsysstate -m ${host_name} -r lpar -o shutdown --id ${lpar_id} --immed") >> $out_log 2>&1

fi

if [ "$log_flag" == "0" ]
then
	rm -f "${error_log}" 2> /dev/null
	rm -f "$out_log" 2> /dev/null
fi
ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"oem_setup_env && rm -f ${cdrom_path}/${config_iso}\"" > /dev/null 2>&1
rm -f ${ovf_xml} 2> /dev/null
rm -f ${template_path}/${config_iso} 2> /dev/null

echo "1|100|SUCCESS"

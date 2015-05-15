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
		rm -f ${cdrom_path}/${config_iso} 2> /dev/null
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

pv_len=0
echo $2 |awk -F"|" '{for(i=1;i<=NF;i++) print $i}' | while read param
do
	if [ "$param" != "" ]
	then
	pv_name[$pv_len]=$param
	pv_len=$(expr $pv_len + 1)
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
		throwException "$ssh_result" "105411"
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
		echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\"") >> $out_log 2>&1
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
vadapter_vios=$(echo "$vadapter_vios" | grep ${serial_num} | grep "C${max_slot}:" | awk -F: '{print $1}')

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

echo "1|15|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                                dd copy                                    #####
#####                                                                           #####
#####################################################################################

#####################################################################################
#####                                                                           #####
#####                             create mapping                                #####
#####                                                                           #####
#####################################################################################
echo "$(date) : create mapping" >> "$out_log"
i=0
while [ $i -lt $pv_len ]
do
	mapping_name=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"mkvdev -vdev ${pv_name[$i]} -vadapter ${vadapter_vios}\"" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		time=0
		error_flag=1
		while [ "$(echo ${error_result} | grep "Volume group is locked")" != "" ]||[ "$(echo ${error_result} | grep "ODM lock")" != "" ]
		do
			sleep 1
			mapping_name=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"mkvdev -vdev ${pv_name[$i]} -vadapter ${vadapter_vios}\"" 2>&1)
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
			j=0
			while [ $j -le $i ]
			do
				echo "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmvdev -vdev ${pv_name[$j]}\" : "$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmvdev -vdev ${pv_name[$j]}\"") >> $out_log 2>&1
				j=$(expr $j + 1)
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
	echo "slotno=19" >> ${ovf_xml}
	echo "ipaddress=${ip_address}" >> ${ovf_xml}
	echo "ipgw=${gateway}" >> ${ovf_xml}
	echo "netmask=${netmask}" >> ${ovf_xml}
	echo "hostname=${host_name}" >> ${ovf_xml}
	echo "macaddr=${mac_address}" >> ${ovf_xml}
	echo "1|79|SUCCESS"
	
	#####################################################################################
	#####                                                                           #####
	#####                             	create iso                                	#####
	#####                                                                           #####
	#####################################################################################
	echo "$(date) : create iso" >> "$out_log"
	ssh_result=$(mkisofs -r -o ${template_path}/${config_iso} ${ovf_xml} >> "$out_log" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		i=0
		while [ $i -lt $pv_len ]
		do
			ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmvdev -vdev ${pv_name[$i]}\"" > /dev/null 2>&1
			i=$(expr $i + 1)
		done
		ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\" && chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id} && chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot} && rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\"" > /dev/null 2>&1
		if [ "$ssh_result" != "" ]
		then
			throwException "$ssh_result" "105064"
		else
			catchException "${error_log}"
			throwException "$error_result" "105064"
		fi
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
		ssh_result=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"oem_setup_env && cp ${template_path}/${config_iso} ${cdrom_path}\"" 2> "${error_log}")
		if [ "$(echo $?)" != "0" ]
		then
			i=0
			while [ $i -lt $pv_len ]
			do
				ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmvdev -vdev ${pv_name[$i]}\"" > /dev/null 2>&1
				i=$(expr $i + 1)
			done
			ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\" && chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id} && chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot} && rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\"" > /dev/null 2>&1
			if [ "$ssh_result" != "" ]
			then
				throwException "$ssh_result" "105064"
			else
				catchException "${error_log}"
				throwException "$error_result" "105064"
			fi
		fi
	fi
	echo "1|81|SUCCESS"
	
	#####################################################################################
	#####                                                                           #####
	#####                          create virtual cdrom                            	#####
	#####                                                                           #####
	#####################################################################################
	vadapter_vcd=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"mkvdev -fbo -vadapter ${vadapter_vios}\"" 2> "${error_log}" | awk '{print $1}')
	if [ "$(echo $?)" != "0" ]
	then
		i=0
		while [ $i -lt $pv_len ]
		do
			ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmvdev -vdev ${pv_name[$i]}\"" > /dev/null 2>&1
			i=$(expr $i + 1)
		done
		ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\" && chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id} && chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot} && rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\"" > /dev/null 2>&1
		if [ "$vadapter_vcd" != "" ]
		then
			throwException "$vadapter_vcd" "105064"
		else
			catchException "${error_log}"
			throwException "$error_result" "105064"
		fi
	fi
	echo "1|82|SUCCESS"
	
	#####################################################################################
	#####                                                                           #####
	#####                                mount iso                                	#####
	#####                                                                           #####
	#####################################################################################
	echo "$(date) : mount iso" >> "$out_log"
	mount_result=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"loadopt -disk ${config_iso} -vtd ${vadapter_vcd}\"" 2> "${error_log}")
	if [ "$(echo $?)" != "0" ]
	then
		i=0
		while [ $i -lt $pv_len ]
		do
			ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmvdev -vdev ${pv_name[$i]}\"" > /dev/null 2>&1
			i=$(expr $i + 1)
		done
		ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\" && chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id} && chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot} && rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\"" > /dev/null 2>&1
		if [ "$mount_result" != "" ]
		then
			throwException "$mount_result" "105064"
		else
			catchException "${error_log}"
			throwException "$error_result" "105064"
		fi
	fi
	echo "1|83|SUCCESS"
	
	#####################################################################################
	#####                                                                           #####
	#####                                startup vm                                 #####
	#####                                                                           #####
	#####################################################################################
	lpar_state=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m ${host_name} -r lpar --filter lpar_ids=${lpar_id} -F state")
	if [ "$(echo $?)" != "0" ]
	then
		i=0
		while [ $i -lt $pv_len ]
		do
			ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmvdev -vdev ${pv_name[$i]}\"" > /dev/null 2>&1
			i=$(expr $i + 1)
		done
		ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\" && chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id} && chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot} && rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\"" > /dev/null 2>&1
		if [ "$lpar_state" != "" ]
		then
			throwException "$lpar_state" "105064"
		else
			catchException "${error_log}"
			throwException "$error_result" "105064"
		fi
	fi
	
	if [ "$lpar_state" != "Running" ]
	then
		ssh_result=$(ssh ${hmc_user}@${hmc_ip} "chsysstate -m ${host_name} -r lpar -o on -b norm --id ${lpar_id} -f $lpar_name" 2> "${error_log}")
		if [ "$(echo $?)" != "0" ]
		then
			i=0
			while [ $i -lt $pv_len ]
			do
				ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmvdev -vdev ${pv_name[$i]}\"" > /dev/null 2>&1
				i=$(expr $i + 1)
			done
			ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\" && chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id} && chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot} && rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\"" > /dev/null 2>&1
			if [ "$ssh_result" != "" ]
			then
				throwException "$ssh_result" "105064"
			else
				catchException "${error_log}"
				throwException "$error_result" "105064"
			fi
		fi
		
		while [ "${lpar_state}" != "Running" ]
		do
			sleep 30
			lpar_state=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m ${host_name} -r lpar --filter lpar_ids=${lpar_id} -F state")
			echo "lpar_state=$lpar_state" >> "$out_log"
		done
	fi
	
	date >> "$out_log"
	time=0
	lpar_state=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m ${host_name} -r lpar --filter lpar_ids=${lpar_id} -F state")
	while [ "${lpar_state}" != "Not Activated" ]
	do
		sleep 15
		time=$(expr $time + 15)
		if [ $time -gt 600 ]
		then
			break
		fi
		lpar_state=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m ${host_name} -r lpar --filter lpar_ids=${lpar_id} -F state")
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
	ssh_result=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"unloadopt -vtd ${vadapter_vcd}\"" 2> "${error_log}")
	if [ "$(echo $?)" != "0" ]
	then
		i=0
		while [ $i -lt $pv_len ]
		do
			ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmvdev -vdev ${pv_name[$i]}\"" > /dev/null 2>&1
			i=$(expr $i + 1)
		done
		ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_name} --id ${vios_id} -c \"rmdev -dev $vadapter_vios\" && chsyscfg -m ${host_name} -r prof -i virtual_scsi_adapters-=${max_slot}/server/${lpar_id}//2/0,name=${vios_name},lpar_id=${vios_id} && chhwres -r virtualio -m ${host_name} -o r --id ${vios_id} --rsubtype scsi -s ${max_slot} && rmsyscfg -r lpar -m ${host_name} -n \"${lpar_name}\"" > /dev/null 2>&1
		if [ "$ssh_result" != "" ]
		then
			throwException "$ssh_result" "105064"
		else
			catchException "${error_log}"
			throwException "$error_result" "105064"
		fi
	fi
	echo "1|95|SUCCESS"
	
	#####################################################################################
	#####                                                                           #####
	#####                               shutdown vm                                	#####
	#####                                                                           #####
	#####################################################################################
	lpar_state=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m ${host_name} -r lpar --filter lpar_ids=${lpar_id} -F state")
	if [ "$lpar_state" != "Not Activated" ]
	then
		ssh ${hmc_user}@${hmc_ip} "chsysstate -m ${host_name} -r lpar -o shutdown --id ${lpar_id} --immed"
	fi
fi

if [ "$log_flag" == "0" ]
then
	rm -f "${error_log}" 2> /dev/null
	rm -f "$out_log" 2> /dev/null
fi
rm -f ${cdrom_path}/${config_iso} 2> /dev/null
rm -f ${ovf_xml} 2> /dev/null
rm -f ${template_path}/${config_iso} 2> /dev/null

echo "1|100|SUCCESS"

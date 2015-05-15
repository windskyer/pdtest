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
		ssh ${ivm_user}@${ivm_ip} "rm -f ${cdrom_path}/${config_iso}" 2> /dev/null
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
					ivm_ip=$param;;
			1)
					j=2;        
					ivm_user=$param;;
			2)
					j=3;
					lpar_name=$param;;
			3)
					j=4;
					proc_mode=$param;;
			4)
					j=5;
					min_proc_units=$param;;
			5)
					j=6;
					desired_proc_units=$param;;
			6)
					j=7;
					max_proc_units=$param;;
			7)
					j=8;
					min_procs=$param;;
			8)
					j=9;
					desired_procs=$param;;
			9)
					j=10;
					max_procs=$param;;
			10)
					j=11;
					min_mem=$param;;
			11)
					j=12;
					desired_mem=$param;;
			12)
					j=13;
					max_mem=$param;;
			13)
					j=14;
					sharing_mode=$param;;
			14)
					j=15;
					template_path=$param;;
			15)
					j=16;
					template_name=$param;;
			16)
					j=17;
					ip_address=$param;;
			17)
					j=18;
					netmask=$param;;
			18)
					j=19;
					gateway=$param;;
			19)
					j=20;
					host_name=$param;;
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

if [ "$ivm_ip" == "" ]
then
	throwException "IP is null" "105005"
fi

if [ "$ivm_user" == "" ]
then
	throwException "User name is null" "105005"
fi

if [ "$lpar_name" == "" ]
then
	throwException "Lpar name is null" "105005"
fi

log_flag=$(cat scrpits.properties 2> /dev/null | grep "LOG=" | awk -F"=" '{print $2}')
if [ "$log_flag" == "" ]
then
	log_flag=0
fi

DateNow=$(date +%Y%m%d%H%M%S)
random=$(perl -e 'my $random = int(rand(9999)); print "$random";')
out_log="out_createvm_nulti_disk_${lpar_name}_${DateNow}_${random}.log"
error_log="error_createvm_nulti_disk_${lpar_name}_${DateNow}_${random}.log"
ovf_xml="config_${DateNow}_${random}.xml"
config_iso="config_${DateNow}_${random}.iso"
cdrom_path="/var/vio/VMLibrary"

if [ "$host_name" == "" ]
then
	host_name=$lpar_name
fi

#####################################################################################
#####                                                                           #####
#####                           check template                                  #####
#####                                                                           #####
#####################################################################################
echo "$(date) : check template" > "$out_log"
img=$(ssh ${ivm_user}@${ivm_ip} "cat ${template_path}/${template_name}/${template_name}.cfg" 2> "${error_log}" | grep "files=" | awk -F"=" '{print $2}')
catchException "${error_log}"
if [ "$error_result" != "" ]
then
	throwException "The template file can not be found." "105009"
fi
# img=$(echo "$tmp_details" | grep "files=" | awk -F"=" '{print $2}')
if [ "$img" != "" ]
then
	img_num=$(echo "$img" | awk -F"," '{print NF}')
	if [ "$length" != "$img_num" ]
	then
		throwException "The disk number is wrong." "105009"
	fi
	i=0
	echo "$img" | awk -F"," '{for(i=1;i<=NF;i++) print $i}' | while read line
	do
		if [ "X$line" != "X" ]
		then
			tmp_name=$(echo $line | awk -F"|" '{print $1}')
			ls $tmp_name > /dev/null 2> $error_log
			catchException "${error_log}"
			throwException "$error_result" "105009"
			img_[$i]=$tmp_name
			i=$(expr $i + 1)
		fi
	done
else
	throwException "The disk can not be found." "105009"
fi
echo "1|5|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                       get host serial number                              #####
#####                                                                           #####
#####################################################################################
echo "$(date) : check host serial number" >> "$out_log"
serial_num=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r sys -F serial_num" 2> "${error_log}")
catchException "${error_log}"
throwException "$error_result" "105060"
echo "serial_num=${serial_num}" >> "$out_log"
echo "1|6|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                               create vm                                   #####
#####                                                                           #####
#####################################################################################
echo "$(date) : create vm" >> "$out_log"
if [ "$proc_mode" != "ded" ]
then
	ssh ${ivm_user}@${ivm_ip} "mksyscfg -r lpar -i name=\"${lpar_name}\",max_virtual_slots=30,lpar_env=aixlinux,auto_start=0,profile_name=\"${lpar_name}\",proc_mode=${proc_mode},min_procs=${min_procs},min_proc_units=${min_proc_units},desired_procs=${desired_procs},desired_proc_units=${desired_proc_units},max_procs=${max_procs},max_proc_units=${max_proc_units},sharing_mode=${sharing_mode},uncap_weight=127,min_mem=${min_mem},desired_mem=${desired_mem},max_mem=${max_mem}" 2> "${error_log}"
else
	ssh ${ivm_user}@${ivm_ip} "mksyscfg -r lpar -i name=\"${lpar_name}\",max_virtual_slots=30,lpar_env=aixlinux,auto_start=0,profile_name=\"${lpar_name}\",proc_mode=${proc_mode},min_procs=${min_procs},desired_procs=${desired_procs},max_procs=${max_procs},sharing_mode=${sharing_mode},min_mem=${min_mem},desired_mem=${desired_mem},max_mem=${max_mem}" 2> "${error_log}"
fi
catchException "${error_log}"
throwException "$error_result" "105012"
echo "1|7|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                             check lpar id                                 #####
#####                                                                           #####
#####################################################################################
echo "$(date) : check lpar id" >> "$out_log"
lpar_id=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar -F lpar_id --filter lpar_names=\"${lpar_name}\"" 2> "${error_log}")
catchException "${error_log}"
throwException "$error_result" "105061"
echo "$(date) : lpar_id : ${lpar_id}" >> "$out_log"
echo "1|8|SUCCESS"


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
	ssh ${ivm_user}@${ivm_ip} "chhwres -r virtualio --rsubtype eth --id $lpar_id -o a -s $slot -a ieee_virtual_eth=0,port_vlan_id=${vlan_id[$i]},is_trunk=0" 2> "${error_log}"
	catchException "${error_log}"
	if [ "${error_result}" != "" ]
	then
		ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
		throwException "$error_result" "105013"
	fi
	i=$(expr $i + 1)
	slot=$(expr $slot + 1)
done
echo "1|9|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                            get eth mac address                            #####
#####                                                                           #####
#####################################################################################
echo "$(date) : get eth mac address" >> "$out_log"
mac_address=$(ssh ${ivm_user}@${ivm_ip} "lshwres -r virtualio --rsubtype eth --level lpar --filter lpar_ids=${lpar_id},slots=15 -F mac_addr" 2> "${error_log}")
catchException "${error_log}"
if [ "${error_result}" != "" ]
then
	ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
	throwException "$error_result" "105062"
fi
mac_1=$(echo $mac_address | cut -c1-2)
mac_2=$(echo $mac_address | cut -c3-4)
mac_3=$(echo $mac_address | cut -c5-6)
mac_4=$(echo $mac_address | cut -c7-8)
mac_5=$(echo $mac_address | cut -c9-10)
mac_6=$(echo $mac_address | cut -c11-12)
mac_address=${mac_1}":"${mac_2}":"${mac_3}":"${mac_4}":"${mac_5}":"${mac_6}
echo "1|10|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                  get virtual_scsi_adapters server id                      #####
#####                                                                           #####
#####################################################################################
echo "$(date) : Get virtual_scsi_adapters server id" >> "$out_log"
server_vscsi_id=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r prof --filter lpar_ids=${lpar_id} -F virtual_scsi_adapters" | awk -F'/' '{print $5}' 2> "${error_log}")
catchException "${error_log}"
throwException "$error_result" "105063"
echo "server_vscsi_id=${server_vscsi_id}" >> "$out_log"
echo "1|11|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                            get vios' adapter                              #####
#####                                                                           #####
#####################################################################################
echo "$(date) : get vios' adapter" >> "$out_log"
vadapter_vios=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -all -fmt :" | grep ${serial_num} | grep "C${server_vscsi_id}:" | awk -F":" '{print $1}' 2> "${error_log}")
catchException "${error_log}"
throwException "$error_result" "105064"
echo "vadapter_vios=${vadapter_vios}" >> "$out_log"
echo "1|12|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                                dd copy                                    #####
#####                                                                           #####
#####################################################################################
i=0
progress=12
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
		vg_free_size=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsvg ${lv_vg[$i]} -field freepps -fmt :" 2> ${error_log} | awk '{print substr($2,2,length($2))}')
		catchException "${error_log}"
		time=0
		while [ "$(echo ${error_result} | grep "Volume group is locked")" != "" ]||[ "$(echo ${error_result} | grep "ODM lock")" != "" ]
		do
			sleep 1
			vg_free_size=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsvg ${lv_vg[$i]} -field freepps -fmt :" 2> ${error_log} | awk '{print substr($2,2,length($2))}')
			catchException "${error_log}"
			time=$(expr $time + 1)
			if [ $time -gt 30 ]
			then
				break
			fi
		done
		if [ "$error_result" != "" ]
		then
			ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
		fi
		throwException "$error_result" "105010"
			
		if [ $vg_free_size -lt ${lv_size[$i]} ]
		then
			ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
			throwException "Storage ${lv_vg[$i]} is not enough !" "105010"
		fi
		progress=$(expr $progress + 1)
		echo "1|$progress|SUCCESS"
		
		#####################################################################################
		#####                                                                           #####
		#####                              create lv                                    #####
		#####                                                                           #####
		#####################################################################################
		echo "$(date) : create lv ${lpar_name}" >> "$out_log"
		lv_name[$i]=$(ssh ${ivm_user}@${ivm_ip} "ioscli mklv ${lv_vg[$i]} ${lv_size[$i]}M" 2> "${error_log}")
		dd_name[$i]=${lv_name[$i]}
		catchException "${error_log}"
		time=0
		while [ "$(echo ${error_result} | grep "Volume group is locked")" != "" ]
		do
			sleep 1
			lv_name[$i]=$(ssh ${ivm_user}@${ivm_ip} "ioscli mklv ${lv_vg[$i]} ${lv_size[$i]}M" 2> "${error_log}")
			catchException "${error_log}"
			time=$(expr $time + 1)
			if [ $time -gt 30 ]
			then
				break
			fi
		done
		if [ "$error_result" != "" ]
		then
			ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
			j=0
			while [ $j -lt $i ]
			do
				if [ "${lv_vg[$j]}" != "" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
				fi
				j=$(expr $j + 1)
			done
		fi
		throwException "$error_result" "105011"
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
		lspv_name=$(ssh ${ivm_user}@${ivm_ip} "ioscli lspv -avail -field name -fmt :" 2> ${error_log})
		catchException "${error_log}"
		if [ "$error_result" != "" ]
		then
			ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
			j=0
			while [ $j -lt $i ]
			do
				if [ "${lv_vg[$j]}" != "" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
				fi
				j=$(expr $j + 1)
			done
		fi
		throwException "$error_result" "105067"
		pv_map=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -all -type disk -field backing -fmt :" 2> ${error_log}  | awk -F":" '{for(i=1;i<=NF;i++) print $i}')
		catchException "${error_log}"
		if [ "$error_result" != "" ]
		then
			ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
			j=0
			while [ $j -lt $i ]
			do
				if [ "${lv_vg[$j]}" != "" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
				fi
				j=$(expr $j + 1)
			done
		fi
		throwException "$error_result" "105067"
		if [ "$(echo $pv_map | sed 's/://')" != "" ]
		then
			echo "$pv_map" | awk -F":" '{for(i=1;i<=NF;i++) print $i}' | while read line
			do
				if [ "$line" != "" ]
				then
					lspv_name=$(echo $lspv_name | awk '{ for(i=1;i<=NF;i++) { if($i != pv_name) { print $i } } }' pv_name="$line")
				fi
			done
		fi
		
		free_flag=0
		for pv in $lspv_name
		do
			if [ "${pv_name[$i]}" == "$pv" ]
			then
				free_flag=1
			fi
		done
		if [ "$free_flag" == "0" ]
		then
			ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
			j=0
			while [ $j -lt $i ]
			do
				if [ "${lv_vg[$j]}" != "" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
				fi
				j=$(expr $j + 1)
			done
			throwException "The ${pv_name[$i]} is in used." "105067"
		fi
		progress=$(expr $progress + 1)
		echo "1|$progress|SUCCESS"
	fi
	
	#####################################################################################
	#####                                                                           #####
	#####                                 dd copy                                   #####
	#####                                                                           #####
	#####################################################################################
	echo "$(date) : dd copy" >> "$out_log"
	expect ./ssh.exp ${ivm_user} ${ivm_ip} "oem_setup_env|dd if=${img_[$i]} of=/dev/r${dd_name[$i]} bs=10M > /dev/null 2> ${error_log} &" > /dev/null 2>&1
	ps_rlt=$(ssh ${ivm_user}@${ivm_ip} "ps -ef|grep \"dd if=${img_[$i]} of=/dev/r${dd_name[$i]}\" | grep -v grep")
	while [ "${ps_rlt}" != "" ]
	do
		sleep 45
		ps_rlt=$(ssh ${ivm_user}@${ivm_ip} "ps -ef|grep \"dd if=${img_[$i]} of=/dev/r${dd_name[$i]}\" | grep -v grep")
		echo "ps_rlt=$ps_rlt" >> "$out_log"
		progress=$(expr $progress + 1)
		echo "1|$progress|SUCCESS"
	done
	
	dd_rlt=$(ssh ${ivm_user}@${ivm_ip} "cat ${error_log}" 2> /dev/null)
	ssh ${ivm_user}@${ivm_ip} "rm -f ${error_log}" > /dev/null 2>&1
	echo "error_log=$dd_rlt" >> "$out_log"

	if [ "$(echo "${dd_rlt}" | grep -v "records in" | grep -v "records out")" != "" ]
	then
		ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
		j=0
		while [ $j -lt $img_num ]
		do
			if [ "${lv_vg[$j]}" != "" ]
			then
				ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
			fi
			j=$(expr $j + 1)
		done
		throwException "$dd_rlt" "105014"
	fi
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
	mapping_name=$(ssh ${ivm_user}@${ivm_ip} "ioscli mkvdev -vdev ${dd_name[$i]} -vadapter ${vadapter_vios}" 2> "${error_log}")
	catchException "${error_log}"
	time=0
	while [ "$(echo ${error_result} | grep "Volume group is locked")" != "" ]||[ "$(echo ${error_result} | grep "ODM lock")" != "" ]
	do
		sleep 1
		mapping_name=$(ssh ${ivm_user}@${ivm_ip} "ioscli mkvdev -vdev ${dd_name[$i]} -vadapter ${vadapter_vios}" 2> "${error_log}")
		catchException "${error_log}"
		time=$(expr $time + 1)
		if [ $time -gt 30 ]
		then
			break
		fi
	done
	if [ "${error_result}" != "" ]
	then
		ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}" > /dev/null 2>&1
		j=0
		while [ $j -lt $img_num ]
		do
			if [ "${lv_vg[$j]}" != "" ]
			then
				ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
			fi
			j=$(expr $j + 1)
		done
	fi
	throwException "$error_result" "105015"
	i=$(expr $i + 1)
done
echo "1|77|SUCCESS"


# if [ "$ip_address" != "" ]&&[ "$netmask" != "" ]&&[ "$gateway" != "" ]
# then
	#####################################################################################
	#####                                                                           #####
	#####                          create virtual cdrom                            	#####
	#####                                                                           #####
	#####################################################################################
	vadapter_vcd=$(ssh ${ivm_user}@${ivm_ip} "ioscli mkvdev -fbo -vadapter ${vadapter_vios}" 2> "${error_log}" | awk '{print $1}')
	echo "vadapter_vcd==${vadapter_vcd}" >> "$out_log"
	catchException "${error_log}"
	if [ "${error_result}" != "" ]
	then
		ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
		j=0
		while [ $j -lt $img_num ]
		do
			if [ "${lv_vg[$j]}" != "" ]
			then
				ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
			fi
			j=$(expr $j + 1)
		done
	fi
	throwException "$error_result" "105017"
	echo "1|78|SUCCESS"
	
	#####################################################################################
	#####                                                                           #####
	#####                             	create xml                             	    #####
	#####                                                                           #####
	#####################################################################################
	echo "devno=0" > ${ovf_xml}
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
	mkisofs -r -o ${template_path}/${config_iso} ${ovf_xml} > /dev/null 2>&1
	echo "1|80|SUCCESS"
	
	#####################################################################################
	#####                                                                           #####
	#####                             	 copy iso                                 	#####
	#####                                                                           #####
	#####################################################################################
	echo "$(date) : copy iso" >> "$out_log"
	if [ "${template_path}" != "${cdrom_path}" ]
	then
		ssh_out=$(expect ./ssh.exp ${ivm_user} ${ivm_ip} "oem_setup_env|cp ${template_path}/${config_iso} ${cdrom_path}")
		echo "$ssh_out" >> $out_log
		error_result=$(echo "$ssh_out" | sed -n '/cp/,/#/p' | grep -v "cp" | grep -v '#')
		echo $error_result > ${error_log}
		catchException "${error_log}"
		if [ "${error_result}" != "" ]
		then
			ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
			j=0
			while [ $j -lt $img_num ]
			do
				if [ "${lv_vg[$j]}" != "" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
				fi
				j=$(expr $j + 1)
			done
			throwException "$error_result" "105021"
		fi
	fi
	echo "1|81|SUCCESS"
	
	#####################################################################################
	#####                                                                           #####
	#####                                mount iso                                	#####
	#####                                                                           #####
	#####################################################################################
	sleep 10
	mount_result=$(ssh ${ivm_user}@${ivm_ip} "ioscli loadopt -disk ${config_iso} -vtd ${vadapter_vcd}" 2> "${error_log}")
	echo "mount_result==${mount_result}" >> "$out_log"
	catchException "${error_log}"
	if [ "${error_result}" != "" ]
	then
		ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
		j=0
		while [ $j -lt $img_num ]
		do
			if [ "${lv_vg[$j]}" != "" ]
			then
				ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
			fi
			j=$(expr $j + 1)
		done
		throwException "$error_result" "105018"
	fi
	echo "1|82|SUCCESS"
	
	#####################################################################################
	#####                                                                           #####
	#####                                startup vm                                 #####
	#####                                                                           #####
	#####################################################################################
	lpar_state=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar --filter lpar_ids=${lpar_id} -F state" 2> $error_log)
	catchException "${error_log}"
	if [ "${error_result}" != "" ]
	then
		ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
		j=0
		while [ $j -lt $img_num ]
		do
			if [ "${lv_vg[$j]}" != "" ]
			then
				ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
			fi
			j=$(expr $j + 1)
		done
		throwException "$error_result" "105030"
	fi
	if [ "$lpar_state" != "Running" ]
	then
		ssh ${ivm_user}@${ivm_ip} "chsysstate -r lpar -o on --id ${lpar_id}" 2> "${error_log}"
		catchException "${error_log}"
		if [ "${error_result}" != "" ]
		then
			ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
			j=0
			while [ $j -lt $img_num ]
			do
				if [ "${lv_vg[$j]}" != "" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
				fi
				j=$(expr $j + 1)
			done
			throwException "$error_result" "105030"
		fi
		
		time=0
		while [ "${lpar_state}" != "Running" ]
		do
			sleep 15
			time=$(expr $time + 15)
			if [ $time -gt 600 ]
			then
				break
			fi
			lpar_state=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar --filter lpar_ids=${lpar_id} -F state" 2> $error_log)
			catchException "${error_log}"
			if [ "${error_result}" != "" ]
			then
				ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
				j=0
				while [ $j -lt $img_num ]
				do
					if [ "${lv_vg[$j]}" != "" ]
					then
						ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
					fi
					j=$(expr $j + 1)
				done
				throwException "$error_result" "105030"
			fi
			echo "lpar_state=$lpar_state" >> "$out_log"
		done
	fi
	
	date >> "$out_log"
	time=0
	lpar_state=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar --filter lpar_ids=${lpar_id} -F state" 2> $error_log)
	catchException "${error_log}"
	if [ "${error_result}" != "" ]
	then
		ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
		j=0
		while [ $j -lt $img_num ]
		do
			if [ "${lv_vg[$j]}" != "" ]
			then
				ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
			fi
			j=$(expr $j + 1)
		done
		throwException "$error_result" "105030"
	fi
	while [ "${lpar_state}" != "Not Activated" ]
	do
		sleep 15
		time=$(expr $time + 15)
		if [ $time -gt 600 ]
		then
			break
		fi
		lpar_state=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar --filter lpar_ids=${lpar_id} -F state" 2> $error_log)
		catchException "${error_log}"
		if [ "${error_result}" != "" ]
		then
			ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
			j=0
			while [ $j -lt $img_num ]
			do
				if [ "${lv_vg[$j]}" != "" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
				fi
				j=$(expr $j + 1)
			done
			throwException "$error_result" "105030"
		fi
		echo "time==$time" >> "$out_log"
		echo "lpar_state=$lpar_state" >> "$out_log"
	done
	date >> "$out_log"
	
	echo "1|90|SUCCESS"
	
	#####################################################################################
	#####                                                                           #####
	#####                               umount iso                                  #####
	#####                                                                           #####
	#####################################################################################
	ssh ${ivm_user}@${ivm_ip} "ioscli unloadopt -release -vtd ${vadapter_vcd}" 2> "${error_log}"
	catchException "${error_log}"
	if [ "${error_result}" != "" ]
	then
		ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
		j=0
		while [ $j -lt $img_num ]
		do
			if [ "${lv_vg[$j]}" != "" ]
			then
				ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
			fi
			j=$(expr $j + 1)
		done
		throwException "$error_result" "105019"
	fi
	echo "1|95|SUCCESS"
	
	#####################################################################################
	#####                                                                           #####
	#####                               shutdown vm                                	#####
	#####                                                                           #####
	#####################################################################################
	lpar_state=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar --filter lpar_ids=${lpar_id} -F state")
	if [ "$lpar_state" != "Not Activated" ]
	then
		ssh ${ivm_user}@${ivm_ip} "chsysstate -r lpar -o shutdown --id ${lpar_id} --immed" > /dev/null 2>&1
	fi
# fi

if [ "$log_flag" == "0" ]
then
	rm -f "${error_log}" 2> /dev/null
	rm -f "$out_log" 2> /dev/null
fi
ssh ${ivm_user}@${ivm_ip} "rm -f ${cdrom_path}/${config_iso}" 2> /dev/null
rm -f ${ovf_xml} 2> /dev/null
rm -f ${template_path}/${config_iso} 2> /dev/null

echo "1|100|SUCCESS"

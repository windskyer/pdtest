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
                                ivm_ip=$param;;
                        1)
                                j=2;        
                                ivm_user=$param;;
                        2)
                                j=3;
                                lpar_name=$param;;
                        3)
                                j=4;
                                vg_name=$param;;
                        4)
                                j=5;
                                lv_size=$param;;
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
                                vlan_id=$param;;
                        17)
                                j=18;
                                template_path=$param;;
                        18)
                                j=19;
                                template_name=$param;;
                        19)
                                j=20;
                                ip_address=$param;;
                        20)
                                j=21;
                                netmask=$param;;
                        21)
                                j=22;
                                gateway=$param;;
                        22)
                        				j=23;
                        				host_name=$param;;
        esac
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
out_log="out_createvm_${lpar_name}_${DateNow}_${random}.log"
error_log="error_createvm_${lpar_name}_${DateNow}_${random}.log"
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
ssh ${ivm_user}@${ivm_ip} "ls ${template_path}/${template_name}" > /dev/null 2> "${error_log}"
catchException "${error_log}"
if [ "$error_result" != "" ]
then
	throwException "The template file can not be found." "105009"
fi

#####################################################################################
#####                                                                           #####
#####                              check vg                                     #####     
#####                                                                           #####
#####################################################################################
echo "$(date) : check vg" >> "$out_log"
vg_free_size=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsvg ${vg_name} -field freepps -fmt :" 2> ${error_log} | awk '{print substr($2,2,length($2))}')
catchException "${error_log}"
time=0
while [ "$(echo ${error_result} | grep "Volume group is locked")" != "" ]||[ "$(echo ${error_result} | grep "ODM lock")" != "" ]
do
	sleep 1
	vg_free_size=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsvg ${vg_name} -field freepps -fmt :" 2> ${error_log} | awk '{print substr($2,2,length($2))}')
	catchException "${error_log}"
	time=$(expr $time + 1)
	if [ $time -gt 30 ]
	then
		break
	fi
done
throwException "$error_result" "105010"

if [ $vg_free_size -lt $lv_size ]
then
	throwException "Storage space is not enough !" "105010"
fi
echo "1|5|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                              create lv                                    #####
#####                                                                           #####
#####################################################################################
echo "$(date) : create lv ${lpar_name}" >> "$out_log"
lv_name=$(ssh ${ivm_user}@${ivm_ip} "ioscli mklv ${vg_name} ${lv_size}M" 2> "${error_log}")
catchException "${error_log}"
time=0
while [ "$(echo ${error_result} | grep "Volume group is locked")" != "" ]
do
	sleep 1
	lv_name=$(ssh ${ivm_user}@${ivm_ip} "ioscli mklv ${vg_name} ${lv_size}M" 2> "${error_log}")
	catchException "${error_log}"
	time=$(expr $time + 1)
	if [ $time -gt 30 ]
	then
		break
	fi
done
throwException "$error_result" "105011"
echo "1|10|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                       get host serial number                              #####
#####                                                                           #####
#####################################################################################
echo "$(date) : check host serial number" >> "$out_log"
serial_num=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r sys -F serial_num" 2> "${error_log}")
catchException "${error_log}"
if [ "${error_result}" != "" ]
then
	ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name}" > /dev/null 2>&1
fi
throwException "$error_result" "105060"
echo "serial_num=${serial_num}" >> "$out_log"
echo "1|15|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                               create vm                                   #####
#####                                                                           #####
#####################################################################################
echo "$(date) : create vm" >> "$out_log"
if [ "$proc_mode" != "ded" ]
then
	ssh ${ivm_user}@${ivm_ip} "mksyscfg -r lpar -i name=\"${lpar_name}\",lpar_env=aixlinux,auto_start=0,profile_name=\"${lpar_name}\",max_virtual_slots=20,proc_mode=${proc_mode},min_procs=${min_procs},min_proc_units=${min_proc_units},desired_procs=${desired_procs},desired_proc_units=${desired_proc_units},max_procs=${max_procs},max_proc_units=${max_proc_units},sharing_mode=${sharing_mode},uncap_weight=127,min_mem=${min_mem},desired_mem=${desired_mem},max_mem=${max_mem}" 2> "${error_log}"
else
	ssh ${ivm_user}@${ivm_ip} "mksyscfg -r lpar -i name=\"${lpar_name}\",lpar_env=aixlinux,auto_start=0,profile_name=\"${lpar_name}\",max_virtual_slots=20,proc_mode=${proc_mode},min_procs=${min_procs},desired_procs=${desired_procs},max_procs=${max_procs},sharing_mode=${sharing_mode},min_mem=${min_mem},desired_mem=${desired_mem},max_mem=${max_mem}" 2> "${error_log}"
fi
catchException "${error_log}"
if [ "${error_result}" != "" ]
then
	ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name}"  > /dev/null 2>&1
fi
throwException "$error_result" "105012"
echo "1|33|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                             check lpar id                                 #####
#####                                                                           #####
#####################################################################################
echo "$(date) : check lpar id" >> "$out_log"
lpar_id=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar -F lpar_id --filter lpar_names=\"${lpar_name}\"" 2> "${error_log}")
catchException "${error_log}"
if [ "${error_result}" != "" ]
then
	ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar -n \"${lpar_name}\" && ioscli rmlv -f ${lv_name}"  > /dev/null 2>&1
fi
throwException "$error_result" "105061"
echo "$(date) : lpar_id : ${lpar_id}" >> "$out_log"
echo "1|40|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                       create virtual_eth_adapters                         #####
#####                                                                           #####
#####################################################################################
echo "$(date) : create virtual_eth_adapters" >> "$out_log"
sleep 1
ssh ${ivm_user}@${ivm_ip} "chsyscfg -r prof -i virtual_eth_adapters=19/0/${vlan_id}//0/1,lpar_id=${lpar_id}" 2> "${error_log}"
catchException "${error_log}"
if [ "${error_result}" != "" ]
then
	ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id} && ioscli rmlv -f ${lv_name}"  > /dev/null 2>&1
fi
throwException "$error_result" "105013"
echo "1|44|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                            get eth mac address                            #####
#####                                                                           #####
#####################################################################################
echo "$(date) : get eth mac address" >> "$out_log"
mac_address=$(ssh ${ivm_user}@${ivm_ip} "lshwres -r virtualio --rsubtype eth --level lpar --filter lpar_ids=${lpar_id},slots=19 -F mac_addr" 2> "${error_log}")
catchException "${error_log}"
if [ "${error_result}" != "" ]
then
	ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id} && ioscli rmlv -f ${lv_name}"  > /dev/null 2>&1
fi
throwException "$error_result" "105062"
mac_1=$(echo $mac_address | cut -c1-2)
mac_2=$(echo $mac_address | cut -c3-4)
mac_3=$(echo $mac_address | cut -c5-6)
mac_4=$(echo $mac_address | cut -c7-8)
mac_5=$(echo $mac_address | cut -c9-10)
mac_6=$(echo $mac_address | cut -c11-12)
mac_address=${mac_1}":"${mac_2}":"${mac_3}":"${mac_4}:"${mac_5}:"${mac_6}

#####################################################################################
#####                                                                           #####
#####                  get virtual_scsi_adapters server id                      #####
#####                                                                           #####
#####################################################################################
echo "$(date) : Get virtual_scsi_adapters server id" >> "$out_log"
server_vscsi_id=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r prof --filter lpar_ids=${lpar_id} -F virtual_scsi_adapters" | awk -F'/' '{print $5}' 2> "${error_log}")
catchException "${error_log}"
if [ "${error_result}" != "" ]
then
	ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id} && ioscli rmlv -f ${lv_name}"  > /dev/null 2>&1
fi
throwException "$error_result" "105063"
echo "server_vscsi_id=${server_vscsi_id}" >> "$out_log"
echo "1|50|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                            get vios' adapter                              #####
#####                                                                           #####
#####################################################################################
echo "$(date) : get vios' adapter" >> "$out_log"
vadapter_vios=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -all" | grep ${serial_num} | grep "C${server_vscsi_id}" | awk '{print $1}' 2> "${error_log}")
catchException "${error_log}"
if [ "${error_result}" != "" ]
then
	ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id} && ioscli rmlv -f ${lv_name}"  > /dev/null 2>&1
fi
throwException "$error_result" "105064"
echo "vadapter_vios=${vadapter_vios}" >> "$out_log"
echo "1|53|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                                 dd copy                                   #####
#####                                                                           #####
#####################################################################################
echo "$(date) : dd copy" >> "$out_log"
expect ./ssh.exp ${ivm_user} ${ivm_ip} "oem_setup_env|dd if=${template_path}/${template_name} of=/dev/r${lv_name} bs=10M 2> ${error_log} &" > /dev/null 2>&1
catchException "${error_log}"
if [ "${error_result}" != "" ]
then
	ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id} && ioscli rmlv -f ${lv_name}"  > /dev/null 2>&1
fi
throwException "$error_result" "105014"


#####################################################################################
#####                                                                           #####
#####                             check dd copy                                 #####
#####                                                                           #####
#####################################################################################
ps_rlt=$(ssh ${ivm_user}@${ivm_ip} "ps -ef|grep \"dd if=${template_path}/${template_name} of=/dev/r${lv_name}\" | grep -v grep")
#echo "ps_rlt=$ps_rlt"
while [ "${ps_rlt}" != "" ]
do
	sleep 30
	ps_rlt=$(ssh ${ivm_user}@${ivm_ip} "ps -ef|grep \"dd if=${template_path}/${template_name} of=/dev/r${lv_name}\" | grep -v grep")
	echo "ps_rlt=$ps_rlt" >> "$out_log"
done

dd_rlt=$(ssh ${ivm_user}@${ivm_ip} "cat \"${error_log}\"")
ssh ${ivm_user}@${ivm_ip} "rm -f \"${error_log}\""
echo "error_log=$dd_rlt" >> "$out_log"

if [ "$(echo "${dd_rlt}" | grep -v "records in" | grep -v "records out")" != "" ]
then
	ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id} && ioscli rmlv -f ${lv_name}"  > /dev/null 2>&1
	throwException "$dd_rlt" "105014"
fi
echo "1|75|SUCCESS"

#new add begin
ddin=$(echo "${dd_rlt}" | grep "records in" | awk '{print $1}')
ddout=$(echo "${dd_rlt}" | grep "records out" | awk '{print $1}')
if [ "${ddin}" != "${ddout}" ]
then
    throwException "dd copy failed,not complete." "105014"
else
    ddin_block=$(echo "${dd_rlt}" | grep "records in" | awk '{print $1}'  | awk -F "+" '{print $1}')
    ddin_rest=$(echo "${dd_rlt}" | grep "records in" | awk '{print $1}'  | awk -F "+" '{print $2}')
    
    if [ "${ddin_rest}" == "0" ]
    then    
      ddcheck=$(echo "$ddin_block" | awk '{print $1*10}')
    else
      ddcheck=$(echo "$ddin_block" | awk '{print ($1+1)*10}')
    fi
    
    temsize=$(ls -l $template_path/$template_name | awk '{print $5/1024/1024}')
    if [ "${ddcheck}" -lt "${temsize}" ]
    then
        throwException "dd copy failed." "105014"
    fi
fi
#new add end
#####################################################################################
#####                                                                           #####
#####                             create mapping                                #####
#####                                                                           #####
#####################################################################################
echo "$(date) : create mapping" >> "$out_log"
mapping_name=$(ssh ${ivm_user}@${ivm_ip} "ioscli mkvdev -vdev ${lv_name} -vadapter ${vadapter_vios}" 2> "${error_log}")
catchException "${error_log}"
time=0
while [ "$(echo ${error_result} | grep "Volume group is locked")" != "" ]||[ "$(echo ${error_result} | grep "ODM lock")" != "" ]
do
	sleep 1
	mapping_name=$(ssh ${ivm_user}@${ivm_ip} "ioscli mkvdev -vdev ${lv_name} -vadapter ${vadapter_vios}" 2> "${error_log}")
	catchException "${error_log}"
	time=$(expr $time + 1)
	if [ $time -gt 30 ]
	then
		break
	fi
done
if [ "${error_result}" != "" ]
then
	ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id} && ioscli rmlv -f ${lv_name}"  > /dev/null 2>&1
fi
throwException "$error_result" "105015"
echo "1|77|SUCCESS"

if [ "$ip_address" != "" ]&&[ "$netmask" != "" ]&&[ "$gateway" != "" ]
then
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
		ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id} && ioscli rmlv -f ${lv_name}"  > /dev/null 2>&1
	fi
	throwException "$error_result" "105017"
	echo "1|78|SUCCESS"
	
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
		error_result=$(echo "$ssh_out" | sed -n '/cp/,/#/p' | grep -v "cp" | grep -v '#')
		echo $error_result > ${error_log}
		catchException "${error_log}"
		throwException "$error_result" "105021"
	fi
	echo "1|81|SUCCESS"
	
	#####################################################################################
	#####                                                                           #####
	#####                                mount iso                                	#####
	#####                                                                           #####
	#####################################################################################
	mount_result=$(ssh ${ivm_user}@${ivm_ip} "ioscli loadopt -disk ${config_iso} -vtd ${vadapter_vcd}" 2> "${error_log}")
	echo "mount_result==${mount_result}" >> "$out_log"
	catchException "${error_log}"
	if [ "${error_result}" != "" ]
	then
		ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id} && ioscli rmlv -f ${lv_name}"  > /dev/null 2>&1
	fi
	throwException "$error_result" "105018"
	echo "1|82|SUCCESS"
	
	#####################################################################################
	#####                                                                           #####
	#####                                startup vm                                 #####
	#####                                                                           #####
	#####################################################################################
	lpar_state=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar --filter lpar_ids=${lpar_id} -F state")
	if [ "$lpar_state" != "Running" ]
	then
		ssh ${ivm_user}@${ivm_ip} "chsysstate -r lpar -o on --id ${lpar_id}" 2> "${error_log}"
		catchException "${error_log}"
		if [ "${error_result}" != "" ]
		then
			ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id} && ioscli rmlv -f ${lv_name}"  > /dev/null 2>&1
		fi
		throwException "$error_result" "105030"
		
		while [ "${lpar_state}" != "Running" ]
		do
			sleep 30
			lpar_state=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar --filter lpar_ids=${lpar_id} -F state")
			echo "lpar_state=$lpar_state" >> "$out_log"
		done
	fi
	
	date >> "$out_log"
	time=0
	lpar_state=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar --filter lpar_ids=${lpar_id} -F state")
	while [ "${lpar_state}" != "Not Activated" ]
	do
		sleep 15
		time=$(expr $time + 15)
		if [ $time -gt 600 ]
		then
			break
		fi
		lpar_state=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar --filter lpar_ids=${lpar_id} -F state")
		echo "time==$time" >> "$out_log"
		echo "lpar_state=$lpar_state" >> "$out_log"
	done
	date >> "$out_log"
	
	#sleep 180

	
	echo "1|90|SUCCESS"
	
	#####################################################################################
	#####                                                                           #####
	#####                               umount iso                                	#####
	#####                                                                           #####
	#####################################################################################
	ssh ${ivm_user}@${ivm_ip} "ioscli unloadopt -vtd ${vadapter_vcd}" 2> "${error_log}"
	catchException "${error_log}"
	if [ "${error_result}" != "" ]
	then
		ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id} && ioscli rmlv -f ${lv_name}"  > /dev/null 2>&1
	fi
	throwException "$error_result" "105019"
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

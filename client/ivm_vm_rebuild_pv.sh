#!/usr/bin/ksh

. ./ivm_function.sh

echo "1|0|SUCCESS"

catchException() {
        
	error_result=$(cat $1)
	          
}

rollback_1() {
	ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar -n ${lpar_name}"  > /dev/null 2>&1
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
		ssh ${ivm_user}@${ivm_ip} "rm -f ${cdrom_path}/${config_iso}" > /dev/null 2>&1
		ssh ${ivm_user}@${ivm_ip} "rm -f ${ovf_cfg}" > /dev/null 2>&1
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
					auto_start=$param;;
        esac
done

pv_len=0
for param in $(echo $2 | awk -F"|" '{for(i=1;i<=NF;i++) print $i}')
do
		if [ "$param" != "" ]
		then
			pv_snum[$pv_len]=$(echo $param | awk -F"," '{print $1}')
			pv_name[$pv_len]=$(echo $param | awk -F"," '{print $2}')
			pv_len=$(expr $pv_len + 1)
		fi
done

i=0
while [ $i -lt $pv_len ]
do
	j=$i
	while [ $j -lt $pv_len ]
	do
		if [ ${pv_snum[$i]} -gt ${pv_snum[$j]} ]
		then
			temp=${pv_name[$j]}
			pv_name[$j]=${pv_name[$i]}
			pv_name[$i]=$temp
		fi
		j=$(expr $j + 1)
	done
	i=$(expr $i + 1)
done


vlan_len=0
for param in $(echo $3 |awk -F"|" '{for(i=1;i<=NF;i++) print $i}')
do
	if [ "$param" != "" ]
	then
		vlan_id[$vlan_len]=$param
		vlan_len=$(expr $vlan_len + 1)
	fi
done

if [ "$ivm_ip" == "" ]
then
	throwException "IP is null" "105053"
fi

if [ "$ivm_user" == "" ]
then
	throwException "User name is null" "105053"
fi

if [ "$lpar_name" == "" ]
then
	throwException "Lpar name is null" "105053"
fi

log_flag=$(cat scrpits.properties 2> /dev/null | grep "LOG=" | awk -F"=" '{print $2}')
if [ "$log_flag" == "" ]
then
	log_flag=0
fi

DateNow=$(date +%Y%m%d%H%M%S)
random=$(perl -e 'my $random = int(rand(9999)); print "$random";')
out_log="${path_log}/out_ivm_vm_rebuild_pv_${DateNow}_${random}.log"
error_log="${path_log}/error_ivm_vm_rebuild_pv_${DateNow}_${random}.log"
ovf_cfg="rebuild_config_${DateNow}_${random}.cfg"
config_iso="config_${DateNow}_${random}.iso"
cdrom_path="/var/vio/VMLibrary"

log_debug $LINENO "$0 $*"

if [ "$host_name" == "" ]
then
	host_name=$lpar_name
fi

# check authorized and repair error authorized
check_authorized ${ivm_ip} ${ivm_user}
#check NFSServer status and restart that had stop NFSServer proc
nfs_server_check ${ivm_ip} ${ivm_user}

#####################################################################################
#####                                                                           #####
#####                       get host serial number                              #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "check host serial number"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"lssyscfg -r sys -F serial_num\""
serial_num=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r sys -F serial_num" 2>&1)
if [ $? -ne 0 ]
then
	throwException "$serial_num" "105060"
fi
log_debug $LINENO "serial_num=${serial_num}"
echo "1|6|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                               create vm                                   #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "create vm"
if [ "$proc_mode" != "ded" ]
then
	log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"mksyscfg -r lpar -i name=\"${lpar_name}\",max_virtual_slots=30,lpar_env=aixlinux,auto_start=$auto_start,profile_name=\"${lpar_name}\",max_virtual_slots=20,proc_mode=${proc_mode},min_procs=${min_procs},min_proc_units=${min_proc_units},desired_procs=${desired_procs},desired_proc_units=${desired_proc_units},max_procs=${max_procs},max_proc_units=${max_proc_units},sharing_mode=${sharing_mode},uncap_weight=127,min_mem=${min_mem},desired_mem=${desired_mem},max_mem=${max_mem}\""
	result=$(ssh ${ivm_user}@${ivm_ip} "mksyscfg -r lpar -i name=\"${lpar_name}\",max_virtual_slots=30,lpar_env=aixlinux,auto_start=$auto_start,profile_name=\"${lpar_name}\",max_virtual_slots=20,proc_mode=${proc_mode},min_procs=${min_procs},min_proc_units=${min_proc_units},desired_procs=${desired_procs},desired_proc_units=${desired_proc_units},max_procs=${max_procs},max_proc_units=${max_proc_units},sharing_mode=${sharing_mode},uncap_weight=127,min_mem=${min_mem},desired_mem=${desired_mem},max_mem=${max_mem}" 2>&1)
else
	log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"mksyscfg -r lpar -i name=\"${lpar_name}\",max_virtual_slots=30,lpar_env=aixlinux,auto_start=$auto_start,profile_name=\"${lpar_name}\",max_virtual_slots=20,proc_mode=${proc_mode},min_procs=${min_procs},desired_procs=${desired_procs},max_procs=${max_procs},sharing_mode=${sharing_mode},min_mem=${min_mem},desired_mem=${desired_mem},max_mem=${max_mem}\""
	result=$(ssh ${ivm_user}@${ivm_ip} "mksyscfg -r lpar -i name=\"${lpar_name}\",max_virtual_slots=30,lpar_env=aixlinux,auto_start=$auto_start,profile_name=\"${lpar_name}\",max_virtual_slots=20,proc_mode=${proc_mode},min_procs=${min_procs},desired_procs=${desired_procs},max_procs=${max_procs},sharing_mode=${sharing_mode},min_mem=${min_mem},desired_mem=${desired_mem},max_mem=${max_mem}" 2>&1)
fi
if [ $? -ne 0 ]
then
	throwException "$result" "105012"
fi
log_debug $LINENO "result=${result}"
echo "1|7|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                             check lpar id                                 #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "check lpar id"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"lssyscfg -r lpar -F lpar_id --filter lpar_names=\"${lpar_name}\"\""
lpar_id=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar -F lpar_id --filter lpar_names=\"${lpar_name}\"" 2>&1)
if [ $? -ne 0 ]
then
	rollback_1
	throwException "$lpar_id" "105061"
fi
log_debug $LINENO "lpar_id=${lpar_id}"
echo "1|8|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                       create virtual_eth_adapters                         #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "create virtual_eth_adapters"
sleep 1
i=0
slot=15
while [ $i -lt $vlan_len ]
do
	if [ "$i" == "0" ]
	then
		log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"chsyscfg -r prof -i virtual_eth_adapters=${slot}/0/${vlan_id[$i]}//0/1,lpar_id=${lpar_id}\""
		result=$(ssh ${ivm_user}@${ivm_ip} "chsyscfg -r prof -i virtual_eth_adapters=${slot}/0/${vlan_id[$i]}//0/1,lpar_id=${lpar_id}" 2>&1)
	else
		log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"chsyscfg -r prof -i virtual_eth_adapters+=${slot}/0/${vlan_id[$i]}//0/1,lpar_id=${lpar_id}\""
		result=$(ssh ${ivm_user}@${ivm_ip} "chsyscfg -r prof -i virtual_eth_adapters+=${slot}/0/${vlan_id[$i]}//0/1,lpar_id=${lpar_id}" 2>&1)
	fi
	#if Power8 cpu,create veth have "Unhandled firmware error"
	if [ $? -ne 0 ] && [ "$(echo "$result" | grep "VIOSE03FF0000-0149")" == "" ]
	then
		rollback_1
		throwException "$result" "105013"
	fi
	slot_num[$i]=$slot
	i=$(expr $i + 1)
	slot=$(expr $slot + 1)
done
log_debug $LINENO "result=${result}"
echo "1|9|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                            get eth mac address                            #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "get eth mac address"
i=0
while [ $i -lt $vlan_len ]
do
	log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"lshwres -r virtualio --rsubtype eth --level lpar --filter lpar_ids=${lpar_id},slots=${slot_num[$i]} -F mac_addr\""
	mac_address=$(ssh ${ivm_user}@${ivm_ip} "lshwres -r virtualio --rsubtype eth --level lpar --filter lpar_ids=${lpar_id},slots=${slot_num[$i]} -F mac_addr" 2>&1)
	if [ $? -ne 0 ]
	then
		rollback_1
		throwException "$mac_address" "105062"
	fi
	
	mac_1=$(echo $mac_address | cut -c1-2)
	mac_2=$(echo $mac_address | cut -c3-4)
	mac_3=$(echo $mac_address | cut -c5-6)
	mac_4=$(echo $mac_address | cut -c7-8)
	mac_5=$(echo $mac_address | cut -c9-10)
	mac_6=$(echo $mac_address | cut -c11-12)
	mac_address[$i]=${mac_1}":"${mac_2}":"${mac_3}":"${mac_4}":"${mac_5}":"${mac_6}
	log_debug $LINENO "mac_address=${mac_address[$i]}"
	i=$(expr $i + 1)
done
echo "1|10|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                  get virtual_scsi_adapters server id                      #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "Get virtual_scsi_adapters server id"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"lssyscfg -r prof --filter lpar_ids=${lpar_id} -F virtual_scsi_adapters\""
server_vscsi_id=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r prof --filter lpar_ids=${lpar_id} -F virtual_scsi_adapters" 2>&1)
if [ $? -ne 0 ]
then
	rollback_1
	throwException "$server_vscsi_id" "105063"
fi
server_vscsi_id=$(echo $server_vscsi_id | awk -F'/' '{print $5}')
log_debug $LINENO "server_vscsi_id=${server_vscsi_id}"
echo "1|11|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                            get vios' adapter                              #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "get vios' adapter"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli lsmap -all -fmt :\""
vadapter_vios=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -all -fmt :" 2>&1)
if [ $? -ne 0 ]
then
	rollback_1
	throwException "$vadapter_vios" "105064"
fi
vadapter_vios=$(echo "$vadapter_vios" | grep ${serial_num} | grep "C${server_vscsi_id}:" | awk -F":" '{print $1}')
log_debug $LINENO "vadapter_vios=${vadapter_vios}"
echo "1|12|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                             create mapping                                #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "create mapping"
i=0
while [ $i -lt $pv_len ]
do
	log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli mkvdev -vdev ${pv_name[$i]} -vadapter ${vadapter_vios}\""
	mapping_name=$(ssh ${ivm_user}@${ivm_ip} "ioscli mkvdev -vdev ${pv_name[$i]} -vadapter ${vadapter_vios}" 2>&1)
	if [ $? -ne 0 ]
	then
		rollback_1
		throwException "$mapping_name" "105015"
	fi
	i=$(expr $i + 1)
done
log_debug $LINENO "mapping_name=${mapping_name}"
echo "1|77|SUCCESS"

######################################################################################
######                                                                           #####
######                          check vmlibrary		                             #####
######                                                                           #####
######################################################################################
check_repo

#####################################################################################
#####                                                                           #####
#####                          create virtual cdrom                            	#####
#####                                                                           #####
#####################################################################################
log_info $LINENO "create virtual cdrom"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli mkvdev -fbo -vadapter ${vadapter_vios}\""
vadapter_vcd=$(ssh ${ivm_user}@${ivm_ip} "ioscli mkvdev -fbo -vadapter ${vadapter_vios}" 2>&1)
if [ $? -ne 0 ]
then
	rollback_1
	throwException "$vadapter_vcd" "105017"
fi
vadapter_vcd=$(echo $vadapter_vcd | awk '{print $1}')
log_debug $LINENO "vadapter_vcd=${vadapter_vcd}"
echo "1|78|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                             	create cfg                             	    #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "create cfg"
command_line="oem_setup_env"
i=0
while [ $i -lt $vlan_len ]
do
	command_line=$command_line"|echo \"macaddr=${mac_address[$i]}\" >> ${ovf_cfg}"
	i=$(expr $i + 1)
done
log_debug $LINENO "CMD:expect ./ssh.exp ${ivm_user} ${ivm_ip} \"$command_line\""
result=$(expect ./ssh.exp ${ivm_user} ${ivm_ip} "$command_line" 2>&1)
log_debug $LINENO "result=${result}"
echo "1|79|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                             	create iso                                	#####
#####                                                                           #####
#####################################################################################
log_info $LINENO "create iso"
log_debug $LINENO "CMD:expect ./ssh.exp ${ivm_user} ${ivm_ip} \"oem_setup_env|mkisofs -r -o ${cdrom_path}/${config_iso} ${ovf_cfg}\""
result=$(expect ./ssh.exp ${ivm_user} ${ivm_ip} "oem_setup_env|mkisofs -r -o ${cdrom_path}/${config_iso} ${ovf_cfg}" 2>&1)
if [ $? -ne 0 ]
then
	rollback_1
	throwException "$result" "105221"
fi
log_debug $LINENO "result=${result}"
echo "1|80|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                                mount iso                                	#####
#####                                                                           #####
#####################################################################################
log_info $LINENO "mount iso"
sleep 10
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli loadopt -disk ${config_iso} -vtd ${vadapter_vcd}\""
mount_result=$(ssh ${ivm_user}@${ivm_ip} "ioscli loadopt -disk ${config_iso} -vtd ${vadapter_vcd}" 2>&1)
if [ $? -ne 0 ]
then
	rollback_1
	throwException "$mount_result" "105018"
fi
log_debug $LINENO "mount_result=${mount_result}"
echo "1|82|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                                startup vm                                 #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "startup vm"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"lssyscfg -r lpar --filter lpar_ids=${lpar_id} -F state\""
lpar_state=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar --filter lpar_ids=${lpar_id} -F state")
log_debug $LINENO "lpar_state=${lpar_state}"
if [ "$lpar_state" != "Running" ]
then
	log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"chsysstate -r lpar -o on --id ${lpar_id}\""
	result=$(ssh ${ivm_user}@${ivm_ip} "chsysstate -r lpar -o on --id ${lpar_id}" 2>&1)
	if [ $? -ne 0 ]
	then
		rollback_1
		throwException "$result" "105030"
	fi
	
	while [ "${lpar_state}" != "Running" ]
	do
		log_info $LINENO "sleep 5"
		sleep 5
		lpar_state=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar --filter lpar_ids=${lpar_id} -F state")
		log_info $LINENO "lpar_state=$lpar_state"
	done
fi

time=0
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"lssyscfg -r lpar --filter lpar_ids=${lpar_id} -F state\""
lpar_state=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar --filter lpar_ids=${lpar_id} -F state")
while [ "${lpar_state}" != "Not Activated" ]
do
	log_info $LINENO "sleep 5"
	sleep 5
	time=$(expr $time + 5)
	if [ $time -gt 600 ]
	then
		break
	fi
	lpar_state=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar --filter lpar_ids=${lpar_id} -F state")
	log_info $LINENO "time==$time"
	log_info $LINENO "lpar_state=$lpar_state"
done

echo "1|90|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                               umount iso                                  #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "umount iso"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli unloadopt -vtd ${vadapter_vcd} -release\""
result=$(ssh ${ivm_user}@${ivm_ip} "ioscli unloadopt -vtd ${vadapter_vcd} -release" 2>&1)
if [ $? -ne 0 ]
then
	rollback_1
	throwException "$result" "105019"
fi
log_debug $LINENO "result=${result}"
echo "1|95|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                               shutdown vm                                	#####
#####                                                                           #####
#####################################################################################
log_info $LINENO "shutdown vm"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"lssyscfg -r lpar --filter lpar_ids=${lpar_id} -F state\""
lpar_state=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar --filter lpar_ids=${lpar_id} -F state")
log_debug $LINENO "lpar_state=${lpar_state}"
if [ "$lpar_state" != "Not Activated" ]
then
	log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"chsysstate -r lpar -o shutdown --id ${lpar_id} --immed\" > /dev/null 2>&1"
	ssh ${ivm_user}@${ivm_ip} "chsysstate -r lpar -o shutdown --id ${lpar_id} --immed" > /dev/null 2>&1
fi

if [ "$log_flag" == "0" ]
then
	rm -f "${error_log}" 2> /dev/null
	rm -f "$out_log" 2> /dev/null
fi
ssh ${ivm_user}@${ivm_ip} "rm -f ${cdrom_path}/${config_iso}" > /dev/null 2>&1
ssh ${ivm_user}@${ivm_ip} "rm -f ${ovf_cfg}" > /dev/null 2>&1

echo "1|100|SUCCESS"
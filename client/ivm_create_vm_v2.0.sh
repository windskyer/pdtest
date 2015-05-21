#!/usr/bin/ksh

echo "1|0|SUCCESS"

. ./ivm_function.sh

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
		unmount_nfs
		ssh ${ivm_user}@${ivm_ip} "rm -f ${cdrom_path}/${config_iso}" > /dev/null 2>&1
		ssh ${ivm_user}@${ivm_ip} "rm -f ${ovf_xml}" > /dev/null 2>&1
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
					main_dns=$param;;
			20)
					j=21;
					bak_dns=$param;;
			21)
					j=22;
					auto_start=$param;;
        esac
done

length=0
echo $2 | awk -F"|" '{for(i=1;i<=NF;i++) print $i}' | while read param
do
	storagetype=$(echo $param | awk -F":" '{print $1}' | awk -F"," '{print $1}')
	if [ "$storagetype" == "lv" ]
	then
		if [ "$(echo $param | awk -F":" '{print $1}' | awk -F"," '{print $2}')" == "size" ]
		then
				storage_type[$length]="LVSIZE"
				lv_vg[$length]=$(echo $param | awk -F":" '{print $2}' | awk -F"," '{print $1}')
				lv_size[$length]=$(echo $param | awk -F":" '{print $2}' | awk -F"," '{print $2}')
				length=$(expr $length + 1)
		else
				storage_type[$length]="LVNAME"
				lv_vg[$length]=$(echo $param | awk -F":" '{print $2}' | awk -F"," '{print $1}')
				lv_name[$length]=$(echo $param | awk -F":" '{print $2}' | awk -F"," '{print $2}')
				length=$(expr $length + 1)
		fi
	fi
	
	if [ "$storagetype" == "pv" ]
	then
			storage_type[$length]="PV"
			pv_name[$length]=$(echo $param | awk -F":" '{print $2}')
			length=$(expr $length + 1)
	fi
	
	if [ "$storagetype" == "lu" ]
	then
		if [ "$(echo $param | awk -F":" '{print $1}' | awk -F"," '{print $2}')" == "size" ]
		then
				storage_type[$length]="LUSIZE"
				clustername[$length]=$(echo $param | awk -F":" '{print $2}' | awk -F"," '{print $1}')
				spname[$length]=$(echo $param | awk -F":" '{print $2}' | awk -F"," '{print $2}')
				lu_size[$length]=$(echo $param | awk -F":" '{print $2}' | awk -F"," '{print $3}')
				lu_name[$length]=$(echo $param | awk -F":" '{print $2}' | awk -F"," '{print $4}')
				lu_mode[$length]=$(echo $param | awk -F":" '{print $2}' | awk -F"," '{print $5}')
				length=$(expr $length + 1)
		else
				storage_type[$length]="LUNAME"
				clustername[$length]=$(echo $param | awk -F":" '{print $2}' | awk -F"," '{print $1}')
				spname[$length]=$(echo $param | awk -F":" '{print $2}' | awk -F"," '{print $2}')
				lu_udid[$length]=$(echo $param | awk -F":" '{print $2}' | awk -F"," '{print $3}')
				length=$(expr $length + 1)
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

j=0
for nfs_info in $(echo $4 |awk -F"|" '{for(i=1;i<=NF;i++) print $i}')
do
	case $j in
		0)
				j=1;
				nfs_ip=$nfs_info;;
		1)
				j=2;        
				nfs_name=$nfs_info;;
		2)
				j=3;
				nfs_passwd=$nfs_info;;
		3)
				j=4;
				nfs_path=$nfs_info;;
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
out_log="${path_log}/out_ivm_create_vm_v2.0_${lpar_name}_${DateNow}_${random}.log"
error_log="${path_log}/error_ivm_create_vm_v2.0_${lpar_name}_${DateNow}_${random}.log"
ovf_xml="config_${DateNow}_${random}.xml"
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
nfs_server_check ${nfs_ip} ${nfs_name} ${nfs_passwd}

#####################################################################################
#####                                                                           #####
#####                          		 mount nfs	                                #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "mount nfs"
mount_nfs
# echo "template_path==$template_path"

#####################################################################################
#####                                                                           #####
#####                           check template                                  #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "check template"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"cat ${template_path}/${template_name}/${template_name}.cfg\" | grep "files=" | awk -F"=" '{print $2}'"
img=$(ssh ${ivm_user}@${ivm_ip} "cat ${template_path}/${template_name}/${template_name}.cfg" 2> "${error_log}" | grep "files=" | awk -F"=" '{print $2}')
log_debug $LINENO "img=${img}"
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
	for line in $(echo "$img" | awk -F"," '{for(i=1;i<=NF;i++) print $i}')
	do
		if [ "X$line" != "X" ]
		then
			tmp_name=$(echo $line | awk -F"|" '{print $1}')
			tmp_name=${tmp_name##*/}
			ssh ${ivm_user}@${ivm_ip} "ls ${template_path}/${template_name}/$tmp_name" > /dev/null 2> $error_log
			catchException "${error_log}"
			throwException "$error_result" "105009"
			img_[$i]=${template_path}/${template_name}/$tmp_name
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
log_info $LINENO "check host serial number"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"lssyscfg -r sys -F serial_num\""
serial_num=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r sys -F serial_num" 2> "${error_log}")
log_debug $LINENO "serial_num=${serial_num}"
catchException "${error_log}"
throwException "$error_result" "105060"
echo "1|6|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                               create vm                                   #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "create vm"
if [ "$proc_mode" != "ded" ]
then
	log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"mksyscfg -r lpar -i name=\"${lpar_name}\",max_virtual_slots=30,lpar_env=aixlinux,auto_start=${auto_start},profile_name=\"${lpar_name}\",proc_mode=${proc_mode},min_procs=${min_procs},min_proc_units=${min_proc_units},desired_procs=${desired_procs},desired_proc_units=${desired_proc_units},max_procs=${max_procs},max_proc_units=${max_proc_units},sharing_mode=${sharing_mode},uncap_weight=127,min_mem=${min_mem},desired_mem=${desired_mem},max_mem=${max_mem}\""
	ssh ${ivm_user}@${ivm_ip} "mksyscfg -r lpar -i name=\"${lpar_name}\",max_virtual_slots=30,lpar_env=aixlinux,auto_start=${auto_start},profile_name=\"${lpar_name}\",proc_mode=${proc_mode},min_procs=${min_procs},min_proc_units=${min_proc_units},desired_procs=${desired_procs},desired_proc_units=${desired_proc_units},max_procs=${max_procs},max_proc_units=${max_proc_units},sharing_mode=${sharing_mode},uncap_weight=127,min_mem=${min_mem},desired_mem=${desired_mem},max_mem=${max_mem}" 2> "${error_log}"
else
	log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"mksyscfg -r lpar -i name=\"${lpar_name}\",max_virtual_slots=30,lpar_env=aixlinux,auto_start=${auto_start},profile_name=\"${lpar_name}\",proc_mode=${proc_mode},min_procs=${min_procs},desired_procs=${desired_procs},max_procs=${max_procs},sharing_mode=${sharing_mode},min_mem=${min_mem},desired_mem=${desired_mem},max_mem=${max_mem}\""
	ssh ${ivm_user}@${ivm_ip} "mksyscfg -r lpar -i name=\"${lpar_name}\",max_virtual_slots=30,lpar_env=aixlinux,auto_start=${auto_start},profile_name=\"${lpar_name}\",proc_mode=${proc_mode},min_procs=${min_procs},desired_procs=${desired_procs},max_procs=${max_procs},sharing_mode=${sharing_mode},min_mem=${min_mem},desired_mem=${desired_mem},max_mem=${max_mem}" 2> "${error_log}"
fi
catchException "${error_log}"
throwException "$error_result" "105012"
echo "1|7|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                             check lpar id                                 #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "check lpar id"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"lssyscfg -r lpar -F lpar_id --filter lpar_names=\"${lpar_name}\"\""
lpar_id=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar -F lpar_id --filter lpar_names=\"${lpar_name}\"" 2> "${error_log}")
log_debug $LINENO "lpar_id=${lpar_id}"
catchException "${error_log}"
throwException "$error_result" "105061"
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
	log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"chhwres -r virtualio --rsubtype eth --id $lpar_id -o a -s $slot -a ieee_virtual_eth=0,port_vlan_id=${vlan_id[$i]},is_trunk=0\""
	ssh ${ivm_user}@${ivm_ip} "chhwres -r virtualio --rsubtype eth --id $lpar_id -o a -s $slot -a ieee_virtual_eth=0,port_vlan_id=${vlan_id[$i]},is_trunk=0" 2> "${error_log}"
	catchException "${error_log}"
	#if Power8 cpu,create veth have "Unhandled firmware error"
	if [ "${error_result}" != "" ] && [ "$(echo "$error_result" | grep "VIOSE03FF0000-0149")" == "" ]
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
log_info $LINENO "get eth mac address"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"lshwres -r virtualio --rsubtype eth --level lpar --filter lpar_ids=${lpar_id},slots=15 -F mac_addr\""
mac_address=$(ssh ${ivm_user}@${ivm_ip} "lshwres -r virtualio --rsubtype eth --level lpar --filter lpar_ids=${lpar_id},slots=15 -F mac_addr" 2> "${error_log}")
log_debug $LINENO "mac_address=${mac_address}"
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
log_info $LINENO "Get virtual_scsi_adapters server id"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"lssyscfg -r prof --filter lpar_ids=${lpar_id} -F virtual_scsi_adapters\" | awk -F'/' '{print \$5}'"
server_vscsi_id=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r prof --filter lpar_ids=${lpar_id} -F virtual_scsi_adapters" | awk -F'/' '{print $5}' 2> "${error_log}")
log_debug $LINENO "server_vscsi_id=${server_vscsi_id}"
catchException "${error_log}"
throwException "$error_result" "105063"
echo "1|11|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                            get vios' adapter                              #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "get vios' adapter"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli lsmap -all -fmt :\" | grep ${serial_num} | grep "C${server_vscsi_id}:" | awk -F":" '{print \$1}'"
vadapter_vios=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -all -fmt :" | grep ${serial_num} | grep "C${server_vscsi_id}:" | awk -F":" '{print $1}' 2> "${error_log}")
log_debug $LINENO "vadapter_vios=${vadapter_vios}"
catchException "${error_log}"
throwException "$error_result" "105064"
echo "1|12|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                                create lv                                  #####
#####                                                                           #####
#####################################################################################
i=0
progress=12
while [ $i -lt $img_num ]
do
	if [ "${storage_type[$i]}" == "LVSIZE" ]
	then
		log_info $LINENO "storage_type is LVSIZE"
		log_info $LINENO "Go to LV..."
		#####################################################################################
		#####                                                                           #####
		#####                              check vg                                     #####
		#####                                                                           #####
		#####################################################################################
		log_info $LINENO "check vg"
		vg_free_size=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsvg ${lv_vg[$i]} -field freepps -fmt :" 2> ${error_log} | head -n 1 | awk '{print substr($2,2,length($2))}')
		log_debug $LINENO "vg_free_size=${vg_free_size}"
		catchException "${error_log}"
		time=0
		while [ "$(echo ${error_result} | grep "Volume group is locked")" != "" ]||[ "$(echo ${error_result} | grep "ODM lock")" != "" ]
		do
			sleep 1
			vg_free_size=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsvg ${lv_vg[$i]} -field freepps -fmt :" 2> ${error_log} | head -n 1 | awk '{print substr($2,2,length($2))}')
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
				if [ "${storage_type[$j]}" == "LVSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
				fi
				if [ "${storage_type[$j]}" == "LUSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmbdsp -clustername ${clustername[$j]} -sp ${spname[$j]} -luudid ${lu_udid[$j]}" > /dev/null 2>&1
				fi
				j=$(expr $j + 1)
			done
		fi
		throwException "$error_result" "105010"
			
		if [ $vg_free_size -lt ${lv_size[$i]} ]
		then
			ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
			j=0
			while [ $j -lt $i ]
			do
				if [ "${storage_type[$j]}" == "LVSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
				fi
				if [ "${storage_type[$j]}" == "LUSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmbdsp -clustername ${clustername[$j]} -sp ${spname[$j]} -luudid ${lu_udid[$j]}" > /dev/null 2>&1
				fi
				j=$(expr $j + 1)
			done
			throwException "Storage ${lv_vg[$i]} is not enough !" "105010"
		fi
		progress=$(expr $progress + 1)
		echo "1|$progress|SUCCESS"
		
		#####################################################################################
		#####                                                                           #####
		#####                              create lv                                    #####
		#####                                                                           #####
		#####################################################################################
		log_info $LINENO "create lv ${lpar_name}"
		lv_name[$i]=$(ssh ${ivm_user}@${ivm_ip} "ioscli mklv ${lv_vg[$i]} ${lv_size[$i]}M" 2> "${error_log}")
		log_debug $LINENO "lv_name=${lv_name[$i]}"
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
				if [ "${storage_type[$j]}" == "LVSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
				fi
				if [ "${storage_type[$j]}" == "LUSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmbdsp -clustername ${clustername[$j]} -sp ${spname[$j]} -luudid ${lu_udid[$j]}" > /dev/null 2>&1
				fi
				j=$(expr $j + 1)
			done
		fi
		throwException "$error_result" "105011"
		progress=$(expr $progress + 1)
		echo "1|$progress|SUCCESS"
	fi
	
	if [ "${storage_type[$i]}" == "LVNAME" ]
	then
		log_info $LINENO "storage_type is LVNAME"
		#####################################################################################
		#####                                                                           #####
		#####                              check lv                                     #####
		#####                                                                           #####
		#####################################################################################
		log_info $LINENO "check lv"
		vg_lv_list=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsvg -lv ${lv_vg[$i]} -fmt :"| awk -F":" '{print $1}' 2> "${error_log}")
		log_debug $LINENO "vg_lv_list=${vg_lv_list}"
		catchException "${error_log}"
		time=0
		while [ "$(echo ${error_result} | grep "Volume group is locked")" != "" ]||[ "$(echo ${error_result} | grep "ODM lock")" != "" ]
		do
			sleep 1
			vg_lv_list=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsvg -lv ${lv_vg[$i]} -fmt :" 2> ${error_log} | awk -F":" '{print $1}' )
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
				if [ "${storage_type[$j]}" == "LVSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
				fi
				if [ "${storage_type[$j]}" == "LUSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmbdsp -clustername ${clustername[$j]} -sp ${spname[$j]} -luudid ${lu_udid[$j]}" > /dev/null 2>&1
				fi
				j=$(expr $j + 1)
			done
		fi
		throwException "$error_result" "105011"
				
		if [ "$(echo $vg_lv_list | awk '{ for(i=1;i<=NF;i++) { if($i == lvname) { print $i } } }' lvname=${lv_name[$i]})" == "" ]
		then
			ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
			j=0
			while [ $j -lt $i ]
			do
				if [ "${storage_type[$j]}" == "LVSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
				fi
				if [ "${storage_type[$j]}" == "LUSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmbdsp -clustername ${clustername[$j]} -sp ${spname[$j]} -luudid ${lu_udid[$j]}" > /dev/null 2>&1
				fi
				j=$(expr $j + 1)
			done
			throwException "LV ${lv_name[$i]} is not existing in VG ${lv_vg[$i]} !" "105010"
		fi
		dd_name[$i]=${lv_name[$i]}
		
		progress=$(expr $progress + 1)
		echo "1|$progress|SUCCESS"
				
	fi
	
	if [ "${storage_type[$i]}" == "PV" ]
	then
		log_info $LINENO "storage_type is PV"
		log_info $LINENO "Go to PV..."
		#####################################################################################
		#####                                                                           #####
		#####                              check pv                                     #####
		#####                                                                           #####
		#####################################################################################
		log_info $LINENO "check pv"
		dd_name[$i]=${pv_name[$i]}
		lspv_name=$(ssh ${ivm_user}@${ivm_ip} "ioscli lspv -avail -field name -fmt :" 2> ${error_log})
		log_debug $LINENO "lspv_name=${lspv_name}"
		catchException "${error_log}"
		if [ "$error_result" != "" ]
		then
			ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
			j=0
			while [ $j -lt $i ]
			do
				if [ "${storage_type[$j]}" == "LVSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
				fi
				if [ "${storage_type[$j]}" == "LUSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmbdsp -clustername ${clustername[$j]} -sp ${spname[$j]} -luudid ${lu_udid[$j]}" > /dev/null 2>&1
				fi
				j=$(expr $j + 1)
			done
		fi
		throwException "$error_result" "105067"
		pv_map=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -all -type disk -field backing -fmt :" 2> ${error_log}  | awk -F":" '{for(i=1;i<=NF;i++) print $i}')
		log_debug $LINENO "pv_map=${pv_map}"
		catchException "${error_log}"
		if [ "$error_result" != "" ]
		then
			ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
			j=0
			while [ $j -lt $i ]
			do
				if [ "${storage_type[$j]}" == "LVSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
				fi
				if [ "${storage_type[$j]}" == "LUSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmbdsp -clustername ${clustername[$j]} -sp ${spname[$j]} -luudid ${lu_udid[$j]}" > /dev/null 2>&1
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
				if [ "${storage_type[$j]}" == "LVSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
				fi
				if [ "${storage_type[$j]}" == "LUSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmbdsp -clustername ${clustername[$j]} -sp ${spname[$j]} -luudid ${lu_udid[$j]}" > /dev/null 2>&1
				fi
				j=$(expr $j + 1)
			done
			throwException "The ${pv_name[$i]} is in used." "105067"
		fi
		progress=$(expr $progress + 1)
		echo "1|$progress|SUCCESS"
	fi
	
	if [ "${storage_type[$i]}" == "LUSIZE" ]
	then
		log_info $LINENO "storage_type is LUSIZE"
		#####################################################################################
		#####                                                                           #####
		#####                              check ssp                                    #####
		#####                                                                           #####
		#####################################################################################
		log_info $LINENO "check ssp ${clustername[$i]}"
		ssp_free_size=$(ssh ${ivm_user}@${ivm_ip} "ioscli lssp -clustername ${clustername[$i]} -field pool size free total overcommit lus type id -fmt :" | awk -F":" '{if($1==sp_name) print $3}' sp_name=${spname[$i]} 2> "${error_log}")
		log_debug $LINENO "ssp_free_size=${ssp_free_size}"
		catchException "${error_log}"
		if [ "$error_result" != "" ]
		then
			ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
			j=0
			while [ $j -lt $i ]
			do
				if [ "${storage_type[$j]}" == "LVSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
				fi
				if [ "${storage_type[$j]}" == "LUSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmbdsp -clustername ${clustername[$j]} -sp ${spname[$j]} -luudid ${lu_udid[$j]}" > /dev/null 2>&1
				fi
				j=$(expr $j + 1)
			done
		fi
		throwException "$error_result" "105010"
			
		if [ $ssp_free_size -lt ${lu_size[$i]} ]
		then
			ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
			j=0
			while [ $j -lt $i ]
			do
				if [ "${storage_type[$j]}" == "LVSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
				fi
				if [ "${storage_type[$j]}" == "LUSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmbdsp -clustername ${clustername[$j]} -sp ${spname[$j]} -luudid ${lu_udid[$j]}" > /dev/null 2>&1
				fi
				j=$(expr $j + 1)
			done
			throwException "Storage SSP ${clustername[$i]} is not enough !" "105010"
		fi
		progress=$(expr $progress + 1)
		echo "1|$progress|SUCCESS"

		#####################################################################################
		#####                                                                           #####
		#####                              create lu                                    #####
		#####                                                                           #####
		#####################################################################################
		log_info $LINENO "create lu ${lu_name}"
		if [ "${lu_mode[$i]}" == "thick" ]
		then
			ssp_lu_info=$(ssh ${ivm_user}@${ivm_ip} "ioscli mkbdsp -clustername ${clustername[$i]} -sp ${spname[$i]} ${lu_size[$i]} -bd ${lu_name[$i]} -${lu_mode[$i]}" 2> "${error_log}")
		else
			ssp_lu_info=$(ssh ${ivm_user}@${ivm_ip} "ioscli mkbdsp -clustername ${clustername[$i]} -sp ${spname[$i]} ${lu_size[$i]} -bd ${lu_name[$i]}" 2> "${error_log}")
		fi
		log_debug $LINENO "ssp_lu_info=${ssp_lu_info}"
		catchException "${error_log}"
		if [ "$error_result" != "" ]
		then
			ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
			j=0
			while [ $j -lt $i ]
			do
				if [ "${storage_type[$j]}" == "LVSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
				fi
				if [ "${storage_type[$j]}" == "LUSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmbdsp -clustername ${clustername[$j]} -sp ${spname[$j]} -luudid ${lu_udid[$j]}" > /dev/null 2>&1
				fi
				j=$(expr $j + 1)
			done
		fi
		throwException "$error_result" "105011"
		lu_udid[$i]=$(echo "$ssp_lu_info"|grep "Lu Udid"|awk -F":" '{print $2}')
		mount_info=$(expect ./ssh.exp ${ivm_user} ${ivm_ip} "oem_setup_env | mount|exit|exit" 2>&1)
		log_debug $LINENO "mount_info=${mount_info}"
		# if [ $? -ne 0 ]
		# then
			# ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
			# j=0
			# while [ $j -lt $img_num ]
			# do
				# if [ "${storage_type[$j]}" == "LVSIZE" ]
				# then
					# ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
				# fi
				# j=$(expr $j + 1)
			# done
			# throwException "$error_result" "105011"
		# fi
		
		lu_dev_path=$(echo "$mount_info" | grep "/var/vio/SSP/${clustername[$i]}/*" | awk '{print $1}')
		lu_rdev[$i]="${lu_dev_path}/VOL1/${lu_name[$i]}.${lu_udid[$i]}"
		dd_name[$i]=${lu_rdev[$i]}
		
		progress=$(expr $progress + 1)
		echo "1|$progress|SUCCESS"
	fi
	if [ "${storage_type[$i]}" == "LUNAME" ]
	then
		log_info $LINENO "storage_type is LUNAME"
		#####################################################################################
		#####                                                                           #####
		#####                              check lu                                     #####
		#####                                                                           #####
		#####################################################################################
		log_info $LINENO "check lu ${lu_udid[$i]}"
		ssp_lu_list=$(ssh ${ivm_user}@${ivm_ip} "ioscli lssp -clustername ${clustername[$i]} -sp ${spname[$i]} -bd -field luname luudid -fmt :" 2> "${error_log}")
		log_debug $LINENO "ssp_lu_list=${ssp_lu_list}"
		catchException "${error_log}"
		if [ "$error_result" != "" ]
		then
			ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
			j=0
			while [ $j -lt $i ]
			do
				if [ "${storage_type[$j]}" == "LVSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
				fi
				if [ "${storage_type[$j]}" == "LUSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmbdsp -clustername ${clustername[$j]} -sp ${spname[$j]} -luudid ${lu_udid[$j]}" > /dev/null 2>&1
				fi
				j=$(expr $j + 1)
			done
		fi
		throwException "$error_result" "105011"
				
		lu_name[$i]=$(echo "$ssp_lu_list" | awk -F":" '{ if($2 == luudid) { print $1 } }' luudid=${lu_udid[$i]})
		if [ "${lu_name[$i]}" == "" ]
		then
			ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
			j=0
			while [ $j -lt $i ]
			do
				if [ "${storage_type[$j]}" == "LVSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
				fi
				if [ "${storage_type[$j]}" == "LUSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmbdsp -clustername ${clustername[$j]} -sp ${spname[$j]} -luudid ${lu_udid[$j]}" > /dev/null 2>&1
				fi
				j=$(expr $j + 1)
			done
			throwException "LU ${lu_udid[$i]} is not existing in SSP ${clustername[$i]}" "105010"
		fi	
		mount_info=$(expect ./ssh.exp ${ivm_user} ${ivm_ip} "oem_setup_env | mount|exit|exit" 2>&1)
		log_debug $LINENO "mount_info=${mount_info}"
		lu_dev_path=$(echo "$mount_info" | grep "/var/vio/SSP/${clustername[$i]}/*" | awk '{print $1}')
		lu_rdev[$i]="${lu_dev_path}/VOL1/${lu_name[$i]}.${lu_udid[$i]}"
		dd_name[$i]=${lu_rdev[$i]}
		progress=$(expr $progress + 1)
		echo "1|$progress|SUCCESS"
	fi
	
		
	#####################################################################################
	#####                                                                           #####
	#####                                 dd copy                                   #####
	#####                                                                           #####
	#####################################################################################
	log_info $LINENO "dd copy"
	log_debug $LINENO "CMD:expect ./ssh.exp ${ivm_user} ${ivm_ip} \"oem_setup_env|mkdir -p ${path_log}|chmod -R 777 ${path_log}\" > /dev/null 2>&1"
	expect ./ssh.exp ${ivm_user} ${ivm_ip} "oem_setup_env|mkdir -p ${path_log}|chmod -R 777 ${path_log}" > /dev/null 2>&1
	
	if [ "${storage_type[$i]}" == "LVSIZE" -o "${storage_type[$i]}" == "LVNAME" -o "${storage_type[$i]}" == "PV" ]
	then
		log_info $LINENO "storage_type is ${storage_type[$i]}"
		# echo "oem_setup_env|dd if=${img_[$i]} of=/dev/r${dd_name[$i]} bs=8M"
		log_debug $LINENO "CMD:expect ./ssh.exp ${ivm_user} ${ivm_ip} \"oem_setup_env|dd if=${img_[$i]} of=/dev/r${dd_name[$i]} bs=8M\""
		expect ./ssh.exp ${ivm_user} ${ivm_ip} "oem_setup_env|dd if=${img_[$i]} of=/dev/r${dd_name[$i]} bs=8M > /dev/null 2> ${error_log} &" > /dev/null 2>&1
		ps_rlt=$(ssh ${ivm_user}@${ivm_ip} "ps -ef|grep \"dd if=${img_[$i]} of=/dev/r${dd_name[$i]}\" | grep -v grep")
		while [ "${ps_rlt}" != "" ]
		do
			log_info $LINENO "sleep 45"
			sleep 45
			ps_rlt=$(ssh ${ivm_user}@${ivm_ip} "ps -ef|grep \"dd if=${img_[$i]} of=/dev/r${dd_name[$i]}\" | grep -v grep")
			log_debug $LINENO "ps_rlt=$ps_rlt"
			progress=$(expr $progress + 1)
			echo "1|$progress|SUCCESS"
		done
		
		dd_rlt=$(ssh ${ivm_user}@${ivm_ip} "cat ${error_log}" 2> /dev/null)
		ssh ${ivm_user}@${ivm_ip} "rm -f ${error_log}" > /dev/null 2>&1
		log_debug $LINENO "error_log=$dd_rlt"
		
		if [ "$(echo "${dd_rlt}" | grep -v "records in" | grep -v "records out")" != "" ]
		then
			ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
			j=0
			while [ $j -lt $img_num ]
			do
				if [ "${storage_type[$j]}" == "LVSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
				fi
				if [ "${storage_type[$j]}" == "LUSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmbdsp -clustername ${clustername[$j]} -sp ${spname[$j]} -luudid ${lu_udid[$j]}" > /dev/null 2>&1
				fi
				j=$(expr $j + 1)
			done
			throwException "$dd_rlt" "105014"
		fi
		
	else #ddcopy ssp lu
		#####################################################################################
		#####                                                                           #####
		#####                              check lu file                                #####
		#####                                                                           #####
		#####################################################################################
		log_info $LINENO "storage_type is ${storage_type[$i]}"
		ls_rlt=$(ssh ${ivm_user}@${ivm_ip} "ls ${dd_name[$i]}" 2>"${error_log}")
		catchException "${error_log}"
		if [ "$error_result" != "" ]
		then
			ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
			j=0
			while [ $j -lt $img_num ]
			do
				if [ "${storage_type[$j]}" == "LVSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
				fi
				if [ "${storage_type[$j]}" == "LUSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmbdsp -clustername ${clustername[$j]} -sp ${spname[$j]} -luudid ${lu_udid[$j]}" > /dev/null 2>&1
				fi
				j=$(expr $j + 1)
			done
			throwException "$error_result" "105014"
		fi
		log_debug $LINENO "CMD:ssh.exp ${ivm_user} ${ivm_ip} \"oem_setup_env|dd if=${img_[$i]} of=${dd_name[$i]} bs=8M\""
		expect ./ssh.exp ${ivm_user} ${ivm_ip} "oem_setup_env|dd if=${img_[$i]} of=${dd_name[$i]} bs=8M > /dev/null 2> ${error_log} &" > /dev/null 2>&1
		ps_rlt=$(ssh ${ivm_user}@${ivm_ip} "ps -ef|grep \"dd if=${img_[$i]} of=${dd_name[$i]}\" | grep -v grep")
		while [ "${ps_rlt}" != "" ]
		do
			log_info $LINENO "sleep 20"
			sleep 20
			ps_rlt=$(ssh ${ivm_user}@${ivm_ip} "ps -ef|grep \"dd if=${img_[$i]} of=${dd_name[$i]}\" | grep -v grep")
			log_debug $LINENO "ps_rlt=$ps_rlt"
			progress=$(expr $progress + 1)
			echo "1|$progress|SUCCESS"
		done
		
		dd_rlt=$(ssh ${ivm_user}@${ivm_ip} "cat ${error_log}" 2> /dev/null)
		ssh ${ivm_user}@${ivm_ip} "rm -f ${error_log}" > /dev/null 2>&1
		log_debug $LINENO "error_log=$dd_rlt"
		
		if [ "$(echo "${dd_rlt}" | grep -v "records in" | grep -v "records out")" != "" ]
		then
			ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
			j=0
			while [ $j -lt $img_num ]
			do
				if [ "${storage_type[$j]}" == "LVSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
				fi
				if [ "${storage_type[$j]}" == "LUSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmbdsp -clustername ${clustername[$j]} -sp ${spname[$j]} -luudid ${lu_udid[$j]}" > /dev/null 2>&1
				fi
				j=$(expr $j + 1)
			done
			throwException "$dd_rlt" "105014"
		fi
		
	fi
	i=$(expr $i + 1)
done
echo "1|76|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                             create mapping                                #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "create mapping"

i=0
while [ $i -lt $img_num ]
do
	if [ "${storage_type[$i]}" == "LVSIZE" -o "${storage_type[$i]}" == "LVNAME" -o "${storage_type[$i]}" == "PV" ]
	then
		log_info $LINENO "storage_type is ${storage_type[$i]}"
		log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli mkvdev -vdev ${dd_name[$i]} -vadapter ${vadapter_vios}\""
		mapping_name=$(ssh ${ivm_user}@${ivm_ip} "ioscli mkvdev -vdev ${dd_name[$i]} -vadapter ${vadapter_vios}" 2> "${error_log}")
		log_debug $LINENO "mapping_name=${mapping_name}"
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
			ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
			j=0
			while [ $j -lt $img_num ]
			do
				if [ "${storage_type[$j]}" == "LVSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
				fi
				if [ "${storage_type[$j]}" == "LUSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmbdsp -clustername ${clustername[$j]} -sp ${spname[$j]} -luudid ${lu_udid[$j]}" > /dev/null 2>&1
				fi
				j=$(expr $j + 1)
			done
		fi
		throwException "$error_result" "105015"
		i=$(expr $i + 1)
	else
		log_info $LINENO "storage_type is ${storage_type[$i]}"
		log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli mkbdsp -clustername ${clustername[$i]} -sp ${spname[$i]} -luudid ${lu_udid[$i]} -vadapter ${vadapter_vios}\""
		lu_map_info=$(ssh ${ivm_user}@${ivm_ip} "ioscli mkbdsp -clustername ${clustername[$i]} -sp ${spname[$i]} -luudid ${lu_udid[$i]} -vadapter ${vadapter_vios}" 2> "${error_log}")
		log_debug $LINENO "lu_map_info=${lu_map_info}"
		catchException "${error_log}"
		if [ "${error_result}" != "" ]
		then
			ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
			j=0
			while [ $j -lt $img_num ]
			do
				if [ "${storage_type[$j]}" == "LVSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
				fi
				if [ "${storage_type[$j]}" == "LUSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmbdsp -clustername ${clustername[$j]} -sp ${spname[$j]} -luudid ${lu_udid[$j]}" > /dev/null 2>&1
				fi
				j=$(expr $j + 1)
			done
		fi
		throwException "$error_result" "105015"
		i=$(expr $i + 1)
	fi
done
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
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli mkvdev -fbo -vadapter ${vadapter_vios}\" | awk '{print \$1}'"
vadapter_vcd=$(ssh ${ivm_user}@${ivm_ip} "ioscli mkvdev -fbo -vadapter ${vadapter_vios}" 2> "${error_log}" | awk '{print $1}')
log_debug $LINENO "vadapter_vcd==${vadapter_vcd}"
catchException "${error_log}"
if [ "${error_result}" != "" ]
then
	ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
	j=0
	while [ $j -lt $img_num ]
	do
		if [ "${storage_type[$j]}" == "LVSIZE" ]
		then
			ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
		fi
		if [ "${storage_type[$j]}" == "LUSIZE" ]
		then
			ssh ${ivm_user}@${ivm_ip} "ioscli rmbdsp -clustername ${clustername[$j]} -sp ${spname[$j]} -luudid ${lu_udid[$j]}" > /dev/null 2>&1
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
log_info $LINENO "create xml"
result=$(expect ./ssh.exp ${ivm_user} ${ivm_ip} "oem_setup_env|echo \"ipaddress=${ip_address}\" >> ${ovf_xml}|echo \"ipgw=${gateway}\" >> ${ovf_xml}|echo \"netmask=${netmask}\" >> ${ovf_xml}|echo \"main_dns=${main_dns}\" >> ${ovf_xml}|echo \"bak_dns=${bak_dns}\" >> ${ovf_xml}|echo \"hostname=${host_name}\" >> ${ovf_xml}|echo \"macaddr=${mac_address}\" >> ${ovf_xml}" 2>&1)
if [ $? -ne 0 ]
then
	ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
	j=0
	while [ $j -lt $img_num ]
	do
		if [ "${storage_type[$j]}" == "LVSIZE" ]
		then
			ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
		fi
		if [ "${storage_type[$j]}" == "LUSIZE" ]
		then
			ssh ${ivm_user}@${ivm_ip} "ioscli rmbdsp -clustername ${clustername[$j]} -sp ${spname[$j]} -luudid ${lu_udid[$j]}" > /dev/null 2>&1
		fi
		j=$(expr $j + 1)
	done
	throwException "$error_result" "105121"
fi
log_debug $LINENO "result=${result}"
echo "1|79|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                             	create iso                                	#####
#####                                                                           #####
#####################################################################################
log_info $LINENO "create iso"
log_debug $LINENO "CMD:expect ./ssh.exp ${ivm_user} ${ivm_ip} \"oem_setup_env|mkisofs -r -o ${cdrom_path}/${config_iso} ${ovf_xml}\""
result=$(expect ./ssh.exp ${ivm_user} ${ivm_ip} "oem_setup_env|mkisofs -r -o ${cdrom_path}/${config_iso} ${ovf_xml}" 2>&1)
if [ $? -ne 0 ]
then
	ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
	j=0
	while [ $j -lt $img_num ]
	do
		if [ "${storage_type[$j]}" == "LVSIZE" ]
		then
			ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
		fi
		if [ "${storage_type[$j]}" == "LUSIZE" ]
		then
			ssh ${ivm_user}@${ivm_ip} "ioscli rmbdsp -clustername ${clustername[$j]} -sp ${spname[$j]} -luudid ${lu_udid[$j]}" > /dev/null 2>&1
		fi
		j=$(expr $j + 1)
	done
	throwException "$error_result" "105221"
fi
log_debug $LINENO "result=${result}"
echo "1|80|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                                mount iso                                	#####
#####                                                                           #####
#####################################################################################
log_info $LINENO "mount iso"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli loadopt -disk ${config_iso} -vtd ${vadapter_vcd}\""
mount_result=$(ssh ${ivm_user}@${ivm_ip} "ioscli loadopt -disk ${config_iso} -vtd ${vadapter_vcd}" 2> "${error_log}")
log_debug $LINENO "mount_result==${mount_result}"
catchException "${error_log}"
if [ "${error_result}" != "" ]
then
	ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
	j=0
	while [ $j -lt $img_num ]
	do
		if [ "${storage_type[$j]}" == "LVSIZE" ]
		then
			ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
		fi
		if [ "${storage_type[$j]}" == "LUSIZE" ]
		then
			ssh ${ivm_user}@${ivm_ip} "ioscli rmbdsp -clustername ${clustername[$j]} -sp ${spname[$j]} -luudid ${lu_udid[$j]}" > /dev/null 2>&1
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
log_info $LINENO "startup vm"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"lssyscfg -r lpar --filter lpar_ids=${lpar_id} -F state\""
lpar_state=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar --filter lpar_ids=${lpar_id} -F state" 2> $error_log)
log_debug $LINENO "lpar_state=${lpar_state}"
catchException "${error_log}"
if [ "${error_result}" != "" ]
then
	ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
	j=0
	while [ $j -lt $img_num ]
	do
		if [ "${storage_type[$j]}" == "LVSIZE" ]
		then
			ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
		fi
		if [ "${storage_type[$j]}" == "LUSIZE" ]
		then
			ssh ${ivm_user}@${ivm_ip} "ioscli rmbdsp -clustername ${clustername[$j]} -sp ${spname[$j]} -luudid ${lu_udid[$j]}" > /dev/null 2>&1
		fi
		j=$(expr $j + 1)
	done
	throwException "$error_result" "105030"
fi
if [ "$lpar_state" != "Running" ]
then
	log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"chsysstate -r lpar -o on --id ${lpar_id}\""
	ssh ${ivm_user}@${ivm_ip} "chsysstate -r lpar -o on --id ${lpar_id}" 2> "${error_log}"
	catchException "${error_log}"
	if [ "${error_result}" != "" ]
	then
		ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
		j=0
		while [ $j -lt $img_num ]
		do
			if [ "${storage_type[$j]}" == "LVSIZE" ]
			then
				ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
			fi
			if [ "${storage_type[$j]}" == "LUSIZE" ]
			then
				ssh ${ivm_user}@${ivm_ip} "ioscli rmbdsp -clustername ${clustername[$j]} -sp ${spname[$j]} -luudid ${lu_udid[$j]}" > /dev/null 2>&1
			fi
			j=$(expr $j + 1)
		done
		throwException "$error_result" "105030"
	fi
	
	time=0
	while [ "${lpar_state}" != "Running" ]
	do
		log_info $LINENO "sleep 5"
		sleep 5
		time=$(expr $time + 5)
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
				if [ "${storage_type[$j]}" == "LVSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
				fi
				if [ "${storage_type[$j]}" == "LUSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmbdsp -clustername ${clustername[$j]} -sp ${spname[$j]} -luudid ${lu_udid[$j]}" > /dev/null 2>&1
				fi
				j=$(expr $j + 1)
			done
			throwException "$error_result" "105030"
		fi
		log_info $LINENO "lpar_state=$lpar_state"
	done
fi

time=0
lpar_state=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar --filter lpar_ids=${lpar_id} -F state" 2> $error_log)
catchException "${error_log}"
if [ "${error_result}" != "" ]
then
	ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
	j=0
	while [ $j -lt $img_num ]
	do
		if [ "${storage_type[$j]}" == "LVSIZE" ]
		then
			ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
		fi
		if [ "${storage_type[$j]}" == "LUSIZE" ]
		then
			ssh ${ivm_user}@${ivm_ip} "ioscli rmbdsp -clustername ${clustername[$j]} -sp ${spname[$j]} -luudid ${lu_udid[$j]}" > /dev/null 2>&1
		fi
		j=$(expr $j + 1)
	done
	throwException "$error_result" "105030"
fi
while [ "${lpar_state}" != "Not Activated" ]
do
	sleep 5
	time=$(expr $time + 5)
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
			if [ "${storage_type[$j]}" == "LVSIZE" ]
			then
				ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
			fi
			if [ "${storage_type[$j]}" == "LUSIZE" ]
			then
				ssh ${ivm_user}@${ivm_ip} "ioscli rmbdsp -clustername ${clustername[$j]} -sp ${spname[$j]} -luudid ${lu_udid[$j]}" > /dev/null 2>&1
			fi
			j=$(expr $j + 1)
		done
		throwException "$error_result" "105030"
	fi
	log_debug $LINENO "time==$time"
	log_debug $LINENO "lpar_state=$lpar_state"
done

echo "1|90|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                               umount iso                                  #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "umount iso"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli unloadopt -release -vtd ${vadapter_vcd}\""
ssh ${ivm_user}@${ivm_ip} "ioscli unloadopt -release -vtd ${vadapter_vcd}" 2> "${error_log}"
catchException "${error_log}"
if [ "${error_result}" != "" ]
then
	ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
	j=0
	while [ $j -lt $img_num ]
	do
		if [ "${storage_type[$j]}" == "LVSIZE" ]
		then
			ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
		fi
		if [ "${storage_type[$j]}" == "LUSIZE" ]
		then
			ssh ${ivm_user}@${ivm_ip} "ioscli rmbdsp -clustername ${clustername[$j]} -sp ${spname[$j]} -luudid ${lu_udid[$j]}" > /dev/null 2>&1
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
log_info $LINENO "shutdown vm"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"lssyscfg -r lpar --filter lpar_ids=${lpar_id} -F state\""
lpar_state=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar --filter lpar_ids=${lpar_id} -F state")
log_debug $LINENO "lpar_state=${lpar_state}"
if [ "$lpar_state" != "Not Activated" ]
then
	log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"chsysstate -r lpar -o shutdown --id ${lpar_id} --immed\""
	ssh ${ivm_user}@${ivm_ip} "chsysstate -r lpar -o shutdown --id ${lpar_id} --immed" > /dev/null 2>&1
fi

#####################################################################################
#####                                                                           #####
#####                          		unmount nfs	                                #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "unmount nfs"
unmount_nfs

if [ "$log_flag" == "0" ]
then
	rm -f "$error_log" 2> /dev/null
	rm -f "$out_log" 2> /dev/null
fi
ssh ${ivm_user}@${ivm_ip} "rm -f ${cdrom_path}/${config_iso}" > /dev/null 2>&1
ssh ${ivm_user}@${ivm_ip} "rm -f ${ovf_xml}" > /dev/null 2>&1

echo "1|100|SUCCESS"

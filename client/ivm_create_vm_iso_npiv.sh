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
			echo "0|0|ERROR-${error_code}: "$(echo "$result" | awk -F']' '{print $2}')
		else
			echo "0|0|ERROR-${error_code}: $result"
		fi
		
		unmount_nfs
		if [ "$log_flag" == "0" ]
		then
			rm -f "${error_log}" 2> /dev/null
			rm -f "$out_log" 2> /dev/null
		fi

		exit 1
	fi

}


mkvoptCheck() {
	#####################################################################################
	#####                                                                           #####
	#####                              check dd cp                                  #####
	#####                                                                           #####
	#####################################################################################
	cp_size=0
	progress=31
	i=1
	while [ ${cp_size} -lt ${iso_size} ]
	do
		sleep 10
		ps_rlt=$(${ivm_user}@${ivm_ip} "ps -ef | grep mkvopt | grep ${new_template_name} | grep -v grep")
		if [ "${ps_rlt}" == "" ]
		then
			catchException "${error_log}"
			if [ "$(echo "$error_result" | grep -v "already exists" | grep -v ^$)" != "" ]
			then
				ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
				throwException "$error_result" "105014"
			fi
			break
		fi
		cp_size=$(ssh ${ivm_user}@${ivm_ip} "ls -l ${cdrom_path}/${new_template_name}"  | awk '{print $5}' 2>&1)
		if [ $? -ne 0 ]
		then
			ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
			throwException "$cp_size" "105014"
		fi
		if [ "$(echo ${cp_size}" "$(echo ${iso_size} | awk '{printf "%0.2f",$1/5*i}' i="$i") | awk '{if($1>=$2) print 0}')" = "0" ]
		then
			progress=$(expr $progress + 10)
			echo "1|${progress}|SUCCESS"
			i=$(expr $i + 1)
		fi
	done
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
                                template_dir=$param;;
						16)
                                j=17;
                                auto_start=$param;;
        esac
done

fc_name=$2

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

log_flag=$(cat scrpits.properties 2> /dev/null | grep "LOG=" | awk -F"=" '{print $2}')
if [ "$log_flag" == "" ]
then
	log_flag=0
fi

DateNow=$(date +%Y%m%d%H%M%S)
random=$(perl -e 'my $random = int(rand(9999)); print "$random";')
out_log="${path_log}/out_ivm_create_vm_iso_npiv_${lpar_name}_${DateNow}_${random}.log"
error_log="${path_log}/error_ivm_create_vm_iso_npiv_${lpar_name}_${DateNow}_${random}.log"
cdrom_path="/var/vio/VMLibrary"

log_debug $LINENO "$0 $*"

# check authorized and repair error authorized
check_authorized ${ivm_ip} ${ivm_user}
#check NFSServer status and restart that had stop NFSServer proc
nfs_server_check ${ivm_ip} ${ivm_user}

#####################################################################################
#####                                                                           #####
#####                          		 mount nfs	                                #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "mount nfs"
mount_nfs

#####################################################################################
#####                                                                           #####
#####                              check iso                                    #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "check template"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"cat ${template_path}/${template_dir}/${template_dir}.cfg\""
cat_result=$(ssh ${ivm_user}@${ivm_ip} "cat ${template_path}/${template_dir}/${template_dir}.cfg" 2>&1)
if [ $? -ne 0 ]
then
	throwException "The iso file can not be found." "105009"
fi
log_debug $LINENO "cat_result=${cat_result}"
tmp_file=$(echo "$cat_result" | awk -F"=" '{if($1=="files") print $2}' | awk -F"|" '{print $1}')
template_name=${tmp_file##*/}
# template_path=${tmp_file%/*}

template_name_len=$(echo "$template_name" | awk '{print length($0)}')
if [ $template_name_len -gt 37 ]
then
	s=$(expr $template_name_len - 37)
	new_template_name=$(echo "$template_name" | awk '{print substr($0,0,length($0)-s)}' s="$s")
else
	new_template_name=$template_name
fi
echo "1|5|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                       get host serial number                              #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "check host serial number"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"lssyscfg -r sys -F serial_num\""
serial_num=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r sys -F serial_num" 2> ${error_log})
log_debug $LINENO "serial_num=${serial_num}"
catchException "${error_log}"
if [ "${error_result}" != "" ]
then
	throwException "$error_result" "105060"
fi
echo "1|25|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                               create vm                                   #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "create vm"
if [ "$proc_mode" != "ded" ]
then
	log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"mksyscfg -r lpar -i name=\"${lpar_name}\",max_virtual_slots=30,lpar_env=aixlinux,auto_start=${auto_start},profile_name=\"${lpar_name}\",max_virtual_slots=20,proc_mode=${proc_mode},min_procs=${min_procs},min_proc_units=${min_proc_units},desired_procs=${desired_procs},desired_proc_units=${desired_proc_units},max_procs=${max_procs},max_proc_units=${max_proc_units},sharing_mode=${sharing_mode},uncap_weight=127,min_mem=${min_mem},desired_mem=${desired_mem},max_mem=${max_mem}\""
	ssh ${ivm_user}@${ivm_ip} "mksyscfg -r lpar -i name=\"${lpar_name}\",max_virtual_slots=30,lpar_env=aixlinux,auto_start=${auto_start},profile_name=\"${lpar_name}\",max_virtual_slots=20,proc_mode=${proc_mode},min_procs=${min_procs},min_proc_units=${min_proc_units},desired_procs=${desired_procs},desired_proc_units=${desired_proc_units},max_procs=${max_procs},max_proc_units=${max_proc_units},sharing_mode=${sharing_mode},uncap_weight=127,min_mem=${min_mem},desired_mem=${desired_mem},max_mem=${max_mem}" 2> ${error_log}
else
	log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"mksyscfg -r lpar -i name=\"${lpar_name}\",max_virtual_slots=30,lpar_env=aixlinux,auto_start=${auto_start},profile_name=\"${lpar_name}\",max_virtual_slots=20,proc_mode=${proc_mode},min_procs=${min_procs},desired_procs=${desired_procs},max_procs=${max_procs},sharing_mode=${sharing_mode},min_mem=${min_mem},desired_mem=${desired_mem},max_mem=${max_mem}\""
	ssh ${ivm_user}@${ivm_ip} "mksyscfg -r lpar -i name=\"${lpar_name}\",max_virtual_slots=30,lpar_env=aixlinux,auto_start=${auto_start},profile_name=\"${lpar_name}\",max_virtual_slots=20,proc_mode=${proc_mode},min_procs=${min_procs},desired_procs=${desired_procs},max_procs=${max_procs},sharing_mode=${sharing_mode},min_mem=${min_mem},desired_mem=${desired_mem},max_mem=${max_mem}" 2> ${error_log}
fi
catchException "${error_log}"
if [ "${error_result}" != "" ]
then
	throwException "$error_result" "105012"
fi
throwException "$error_result" "105012"
echo "1|26|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                             check lpar id                                 #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "check lpar id"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"lssyscfg -r lpar -F lpar_id --filter lpar_names=\"${lpar_name}\"\""
lpar_id=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar -F lpar_id --filter lpar_names=\"${lpar_name}\"" 2> ${error_log})
log_debug $LINENO "lpar_id=${lpar_id}"
catchException "${error_log}"
if [ "${error_result}" != "" ]
then
	ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
	throwException "$error_result" "105061"
fi
echo "1|27|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                       create virtual_eth_adapters                         #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "create virtual_eth_adapters"
i=0
slot=15
while [ $i -lt $vlan_len ]
do
	# echo "slot==$slot"
	if [ "$i" == "0" ]
	then
		log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"chsyscfg -r prof -i virtual_eth_adapters=${slot}/0/${vlan_id[$i]}//0/1,lpar_id=${lpar_id}\""
		ssh ${ivm_user}@${ivm_ip} "chsyscfg -r prof -i virtual_eth_adapters=${slot}/0/${vlan_id[$i]}//0/1,lpar_id=${lpar_id}" 2> ${error_log}
	else
		log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"chsyscfg -r prof -i virtual_eth_adapters+=${slot}/0/${vlan_id[$i]}//0/1,lpar_id=${lpar_id}\""
		ssh ${ivm_user}@${ivm_ip} "chsyscfg -r prof -i virtual_eth_adapters+=${slot}/0/${vlan_id[$i]}//0/1,lpar_id=${lpar_id}" 2> ${error_log}
	fi
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
echo "1|28|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                  get virtual_scsi_adapters server id                      #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "Get virtual_scsi_adapters server id"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"lssyscfg -r prof --filter lpar_ids=${lpar_id} -F virtual_scsi_adapters\" | awk -F'/' '{print \$5}'"
server_vscsi_id=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r prof --filter lpar_ids=${lpar_id} -F virtual_scsi_adapters"  2> ${error_log} | awk -F'/' '{print $5}')
log_debug $LINENO "server_vscsi_id=${server_vscsi_id}"
catchException "${error_log}"
if [ "${error_result}" != "" ]
then
	ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
	throwException "$error_result" "105063"
fi
echo "1|29|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                            get vios' adapter                              #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "get vios' adapter"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli lsmap -all -fmt :\" | grep ${serial_num} | grep "C${server_vscsi_id}:" | awk -F":" '{print \$1}'"
vadapter_vios=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -all -fmt :" 2> ${error_log} | grep ${serial_num} | grep "C${server_vscsi_id}:" | awk -F":" '{print $1}')
log_debug $LINENO "vadapter_vios=${vadapter_vios}"
catchException "${error_log}"
if [ "${error_result}" != "" ]
then
	ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
	throwException "$error_result" "105064"
fi
echo "1|30|SUCCESS"


######################################################################################
######                                                                           #####
######                          check vmlibrary		                             #####
######                                                                           #####
######################################################################################
check_repo


######################################################################################
######                                                                           #####
######                          create virtual cdrom                             #####
######                                                                           #####
######################################################################################
log_info $LINENO "create virtual cdrom"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli mkvdev -fbo -vadapter ${vadapter_vios}\" | awk '{print \$1}'"
vadapter_vcd=$(ssh ${ivm_user}@${ivm_ip} "ioscli mkvdev -fbo -vadapter ${vadapter_vios}" 2> ${error_log} | awk '{print $1}')
log_debug $LINENO "vadapter_vcd=${vadapter_vcd}"
catchException "${error_log}"
if [ "${error_result}" != "" ]
then
	ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
	throwException "$error_result" "105017"
fi
echo "1|31|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                       create virtual_fc_adapters                          #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "create virtual_fc_adapters"
vfc_slot=19
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"chhwres -r virtualio --rsubtype fc --id $lpar_id -o a -s $vfc_slot\""
vfc_info=$(ssh ${ivm_user}@${ivm_ip} "chhwres -r virtualio --rsubtype fc --id $lpar_id -o a -s $vfc_slot" 2> "${error_log}")
log_debug $LINENO "vfc_info=${vfc_info}"
catchException "${error_log}"
if [ "${error_result}" != "" ]
then
	ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
	throwException "$error_result" "105013"
fi
echo "1|32|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                  get virtual_fc_adapters server id        	            #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "Get virtual_fc_adapters server id"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"lssyscfg -r prof --filter lpar_ids=${lpar_id} -F virtual_fc_adapters\""
server_vfc_id=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r prof --filter lpar_ids=${lpar_id} -F virtual_fc_adapters"  2> "${error_log}" | sed 's/"//g'| awk -F'/' '{print $5}')
log_debug $LINENO "server_vfc_id=${server_vfc_id}"
catchException "${error_log}"
if [ "${error_result}" != "" ]
then
	ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
	throwException "$error_result" "105063"
fi
echo "1|33|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                            get virtual_fc_adapters                        #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "get vios' adapter"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli lsmap -all -npiv -fmt :\" | grep ${serial_num} | grep "C${server_vfc_id}:" | awk -F":" '{print $1}'"
vadapter_fc=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -all -npiv -fmt :" 2> "${error_log}" | grep ${serial_num} | grep "C${server_vfc_id}:" | awk -F":" '{print $1}')
log_debug $LINENO "vadapter_fc=${vadapter_fc}"
catchException "${error_log}"
if [ "${error_result}" != "" ]
then
	ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
	throwException "$error_result" "105064"
fi
echo "1|34|SUCCESS"


######################################################################################
######                                                                           #####
######                             	 copy iso                                 	 #####
######                                                                           #####
######################################################################################
log_info $LINENO "copy iso"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ls -l ${template_path}/${template_dir}/${template_name}\" | awk '{print \$5}'"
iso_size=$(ssh ${ivm_user}@${ivm_ip} "ls -l ${template_path}/${template_dir}/${template_name}" 2> ${error_log} | awk '{print $5}')
log_debug $LINENO "iso_size=${iso_size}"
catchException "${error_log}"
if [ "$error_result" != "" ]
then
	ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
	throwException "$error_result" "105014"
fi
ls_result=$(ssh ${ivm_user}@${ivm_ip} "ls -l ${cdrom_path}/${new_template_name}" 2> ${error_log})
catchException "${error_log}"
if [ "$error_result" == "" ]
then
	if [ "$(echo $ls_result | awk '{print $5}')" != "$iso_size" ]
	then
		lsvopt=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsvopt -field vtd media -fmt :" 2>&1)
		if [ $? -ne 0 ]
		then
			ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
			throwException "$lsvopt" "105014"
		fi
		iso_vtd=$(echo "$lsvopt" | awk -F":" '{if($2==iso) print $1}' iso="$template_name")
		
		if [ "$iso_vtd" != "" ]
		then
			for vopt_vtd in $iso_vtd
			do
				
				result=$(ssh ${ivm_user}@${ivm_ip} "ioscli unloadopt -release -vtd $vopt_vtd" 2>&1)
				if [ $? -ne 0 ]
				then
					ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
					throwException "$result" "105014"
				fi
			done
		fi
		result=$(ssh ${ivm_user}@${ivm_ip} "ioscli rmvopt -f -name ${template_name}" 2>&1)
		if [ $? -ne 0 ]
		then
			ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
			throwException "$result" "105014"
		fi
		ssh ${ivm_user}@${ivm_ip} "ioscli mkvopt -name ${new_template_name} -file ${template_path}/${template_dir}/${template_name}" 2> $error_log &
		mkvoptCheck
	fi
else
	ssh ${ivm_user}@${ivm_ip} "ioscli mkvopt -name ${new_template_name} -file ${template_path}/${template_dir}/${template_name}" 2> $error_log &
	mkvoptCheck
fi
echo "1|85|SUCCESS"

######################################################################################
######                                                                           #####
######                            change access                             	 #####
######                                                                           #####
######################################################################################
log_info $LINENO "change access"
log_debug $LINENO "CMD:expect ./ssh.exp ${ivm_user} ${ivm_ip} \"oem_setup_env|chmod 444 ${cdrom_path}/${new_template_name}\""
result=$(expect ./ssh.exp ${ivm_user} ${ivm_ip} "oem_setup_env|chmod 444 ${cdrom_path}/${new_template_name}" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	throwException "$result" "105017"
fi
log_debug $LINENO "result=${result}"
echo "1|87|SUCCESS"

######################################################################################
######                                                                           #####
######                                mount iso                                	 #####
######                                                                           #####
######################################################################################
log_info $LINENO "mount iso"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli loadopt -disk ${new_template_name} -vtd ${vadapter_vcd}\""
mount_result=$(ssh ${ivm_user}@${ivm_ip} "ioscli loadopt -disk ${new_template_name} -vtd ${vadapter_vcd}" 2> ${error_log})
log_debug $LINENO "mount_result=${mount_result}"
catchException "${error_log}"
if [ "$error_result" != "" ]
then
	ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
	throwException "$error_result" "105018"
fi
echo "1|89|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                             create NPIV mapping                           #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "create mapping"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli vfcmap -vadapter ${vadapter_fc} -fcp ${fc_name}\""
mapping_result=$(ssh ${ivm_user}@${ivm_ip} "ioscli vfcmap -vadapter ${vadapter_fc} -fcp ${fc_name}" 2> ${error_log})
log_debug $LINENO "mapping_result=${mapping_result}"
catchException "${error_log}"
if [ "$error_result" != "" ]
then
	ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
	throwException "$error_result" "105018"
fi
echo "1|90|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                          		unmount nfs	                                #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "unmount nfs"
unmount_nfs


if [ "$log_flag" == "0" ]
then
	rm -f "${error_log}" 2> /dev/null
	rm -f "$out_log" 2> /dev/null
fi

echo "1|100|SUCCESS"

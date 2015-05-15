#!/usr/bin/ksh
#./ivm_migrate_active_validate.sh "172.30.126.13|padmin|12|172.30.126.10|padmin"

#echo "1|0|SUCCESS"

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
			echo "0|0|ERROR-${error_code}:"$(echo "$result" | awk -F']' '{print $2}') >&2
		else
			echo "0|0|ERROR-${error_code}: ${result}"                                 >&2
		fi
		
		if [ "$log_flag" == "0" ]
		then
			rm -f "${error_log}" 2> /dev/null
			rm -f "$out_log" 2> /dev/null
		fi
		exit 1
	fi

}

validate_migrate_aix()
{
  echo "{\"migrate_state\": \c"
  echo "\"$1\" }"
}

validate_migrate_linux()
{
  echo -e "{\"migrate_state\": \c"
  echo -e "\"$1\" }"
}

print_info()
{
   case $(uname -s) in
	AIX)
			validate_migrate_aix $1;;
	Linux)
			validate_migrate_linux $1;;
  esac
}

j=0
echo $1 |awk -F"|" '{for(i=1;i<=NF;i++) print $i}' | while read param
do
        case $j in
                        0)
                                j=1;
                                ivm_source_ip=$param;;
                        1)
                                j=2;        
                                ivm_source_user=$param;;
                        2)
                                j=3;
                                lpar_id=$param;;
                        3)
                        		j=4;
                                ivm_target_ip=$param;;
                        4)
                        		j=5;
                                ivm_target_user=$param;;
        esac
done

log_flag=$(cat scrpits.properties 2> /dev/null | grep "LOG=" | awk -F"=" '{print $2}')
if [ "$log_flag" == "" ]
then
	log_flag=0
fi

DateNow=$(date +%Y%m%d%H%M%S)
random=$(perl -e 'my $random = int(rand(9999)); print "$random";')
out_log="${path_log}/out_ivm_migrate_active_validate_${DateNow}_${random}.log"
error_log="${path_log}/error_ivm_migrate_active_validate_${DateNow}_${random}.log"

#echo "1|10|SUCCESS"
log_debug $LINENO "$0 $*"


######################################################################################
######                                                                           #####
######                       judge parameter:null or not                         #####
######                                                                           #####
######################################################################################

if [ "$ivm_source_ip" == "" ]
then
	throwException "ivm_source_ip is null" "105005" 
fi

if [ "$ivm_source_user" == "" ]
then
	throwException "ivm_source_user is null" "105005" 
fi

if [ "$lpar_id" == "" ]
then
	throwException "Lpar id is null" "105005" 
fi

if [ "$ivm_target_ip" == "" ]
then
	throwException "ivm_target_ip is null" "105005" 
fi

if [ "$ivm_target_user" == "" ]
then
	throwException "ivm_target_user is null" "105005" 
fi
#echo "1|20|SUCCESS"

ssh ${ivm_source_user}@${ivm_source_ip} "lssyscfg -r lpar --filter lpar_ids=$lpar_id" > /dev/null 2> ${error_log}
catchException "${error_log}"
throwException "$error_result" "105005" 

##############################new add:begin####################################
##############################new add:begin####################################
log_info $LINENO ""
log_debug $LINENO "CMD:ssh ${ivm_source_user}@${ivm_source_ip} \"lshwres -r io --rsubtype slot --filter \"lpar_ids=$lpar_id\"\""
io_adapters=$(ssh ${ivm_source_user}@${ivm_source_ip} "lshwres -r io --rsubtype slot --filter \"lpar_ids=$lpar_id\"" 2> ${error_log})
#echo "io_adapters:$io_adapters"
log_debug $LINENO "io_adapters=${io_adapters}"
if [ "$io_adapters" != ""  ]
then
	throwException "The migrated partition has special adapters." "105068"
fi


###########################get virtual_scsi_adapters server id #################
log_info $LINENO "Get virtual_scsi_adapters server id"
log_debug $LINENO "CMD:ssh ${ivm_source_user}@${ivm_source_ip} \"lssyscfg -r prof --filter lpar_ids=${lpar_id} -F virtual_scsi_adapters\" | awk -F'/' '{print \$5}'"
server_vscsi_id=$(ssh ${ivm_source_user}@${ivm_source_ip} "lssyscfg -r prof --filter lpar_ids=${lpar_id} -F virtual_scsi_adapters" | awk -F'/' '{print $5}' 2> "${error_log}")
if [ "$(echo $?)" != "0" ]
then
	if [ "$server_vscsi_id" != "" ]
	then
		throwException "$server_vscsi_id" "105063"
	else
		catchException "${error_log}"
		throwException "$error_result" "105063"
	fi
fi
log_debug $LINENO "server_vscsi_id=${server_vscsi_id}"


#########################get vios' adapter #########################
log_info $LINENO "get vios' adapter"
log_debug $LINENO "CMD:ssh ${ivm_source_user}@${ivm_source_ip} \"lssyscfg -r sys -F serial_num\""
serial_num=$(ssh ${ivm_source_user}@${ivm_source_ip} "lssyscfg -r sys -F serial_num" 2> $error_log)
if [ "$(echo $?)" != "0" ]
then
	if [ "$serial_num" != "" ]
	then
		throwException "$serial_num" "105060"
	else
		catchException "${error_log}"
		throwException "$error_result" "105060"
	fi
fi
log_debug $LINENO "serial_num=${serial_num}"

log_info $LINENO "get vios' adapter"
log_debug $LINENO "CMD:ssh ${ivm_source_user}@${ivm_source_ip} \"ioscli lsmap -all -fmt :\" | grep ${serial_num} | grep "C${server_vscsi_id}:" | awk -F":" '{print $1}'"
vadapter_vios=$(ssh ${ivm_source_user}@${ivm_source_ip} "ioscli lsmap -all -fmt :" | grep ${serial_num} | grep "C${server_vscsi_id}:" | awk -F":" '{print $1}' 2> "${error_log}")
if [ "$(echo $?)" != "0" ]
then
	if [ "$vadapter_vios" != "" ]
	then
		throwException "$vadapter_vios" "105064"
	else
		catchException "${error_log}"
		throwException "$error_result" "105064"
	fi
fi
log_debug $LINENO "vadapter_vios=${vadapter_vios}"
#echo "1|50|SUCCESS"

#########################get backing device:pv #########################
log_info $LINENO "get backing device:pv"
log_debug $LINENO "CMD:ssh ${ivm_source_user}@${ivm_source_ip} \"ioscli lsmap -vadapter $vadapter_vios -field backing -type disk\" | awk '{print $NF}'"
backing=$(ssh ${ivm_source_user}@${ivm_source_ip} "ioscli lsmap -vadapter $vadapter_vios -field backing -type disk" | awk '{print $NF}' 2> "${error_log}")
if [ "$(echo $?)" != "0" ]
then
	if [ "$backing" != "" ]
	then
		throwException "$backing" "105064"
	else
		catchException "${error_log}"
		throwException "$error_result" "105064"
	fi
fi

######################## get backing device:lu #########################
lu_backings=$(ssh ${ivm_source_user}@${ivm_source_ip} "ioscli lsmap -vadapter $vadapter_vios -field backing" | awk '{print $NF}' 2> "${error_log}")
if [ "$(echo $?)" != "0" ]
then
	if [ "$lu_backings" != "" ]
	then
		throwException "$lu_backings" "105064"
	else
		catchException "${error_log}"
		throwException "$error_result" "105064"
	fi
fi

lu_back="false"
ssp_clusters=$(ssh ${ivm_source_user}@${ivm_source_ip} "ioscli cluster -list|grep -E 'CLUSTER_NAME' "|awk '{print $2}')
for ssp_cluster in 	`echo "$ssp_clusters"`
do
	ssp_cluster_info=$(ssh ${ivm_source_user}@${ivm_source_ip} "ioscli lssp -clustername $ssp_cluster")
	#echo $ssp_cluster
	pool_name=$(echo "$ssp_cluster_info" |grep -E 'POOL_NAME'|awk '{print $2}')
	lu_info=$(ssh ${ivm_source_user}@${ivm_source_ip} "ioscli lssp -clustername $ssp_cluster -sp $pool_name -bd | grep -v \"Lu Name \"")
	
	OLDIFS=$IFS;IFS='
	';
	for lu in `echo "$lu_info"`
	do	
		lu_name=$(echo "$lu" | awk '{print $1}')
		lu_id=$(echo "$lu" | awk '{print $NF}')
		lu_file=$(echo $lu_name"."$lu_id)
		#echo "lu_file is :$lu_file"
		for lu_backing in `echo "$lu_backings"`
		do
			if [ "$lu_file"  == "$lu_backing" ]
			then
				IFS=$OLDIFS
				lu_back="true"
				break 2
			fi
		done
	
	done
	IFS=$OLDIFS
	
done
#echo "lu_back is:$lu_back"


######################### backing device:pv or lu #########################
if [ "$backing" == "" -a "lu_back" == "false" ]
then
	throwException "Backing device must be share storage." "105064"
fi

if [ "$backing" != "" ]
then
	#check_share_pv $backing				  >> $out_log
	check_unique_id=$(lsattr -El $backing | grep unique_id |  awk '{print $2}')
	pvs=$(ssh ${ivm_target_user}@${ivm_target_ip} "ioscli lspv | grep -v "NAME"| awk '{print \$1}'")
	for pv in `echo $pvs`
	do
		unique_id_info=$(lsattr -El $pv | grep unique_id 2>/dev/null )
		if [ "$unique_id_info" != ""  ]
		then
			unique_id=$(echo $unique_id_info | awk '{print $2}')
			log_debug $LINENO "unique_id of $pv is: $unique_id"
			if [ "$check_unique_id" == "$unique_id" ]
			then
				log_debug $LINENO "$pv equals to $backing,id is $unique_id"
			fi
		fi
	done
	
	log_debug $LINENO "backing=${backing}"

	#########################check reserve_policy #########################

	log_info $LINENO "check reserve_policy"
	reserve_policy=$(ssh ${ivm_source_user}@${ivm_source_ip} "oem_setup_env <<eof
	lsattr -El $backing | grep reserve_policy
	<<eof" | awk '{print $2}' 2> "${error_log}")
	log_debug $LINENO "reserve_policy=${reserve_policy}"
	if [ "$(echo $?)" != "0"  -o "$reserve_policy" != "no_reserve" ]
	then
		if [ "$reserve_policy" != "" ]
		then
			#echo "reserve_policy wrong." >> $error_log
			throwException "reserve_policy wrong:$reserve_policy" "105064"
		else
			#echo "reserve_policy wrong." >> $error_log
			catchException "${error_log}"
			throwException "reserve_policy wrong:$error_result" "105064"
		fi
	fi
fi

#########################check vios slots #########################
log_info $LINENO "check vios slots"
log_debug $LINENO "CMD:ssh ${ivm_target_user}@${ivm_target_ip} \"lssyscfg -r lpar -F lpar_id,lpar_env\""
vm_sys_info=$(ssh ${ivm_target_user}@${ivm_target_ip} "lssyscfg -r lpar -F lpar_id,lpar_env")
log_debug $LINENO "vm_sys_info=${vm_sys_info}"
echo "$vm_sys_info" | while read sys
do
	if [ "$(echo $sys | awk -F"," '{print $2}')" == "vioserver" ]
	then
		target_vios_id=$(echo $sys | awk -F"," '{print $1}')
		log_debug $LINENO "target_vios_id=${target_vios_id}"
	fi
done

log_debug $LINENO "CMD:ssh ${ivm_target_user}@${ivm_target_ip} \"lssyscfg -r prof --filter \"lpar_ids=$target_vios_id\" -F max_virtual_slots\""
vios_slots_num=$(ssh ${ivm_target_user}@${ivm_target_ip} "lssyscfg -r prof --filter \"lpar_ids=$target_vios_id\" -F max_virtual_slots")
if [ "$(echo $?)" != "0" ]
then
	if [ "$vios_slots_num" != "" ]
	then
		throwException "$vios_slots_num" "105064"
	else
		catchException "${error_log}"
		throwException "$error_result" "105064"
	fi
fi
log_debug $LINENO "vios_slots_number=${vios_slots_num}"

if [ $vios_slots_num -lt 1 ]
then
	#echo "vios_slots_number is less then need." >> $error_log
	throwException "vios_slots_number is less then need" "105064"
fi

#############################check sea #############################
log_info $LINENO "check sea"
source_sea=$(ssh ${ivm_source_user}@${ivm_source_ip} "ioscli lsdev -type sea")
target_sea=$(ssh ${ivm_target_user}@${ivm_target_ip} "ioscli lsdev -type sea")
log_debug $LINENO "source_sea=${source_sea}"
log_debug $LINENO "target_sea=${target_sea}"

source_sea_num=$(echo "$source_sea" | grep " Shared Ethernet Adapter" | wc -l )
target_sea_num=$(echo "$target_sea" | grep " Shared Ethernet Adapter" | wc -l )
if [ $source_sea_num -eq 0 ]
then
	#echo "There is at least 1 sea on source vios:$ivm_source_ip." >> $error_log
	throwException "There is at least 1 sea on source vios:$ivm_source_ip." "105064"    
fi

if [ $target_sea_num -eq 0 ]
then
	#echo "There is at least 1 sea on target vios:$ivm_source_ip." >> $error_log
	throwException "There is at least 1 sea on target vios:$ivm_target_ip." "105064"    
fi

#######################check target lpar name ######################
log_info $LINENO "check target lpar name"
source_name=$(ssh ${ivm_source_user}@${ivm_source_ip} "lssyscfg -r lpar -F name --filter lpar_ids=$lpar_id")
target_names=$(ssh ${ivm_target_user}@${ivm_target_ip} "lssyscfg -r lpar -F name")
log_debug $LINENO "target_names=${target_names}"
target_name=$(echo "$target_names" | grep $source_name)
if [ "$target_name" != "" ]
then
	#echo "Target name can not be the same as source name." >> $error_log
	throwException "Target name can not be the same as source name." "105064"    
fi


###########################check ISO file ##########################
log_info $LINENO "check ISO file"
isoinfo=$(ssh ${ivm_source_user}@${ivm_source_ip} "ioscli lsmap -vadapter $vadapter_vios -field vtd" 2> "${error_log}")
vtopt_file=$(echo "$isoinfo" | awk '{print $2}' | grep vtopt)
if [ "$vtopt_file" != "" ]
then
	iso_files=$(ssh ${ivm_source_user}@${ivm_source_ip} "ioscli lsvopt -vtd $vtopt_file " 2> "${error_log}")
	log_debug $LINENO "iso_files=${iso_files}"
	iso_notExist=$(echo "$iso_files" | grep "No Media" | wc -l)
	if [ $iso_notExist -eq 0  ]
	then
		#echo "ISO file in CD must eject first." >> $error_log
		throwException "ISO file in CD must eject first." "105064"    
	fi
fi

####################new add:end######################################
####################new add:end######################################



######################################################################################
######                                                                           #####
######                              check rmc state                              #####
######                                                                           #####
######################################################################################
log_info $LINENO "check rmc state"
log_debug $LINENO "CMD:ssh ${ivm_source_user}@${ivm_source_ip} \"lssyscfg -r lpar --filter lpar_ids=$lpar_id -F rmc_state\""
rmc_state=$(ssh ${ivm_source_user}@${ivm_source_ip} "lssyscfg -r lpar --filter lpar_ids=$lpar_id -F rmc_state" 2> ${error_log})
log_debug $LINENO "rmc_state=${rmc_state}"
if [ "$rmc_state" == "active" -o "$rmc_state" == "inactive" ]
then
   : 
else
   throwException "rmc state or vm status is not ready." "105068" 
fi

#####################################################################################
#####                                                                           #####
#####              get target host type_model and serial number                 #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "check target host type_model"
log_debug $LINENO "CMD:ssh ${ivm_target_user}@${ivm_target_ip} \"lssyscfg -r sys -F type_model,serial_num\" | sed 's/,/\*/'"
host_num=$(ssh ${ivm_target_user}@${ivm_target_ip} "lssyscfg -r sys -F type_model,serial_num" 2> "${error_log}" | sed 's/,/\*/')
log_debug $LINENO "host_num=${host_num}"
#echo "1|40|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                  check migrate lpar authorized keys                       #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "check migrate lpar authorized keys"
log_debug $LINENO "CMD:ssh ${ivm_source_user}@${ivm_source_ip} \"mkauthkeys --test --ip ${ivm_target_ip} -u ${ivm_target_user}\""
result=$(ssh ${ivm_source_user}@${ivm_source_ip} "mkauthkeys --test --ip ${ivm_target_ip} -u ${ivm_target_user}" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	log_debug $LINENO "CMD:ssh ${ivm_source_user}@${ivm_source_ip} \"mkauthkeys -g\""
	rsa=$(ssh ${ivm_source_user}@${ivm_source_ip} "mkauthkeys -g" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		throwException "$rsa" "105087"
	else
		log_debug $LINENO "CMD:ssh ${ivm_target_user}@${ivm_target_ip} \"mkauthkeys -a \"$rsa\"\""
		result=$(ssh ${ivm_target_user}@${ivm_target_ip} "mkauthkeys -a \"$rsa\"" 2>&1)
		if [ "$(echo $?)" != "0" ]
		then
			throwException "$result" "105087"
		fi
	fi
fi


#####################################################################################
#####                                                                           #####
#####                       validate a partition migration                      #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "validate a partition migration"
log_debug $LINENO "CMD:ssh ${ivm_source_user}@${ivm_source_ip} \"migrlpar -o v -t ${host_num} --ip ${ivm_target_ip} -u ${ivm_target_user} --id $lpar_id\""
migr_validate=$(ssh ${ivm_source_user}@${ivm_source_ip} "migrlpar -o v -t ${host_num} --ip ${ivm_target_ip} -u ${ivm_target_user} --id $lpar_id" > /dev/null)
if [ "$(echo $?)" != "0" ]
then
   #echo "1|100|SUCCESS"
   print_info 0
else
   #echo "1|100|SUCCESS"
   print_info 1
fi

if [ "$log_flag" == "0" ]
then
	rm -f "${error_log}" 2> /dev/null
	rm -f "$out_log" 2> /dev/null
fi








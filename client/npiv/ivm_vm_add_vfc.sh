#!/usr/bin/ksh

. ../ivm_function.sh

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
			echo "ERROR-${error_code}:"$(echo "$result" | awk -F']' '{print $2}') >&2
		else
			echo "ERROR-${error_code}: $result" >&2
		fi
		
		if [ "$log_flag" == "0" ]
		then
			rm -f "${error_log}" 2> /dev/null
			rm -f "$out_log" 2> /dev/null
		fi
		exit 1
	fi

}

aix_getinfo() {
echo "{\c"
echo "\"name\":\"${vadapter_fc}\", \c"
echo "\"status\":\"${vfchost_status}\", \c"
echo "\"vPhysicalSlotNo\":\"${vfchost_physloc}\", \c"
echo "\"vmId\":\"${lpar_id}\", \c"
echo "\"SlotNo\":\"${add_new_slot}\", \c"
echo "\"vWwpn\":\"${vfchost_vwwpn}\" \c"
echo "}"
}

linux_getinfo() {
echo -e "{\c"
echo -e "\"name\":\"${vadapter_fc}\", \c"
echo -e "\"status\":\"${vfchost_status}\", \c"
echo -e "\"vPhysicalSlotNo\":\"${vfchost_physloc}\", \c"
echo -e "\"vmId\":\"${lpar_id}\", \c"
echo -e "\"SlotNo\":\"${add_new_slot}\", \c"
echo -e "\"vWwpn\":\"${vfchost_vwwpn}\" \c"
echo -e "}"
}

log_flag=$(cat ../scrpits.properties 2> /dev/null | grep "LOG=" | awk -F"=" '{print $2}')
if [ "$log_flag" == "" ]
then
	log_flag=0
fi

ivm_ip=$1
ivm_user=$2
lpar_id=$3
fc_port=$4

if [ "$ivm_ip" == "" ]
then
	throwException "IP is null" "105053"
fi

if [ "$ivm_user" == "" ]
then
	throwException "User name is null" "105053"
fi

if [ "$lpar_id" == "" ]
then
	throwException "Lpar id is null" "105053"
fi

if [ "$fc_port" == "" ]
then
	throwException "FC port is null" "105053"
fi

DateNow=$(date +%Y%m%d%H%M%S)
random=$(perl -e 'my $random = int(rand(9999)); print "$random";')
out_log="${path_log}/out_ivm_vm_add_vfc_${DateNow}_${random}.log"
error_log="${path_log}/error_ivm_vm_add_vfc_${DateNow}_${random}.log"

log_debug $LINENO "$0 $*"

check_authorized ${ivm_ip} ${ivm_user}

vios_id=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar -F lpar_id,lpar_env" | awk -F"," '{if($2=="vioserver") print $1}')
lpar_state=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar -F state --filter lpar_ids=$lpar_id")
rmc_state=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar -F rmc_state,dlpar_io_capable --filter lpar_ids=${lpar_id}")

# echo "rmc_state==$rmc_state"

if [ "$lpar_state" != "Not Activated" ]&&[ "$rmc_state" != "active,1" ]
then
	throwException "Lpar does not support dynamic modification, please shutdown first." "105068"
fi

max_virtual_slots=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r prof -F max_virtual_slots --filter lpar_ids=\"${lpar_id}\"" 2> $error_log) 
catchException "${error_log}"
throwException "$error_result" "105075"
#echo $max_virtual_slots

# virtrual_fc_adapters="virtual_fc_adapters"
# virtual_adapters="virtual_eth_adapters,virtual_opti_pool_id,virtual_scsi_adapters,virtual_serial_adapters"

# virtual_adapters_list=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r prof -F $virtual_adapters --filter lpar_ids=\"${lpar_id}\"" 2> $error_log)
# catchException "${error_log}"
# throwException "$error_result" "105076"

# virtual_fc_adapters_list=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r prof -F $virtrual_fc_adapters --filter lpar_ids=\"${lpar_id}\"" 2> $error_log)
# catchException "${error_log}"
# throwException "$error_result" "105076"

#echo $virtual_adapters_list
# fc_slot_number=$(echo $virtual_fc_adapters_list|awk -F"\",\"" '{for(i=1;i<=NF;i++) print $i}' | sed 's/"//g' | awk -F[/] '{print $1}')
# other_slot_number=$(echo $virtual_adapters_list | sed 's/"//g' |awk -F[,] '{for(i=1;i<=NF;i++) print $i}' | awk -F[/] '{print $1}')
# all_slot_number=$(echo "$fc_slot_number $other_slot_number")
# echo $all_slot_number

all_slot_number=$(ssh ${ivm_user}@${ivm_ip} "lshwres -r virtualio --rsubtype slot --level slot --filter lpar_ids=$lpar_id -F slot_num" 2> $error_log)
#echo $all_slot_number

add_new_slot=5
# echo "all_slot_number==$all_slot_number"

while [ $add_new_slot -le $max_virtual_slots ]
do
	flag=0
	for param in $all_slot_number
	do
		if [ "$param" == "$add_new_slot" ]
		then
			flag=1
			break		 
		fi
	done
	if [ "$flag" == "0" ]
	then
		break
	fi
	add_new_slot=$(expr $add_new_slot + 1)
done

# echo "add_new_slot==$add_new_slot"
# echo "max_virtual_slots==$max_virtual_slots"


if [ $add_new_slot -ge $max_virtual_slots ]
then
	throwException "Reconfig virtual machine's nic failed, No free slot number." "105078"
fi
#echo $add_new_slot

#####################################################################################
#####                                                                           #####
#####                       get host serial number                              #####
#####                                                                           #####
#####################################################################################
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"lssyscfg -r sys -F serial_num\""
serial_num=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r sys -F serial_num" 2> ${error_log})
log_debug $LINENO "serial_num=${serial_num}"
catchException "${error_log}"
throwException "$error_result" "105060"

#####################################################################################
#####                                                                           #####
#####                       create virtual_fc_adapters                          #####
#####                                                                           #####
#####################################################################################
if [ "$lpar_state" == "Not Activated" ] || [ "$rmc_state" == "active,1" ]
then
	log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"chhwres -r virtualio --rsubtype fc --id $lpar_id -o a -s $add_new_slot\""
	vfc_info=$(ssh ${ivm_user}@${ivm_ip} "chhwres -r virtualio --rsubtype fc --id $lpar_id -o a -s $add_new_slot" 2> "${error_log}")
	log_debug $LINENO "vfc_info=${vfc_info}"
	catchException "${error_log}"
	throwException "$error_result" "105079"
else
	throwException "Lpar does not support dynamic modification, please shutdown first." "105068"
fi

#####################################################################################
#####                                                                           #####
#####                  get virtual_fc_adapters server id        	            #####
#####                                                                           #####
#####################################################################################
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"lssyscfg -r prof --filter lpar_ids=${lpar_id} -F virtual_fc_adapters\""
server_vfc_info=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r prof --filter lpar_ids=${lpar_id} -F virtual_fc_adapters"  2> "${error_log}")
log_debug $LINENO "server_vfc_info=${server_vfc_info}"
server_vfc_id=$(echo $server_vfc_info|awk -F"\",\"" '{for(i=1;i<=NF;i++) print $i}'|sed 's/"//g'|awk -F"/" '{if($1==slot_num) print $5}' slot_num=$add_new_slot)
catchException "${error_log}"
throwException "$error_result" "105063"

vfchost_vwwpn=$(echo "$server_vfc_info"|awk -F"\",\"" '{for(i=1;i<=NF;i++) print $i}'|sed 's/"//g'| awk -F[/] '{if($1==slot_num) print $6}' slot_num=$add_new_slot | awk -F"," '{print $1}')
catchException "${error_log}"
throwException "$error_result" "105063"

#####################################################################################
#####                                                                           #####
#####                            get virtual_fc_adapters                        #####
#####                                                                           #####
#####################################################################################
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli lsmap -all -npiv -fmt :\""
vadapter_fc_info=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -all -npiv -fmt :" 2> "${error_log}")
log_debug $LINENO "vadapter_fc_info=${vadapter_fc_info}"
catchException "${error_log}"
throwException "$error_result" "105064"
vadapter_fc=$(echo "${vadapter_fc_info}" | grep ${serial_num} | grep "C${server_vfc_id}:" | awk -F":" '{print $1}')
vfchost_physloc=$(echo "${vadapter_fc_info}" | grep ${serial_num} | grep "C${server_vfc_id}:"| awk -F":" '{print $2}')
vfchost_status=$(echo "${vadapter_fc_info}" | grep ${serial_num} | grep "C${server_vfc_id}:"| awk -F":" '{print $6}')

#####################################################################################
#####                                                                           #####
#####                             create NPIV mapping                           #####
#####                                                                           #####
#####################################################################################
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli vfcmap -vadapter ${vadapter_fc} -fcp ${fc_port}\""
mapping_result=$(ssh ${ivm_user}@${ivm_ip} "ioscli vfcmap -vadapter ${vadapter_fc} -fcp ${fc_port}" 2> ${error_log})
log_debug $LINENO "mapping_result=${mapping_result}"
catchException "${error_log}"
if [ "${error_result}" != "" ]
then
	ssh ${ivm_user}@${ivm_ip} "chhwres -r virtualio --rsubtype fc --id $lpar_id -o r -s $add_new_slot"  > /dev/null 2>&1
fi
throwException "$error_result" "105018"


case $(uname -s) in
	AIX)
		aix_getinfo;;
	Linux)
		linux_getinfo;;
	*BSD)
		bsd_getinfo;;
	SunOS)
		sun_getinfo;;
	HP-UX)
		hp_getinfo;;
	*) echo "unknown";;
esac

if [ "$log_flag" == "0" ]
then
	rm -f "${error_log}" 2> /dev/null
	rm -f "$out_log" 2> /dev/null
fi

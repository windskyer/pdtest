#!/usr/bin/ksh

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
	echo  "{\c"
	echo  "\"eth_slot\":\"${add_new_slot}\", \c"
	echo  "\"eth_id\":\"${eth_num}\", \c"
	echo  "\"eth_name\":\"eth${eth_num}\", \c"
	echo  "\"eth_pvid\":\"$vlan_id\", \c"
	num=0
	vm_physloc=""
	while [ $num -lt $sea_length ]
	do
		if [ "$(echo ${vlan_ids[$num]} | awk -F"," '{ for(i=1;i<=NF;i++) { if($i==vlan_id) {print 0; break;} } }' vlan_id=$vlan_id)" == "0" ]
		then
			vm_physloc=$(echo "${sea_physloc[$num]}" | sed 's/ //g')
			break
		fi
		num=$(expr $num + 1)
	done
	echo  "\"eth_physloc\":\"$vm_physloc\"\c"
	echo  "}"
}

linux_getinfo() {
	echo -e "{\c"
	echo -e "\"eth_slot\":\"${add_new_slot}\", \c"
	echo -e "\"eth_id\":\"${eth_num}\", \c"
	echo -e "\"eth_name\":\"eth${eth_num}\", \c"
	echo -e "\"eth_pvid\":\"$vlan_id\", \c"
	num=0
	vm_physloc=""
	while [ $num -lt $sea_length ]
	do
		if [ "$(echo ${vlan_ids[$num]} | awk -F"," '{ for(i=1;i<=NF;i++) { if($i==vlan_id) {print 0; break;} } }' vlan_id=$vlan_id)" == "0" ]
		then
			vm_physloc=$(echo "${sea_physloc[$num]}" | sed 's/ //g')
			break
		fi
		num=$(expr $num + 1)
	done
	echo -e "\"eth_physloc\":\"$vm_physloc\"\c"
	echo -e "}"
}

log_flag=$(cat scrpits.properties 2> /dev/null | grep "LOG=" | awk -F"=" '{print $2}')
if [ "$log_flag" == "" ]
then
	log_flag=0
fi

ivm_ip=$1
ivm_user=$2
lpar_id=$3
vlan_id=$4

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

if [ "$vlan_id" == "" ]
then
	throwException "Vlan id is null" "105053"
fi

DateNow=$(date +%Y%m%d%H%M%S)
random=$(perl -e 'my $random = int(rand(9999)); print "$random";')
out_log="${path_log}/out_ivm_vm_add_eth_${DateNow}_${random}.log"
error_log="${path_log}/error_ivm_vm_add_eth_${DateNow}_${random}.log"

log_debug $LINENO "$0 $*"

log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"lssyscfg -r lpar -F lpar_id,lpar_env\""
vios_id=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar -F lpar_id,lpar_env" | awk -F"," '{if($2=="vioserver") print $1}')
log_debug $LINENO "vios_id=${vios_id}"

log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"lssyscfg -r lpar -F state --filter lpar_ids=$lpar_id\""
lpar_state=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar -F state --filter lpar_ids=$lpar_id")
log_debug $LINENO "lpar_state=${lpar_state}"

log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"lssyscfg -r lpar -F rmc_state,dlpar_io_capable --filter lpar_ids=${lpar_id}\""
rmc_state=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar -F rmc_state,dlpar_io_capable --filter lpar_ids=${lpar_id}")
log_debug $LINENO "rmc_state=${rmc_state}"

# echo "rmc_state==$rmc_state"

if [ "$lpar_state" != "Not Activated" ]&&[ "$rmc_state" != "active,1" ]
then
	throwException "Lpar does not support dynamic modification, please shutdown first." "105068"
fi
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli lsdev -type sea\""
sea_name=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsdev -type sea" | grep Available | awk '{print $1}')
log_debug $LINENO "sea_name=${sea_name}"

log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli lsmap -all -net -field svea physloc -fmt :\""
sea_map_info=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -all -net -field svea physloc -fmt :")
log_debug $LINENO "sea_map_info=${sea_map_info}"

# echo "vios_id==$vios_id"
# echo "sea_name==$sea_name"
# echo "sea_map_info==$sea_map_info"

sea_length=0
echo "$sea_name" | while read sea
do
	if [ "$sea" != "" ]
	then
		sea_name[$sea_length]=$sea
		sea_info=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsdev -dev $sea -attr")
		log_debug $LINENO "sea_info=${sea_info}"
		# sea_pvid[$sea_length]=$(echo "$sea_info" | awk '{if($1=="pvid") print $2}')
		sea_pvid_ent=$(echo "$sea_info" | awk '{if($1=="pvid_adapter") print $2}')
		sea_virt_adapters=$(echo "$sea_info" | awk '{if($1=="virt_adapters") print $2}')
		# echo "sea_virt_adapters==$sea_virt_adapters"
		echo ${sea_virt_adapters} | awk -F"," '{for(i=1;i<=NF;i++) print $i}' | while read ent
		do
			if [ "$ent" != "" ]
			then
				if [ "$ent" == "$sea_pvid_ent" ]
				then
					echo "${sea_map_info}" | while read map
					do
						if [ "$sea_pvid_ent" == "$(echo "$map" | awk -F":" '{print $1}')" ]
						then
							sea_physloc[$sea_length]=$(echo "$map" | awk -F":" '{print $2}')
							slot_num=$(echo "$map" | awk -F":" '{print $2}' | awk -F"-" '{print $3}' | sed 's/C//g')
							# echo "slot_num==$slot_num"
							vlans=$(ssh ${ivm_user}@${ivm_ip} "lshwres -r virtualio --rsubtype eth --level lpar --filter lpar_ids=$vios_id,slots=$slot_num -F port_vlan_id,addl_vlan_ids" | sed 's/,none//g' | sed 's/"//g')","$vlans
							log_debug $LINENO "vlans=${vlans}"
							# echo "vlans==$vlans"
							break
						fi
					done
				else
					echo "${sea_map_info}" | while read map
					do
						if [ "$ent" == "$(echo "$map" | awk -F":" '{print $1}')" ]
						then
							slot_num=$(echo "$map" | awk -F":" '{print $2}' | awk -F"-" '{print $3}' | sed 's/C//g')
							log_debug $LINENO "slot_num=${slot_num}"
							# echo "slot_num==$slot_num"
							vlans=$(ssh ${ivm_user}@${ivm_ip} "lshwres -r virtualio --rsubtype eth --level lpar --filter lpar_ids=$vios_id,slots=$slot_num -F port_vlan_id,addl_vlan_ids"  | sed 's/,none//g' | sed 's/"//g')","$vlans
							log_debug $LINENO "vlans=${vlans}"
							# echo "vlans==$vlans"
							break
						fi
					done
				fi
			fi
		done
		vlan_ids[$sea_length]=${vlans%,*}
		
		# echo "sea_name[$sea_length]==${sea_name[$sea_length]}"
		# echo "vlan_id[$sea_length]==${vlan_id[$sea_length]}"
		# echo "sea_physloc[$sea_length]==${sea_physloc[$sea_length]}"
		sea_length=$(expr $sea_length + 1)
	fi
done

log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"lssyscfg -r prof -F max_virtual_slots --filter lpar_ids=\"${lpar_id}\"\""
max_virtual_slots=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r prof -F max_virtual_slots --filter lpar_ids=\"${lpar_id}\"" 2> $error_log) 
log_debug $LINENO "max_virtual_slots=${max_virtual_slots}"
catchException "${error_log}"
throwException "$error_result" "105075"
#echo $max_virtual_slots

log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"lssyscfg -r prof -F virtual_eth_adapters,virtual_fc_adapters,virtual_opti_pool_id,virtual_scsi_adapters,virtual_serial_adapters --filter lpar_ids=\"${lpar_id}\"\""
virtual_adapters="virtual_eth_adapters,virtual_fc_adapters,virtual_opti_pool_id,virtual_scsi_adapters,virtual_serial_adapters"
virtual_adapters_list=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r prof -F $virtual_adapters --filter lpar_ids=\"${lpar_id}\"" 2> $error_log)
log_debug $LINENO "virtual_adapters_list=${virtual_adapters_list}"
catchException "${error_log}"
throwException "$error_result" "105076"

#echo $virtual_adapters_list
all_slot_number=$(echo $virtual_adapters_list | sed 's/"//g' |awk -F[,] '{for(i=1;i<=NF;i++) print $i}' | awk -F[/] '{print $1}')

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
# echo $add_new_slot

if [ "$lpar_state" == "Not Activated" ]
then
	log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"chsyscfg -r prof -i virtual_eth_adapters+=${add_new_slot}/0/${vlan_id}//0/1,lpar_id=${lpar_id}\""
	ssh ${ivm_user}@${ivm_ip} "chsyscfg -r prof -i virtual_eth_adapters+=${add_new_slot}/0/${vlan_id}//0/1,lpar_id=${lpar_id}" 2> $error_log
	catchException "${error_log}"
	#if Power8 cpu,create veth have "Unhandled firmware error"
	if [ "${error_result}" != "" ] && [ "$(echo "$error_result" | grep "VIOSE03FF0000-0149")" == "" ]
	then
		throwException "$error_result" "105079"
	fi
else
	if [ "$rmc_state" == "active,1" ]
	then
		log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"chhwres -r virtualio --rsubtype eth -o a -s $add_new_slot --id $lpar_id -a ieee_virtual_eth=0,port_vlan_id=${vlan_id},is_trunk=0\""
		ssh ${ivm_user}@${ivm_ip} "chhwres -r virtualio --rsubtype eth -o a -s $add_new_slot --id $lpar_id -a ieee_virtual_eth=0,port_vlan_id=${vlan_id},is_trunk=0" > /dev/null 2> $error_log
		catchException "${error_log}"
		#if Power8 cpu,create veth have "Unhandled firmware error"
		if [ "${error_result}" != "" ] && [ "$(echo "$error_result" | grep "VIOSE03FF0000-0149")" == "" ]
		then
			throwException "$error_result" "105079"
		fi
	else
		throwException "Lpar does not support dynamic modification, please shutdown first." "105068"
	fi
fi

log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"lssyscfg -r prof -F virtual_eth_adapters --filter lpar_ids=$lpar_id\""
eth_num=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r prof -F virtual_eth_adapters --filter lpar_ids=$lpar_id" 2> $error_log | awk -F"," '{if($0=="none") print 0; else print NF}')
log_debug $LINENO "eth_num=${eth_num}"
catchException "${error_log}"
throwException "$error_result" "105077"
if [ "$eth_num" != "0" ]
then
	eth_num=$(expr $eth_num - 1)
fi


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

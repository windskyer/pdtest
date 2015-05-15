#!/usr/bin/ksh
#./hmc_vm_ref_eth.sh 172.30.126.19 hscroot p730-2 3 6 2
# lssyscfg -r prof -m p730-2 --filter lpar_ids=3

. ./hmc_function.sh


aix_getinfo() {
	echo  "{\c"
	echo  "\"eth_slot\":\"${slot_num}\", \c"
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
	echo -e "\"eth_slot\":\"${slot_num}\", \c"
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

hmc_ip=$1
hmc_user=$2
host_id=$3
lpar_id=$4
slot_num=$5
vlan_id=$6

if [ "$hmc_ip" == "" ]
then
	echoError "IP is null" "105401"
fi

if [ "$hmc_user" == "" ]
then
	echoError "User name is null" "105402"
fi

if [ "$host_id" == "" ]
then
	echoError "host id is null" "105433"
fi

if [ "$lpar_id" == "" ]
then
	echoError "Lpar id is null" "105434"
fi

DateNow=$(date +%Y%m%d%H%M%S)
random=$(perl -e 'my $random = int(rand(9999)); print "$random";')
out_log="out_vm_add_eth_${DateNow}_${random}.log"
error_log="error_vm_add_eth_${DateNow}_${random}.log"

######################################################################################
######                                                                           #####
######                           get vios info                                   #####
######                                                                           #####
######################################################################################
echo "$(date) : get active vios' id" > $out_log
get_hmc_vios
if [ "$(echo $?)" != "0" ]
then
	echoError "$getHmcViosErrorMsg" "105436"
fi
i=0
while [ $i -lt $vios_len ]
do
	if [ "${viosActive[$i]}" == "1" ]
	then
		vios_id=${viosId[$i]}
		break
	fi
	i=$(expr $i + 1)
done

if [ "$vios_id" == "" ]
then
	echoError "Vios is not found." "105436"
fi
echo "vios_id=${vios_id}" >> "$out_log"


lpar_name=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -r prof -m $host_id -F name --filter lpar_ids=$lpar_id  ")
lpar_state=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -r lpar -m $host_id -F state --filter lpar_ids=$lpar_id")
rmc_state=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -r lpar -m $host_id -F rmc_state,dlpar_io_capable --filter lpar_ids=${lpar_id}")

if [ "$lpar_state" != "Not Activated" ]&&[ "$rmc_state" != "active,1" ]
then
	echoError "Lpar does not support dynamic modification, please shutdown first." "105468"
fi

sea_name=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id $vios_id -c \"lsdev -type sea\"" | grep Available | awk '{print $1}')
sea_map_info=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id $vios_id -c \"lsmap -all -net -field svea physloc -fmt :\"")

sea_length=0
echo "$sea_name" | while read sea
do
	if [ "$sea" != "" ]
	then
		sea_name[$sea_length]=$sea
		sea_info=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id $vios_id -c \"lsdev -dev $sea -attr\"")
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
							slot=$(echo "$map" | awk -F":" '{print $2}' | awk -F"-" '{print $3}' | sed 's/C//g')
							# echo "slot==$slot"
							vlans=$(ssh ${hmc_user}@${hmc_ip} "lshwres -r virtualio -m $host_id --rsubtype eth --level lpar --filter lpar_ids=$vios_id,slots=$slot -F port_vlan_id,addl_vlan_ids" | sed 's/,none//g' | sed 's/"//g' | sed 's/,//g')","$vlans
							# echo "vlans==$vlans"
							break
						fi
					done
				else
					echo "${sea_map_info}" | while read map
					do
						if [ "$ent" == "$(echo "$map" | awk -F":" '{print $1}')" ]
						then
							slot=$(echo "$map" | awk -F":" '{print $2}' | awk -F"-" '{print $3}' | sed 's/C//g')
							# echo "slot==$slot"
							vlans=$(ssh ${hmc_user}@${hmc_ip} "lshwres -r virtualio -m $host_id --rsubtype eth --level lpar --filter lpar_ids=$vios_id,slots=$slot -F port_vlan_id,addl_vlan_ids"  | sed 's/,none//g' | sed 's/"//g' | sed 's/,//g')","$vlans
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

# echo "lpar_id==$lpar_id"
# echo "slot_num==$slot_num"
# echo "vlan_id==$vlan_id"
eth_info=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -r prof -m $host_id -F virtual_eth_adapters --filter lpar_ids=${lpar_id}" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	echoError "$eth_info" "105471"
fi
eth_info=$(echo "$eth_info" | sed 's/"//g' | awk -F"," '{for(i=1;i<=NF;i++) print $i}' | awk -F"/" '{if($1==slot_num) { printf $1"/"$2"/"vlan_id"/"$4"/"$5"/"$6","; } else { printf $0","; } }' slot_num="$slot_num" vlan_id="$vlan_id")
eth_info=${eth_info%*,}
# echo "eth_info==$eth_info"
if [ "$eth_info" == "" ]
then
	echoError "The virtual network info is null." "105471"
fi

del_eth_info=$(echo "$eth_info" | sed 's/"//g' | awk -F"," '{for(i=1;i<=NF;i++) print $i}' | awk -F"/" '{if($1==slot_num) print $0}' slot_num="$slot_num")

if [ "$lpar_state" == "Not Activated" ]
then
	result=$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -r prof -m $host_id -i \"virtual_eth_adapters=\\\"${eth_info}\\\",lpar_id=${lpar_id},name=${lpar_name}\"" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		echoError "$result" "105415"
	fi
else
	if [ "$rmc_state" == "active,1" ]
	then
		result=$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -r prof -m $host_id -i virtual_eth_adapters-=${del_eth_info},lpar_id=${lpar_id},name=${lpar_name}" 2>&1)
		if [ "$(echo $?)" != "0" ]
		then
			echoError "$result" "105472"
		fi
		
		result=$(ssh ${hmc_user}@${hmc_ip} "chhwres -r virtualio -m $host_id --rsubtype eth -o r -s $slot_num --id $lpar_id" 2>&1)
		if [ "$(echo $?)" != "0" ]
		then
			echoError "$result" "105470"
		fi
		
		result=$(ssh ${hmc_user}@${hmc_ip} "chhwres -r virtualio -m $host_id --rsubtype eth -o a -s $slot_num --id $lpar_id -a ieee_virtual_eth=0,port_vlan_id=$vlan_id,is_trunk=0" 2>&1)
		if [ "$(echo $?)" != "0" ]
		then
			echoError "$result" "105470"
		fi
		
		result=$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -r prof -m $host_id -i \"virtual_eth_adapters=\\\"${eth_info}\\\",lpar_id=${lpar_id},name=${lpar_name}\"" 2>&1)
		if [ "$(echo $?)" != "0" ]
		then
			echoError "$result" "105415"
		fi
	else
		echoError "Lpar does not support dynamic modification, please shutdown first." "105468"
	fi
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

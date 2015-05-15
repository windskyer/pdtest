#!/usr/bin/ksh

hmc_ip=$1
hmc_user=$2
host_id=$3
vios_id=$4
pv_name=$5

pv_list=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id $vios_id -c \"lspv -avail -field name size -fmt :\"")
if [ "$(echo $?)" != "0" ]
then
	echo "$pv_list" >&2
	exit 1
fi

pv_map=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id $vios_id -c \"lsmap -all -type disk -field backing -fmt :\"")
if [ "$(echo $?)" != "0" ]
then
	echo "$pv_map" >&2
	exit 1
fi
pv_map=$(echo "$pv_map" | grep -v "is not in AVAILABLE" | awk -F":" '{for(i=1;i<=NF;i++) print $i}')

if [ "$(echo $pv_map | sed 's/://')" == "" ]
then
	pvs=$pv_list
else
	echo "$pv_map" | while read line
	do
		if [ "$line" != "" ]
		then
			pv_list=$(echo "$pv_list" | grep -v $line":")
		fi
	done
fi

if [ "$pv_name" == "" ]
then
	pvs=$pv_list
	# echo "pvs==$pvs"
	if [ "$pvs" == "" ]
	then
		echo "[]"
		exit 0
	fi
else
	pvs=$(echo "$pv_list" | awk -F":" '{if($1 == pv_name) print $0}' pv_name="$pv_name")
	# echo "pvs==$pvs"
	if [ "$pvs" == "" ]
	then
		echo "Not found $pv_name. (hmc: $hmc_ip, host: $host_id, vios: $vios_id)" >&2
		exit 1
	fi
fi

# echo "pvs==$pvs"

length=0
for pv in $pvs
do
	# echo "pv==$pv"
	
	pv_name[$length]=$(echo "$pv" | awk -F":" '{print $1}')
	pv_size[$length]=$(echo "$pv" | awk -F":" '{print $2}')
	
	if [ "${pv_name[$length]}" != "" ]
	then
		pv_status[$length]=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id $vios_id -c \"lsdev -dev ${pv_name[$length]} -field status -fmt :\"")
		if [ "$(echo $?)" != "0" ]
		then
			echo "${pv_status[$length]}" >&2
			exit 1
		fi
		if [ "${pv_status[$length]}" != "Available" ]
		then
			continue
		fi
		
		pvid=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id $vios_id -c \"lsdev -dev ${pv_name[$length]} -attr pvid\"")
		if [ "$(echo $?)" != "0" ]
		then
			echo "${pvid}" >&2
			exit 1
		fi
		pvid=$(echo "$pvid" | grep -v value | grep -v ^$)
		
		uniqueid=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id $vios_id -c \"lsdev -dev ${pv_name[$length]} -attr unique_id\"")
		if [ "$(echo $?)" != "0" ]
		then
			echo "${uniqueid}" >&2
			exit 1
		fi
		uniqueid=$(echo "$uniqueid" | grep -v value | grep -v ^$)
		
		if [ "${pvid}" == "none" ]
		then
			pv_id[$length]=""
		else
			pv_id[$length]=$pvid
		fi
		
		if [ "${uniqueid}" == "none" ]
		then
			unique_id[$length]=""
		else
			unique_id[$length]=$uniqueid
		fi
		
		length=$(expr $length + 1)
	fi
done

# echo "length==$length"

aix_getinfo() {
	i=0
	echo "[\c"
	while [ $i -lt $length ]
	do
		echo "{\c"
		echo "\"unique_id\":\"${unique_id[$i]}\", \c"
		echo "\"pv_id\":\"${pv_id[$i]}\", \c"
		echo "\"pv_name\":\"${pv_name[$i]}\", \c"
		echo "\"pv_status\":\"${pv_status[$i]}\", \c"
		echo "\"pv_size\":\"${pv_size[$i]}\"\c"
		echo "}\c"
		i=$(expr $i + 1)
		if [ "$i" != "$length" ]
		then
			echo ", \c"
		fi
	done
	echo "]"
			
}


linux_getinfo() {
	i=0
	echo -e "[\c"
	while [ $i -lt $length ]
	do
		echo -e "{\c"
		echo -e "\"unique_id\":\"${unique_id[$i]}\", \c"
		echo -e "\"pv_id\":\"${pv_id[$i]}\", \c"
		echo -e "\"pv_name\":\"${pv_name[$i]}\", \c"
		echo -e "\"pv_status\":\"${pv_status[$i]}\", \c"
		echo -e "\"pv_size\":\"${pv_size[$i]}\"\c"
		echo -e "}\c"
		i=$(expr $i + 1)
		if [ "$i" != "$length" ]
		then
			echo -e ", \c"
		fi
	done
	echo -e "]"
}

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
	*) 
		echo "unknown";;
esac
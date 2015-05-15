#!/usr/bin/ksh

hmc_ip=$1
hmc_user=$2
host_id=$3

if [ "$host_id" == "" ]
then
	host_info=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -r sys -F name,type_model,serial_num,state,max_lpars,service_lpar_id" | awk -F"," '{if($4=="Operating") print $0}')
else
	host_info=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m $host_id -r sys -F name,type_model,serial_num,state,max_lpars,service_lpar_id" | awk -F"," '{if($4=="Operating") print $0}')
fi

if [ "$(echo $?)" != "0" ]
then
	echo "$host_info" >&2
fi

length=0
for host in $host_info
do
	managed_system[$length]=$(echo $host | awk -F"," '{print $1}')
	type_model[$length]=$(echo $host | awk -F"," '{print $2}')
	serial_num[$length]=$(echo $host | awk -F"," '{print $3}')
	state[$length]=$(echo $host | awk -F"," '{print $4}')
	max_lpars[$length]=$(echo $host | awk -F"," '{print $5}')
	service_lpar_id[$length]=$(echo $host | awk -F"," '{print $6}')
	vios_id=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m ${managed_system[$length]} -r lpar -F lpar_id:lpar_env:state")
	if [ "$(echo $?)" != "0" ]
	then
		continue
	fi
	vios_id=$(echo "$vios_id" | awk -F":" '{if($2=="vioserver" && $3=="Running") print $1}')
	if [ "$vios_id" == "" ]
	then
		continue
	fi
	flag=0
	for vios in $vios_id
	do
		proc_info=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${managed_system[$length]} --id $vios -c \"oem_setup_env && prtconf\"")
		if [ "$(echo $?)" == "0" ]
		then
			flag=1
			break
		fi
	done
	if [ "$flag" == "0" ]
	then
		continue
	fi
	host_name[$length]=$(echo "$proc_info" | grep "Host Name:" | awk -F":" '{print $2}' | sed 's/ //g')
	cpu_mode[$length]=$(echo "$proc_info" | grep "Processor Implementation Mode:" | awk -F":" '{print $2}' | sed 's/ //g')
	cpu_speed[$length]=$(echo "$proc_info" | grep "Processor Clock Speed:" | awk -F":" '{print $2}' | sed 's/ //g' | sed 's/MHz//g')
	cpu_type[$length]=$(echo "$proc_info" | grep "CPU Type:" | awk -F":" '{print $2}' | sed 's/ //g' | awk -F"-" '{print $1}')
	kernel_type[$length]=$(echo "$proc_info" | grep "Kernel Type:" | awk -F":" '{print $2}' | sed 's/ //g' | awk -F"-" '{print $1}')
	proc_info=$(ssh ${hmc_user}@${hmc_ip} "lshwres -m ${managed_system[$length]} -r proc --level sys -F curr_avail_sys_proc_units,configurable_sys_proc_units,installed_sys_proc_units")
	if [ "$(echo $?)" != "0" ]
	then
		continue
	fi
	mem_info=$(ssh ${hmc_user}@${hmc_ip} "lshwres -m ${managed_system[$length]} -r mem --level sys -F configurable_sys_mem,curr_avail_sys_mem,installed_sys_mem")
	if [ "$(echo $?)" != "0" ]
	then
		continue
	fi
	if [ "$proc_info" != "" ]&&[ "$mem_info" != "" ]
	then
		avail_proc_units[$length]=$(echo "$proc_info" | awk -F"," '{print $1}')
		configurable_proc_units[$length]=$(echo "$proc_info" | awk -F"," '{print $2}')
		installed_proc_units[$length]=$(echo "$proc_info" | awk -F"," '{print $3}')
		configurable_mem[$length]=$(echo "$mem_info" | awk -F"," '{print $1}')
		avail_mem[$length]=$(echo "$mem_info" | awk -F"," '{print $2}')
		installed_mem[$length]=$(echo "$mem_info" | awk -F"," '{print $3}')
	fi
	
	length=$(expr $length + 1)
done

linux_getinfo() {
	i=0
	echo -e "[\c"
	while [ $i -lt $length ]
	do
		echo -e "{\c"
		#echo -e "\"managed_system\":\""${managed_system[$i]}"\", \c"
		echo -e "\"host_name\":\""${managed_system[$i]}"\", \c"
		echo -e "\"serial_num\":\"${serial_num[$i]}\", \c"
		echo -e "\"type_model\":\"${type_model[$i]}\", \c"
		echo -e "\"state\":\"${state[$i]}\", \c"
		echo -e "\"max_lpars\":\"${max_lpars[$i]}\", \c"
		echo -e "\"cpu_mode\":\"${cpu_mode[$i]}\", \c"
		echo -e "\"cpu_speed\":\"${cpu_speed[$i]}\", \c"
		echo -e "\"cpu_type\":\"${cpu_type[$i]}\", \c"
		echo -e "\"kernel_type\":\"${kernel_type[$i]}\", \c"
		echo -e "\"avail_proc_units\":\"${avail_proc_units[$i]}\", \c"
		echo -e "\"configurable_proc_units\":\"${configurable_proc_units[$i]}\", \c"
		echo -e "\"installed_proc_units\":\"${installed_proc_units[$i]}\", \c"
		echo -e "\"avail_mem\":\"${avail_mem[$i]}\", \c"
		echo -e "\"configurable_mem\":\"${configurable_mem[$i]}\", \c"
		echo -e "\"installed_mem\":\"${installed_mem[$i]}\"\c"
		echo -e "}\c"
		
		i=$(expr $i + 1)
		if [ "$i" != "$length" ]
		then
			echo -e ", \c"
		fi
	done
	echo "]"
}

aix_getinfo() {
	i=0
	echo "[\c"
	while [ $i -lt $length ]
	do
		echo "{\c"
		#echo "\"managed_system\":\""${managed_system[$i]}"\", \c"
		echo "\"host_name\":\""${managed_system[$i]}"\", \c"
		echo "\"serial_num\":\"${serial_num[$i]}\", \c"
		echo "\"type_model\":\"${type_model[$i]}\", \c"
		echo "\"state\":\"${state[$i]}\", \c"
		echo "\"max_lpars\":\"${max_lpars[$i]}\", \c"
		echo "\"cpu_mode\":\"${cpu_mode[$i]}\", \c"
		echo "\"cpu_speed\":\"${cpu_speed[$i]}\", \c"
		echo "\"cpu_type\":\"${cpu_type[$i]}\", \c"
		echo "\"kernel_type\":\"${kernel_type[$i]}\", \c"
		echo "\"avail_proc_units\":\"${avail_proc_units[$i]}\", \c"
		echo "\"configurable_proc_units\":\"${configurable_proc_units[$i]}\", \c"
		echo "\"installed_proc_units\":\"${installed_proc_units[$i]}\", \c"
		echo "\"avail_mem\":\"${avail_mem[$i]}\", \c"
		echo "\"configurable_mem\":\"${configurable_mem[$i]}\", \c"
		echo "\"installed_mem\":\"${installed_mem[$i]}\"\c"
		echo "}\c"
	
		i=$(expr $i + 1)
		if [ "$i" != "$length" ]
		then
			echo ", \c"
		fi
	done
	
	echo "]"
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
  *) echo "unknown os" >&2;;
esac
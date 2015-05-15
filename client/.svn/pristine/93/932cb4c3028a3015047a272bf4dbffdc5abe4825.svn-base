#!/usr/bin/ksh

echo "1|0|SUCCESS"

. ./hmc_function.sh

j=0
echo $1 |awk -F"|" '{for(i=1;i<=NF;i++) print $i}' | while read param
do
        case $j in
			0)
					j=1;
					hmc_ip=$param;;
			1)
					j=2;        
					hmc_user=$param;;
			2)
					j=3;
					host_id=$param;;
			3)
					j=4;
					lpar_id=$param;;
        esac
done

length=0
echo $2 |awk -F"|" '{for(i=1;i<=NF;i++) print $i}' | while read param
do
	pv_name[$length]=$param
	length=$(expr $length + 1)
done

if [ "$hmc_ip" == "" ]
then
	echoError "HMC ip is null" "105401"
fi

if [ "$hmc_user" == "" ]
then
	echoError "User name is null" "105402"
fi

if [ "$lpar_id" == "" ]
then
	echoError "Lpar id is null" "105434"
fi

log_flag=$(cat scrpits.properties 2> /dev/null | grep "LOG=" | awk -F"=" '{print $2}')
if [ "$log_flag" == "" ]
then
	log_flag=0
fi

DateNow=$(date +%Y%m%d%H%M%S)
random=$(perl -e 'my $random = int(rand(9999)); print "$random";')
out_log="out_dviosaddpv_${hmc_ip}_${hmc_user}_${host_id}_${lpar_id}_${DateNow}_${random}.log"
error_log="error_dviosaddpv_${hmc_ip}_${hmc_user}_${host_id}_${lpar_id}_${DateNow}_${random}.log"

######################################################################################
######                                                                           #####
######                           get lpar name                                   #####
######                                                                           #####
######################################################################################
echo "$(date) : Get lpar prof name" >> ${out_log}
lpar_name=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m $host_id -r lpar --filter lpar_ids=${lpar_id} -F name" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	echoError "$lpar_name" "105438"
fi
echo "1|1|SUCCESS"

######################################################################################
######                                                                           #####
######                           get vios info                                   #####
######                                                                           #####
######################################################################################
echo "$(date) : get active vios' id" > "$out_log"
get_hmc_vios
if [ "$(echo $?)" != "0" ]
then
	echoError "$getHmcViosErrorMsg" "105436"
fi
i=0
if [ "$vios_len" == "2" ]
then
	while [ $i -lt $vios_len ]
	do
		# echo "viosId[$i]==${viosId[$i]}"
		# echo "viosActive[$i]==${viosActive[$i]}"
		if [ "${viosActive[$i]}" == "1" ]
		then
			vios_id=${viosId[$i]}
			vios_name=${viosName[$i]}
		else
			dvios_vios_id=${viosId[$i]}
			dvios_vios_name=${viosName[$i]}
		fi
		i=$(expr $i + 1)
	done
else
	echoError "Host $host_id does not have double vios." "105436"
fi
echo "vios_id=${vios_id}" >> "$out_log"
echo "vios_name=${vios_name}" >> "$out_log"
echo "dvios_vios_id=${dvios_vios_id}" >> "$out_log"
echo "dvios_vios_name=${dvios_vios_name}" >> "$out_log"
echo "1|10|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                  get vios virtual_scsi_adapters info                      #####
#####                                                                           #####
#####################################################################################
echo "$(date) : Get vios virtual_scsi_adapters info" >> $out_log
a_server_vscsi_info=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m ${host_id} -r prof --filter lpar_ids=${vios_id} -F virtual_scsi_adapters:" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	echoError "$a_server_vscsi_info" "105440"
fi
a_server_vscsi_info=$(echo "$a_server_vscsi_info" | awk -F"," '{for(i=1;i<=NF;i++) print $i}')

b_server_vscsi_info=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m ${host_id} -r prof --filter lpar_ids=${dvios_vios_id} -F virtual_scsi_adapters:" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	echoError "$b_server_vscsi_info" "105440"
fi
b_server_vscsi_info=$(echo "$b_server_vscsi_info" | awk -F"," '{for(i=1;i<=NF;i++) print $i}')

echo "a_server_vscsi_info=${a_server_vscsi_info}" >> $out_log
echo "b_server_vscsi_info=${b_server_vscsi_info}" >> $out_log
echo "1|15|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                   get vm virtual_scsi_adapters info                       #####
#####                                                                           #####
#####################################################################################
echo "$(date) : Get virtual_scsi_adapters server id" >> $out_log
vm_vscsi_info=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m ${host_id} -r prof --filter lpar_ids=${lpar_id} -F virtual_scsi_adapters:" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	echoError "$vm_vscsi_info" "105436"
fi

if [ "$vm_vscsi_info" == "none" ]
then
	echoError "Virtual scsi adapters of ${lpar_name} is none" "105436"
fi

vm_vscsi_num=$(echo "$vm_vscsi_info" | awk -F"," '{print NF}')
if [ "$vm_vscsi_num" != "2" ]
then
	echoError "Lpar $lpar_name does not support HA." "105436"
fi

vm_vscsi_info=$(echo "$vm_vscsi_info" | awk -F"," '{for(i=1;i<=NF;i++) print $i}')

a_vm_vscsi_id=$(echo "$vm_vscsi_info" | awk -F"/" '{if($3==a_vios_id) print $1}' a_vios_id="$vios_id")
b_vm_vscsi_id=$(echo "$vm_vscsi_info" | awk -F"/" '{if($3==a_vios_id) print $1}' a_vios_id="$dvios_vios_id")
a_server_vscsi_id=$(echo "$vm_vscsi_info" | awk -F"/" '{if($3==a_vios_id) print $5}' a_vios_id="$vios_id")
b_server_vscsi_id=$(echo "$vm_vscsi_info" | awk -F"/" '{if($3==b_vios_id) print $5}' b_vios_id="$dvios_vios_id")
echo "a_vm_vscsi_id=${a_vm_vscsi_id}" >> $out_log
echo "b_vm_vscsi_id=${b_vm_vscsi_id}" >> $out_log
echo "a_server_vscsi_id=${a_server_vscsi_id}" >> $out_log
echo "b_server_vscsi_id=${b_server_vscsi_id}" >> $out_log

a_server_vscsi_id=$(echo "$a_server_vscsi_info" | awk -F"/" '{if(($1==vscsi_id && $3==lpar_id && $4==lpar_name && $5==vm_vscsi_id) || ($1==vscsi_id && $3=="any")) print $1}' vscsi_id="$a_server_vscsi_id" lpar_id="${lpar_id}" lpar_name="${lpar_name}" vm_vscsi_id="$a_vm_vscsi_id")
b_server_vscsi_id=$(echo "$b_server_vscsi_info" | awk -F"/" '{if(($1==vscsi_id && $3==lpar_id && $4==lpar_name && $5==vm_vscsi_id) || ($1==vscsi_id && $3=="any")) print $1}' vscsi_id="$b_server_vscsi_id" lpar_id="${lpar_id}" lpar_name="${lpar_name}" vm_vscsi_id="$b_vm_vscsi_id")

if [ "$a_server_vscsi_id" == "" ]||[ "$b_server_vscsi_id" == "" ]
then
	echoError "The lpar's profile does not match to the vios' profile." "105436"
fi
echo "1|20|SUCCESS"


######################################################################################
######                                                                           #####
######                          get back pv name                                 #####
######                                                                           #####
######################################################################################
echo "$(date) : get back pv name" >> "$out_log"
pv_avail=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id $dvios_vios_id -c \"lspv -avail -field name -fmt :\"" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	echoError "$pv_avail" "105432"
fi

back_pv_length=0
for pv in $pv_avail
do
	back_pv_name[$back_pv_length]=$pv
	back_pv_uuid[$back_pv_length]=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id $dvios_vios_id -c \"lsdev -dev $pv -attr unique_id\"" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		echoError "${back_pv_uuid[$back_pv_length]}" "105432"
	fi
	back_pv_uuid[$back_pv_length]=$(echo "${back_pv_uuid[$back_pv_length]}" | grep -v ^$ | grep -v value)
	back_pv_length=$(expr $back_pv_length + 1)
done

i=0
while [ $i -lt $length ]
do
	pv_uuid=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id $vios_id -c \"lsdev -dev ${pv_name[$i]} -attr unique_id\"" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		echoError "${pv_uuid}" "105432"
	fi
	pv_uuid=$(echo "$pv_uuid" | grep -v ^$ | grep -v value)
	j=0
	while [ $j -lt $back_pv_length ]
	do
		if [ "$pv_uuid" == "${back_pv_uuid[$j]}" ]
		then
			dvios_pv_name[$i]=${back_pv_name[$j]}
			break
		fi
		j=$(expr $j + 1)
	done
	if [ "${dvios_pv_name[$i]}" == "" ]
	then
		echoError "Not found pv's unique_id $pv_uuid in vios $dvios_vios_name." "105432"
	fi
	i=$(expr $i + 1)
done
echo "1|27|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                          get vios scsi_adapters                           #####
#####                                                                           #####
#####################################################################################
a_lsmap=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id $vios_id -c \"lsmap -all -field svsa physloc -fmt :\"" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	echoError "$a_lsmap" "105413"
fi
b_lsmap=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id $dvios_vios_id -c \"lsmap -all -field svsa physloc -fmt :\"" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	echoError "$b_lsmap" "105413"
fi

a_vhost=$(echo "$a_lsmap" | awk -F"-" '{if($3=="C"num) print $0}' num="$a_server_vscsi_id" | awk -F":" '{print $1}')
b_vhost=$(echo "$b_lsmap" | awk -F"-" '{if($3=="C"num) print $0}' num="$b_server_vscsi_id" | awk -F":" '{print $1}')

echo "a_vhost=${a_vhost}" >> $out_log
echo "b_vhost=${b_vhost}" >> $out_log

echo "1|55|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                             create mapping                                #####
#####                                                                           #####
#####################################################################################
echo "$(date) : create mapping" >> "$out_log"
i=0
while [ $i -lt $length ]
do
	# mapping main vios
	mapping_name=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"mkvdev -vdev ${pv_name[$i]} -vadapter ${a_vhost}\"" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		time=0
		error_flag=1
		while [ "$(echo "$mapping_name" | grep "Volume group is locked")" != "" ]||[ "$(echo "$mapping_name" | grep "ODM lock")" != "" ]
		do
			sleep 1
			mapping_name=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"mkvdev -vdev ${pv_name[$i]} -vadapter ${a_vhost}\"" 2>&1)
			if [ "$(echo $?)" == "0" ]
			then
				error_flag=0
				break
			fi
			time=$(expr $time + 1)
			if [ $time -gt 30 ]
			then
				break
			fi
		done
		if [ "${error_flag}" != "0" ]
		then
			j=0
			while [ $j -lt $i ]
			do
				echo "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmvdev -vdev ${pv_name[$j]}\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmvdev -vdev ${pv_name[$j]}\"") >> "$out_log" 2>&1
				echo "viosvrcmd -m ${host_id} --id ${dvios_vios_id} -c \"rmvdev -vdev ${ddvios_pv_name[$j]}\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${dvios_vios_id} -c \"rmvdev -vdev ${ddvios_pv_name[$j]}\"") >> $out_log 2>&1
				j=$(expr $j + 1)
			done
			echoError "$mapping_name" "105422"
		fi
	fi
	
	# mapping back vios
	dvios_mapping_name=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${dvios_vios_id} -c \"mkvdev -vdev ${dvios_pv_name[$i]} -vadapter ${b_vhost}\"" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		time=0
		error_flag=1
		while [ "$(echo "$dvios_mapping_name" | grep "Volume group is locked")" != "" ]||[ "$(echo "$dvios_mapping_name" | grep "ODM lock")" != "" ]
		do
			sleep 1
			dvios_mapping_name=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${dvios_vios_id} -c \"mkvdev -vdev ${dvios_pv_name[$i]} -vadapter ${b_vhost}\"" 2>&1)
			if [ "$(echo $?)" == "0" ]
			then
				error_flag=0
				break
			fi
			time=$(expr $time + 1)
			if [ $time -gt 30 ]
			then
				break
			fi
		done
		if [ "${error_flag}" != "0" ]
		then
			echo "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmvdev -vdev ${pv_name[$i]}\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmvdev -vdev ${pv_name[$i]}\"") >> $out_log 2>&1
			j=0
			while [ $j -lt $i ]
			do
				echo "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmvdev -vdev ${pv_name[$j]}\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmvdev -vdev ${pv_name[$j]}\"") >> $out_log 2>&1
				echo "viosvrcmd -m ${host_id} --id ${dvios_vios_id} -c \"rmvdev -vdev ${ddvios_pv_name[$j]}\" :"$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${dvios_vios_id} -c \"rmvdev -vdev ${ddvios_pv_name[$j]}\"") >> $out_log 2>&1
				j=$(expr $j + 1)
			done
			echoError "$dvios_mapping_name" "105422"
		fi
	fi
	i=$(expr $i + 1)
done

echo "1|77|SUCCESS"


if [ "$log_flag" == "0" ]
then
	rm -f "$error_log" 2> /dev/null
	rm -f "$out_log" 2> /dev/null
fi

echo "1|100|SUCCESS"

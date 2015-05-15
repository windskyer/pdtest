#!/usr/bin/ksh
#example1: ./hmc_unmount_iso.sh "172.30.125.15|hscroot|p730-1|8|0"   ,unmount iso only
#example2: ./hmc_unmount_iso.sh "172.30.126.10|hscroot|p730-1|13|1"   ,unmount iso, remove optical device
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
				4)
						j=5;
						remove_flag=$param;;
				5)
                        j=6;
                        unmount_flag=$param;;
        esac
done

log_flag=$(cat scrpits.properties 2> /dev/null | grep "LOG=" | awk -F"=" '{print $2}')
if [ "$log_flag" == "" ]
then
	log_flag=0
fi

DateNow=$(date +%Y%m%d%H%M%S)
random=$(perl -e 'my $random = int(rand(9999)); print "$random";')
out_log="out_unmount_iso_${lpar_id}_${DateNow}_${random}.log"
error_log="error_unmount_iso_${lpar_id}_${DateNow}_${random}.log"
cdrom_path="/var/vio/VMLibrary"

#####################################################################################
#####                                                                           #####
#####                             get lpar name                                 #####
#####                                                                           #####
#####################################################################################
echo "$(date) : Get lpar prof name" > $out_log
lpar_name=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m $host_id -r lpar --filter lpar_ids=${lpar_id} -F name" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	echoError "$lpar_name" "105438"
fi
echo "1|6|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                  get lpar virtual_scsi_adapters info                      #####
#####                                                                           #####
#####################################################################################
echo "$(date) : Get lpar virtual_scsi_adapters info" >> $out_log
vm_vscsi_info=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m $host_id -r prof --filter lpar_ids=${lpar_id} -F virtual_scsi_adapters:" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	echoError "$vm_vscsi_info" "105436"
fi

if [ "$vm_vscsi_info" == "none" ]
then
	throwException "Virtual scsi adapters of ${lpar_name} is none" "105436"
fi

num=$(echo $vm_vscsi_info | awk -F"," '{print NF}' )

vm_vscsi_info=$(echo "$vm_vscsi_info" | awk -F"," '{for(i=1;i<=NF;i++) print $i}')

######################################################################################
######                                                                           #####
######                           get vios info                                   #####
######                                                                           #####
######################################################################################
echo "$(date) : get active vios' id" >> $out_log
if [ $num -ge 2 ]
then
	get_hmc_vios
	if [ "$(echo $?)" != "0" ]
	then
		echoError "$getHmcViosErrorMsg" "105436"
	fi
	i=0
	while [ $i -le $vios_len ]
	do
	  if [ ${viosActive[$i]} -eq 1 ]
	  then
		vios_id=${viosId[$i]}
		break
	  fi
	  i=$(expr $i + 1)
	done
	# echo "vm_vscsi_info==$vm_vscsi_info"
	# echo "vios_id==$vios_id"
	vscsi_id=$(echo "$vm_vscsi_info" | awk -F"/" '{if($3==vios_id) print $5}' vios_id="$vios_id")
	vm_vscsi_id=$(echo "$vm_vscsi_info" | awk -F"/" '{if($3==vios_id) print $1}' vios_id="$vios_id")
else
	vscsi_id=$(echo "$vm_vscsi_info" | awk -F'/' '{print $5}')
	vios_id=$(echo "$vm_vscsi_info" | awk -F'/' '{print $3}')
	vm_vscsi_id=$(echo "$vm_vscsi_info" | awk -F'/' '{print $1}')
fi

info=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m ${host_id} -r prof --filter lpar_ids=$vios_id -F name:max_virtual_slots" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	echoError "$info" "105436"
fi
vios_name=$(echo "$info" | awk -F":" '{print $1}')
max_virtual_slots=$(echo "$info" | awk -F":" '{print $2}')

if [ "$vios_id" == "" ]
then
     echoError "vios is null" "105436"
fi

echo "vscsi_id=${vscsi_id}" >> $out_log
echo "vios_id=${vios_id}" >> $out_log
echo "vios_name=${vios_name}" >> $out_log
echo "max_virtual_slots=${max_virtual_slots}" >> $out_log
echo "vm_vscsi_id=${vm_vscsi_id}" >> $out_log
echo "1|7|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                 get server virtual_scsi_adapters info                     #####
#####                                                                           #####
#####################################################################################
echo "$(date) : Get vios virtual_scsi_adapters info" >> $out_log
server_vscsi_info=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m ${host_id} -r prof --filter lpar_ids=${vios_id} -F virtual_scsi_adapters:" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	throwException "$server_vscsi_info" "105063"
fi
server_vscsi_info=$(echo "$server_vscsi_info" | awk -F"," '{for(i=1;i<=NF;i++) print $i}')
echo "server_vscsi_info=${server_vscsi_info}" >> $out_log
server_vscsi_id=$(echo "$server_vscsi_info" | awk -F"/" '{if(($1==vscsi_id && $3==lpar_id && $4==lpar_name && $5==vm_vscsi_id) || ($1==vscsi_id && $3=="any")) print $1}' vscsi_id="$vscsi_id" lpar_id="${lpar_id}" lpar_name="${lpar_name}" vm_vscsi_id="$vm_vscsi_id")
if [ "$server_vscsi_id" == "" ]
then
	throwException "The lpar's profile does not match to the vios' profile." "105063"
fi
echo "1|8|SUCCESS"

#echo "remove_flag===$remove_flag"

######################################################################################
######                                                                           #####
######                           get vios info                                   #####
######                                                                           #####
######################################################################################
# echo "$(date) : get active vios' id" > "$out_log"
# get_hmc_vios
# i=0
# while [ $i -lt $vios_len ]
# do
	# echo "viosId[$i]==${viosId[$i]}"
	# echo "viosActive[$i]==${viosActive[$i]}"
	# if [ "${viosActive[$i]}" == "1" ]
	# then
		# vios_id=${viosId[$i]}
		# info=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m ${host_id} -r prof --filter lpar_ids=$vios_id -F name:max_virtual_slots" 2>&1)
		# if [ "$(echo $?)" != "0" ]
		# then
			# echoError "$info" "105060"	
		# fi
		# vios_name=$(echo "$info" | awk -F":" '{print $1}')
		# max_virtual_slots=$(echo "$info" | awk -F":" '{print $2}')
		# echo "max_virtual_slots==$max_virtual_slots"
	# fi
	# i=$(expr $i + 1)
# done
# if [ "$vios_id" == "" ]||[ "$vios_name" == "" ]||[ "$max_virtual_slots" == "" ]
# then
	# echoError "Host ${host_id} does not support power vm."
# fi
# echo "vios_id=${vios_id}" >> "$out_log"
# echo "vios_name=${vios_name}" >> "$out_log"
# echo "max_virtual_slots=${max_virtual_slots}" >> "$out_log"
# echo "1|10|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                            get vios' adapter                              #####
#####                                                                           #####
#####################################################################################
echo "$(date) : get vios' adapter" >> $out_log
vadapter_vios=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"lsmap -all -fmt :\"" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	echoError "$vadapter_vios" "105413"
fi
vadapter_vios=$(echo "$vadapter_vios" | grep "C${server_vscsi_id}:" | awk -F":" '{print $1}')
echo "1|30|SUCCESS"


######################################################################################
######                                                                           #####
######                          unmount iso file                              	 #####
######                                                                           #####
######################################################################################
opt_vtd=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"lsmap -vadapter ${vadapter_vios} -field vtd\"" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	echoError "$opt_vtd" "105429"
fi
opt_vtd=$(echo "$opt_vtd" | grep -i vtopt | awk '{print $2}')
if [ "$(echo $opt_vtd | sed 's/://g')" != "" ]
then
	if [ "$unmount_flag" == "1" ]
	then
		ssh_result=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"unloadopt -vtd ${opt_vtd} -release\"" 2>&1)
		if [ "$(echo $?)" != "0" ]
		then
			echoError "$ssh_result" "105429"
		fi
	else
		ssh_result=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"unloadopt -vtd ${opt_vtd}\"" 2>&1)
		if [ "$(echo $?)" != "0" ]
		then
			echoError "$ssh_result" "105429"
		fi
	fi
	echo "1|50|SUCCESS"
	
	
	if [ "$remove_flag" == "1" ]
	then
		######################################################################################
		######                                                                           #####
		######                          remove optical device                          	 #####
		######                                                                           #####
		######################################################################################
		ssh_result=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmvdev -vtd ${opt_vtd}\"" 2>&1)
		if [ "$(echo $?)" != "0" ]
		then
			echoError "$ssh_result" "105463"
		fi
	fi
fi

if [ "$log_flag" == "0" ]
then
	rm -f "${error_log}" 2> /dev/null
	rm -f "$out_log" 2> /dev/null
fi

echo "1|100|SUCCESS"



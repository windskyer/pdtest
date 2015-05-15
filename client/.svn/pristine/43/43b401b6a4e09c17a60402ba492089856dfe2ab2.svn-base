#!/usr/bin/ksh

# . ./hmc_function.sh

hmc_ip=$1
hmc_user=$2
host_id=$3
lpar_id=$4
new_name=$5

# log_flag=$(cat scrpits.properties 2> /dev/null | grep "LOG=" | awk -F"=" '{print $2}')
# if [ "$log_flag" == "" ]
# then
	# log_flag=0
# fi

# DateNow=$(date +%Y%m%d%H%M%S)
# random=$(perl -e 'my $random = int(rand(9999)); print "$random";')

#####################################################################################
#####                                                                           #####
#####                              get lpar name                                #####
#####                                                                           #####
#####################################################################################
# lpar_name=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m $host_id -r lpar --filter lpar_ids=${lpar_id} -F name" 2>&1)
# if [ "$(echo $?)" != "0" ]
# then
	# throwException "$lpar_name" "105030"
# fi

# out_log="out_hmc_rename_vm_${lpar_name}_${new_name}_${DateNow}_${random}.log"

#####################################################################################
#####                                                                           #####
#####                  get lpar virtual_scsi_adapters info                      #####
#####                                                                           #####
#####################################################################################
# echo "$(date) : Get lpar virtual_scsi_adapters info" >> $out_log
# vm_vscsi_info=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m $host_id -r prof --filter lpar_ids=${lpar_id} -F virtual_scsi_adapters:" 2>&1)
# if [ "$(echo $?)" != "0" ]
# then
	# throwException "$vm_vscsi_info" "105063"
# fi

# if [ "$vm_vscsi_info" == "none" ]
# then
	# throwException "Virtual scsi adapters of ${lpar_name} is none" "105063"
# fi

# vm_vscsi_len=0
# for info in $(echo "$vm_vscsi_info" | awk -F"," '{for(i=1;i<=NF;i++) print $i}')
# do
	# echo "vm_vscsi_info==${info}" >> ${out_log}
	# vscsi_id[$vm_vscsi_len]=$(echo "$info" | awk -F'/' '{print $5}')
	# vios_id[$vm_vscsi_len]=$(echo "$info" | awk -F'/' '{print $3}')
	# vios_prof_name[$vm_vscsi_len]=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m $host_id -r lpar --filter lpar_ids=${vios_id[$vm_vscsi_len]} -F name" 2>&1)
	# if [ "$(echo $?)" != "0" ]
	# then
		# throwException "${vios_prof_name[$vm_vscsi_len]}" "105063"
	# fi
	# vm_vscsi_id[$vm_vscsi_len]=$(echo "$info" | awk -F'/' '{print $1}')
	# echo "vscsi_id[$vm_vscsi_len]=${vscsi_id[$vm_vscsi_len]}" >> ${out_log}
	# echo "vios_id[$vm_vscsi_len]=${vios_id[$vm_vscsi_len]}" >> ${out_log}
	# echo "vm_vscsi_id[$vm_vscsi_len]=${vm_vscsi_id[$vm_vscsi_len]}" >> ${out_log}
	# vm_vscsi_len=$(expr $vm_vscsi_len + 1)
# done


#####################################################################################
#####                                                                           #####
#####                 get server virtual_scsi_adapters info                     #####
#####                                                                           #####
#####################################################################################
# echo "$(date) : Get vios virtual_scsi_adapters info" >> $out_log
# i=0
# while [ $i -lt $vm_vscsi_len ]
# do
	# vios_vscsi_info[$i]=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m ${host_id} -r prof --filter lpar_ids=${vios_id[$i]} -F virtual_scsi_adapters:" 2>&1)
	# if [ "$(echo $?)" != "0" ]
	# then
		# throwException "$vios_vscsi_info" "105063"
	# fi
	# my_vios_vscsi=$(echo "${vios_vscsi_info[$i]}" | awk -F"," '{for(i=1;i<=NF;i++) print $i}')
	# echo "my_vios_vscsi[$i]==${my_vios_vscsi}" >> ${out_log}

	# vscsi_id[$i]=$(echo "${my_vios_vscsi}" | awk -F"/" '{if(($1==vscsi_id && $3==lpar_id && $4==lpar_name && $5==vm_vscsi_id) || ($1==vscsi_id && $3=="any")) print $1}' vscsi_id="${vscsi_id[$i]}" lpar_id="${lpar_id}" lpar_name="${lpar_name}" vm_vscsi_id="${vm_vscsi_id[$i]}")
	# if [ "${vscsi_id[$i]}" == "" ]
	# then
		# throwException "The lpar's profile does not match to the vios' profile." "105063"
	# fi
	
	# i=$(expr $i + 1)
# done

#####################################################################################
#####                                                                           #####
#####                             change lpar name                              #####
#####                                                                           #####
#####################################################################################
# echo "$(date) : Change lpar name" >> $out_log
ssh_result=$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -r lpar -m ${host_id} -i new_name=\"${new_name}\",lpar_id=${lpar_id}" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	throwException "$ssh_result" "105481"
fi


#####################################################################################
#####                                                                           #####
#####                        change vios vscsi adapters                         #####
#####                                                                           #####
#####################################################################################
# echo "$(date) : Change vios vscsi adapters" >> $out_log
# i=0
# while [ $i -lt $vm_vscsi_len ]
# do
	# vios_vscsi_info[$i]=$(echo "${vios_vscsi_info[$i]}" | sed 's/'${vscsi_id[$i]}'\/server\/'${lpar_id}'\/'${lpar_name}'\/'${vm_vscsi_id[$i]}'\/0/'${vscsi_id[$i]}'\/server\/'${lpar_id}'\/'${new_name}'\/'${vm_vscsi_id[$i]}'\/0/g')
	# echo "After change, vios_vscsi_info[$i]==${vios_vscsi_info[$i]}" >> $out_log
	# ssh_result=$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -m ${host_id} -r prof -i \"\"virtual_scsi_adapters=${vios_vscsi_info[$i]}\",lpar_id=${vios_id[$i]},name=${vios_prof_name[$i]}\"" 2>&1)
	# if [ "$(echo $?)" == "" ]
	# then
		# throwException "$ssh_result" "105063"
	# fi
	# i=$(expr $i + 1)
# done

# if [ "$log_flag" == "0" ]
# then
	# rm -f "$out_log" 2> /dev/null
# fi







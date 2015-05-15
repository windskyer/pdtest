#!/usr/bin/ksh
#example: ./hmc_mount_iso.sh "172.30.125.15|hscroot|p730-1|7|/template|aix-6.1-iso"

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
						template_path=$param;;
				5)
						j=6;
						template_name=$param;;
        esac
done


log_flag=$(cat scrpits.properties 2> /dev/null | grep "LOG=" | awk -F"=" '{print $2}')
if [ "$log_flag" == "" ]
then
	log_flag=0
fi

DateNow=$(date +%Y%m%d%H%M%S)
random=$(perl -e 'my $random = int(rand(9999)); print "$random";')
out_log="out_create_iso_${lpar_name}_${DateNow}_${random}.log"
error_log="error_create_iso_${lpar_name}_${DateNow}_${random}.log"
error_cp_log="error_create_iso_cp_${lpar_name}_${DateNow}_${random}.log"
cdrom_path="/var/vio/VMLibrary"

#####################################################################################
#####                                                                           #####
#####                             get lpar name                                 #####
#####                                                                           #####
#####################################################################################
echo "$(date) : Get lpar prof name" >> ${out_log}
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
# echo "vm_vscsi_info==$$vm_vscsi_info"

if [ "$vm_vscsi_info" == "none" ]
then
	echoError "Virtual scsi adapters of ${lpar_name} is none" "105436"
fi

num=$(echo $vm_vscsi_info | awk -F"," '{print NF}' )

vm_vscsi_info=$(echo "$vm_vscsi_info" | awk -F"," '{for(i=1;i<=NF;i++) print $i}')

######################################################################################
######                                                                           #####
######                           get vios info                                   #####
######                                                                           #####
######################################################################################
echo "$(date) : get active vios' id" >> "$out_log"
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

# echo "vscsi_id=${vscsi_id}"
# echo "vios_id=${vios_id}"
# echo "vm_vscsi_id=${vm_vscsi_id}"

echo "vscsi_id=${vscsi_id}" >> ${out_log}
echo "vios_id=${vios_id}" >> ${out_log}
echo "vios_name=${vios_name}" >> "$out_log"
echo "max_virtual_slots=${max_virtual_slots}" >> "$out_log"
echo "vm_vscsi_id=${vm_vscsi_id}" >> ${out_log}
echo "1|7|SUCCESS"

# exit 1

#####################################################################################
#####                                                                           #####
#####                 get server virtual_scsi_adapters info                     #####
#####                                                                           #####
#####################################################################################
echo "$(date) : Get vios virtual_scsi_adapters info" >> $out_log
server_vscsi_info=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m ${host_id} -r prof --filter lpar_ids=${vios_id} -F virtual_scsi_adapters:" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	echoError "$server_vscsi_info" "105440"
fi
server_vscsi_info=$(echo "$server_vscsi_info" | awk -F"," '{for(i=1;i<=NF;i++) print $i}')
echo "server_vscsi_info=${server_vscsi_info}" >> ${out_log}
server_vscsi_id=$(echo "$server_vscsi_info" | awk -F"/" '{if(($1==vscsi_id && $3==lpar_id && $4==lpar_name && $5==vm_vscsi_id) || ($1==vscsi_id && $3=="any")) print $1}' vscsi_id="$vscsi_id" lpar_id="${lpar_id}" lpar_name="${lpar_name}" vm_vscsi_id="$vm_vscsi_id")
if [ "$server_vscsi_id" == "" ]
then
	echoError "The lpar's profile does not match to the vios' profile." "105440"
fi
echo "1|8|SUCCESS"


######################################################################################
######                                                                           #####
######                           get vios info                                   #####
######                                                                           #####
######################################################################################
# echo "$(date) : get active vios' id" > "$out_log"
# get_hmc_vios
# if [ "$(echo $?)" != "0" ]
# then
	# throwException "$getHmcViosErrorMsg" "105404"
# fi
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
#####                              check iso                                    #####
#####                                                                           #####
#####################################################################################
echo "$(date) : check template" > $out_log
cat_result=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"oem_setup_env && cat ${template_path}/${template_name}/${template_name}.cfg\"" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	echoError "$cat_result" "105461"
fi

tmp_file=$(echo "$cat_result" | awk -F"=" '{if($1=="files") print $2}' | awk -F"|" '{print $1}')
template_name=${tmp_file##*/}
template_path=${tmp_file%/*}

iso_name=${template_name%.*}
iso_suffix=${template_name##*.}
template_name_len=$(echo "$template_name" | awk '{print length($0)}')
if [ $template_name_len -gt 37 ]
then
	s=$(expr $template_name_len - 37)
	template_name=$(echo "$template_name" | awk '{print substr($0,0,length($0)-s)}' s="$s")
fi
echo "1|15|SUCCESS"

######################################################################################
######                                                                           #####
######                             	 copy iso                                 	 #####
######                                                                           #####
######################################################################################
echo "$(date) : copy iso" >> $out_log
iso_size=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"oem_setup_env && ls -l ${template_path}/${template_name} \"" 2>&1)  
if [ "$(echo $?)" != "0" ]
then
	echoError "$iso_size" "105424"
fi
iso_size=$(echo $iso_size | awk '{print $5/1024/1024}')
cp_size=0
ls_result=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"oem_setup_env && ls -l ${cdrom_path}/${template_name}\"" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	if [ "$(echo "$ls_result" | grep "does not exist")" != "" ]
	then
		ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"oem_setup_env && cp ${template_path}/${template_name} ${cdrom_path}\"" > ${error_log} 2>&1 &
		catchException "${error_log}"
		echoError "$error_result" "105424"
		ddcopyCheck 15
	else
		echoError "$ls_result" "105424"
	fi
else
	if [ "$(echo $ls_result | awk '{print $5/1024/1024}')" != "$iso_size" ]
	then
		ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"oem_setup_env && cp ${template_path}/${template_name} ${cdrom_path} \"" > ${error_log} 2>&1 &
		catchException "${error_log}"
		echoError "$error_result" "105424"
		ddcopyCheck 15
	fi
fi
ls_result=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"oem_setup_env && ls -l ${cdrom_path}/${template_name}\"" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	echoError "$ls_result" "105424"
fi
if [ "$(echo $ls_result | awk '{print $1}')" != "-r--r--r--" ]
then
	chmod_result=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"oem_setup_env && chmod 444 ${cdrom_path}/${template_name}\"" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		echoError "$chmod_result" "105424"
	fi
fi
echo "1|60|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                       get host serial number                              #####
#####                                                                           #####
#####################################################################################
echo "$(date) : check host serial number" >> $out_log
serial_num=$(ssh ${hmc_user}@${hmc_ip} " lssyscfg -r sys -m ${host_id} -F serial_num" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	echoError "$serial_num" "105406"
fi

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
vadapter_vios=$(echo "$vadapter_vios" | grep ${serial_num} | grep "C${server_vscsi_id}:" | awk -F":" '{print $1}')

######################################################################################
######                                                                           #####
######                          check virtual cdrom                             #####
######                                                                           #####
######################################################################################
echo "$(date) : check virtual cdrom" >> $out_log
vadapter_vcd=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"lsmap -vadapter ${vadapter_vios} -field vtd\"" 2>&1) 
if [ "$(echo $?)" != "0" ]
then
	echoError "$vadapter_vcd" "105425"
else
	vadapter_vcd=$(echo "$vadapter_vcd" | grep -i vtopt | awk '{print $2}')
	if [ "$vadapter_vcd" == "" ]
	then
		vadapter_vcd=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"mkvdev -fbo -vadapter ${vadapter_vios}\"" 2>&1)
		if [ "$(echo $?)" != "0" ]
		then
			echoError "$vadapter_vcd" "105425"
		fi
		vadapter_vcd=$(echo $vadapter_vcd  | awk '{print $1}')
	fi
fi
echo "1|75|SUCCESS"


######################################################################################
######                                                                           #####
######                          check if iso mounted                           	 #####
######                                                                           #####
######################################################################################
mount_info=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"lsmap -vadapter ${vadapter_vios} -type file_opt -field backing -fmt :\"" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	echoError "$mount_info" "105462"
fi
mount_isofile=$(echo $mount_info | sed 's/://' | awk '{print $NF}'| awk -F"/" '{print $NF}')
if [ "${mount_isofile}" != "" ]
then
	if [ ${mount_isofile} == "${template_name}" ]
	then
		 echo "the mounted iso is the same as iso in cdrom." >> $out_log
		 echo "1|100|SUCCESS"
		 exit 0
	else
		ssh_result=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"unloadopt -vtd ${vadapter_vcd} -release\"" 2>&1)
		if [ "$(echo $?)" != "0" ]
		then
			echoError "$ssh_result" "105462"
		fi
	fi
fi
echo "1|85|SUCCESS"
######################################################################################
######                                                                           #####
######                                mount iso                                	 #####
######                                                                           #####
######################################################################################
echo "$(date) : mount iso" >> $out_log
mount_result=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"loadopt -disk ${template_name} -vtd ${vadapter_vcd}\"" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	echoError "$mount_result" "105426"
fi
echo "1|95|SUCCESS"

if [ "$log_flag" == "0" ]
then
	rm -f $error_log 2> /dev/null
	rm -f $out_log 2> /dev/null
	rm -f $error_cp_log 2> /dev/null
fi

echo "1|100|SUCCESS"

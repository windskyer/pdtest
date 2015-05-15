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
				4)
						j=5;
						tmp_path=$param;;
				5)
						j=6;
						tmp_name=$param;;
				6)
						j=7;
						tmp_id=$param;;
				7)
						j=8;
						tmp_des=$param;;
        esac
done

j=0
for nfs_info in $(echo $2 |awk -F"|" '{for(i=1;i<=NF;i++) print $i}')
do
	case $j in
		0)
				j=1;
				nfs_ip=$nfs_info;;
		1)
				j=2;        
				nfs_name=$nfs_info;;
		2)
				j=3;
				nfs_passwd=$nfs_info;;
		3)
				j=4;
				nfs_path=$nfs_info;;
	esac
done

if [ "$hmc_ip" == "" ]
then
	throwException "IP is null" "105401"
fi

if [ "$hmc_user" == "" ]
then
	throwException "User name is null" "105402"
fi

if [ "$host_id" == "" ]
then
	throwException "Host id is null" "105433"
fi

if [ "$lpar_id" == "" ]
then
	throwException "Lpar id is null" "105434"
fi

log_flag=$(cat scrpits.properties 2> /dev/null | grep "LOG=" | awk -F"=" '{print $2}')
if [ "$log_flag" == "" ]
then
	log_flag=0
fi


DateNow=$(date +%Y%m%d%H%M%S)
random=$(perl -e 'my $random = int(rand(9999)); print "$random";')
out_log="out_convert_${DateNow}_${random}.log"
error_log="error_convert_${DateNow}_${random}.log"

pd_mount_nfs()
{
	
    ping -c 3 $nfs_ip > /dev/null 2>&1
    if [ $? -ne 0 ]
    then
            throwException "Unable to connect nfs server." "10000"
    fi
    formatPath "$nfs_path"
    nfs_path=$path
    if [ "$nfs_ip" != "" -a "$nfs_path" != "" ]
    then
            template_path=$pd_nfs"/nfs_${DateNow}_${random}"
            ls_check=$(ls $template_path  > ${error_log} 2>&1)
            if [ $? -ne 0 ]
            then
                    new_path=$(mkdir -p $template_path) > ${error_log} 2>&1
            fi
            #echo $new_path
            mount_result=$( mount ${nfs_ip}:${nfs_path} ${template_path}) > ${error_log} 2>&1
            if [ $? -ne 0 ]
            then
                    echo $mount_result
                    throwException "NFS client ${nfs_ip} mount failed." "10000"
            fi
    else
            echo "0|0|ERROR-10000: NFS server parameters is error." >&2
            exit 1
    fi
}
######################################################################################
######                            get vios id                                 #####
######################################################################################
vios_id=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -r lpar -m ${host_id} -F lpar_id:lpar_env " | awk -F: '{if(($2=="vioserver")) print $1}')
if [ $? -ne 0 ]
   then
      throwException "Get viosid failed." "10000"
fi

######################################################################################
######                            nfs mount                                 #####
######################################################################################
#  mount_nfs
        ping -c 3 $nfs_ip > /dev/null 2>&1
        if [ $? -ne 0 ]
        then
                throwException "Unable to connect nfs server." "10000"
        fi
        formatPath "$nfs_path"
        nfs_path=$path
        if [ "$nfs_ip" != "" -a "$nfs_path" != "" ]
        then
                template_path=$pd_nfs"/nfs_${DateNow}_${random}"
                ls_check=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"oem_setup_env && ls $template_path\"") > ${error_log} 2>&1
                if [ $? -ne 0 ]
                then
                        new_path=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"oem_setup_env && mkdir -p $template_path\"") > ${error_log} 2>&1
                fi
                #echo $new_path
                mount_result=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"oem_setup_env && mount ${nfs_ip}:${nfs_path} ${template_path}\"") > ${error_log} 2>&1
                if [ $? -ne 0 ]
                then
                        echo $mount_result
                        throwException "NFS client ${nfs_ip} mount failed." "10000"
                fi
        else
                echo "0|0|ERROR-10000: NFS server parameters is error." >&2
                exit 1
        fi
		
			echo "1|1|SUCCESS"
			
#####################################################################################
#####                                                                           #####
#####                           check vm state                                  #####
#####                                                                           #####
#####################################################################################
echo "$(date) : check vm state" > $out_log
lpar_state=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m $host_id -r lpar --filter lpar_ids=${lpar_id} -F state" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	throwException "$lpar_state" "105435"
fi
echo "lpar_state==$lpar_state" >> $out_log

while [ "$lpar_state" != "Not Activated" ]&&[ "${lpar_state}" != "Not Available" ]
do
		lpar_state=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m $host_id -r lpar --filter lpar_ids=${lpar_id} -F state")
#		echo "lpar_state==$lpar_state"
		case $lpar_state in
				Starting)
							waitRunning;;
				Running)
							shutDown;;
				"Shutting Down")
							waitShutDown;;
				"Open Firmware")
							shutDown;;
				Error)
							throwException "Virtual machine state is error.";;
				"Not Available")
							throwException "Virtual machine state is not available.";;
				"Not Activated")
							echo "1|5|SUCCESS";;
		esac
done

#####################################################################################
#####                                                                           #####
#####                             get lpar name                                 #####
#####                                                                           #####
#####################################################################################
echo "$(date) : Get lpar prof name" >> ${out_log}
lpar_name=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m $host_id -r lpar --filter lpar_ids=${lpar_id} -F name" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	throwException "$lpar_name" "105438"
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
	throwException "$vm_vscsi_info" "105436"
fi

if [ "$vm_vscsi_info" == "none" ]
then
	throwException "Virtual scsi adapters of ${lpar_name} is none" "105436"
fi

num=$(echo $vm_vscsi_info | awk -F"," '{print NF}' )

vm_vscsi_info=$(echo "$vm_vscsi_info" | awk -F"," '{for(i=1;i<=NF;i++) print $i}')

if [ $num -ge 2 ]
then
	get_hmc_vios
	if [ "$getHmcViosErrorMsg" != "" ]
	then
		throwException "$getHmcViosErrorMsg" "105436"
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
	vscsi_id=$(echo "$vm_vscsi_info" | awk -F"/" '{if($3==vios_id) print $5}' vios_id="$vios_id")
	vm_vscsi_id=$(echo "$vm_vscsi_info" | awk -F"/" '{if($3==vios_id) print $1}' vios_id="$vios_id")
else
	vscsi_id=$(echo "$vm_vscsi_info" | awk -F'/' '{print $5}')
	vios_id=$(echo "$vm_vscsi_info" | awk -F'/' '{print $3}')
	vm_vscsi_id=$(echo "$vm_vscsi_info" | awk -F'/' '{print $1}')
fi

if [ "$vios_id" == "" ]
then
     throwException "vios is not found." "105436"
fi

echo "vscsi_id=${vscsi_id}" >> ${out_log}
echo "vios_id=${vios_id}" >> ${out_log}
echo "vm_vscsi_id=${vm_vscsi_id}" >> ${out_log}
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
	throwException "$server_vscsi_info" "105440"
fi
server_vscsi_info=$(echo "$server_vscsi_info" | awk -F"," '{for(i=1;i<=NF;i++) print $i}')
echo "server_vscsi_info=${server_vscsi_info}" >> ${out_log}
echo "my_vscsi=="$vscsi_id"/server/"$lpar_id"/"$lpar_name"/"$vm_vscsi_id"/0" >> $out_log
vscsi_id=$(echo "$server_vscsi_info" | awk -F"/" '{if(($1==vscsi_id && $3==lpar_id && $4==lpar_name && $5==vm_vscsi_id) || ($1==vscsi_id && $3=="any")) print $1}' vscsi_id="$vscsi_id" lpar_id="${lpar_id}" lpar_name="${lpar_name}" vm_vscsi_id="$vm_vscsi_id")
if [ "$vscsi_id" == "" ]
then
	throwException "The lpar's profile does not match to the vios' profile." "105440"
fi
echo "1|8|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                         check template path                               #####
#####                                                                           #####
#####################################################################################
echo "$(date) : check template" >> $out_log
result=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id ${vios_id} -c \"oem_setup_env && ls $template_path\"" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	throwException "$result" "105452"
fi
echo "1|9|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                             get disk name                                 #####
#####                                                                           #####
#####################################################################################
disk_info=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id ${vios_id} -c \"lsmap -all -type disk lv -field lun physloc backing -fmt :\"" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	throwException "$disk_info" "105453"
fi
disk_name=$(echo "$disk_info" | grep "C${vscsi_id}:")
echo "disk_name=${disk_name}" >> $out_log

if [ "$disk_name" == "" ]
then
	throwException "Virtual machine logical volume not found." "105453"
fi

disk_len=0
echo "$disk_name" | awk -F":" '{for(i=2;i<=NF;i++) {if(i%2==0) printf $i","; else print $i}}' | while read param
do
	lun[$disk_len]=$(echo $param | awk -F"," '{print $1}')
    lun[$disk_len]=$(echo ${lun[$disk_len]#*x} | awk '{num=$0; i=length($0); while(substr(num,i,1)==0) { num=substr(num,0,i-1); i--; } print num}')
    disk_[$disk_len]=$(echo $param | awk -F"," '{print $2}')
	disk_len=$(expr $disk_len + 1)
done

i=0
while [ $i -lt $disk_len ]
do
	j=$(expr $i + 1)
	while [ $j -lt $disk_len ]
	do
		if [ ${lun[$i]} -gt ${lun[$j]} ]
		then
			temp=${lun[$j]}
			lun[$j]=${lun[$i]}
			lun[$i]=$temp
			temp=${disk_[$j]}
			disk_[$j]=${disk_[$i]}
			disk_[$i]=$temp
		fi
		j=$(expr $j + 1)
	done
	i=$(expr $i + 1)
done
echo "1|10|SUCCESS"

# disk_len=0
# echo "$disk_name" | awk -F":" '{for(i=2;i<=NF;i++) print $i}' | while read param
# do
	# disk_[$disk_len]=$param
	# disk_len=$(expr $disk_len + 1)
# done
# echo "1|10|SUCCESS"

lv_name=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id ${vios_id} -c \"lsmap -all -type lv -field physloc backing -fmt :\"" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	throwException "$lv_name" "105454"
fi
lv_name=$(echo "$lv_name" | grep "C${vscsi_id}:")

lv_len=0
echo "$lv_name" | awk -F":" '{for(i=2;i<=NF;i++) print $i}' | while read param
do
	lv_[$lv_len]=$param
	lv_len=$(expr $lv_len + 1)
done

pv_name=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id ${vios_id} -c \"lsmap -all -type disk -field physloc backing -fmt :\"" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	throwException "$pv_name" "105455"
fi
pv_name=$(echo "$pv_name" | grep "C${vscsi_id}:")
 
pv_len=0
echo "$pv_name" | awk -F":" '{for(i=2;i<=NF;i++) print $i}' | while read param
do
	pv_[$pv_len]=$param
	pv_len=$(expr $pv_len + 1)
done
echo "1|12|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                           get disk ppsize                                 #####
#####                                                                           #####
#####################################################################################
echo "$(date) : Get lv ppsize" >> $out_log
lv_size=0
i=0
while [ $i -lt $lv_len ]
do
	lv_size_info=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id ${vios_id} -c \"lslv ${lv_[$i]} -field ppsize pps -fmt :\"" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		throwException "$lv_size_info" "105451"
	fi
	lv_ppsize=$(echo "$lv_size_info" | awk -F":" '{print $1}' | awk '{print $1}')
	lv_pps=$(echo "$lv_size_info" | awk -F":" '{print $2}')
	lv_size=$(expr $(echo $lv_ppsize $lv_pps | awk '{print $1*$2}') + $lv_size)
	i=$(expr $i + 1)
done
echo "lv_size=${lv_size}" >> $out_log

echo "$(date) : Get pv size" >> $out_log
pv_size=0
i=0
while [ $i -lt $pv_len ]
do
	pv_size_info=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id ${vios_id} -c \"oem_setup_env && bootinfo -s ${pv_[$i]}\"" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		throwException "$pv_size_info" "105456"
	fi
	pv_size=$(expr $pv_size_info + $pv_size)
	i=$(expr $i+1)
done

# echo $pv_size
echo "1|15|SUCCESS"
echo "pv_size=${pv_size}" >> $out_log

echo "$(date) : Get all disk size" >> $out_log
disk_size=$(expr $lv_size + $pv_size)
echo "disk_size=${disk_size}" >> $out_log

echo "1|16|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                     check template path size                              #####     
#####                                                                           #####
#####################################################################################
echo "$(date) : check template path size" >> $out_log
free_size=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id ${vios_id} -c \"oem_setup_env && df -k $template_path\"" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	throwException "$free_size" "105457"
fi
free_size=$(echo "$free_size" | tail -1 | awk '{print $3/1024}')
echo "free_size=${free_size}" >> $out_log

if [ $free_size -lt $disk_size ]
then
	throwException "Storage space is not enough !" "105457"
fi
echo "1|25|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                                 dd copy                                   #####
#####                                                                           #####
#####################################################################################
echo "$(date) : dd copy" >> $out_log
if [ ! -d "$template_path/${tmp_name}" ]
then

	result=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id ${vios_id} -c \"oem_setup_env && cd $template_path && mkdir ${tmp_name} \" " 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		throwException "$result" "105458"
	fi
fi

result=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id ${vios_id} -c \"oem_setup_env && cd $template_path && chmod -R 777 ${tmp_name} \" " 2>&1)

if [ "$(echo $?)" != "0" ]
then
	throwException "$result" "105459"
fi

i=0
progress=25
while [ $i -lt $disk_len ]
do
	tmps_name=$template_path"/"${tmp_name}"/"${tmp_name}".img."$(expr $i + 1)
	num=0
	type="lv"
	while [ $num -lt $pv_len ]
	do
		if [ "${pv_[$num]}" == "${disk_[$i]}" ]
		then
			type="pv"
			break
		fi
		num=$(expr $num + 1)
	done
	
	ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"oem_setup_env && dd if=/dev/r${disk_[$i]} of=${tmps_name} bs=10M && exit \"" >/dev/null 2>&1 &
	
	sleep 1

#	pid=$(ssh ${hmc_user}@${hmc_ip} 'for proc in $(ls -d /proc/[0-9]* | sed '"'"'s/\/proc\///g'"'"'); do cmdline=$(cat /proc/$proc/cmdline); if [ "$(echo $cmdline | grep "viosvrcmd-m'${host_id}'--id'${vios_id}'-coem_setup_env && dd if=/dev/r${disk_[$i]} of=${tmps_name} bs=10M" | grep -v grep)" != "" ]; then echo $proc; fi done' 2> /dev/null)
	
#	if [ "$pid" != "" ]
#	then
#		ssh ${hmc_user}@${hmc_ip} "kill $pid"
	#else
#		rm -Rf ${tmp_path}"/"${tmp_name} > /dev/null 2>&1
	#	throwException "The process of dd copy not found." "105421"
#	fi
	
	# cp_size=0
	# p=1
	# while [ 1 ]
	# do
		# sleep 60
		# ps_rlt=$(ps -ef | grep "dd if=/dev/r${disk_[$i]} of=${tmps_name}" | grep -v grep)
		# echo "ps_rlt==$ps_rlt" >> $out_log
		# if [ "${ps_rlt}" == "" ]
		# then
			# catchException "${error_log}"
			# echo "error_result==$error_result" >> $out_log
			# if [ "$(echo "$error_result" | grep "The specified time limit" | grep "has been exceeded")" != "" ]
			# then
				# ps_rlt=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"oem_setup_env && ps -ef\"" 2>&1)
				# if [ "$(echo $?)" != "0" ]
				# then
					# rm -Rf ${tmp_path}"/"${tmp_name} > /dev/null 2>&1
					# throwException "$ps_rlt" "105421"
				# fi
				# ps_rlt=$(echo "$ps_rlt" | grep -v grep | grep "dd if=/dev/r${disk_[$i]} of=${tmps_name}")
				# echo "ps_rlt==$ps_rlt" >> $out_log
				# if [ "$ps_rlt" == "" ]
				# then
					# break
				# fi
			# else
				# if [ "$(echo "$error_result" | sed 's/://g' | grep -v "records in" | grep -v "records out")" != "" ]
				# then
					# rm -Rf ${tmp_path}"/"${tmp_name} > /dev/null 2>&1
					# throwException "$(echo "$error_result" | grep -v "records in" | grep -v "records out")" "105421"
				# else
					# break
				# fi
			# fi
		# fi
		
	while [ 1 ]
	do
		sleep 60
		ps_rlt=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"oem_setup_env && ps -ef && exit \"" 2>&1)
		if [ "$(echo $?)" != "0" ]
		then
			if [ "$(echo "$ps_rlt" | grep "time limit")" == "" ]	
		        then
		        	rm -Rf ${tmp_path}"/"${tmp_name} > /dev/null 2>&1
		        	throwException "$ps_rlt" "105421"
                        fi
		fi
#		ps_rlt=$(echo "$ps_rlt" | grep -v grep | grep "dd if=/dev/r${disk_[$i]} of=${tmps_name}")
		ps_rlt=$(echo "$ps_rlt" | grep -v grep | grep -w "dd" | grep "${tmps_name}")
		echo "ps_rlt==$ps_rlt" >> $out_log
		if [ "$ps_rlt" == "" ]
		then
			break
		fi
		progress=$(expr $progress + 1)
		echo "1|${progress}|SUCCESS"
	done
	files=${files}","${tmps_name}"|"$type
	i=$(expr $i + 1)
done

echo "1|75|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                  mount nfs on pd                                          #####
#####                                                                           #####
#####################################################################################
 ping -c 3 $nfs_ip > /dev/null 2>&1
 if [ $? -ne 0 ]
 then
    throwException "Unable to connect nfs server." "10000"
 fi
 formatPath "$nfs_path"
 nfs_path=$path
 if [ "$nfs_ip" != "" -a "$nfs_path" != "" ]
 then
     pd_template_path=$pd_nfs"/temprary_${random}"
     ls_check=$(ls $pd_template_path) > ${error_log} 2>&1
     if [ $? -ne 0 ]
     then
          new_path=$(mkdir -p $pd_template_path) > ${error_log} 2>&1
     fi
         #echo $new_path
     mount_result=$(mount ${nfs_ip}:${nfs_path} ${pd_template_path}) > ${error_log} 2>&1
     if [ $? -ne 0 ]
     then
         echo $mount_result
         throwException "NFS client ${nfs_ip} mount failed." "10000"
     fi
 else
      echo "0|0|ERROR-10000: NFS server parameters is error." >&2
      exit 1
 fi
		

#####################################################################################
#####                                                                           #####
#####                             create tmp cfg                                #####
#####                                                                           #####
#####################################################################################
echo "$(date) : create tmp cfg" >> $out_log
tmp_cfg=$pd_template_path"/"${tmp_name}"/"${tmp_name}".cfg"
echo "id=$tmp_id" > $tmp_cfg 2> $error_log
echo "files=${files#*,}" >> $tmp_cfg 2> $error_log
echo "type=0" >> $tmp_cfg 2> $error_log
echo "desc=$tmp_des" >> $tmp_cfg 2> $error_log

catchException "${error_log}"
if [ "$error_result" != "" ]
then
	rm -Rf $template_path"/"${tmp_name} > /dev/null 2>&1
	throwException "$error_result" "105460"
fi

if [ "$log_flag" == "0" ]
then
		rm -f $error_log 2> /dev/null
		rm -f $out_log 2> /dev/null
fi

echo "1|100|SUCCESS"

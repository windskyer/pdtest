#!/usr/bin/ksh

echo "1|0|SUCCESS"

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
			echo "0|0|ERROR:"$(echo "$result" | awk -F']' '{print $2}')
		else
			echo "0|0|ERROR-${error_code}: $result"
		fi
		
		unmount_nfs
		if [ "$log_flag" == "0" ]
		then
			rm -f $error_log 2> /dev/null
			rm -f $out_log 2> /dev/null
		fi
		
		exit 1
	fi

}

j=0
echo $1 |awk -F"|" '{for(i=1;i<=NF;i++) print $i}' | while read param
do
        case $j in
			0)
				  j=1;
				  ivm_ip=$param;;
			1)
				  j=2;        
				  ivm_user=$param;;
			2)
				  j=3;
				  lpar_id=$param;;
			3)
				  j=4;
				  tmp_path=$param;;
			4)
				  j=5;
				  tmp_name=$param;;
			5)
				  j=6;
				  tmp_id=$param;;
			6)
				  j=7;
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

disk_len=0
for disk in $(echo $3 | awk -F"|" '{for(i=1;i<=NF;i++) print $i}')
do
	select_disk[$disk_len]=$disk
	disk_len=$(expr $disk_len + 1)
done

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

log_flag=$(cat scrpits.properties 2> /dev/null | grep "LOG=" | awk -F"=" '{print $2}')
if [ "$log_flag" == "" ]
then
	log_flag=0
fi

DateNow=$(date +%Y%m%d%H%M%S)
random=$(perl -e 'my $random = int(rand(9999)); print "$random";')
out_log="${path_log}/out_ivm_vm_convert_tmp_v2.1_${DateNow}_${random}.log"
error_log="${path_log}/error_ivm_vm_convert_tmp_v2.1_${DateNow}_${random}.log"

log_debug $LINENO "$0 $*"


# check authorized and repair error authorized
check_authorized ${ivm_ip} ${ivm_user}
#check NFSServer status and restart that had stop NFSServer proc
nfs_server_check ${ivm_ip} ${ivm_user}

#####################################################################################
#####                                                                           #####
#####                          		 mount nfs	                                #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "mount nfs"
mount_nfs
if [ "$template_path" != "" ]
then
	tmp_path=$template_path
fi

#####################################################################################
#####                                                                           #####
#####                           check vm state                                  #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "check vm state"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"lssyscfg -r lpar --filter lpar_ids=${lpar_id} -F state\""
lpar_state=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar --filter lpar_ids=${lpar_id} -F state" 2>&1)
if [ $? -ne 0 ]
then
	throwException "$lpar_state" "105068"
fi
log_debug $LINENO "lpar_state==$lpar_state"
if [ "${lpar_state}" != "Not Activated" ]
then
	throwException "Please poweroff the lpar first." "105068"
fi
echo "1|5|SUCCESS"



#####################################################################################
#####                                                                           #####
#####                         check template path                               #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "check template"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ls ${tmp_path}\""
result=$(ssh ${ivm_user}@${ivm_ip} "ls ${tmp_path}" 2>&1)
if [ $? -ne 0 ]
then
	throwException "$result" "105009"
fi
log_debug $LINENO "result=${result}"
echo "1|7|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                  get virtual_scsi_adapters server id                      #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "Get virtual_scsi_adapters server id"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"lssyscfg -r prof --filter lpar_ids=${lpar_id} -F virtual_scsi_adapters\""
server_vscsi_id=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r prof --filter lpar_ids=${lpar_id} -F virtual_scsi_adapters" 2>&1)
if [ $? -ne 0 ]
then
	throwException "$server_vscsi_id" "105063"
fi
server_vscsi_id=$(echo "$server_vscsi_id" | awk -F'/' '{print $5}')
log_debug $LINENO "server_vscsi_id=${server_vscsi_id}"
echo "1|9|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                              get disk name                                #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "Get lv name"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli lsmap -all -type lv disk cl_disk -field physloc lun backing -fmt :\""
disk_name=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -all -type lv disk cl_disk -field physloc lun backing -fmt :" 2>&1)
if [ $? -ne 0 ]
then
	throwException "$disk_name" "105065"
fi
disk_name=$(echo "$disk_name" | grep "C${server_vscsi_id}:")
log_debug $LINENO "disk_name=${disk_name}"
if [ "$disk_name" == "" ]
then
	throwException "Virtual machine logical volume not found." "105065"
fi

disk_name=$(echo "$disk_name" | awk -F":" '{for(i=2;i<=NF;i++) {if(i%2==0) printf $i","; else print $i}}')

i=0
while [ $i -lt $disk_len ]
do	
	disk_info=$(echo "$disk_name" | awk -F"," '{if($2==disk) print $0}' disk="${select_disk[$i]}")
	if [ "$disk_info" == "" ]
	then
		throwException "${select_disk[$i]} is not found in lpar $lpar_id." "105065"
	fi	
	disk_[$i]=$(echo $disk_info | awk -F"," '{print $2}')
	lun[$i]=$(echo $disk_info | awk -F"," '{print $1}')
	if [ $(uname -s) == "AIX" ]
	then
		lun[$i]=$(echo ${lun[$i]} | awk '{num=$0; i=length($0); while(substr(num,i,1)==0) { num=substr(num,0,i-1);i--; } printf "%d",num}')
	fi
	if [ $(uname -s) == "Linux" ]
	then
		lun[$i]=$(echo ${lun[$i]} | awk --posix '{num=$0; i=length($0); while(substr(num,i,1)==0) { num=substr(num,0,i-1);i--; } printf "%d",num}')
	fi
	i=$(expr $i + 1)
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

# j=0
# while [ $j -lt $disk_len ]
# do
	# echo "disk_[$j]==${disk_[$j]}"
	# j=$(expr $j + 1)
# done

echo "1|10|SUCCESS"

log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli lsmap -all -type lv -field physloc backing -fmt :\" | grep "C${server_vscsi_id}:""
lv_name=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -all -type lv -field physloc backing -fmt :" 2> ${error_log} | grep "C${server_vscsi_id}:")
log_debug $LINENO "lv_name=${lv_name}"
catchException "${error_log}"
throwException "$error_result" "105065"

k=0
echo "$lv_name" | awk -F":" '{for(i=2;i<=NF;i++) print $i}' | while read param
do
	lv_[$k]=$param
	k=$(expr $k + 1)
done

log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli lsmap -all -type disk -field physloc backing -fmt :\" | grep "C${server_vscsi_id}:""
pv_name=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -all -type disk -field physloc backing -fmt :" 2> ${error_log} | grep "C${server_vscsi_id}:")
log_debug $LINENO "pv_name=${pv_name}"
x=0
echo "$pv_name" | awk -F":" '{for(i=2;i<=NF;i++) print $i}' | while read param
do
	pv_[$x]=$param
	x=$(expr $x + 1)
done

log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli lsmap -all -type cl_disk -field physloc backing -fmt :\" | grep "C${server_vscsi_id}:""
lu_name=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -all -type cl_disk -field physloc backing -fmt :" 2> ${error_log} | grep "C${server_vscsi_id}:")
log_debug $LINENO "lu_name=${lu_name}"
y=0
echo "$lu_name" | awk -F":" '{for(i=2;i<=NF;i++) print $i}' | while read param
do
	lu_[$y]=$param
	y=$(expr $y + 1)
done

echo "1|12|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                            get disk ppsize                                #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "Get lv ppsize"
lv_size=0
i=0
while [ $i -lt $k ]
do
	j=0
	flag=0
	while [ $j -lt $disk_len ]
	do
		#if [ "${select_disk[$j]}" == "${lv_[$i]}" ]
		if [ "${disk_[$j]}" == "${lv_[$i]}" ]
		then
			storagetype[$j]="lv"
			flag=1
			break
		fi
		j=$(expr $j + 1)
	done
	
	if [ $flag -eq 1 ]
	then
		log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli lslv ${lv_[$i]} -field ppsize pps -fmt :\""
		lv_size_info=$(ssh ${ivm_user}@${ivm_ip} "ioscli lslv ${lv_[$i]} -field ppsize pps -fmt :" 2> ${error_log})
		log_debug $LINENO "lv_size_info=${lv_size_info}"
		catchException "${error_log}"
		throwException "$error_result" "105066"
		lv_ppsize=$(echo "$lv_size_info" | awk -F":" '{print $1}' | awk '{print $1}')
		lv_pps=$(echo "$lv_size_info" | awk -F":" '{print $2}')
		lv_size=$(expr $(echo $lv_ppsize $lv_pps | awk '{print $1*$2}') + $lv_size)
	fi
	
	i=$(expr $i + 1)
done

echo "1|14|SUCCESS"
log_debug $LINENO "lv_size=${lv_size}"

log_info $LINENO "Get pv size"
pv_size=0
i=0
while [ $i -lt $x ]
do
	j=0
	flag=0
	while [ $j -lt $disk_len ]
	do
		if [ "${disk_[$j]}" == "${pv_[$i]}" ]
		then
			storagetype[$j]="pv"
			flag=1
			break
		fi
		j=$(expr $j + 1)
	done
	
	if [ $flag -eq 1 ]
	then
		log_debug $LINENO "CMD:exec ./ssh.exp ${ivm_user} ${ivm_ip} \"oem_setup_env | bootinfo -s ${pv_[$i]}\" | sed -n '/bootinfo/,/#/p' | grep -v "bootinfo"| grep -v '#' | awk '{print substr(\$0,0,length(\$0)-1)}'"
		pv_size_info=$(exec ./ssh.exp ${ivm_user} ${ivm_ip} "oem_setup_env | bootinfo -s ${pv_[$i]}" | sed -n '/bootinfo/,/#/p' | grep -v "bootinfo"| grep -v '#' | awk '{print substr($0,0,length($0)-1)}')
		log_debug $LINENO "pv_size_info=${pv_size_info}"
		pv_size=$(expr $pv_size_info + $pv_size)
	fi
	
	i=$(expr $i + 1)
done

echo "1|15|SUCCESS"
log_debug $LINENO "pv_size=${pv_size}"



log_info $LINENO "Get lu size"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli cluster -list|grep -E 'CLUSTER_NAME'|awk '{print \$2}'\""
clustername=$(ssh ${ivm_user}@${ivm_ip} "ioscli cluster -list|grep -E 'CLUSTER_NAME'|awk '{print \$2}'")
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} 2>/dev/null \"ioscli lssp -clustername $clustername|grep -E 'POOL_NAME'|awk '{print \$2}'\""
spname=$(ssh ${ivm_user}@${ivm_ip} 2>/dev/null "ioscli lssp -clustername $clustername|grep -E 'POOL_NAME'|awk '{print \$2}'")
log_debug $LINENO "clustername=${clustername}"
log_debug $LINENO "spname=${spname}"

lu_size=0
i=0
while [ $i -lt $y ]
do
	j=0
	flag=0
	while [ $j -lt $disk_len ]
	do
		if [ "${disk_[$j]}" == "${lu_[$i]}" ]
		then
			storagetype[$j]="lu"
			flag=1
			break
		fi
		j=$(expr $j + 1)
	done
	
	if [ $flag -eq 1 ]
	then
		luudid=$(echo "${lu_[$i]}"|awk -F"." '{print $NF}')
		log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli lssp -clustername ${clustername} -sp ${spname} -bd -field luudid size -fmt :\"|awk -F":" '{if(\$1==luudid) print \$2}' luudid=${luudid}"
		lu_size_info=$(ssh ${ivm_user}@${ivm_ip} "ioscli lssp -clustername ${clustername} -sp ${spname} -bd -field luudid size -fmt :"|awk -F":" '{if($1==luudid) print $2}' luudid=${luudid})
		log_debug $LINENO "lu_size_info=${lu_size_info}"
		lu_size=$(expr $lu_size_info + $lu_size)
	fi
	
	i=$(expr $i + 1)
done
log_debug $LINENO "lu_size=${lu_size}"
echo "1|16|SUCCESS"


log_info $LINENO "Get all disk size"
disk_size=$(expr $lv_size + $pv_size + $lu_size)
log_debug $LINENO "disk_size=${disk_size}"
echo "1|17|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                     check template path size                              #####     
#####                                                                           #####
#####################################################################################
log_info $LINENO "check template path size"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"df -k ${tmp_path}\" | tail -1 | awk '{print \$3/1024}'"
free_size=$(ssh ${ivm_user}@${ivm_ip} "df -k ${tmp_path}" 2> "${error_log}" | tail -1 | awk '{print $3/1024}')
log_debug $LINENO "free_size=${free_size}"
catchException "${error_log}"
throwException "$error_result" "105070"
# echo $free_size
if [ $free_size -lt $disk_size ]
then
	throwException "Storage space is not enough !" "105069"
fi
echo "1|18|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                                 dd copy                                   #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "dd copy"
log_debug $LINENO "CMD:expect ./ssh.exp ${ivm_user} ${ivm_ip} \"oem_setup_env|mkdir -p ${tmp_path}/${tmp_name}|chmod -R 777 ${tmp_path}/${tmp_name}\" > /dev/null 2>&1"
expect ./ssh.exp ${ivm_user} ${ivm_ip} "oem_setup_env|mkdir -p ${tmp_path}/${tmp_name}|chmod -R 777 ${tmp_path}/${tmp_name}" > /dev/null 2>&1

i=0
cp_size=0
progress=20
p=1
while [ $i -lt $disk_len ]
do
	tmps_name=${tmp_path}"/"${tmp_name}"/"${tmp_name}".img."$(expr $i + 1)
	# num=0
	# type="lv"
	# while [ $num -lt $x ]
	# do
		# if [ "${pv_[$num]}" == "${disk_[$i]}" ]
		# then
			# type="pv"
			# break
		# fi
		# num=$(expr $num + 1)
	# done
	log_info $LINENO "storagetype is ${storagetype[$i]}"
	if [ ${storagetype[$i]} == "lv" -o  ${storagetype[$i]} == "pv" ]
	then
		log_debug $LINENO "CMD:expect ./ssh.exp ${ivm_user} ${ivm_ip} \"oem_setup_env|dd if=/dev/r${disk_[$i]} of="${tmps_name}" bs=8M 2> ${error_log} > /dev/null &\" > /dev/null 2>&1"
		expect ./ssh.exp ${ivm_user} ${ivm_ip} "oem_setup_env|dd if=/dev/r${disk_[$i]} of="${tmps_name}" bs=8M 2> ${error_log} > /dev/null &" > /dev/null 2>&1

		#p=1
		while [ ${cp_size} -lt ${disk_size} ]
		do
				log_info $LINENO "sleep 15" 
				sleep 15
				ps_rlt=$(ssh ${ivm_user}@${ivm_ip} "ps -ef|grep \"dd if=/dev/r${disk_[$i]} of="${tmps_name}"\" | grep -v grep")
				if [ "${ps_rlt}" == "" ]
				then
					dd_rlt=$(ssh ${ivm_user}@${ivm_ip} "cat ${error_log}" 2> ${error_log})
					catchException "${error_log}"
					if [ "$error_result" != "" ]
					then
						rm -Rf ${tmp_path}"/"${tmp_name} > /dev/null 2>&1
						ssh ${ivm_user}@${ivm_ip} "rm -f ${error_log}" >> $out_log 2>&1
						throwException "$error_result" "105070"
					fi
					if [ "$(echo "${dd_rlt}" | grep -v "records in" | grep -v "records out")" != "" ]
					then
						rm -Rf ${tmp_path}"/"${tmp_name} > /dev/null 2>&1
						ssh ${ivm_user}@${ivm_ip} "rm -f ${error_log}" >> $out_log 2>&1
						throwException "$(echo "$dd_rlt" | grep -v "records in" | grep -v "records out")" "105070"
					else
						break
					fi
				fi
				cp_size=$(ssh ${ivm_user}@${ivm_ip} "ls -l ${tmp_path}"/"${tmp_name}" 2> ${error_log} | awk '{array[$9]=$5/1024/1024; size=0; for(key in array) size=size+array[key]} END {print size}')
				log_debug $LINENO "cp_size=${cp_size}"
				catchException "${error_log}"
				if [ "${error_result}" != "" ]
				then
					ssh ${ivm_user}@${ivm_ip} "kill $(ps -ef|grep \"dd if=/dev/r${disk_[$i]} of="${tmps_name}"\" | grep -v grep | awk '{print $2}')" > /dev/null 2>&1
					ssh ${ivm_user}@${ivm_ip} "rm -f ${error_log}" >> $out_log 2>&1
					rm -Rf ${tmp_path}"/"${tmp_name} > /dev/null 2>&1
					throwException "Copy template failure" "105070"
				fi
				if [ "$(echo ${cp_size}" "$(echo ${disk_size} | awk '{printf "%0.2f",$1/5*i}' i="$p") | awk '{if($1>=$2) print 0}')" = "0" ]
				then
					progress=$(expr $progress + 14)
					echo "1|${progress}|SUCCESS"
					p=$(expr $p + 1)
				fi
		done
		files=${files}","${tmps_name}"|"${storagetype[$i]}
		log_debug $LINENO "files=${files}"
	fi
	log_info $LINENO "storagetype is lu"
	if [ ${storagetype[$i]} == "lu" ]
	then
		#####################################################################################
		#####                                                                           #####
		#####                              check lu file                                #####
		#####                                                                           #####
		#####################################################################################
		log_debug $LINENO "CMD:expect ./ssh.exp ${ivm_user} ${ivm_ip} \"oem_setup_env | mount|exit|exit\" 2>&1"
		mount_info=$(expect ./ssh.exp ${ivm_user} ${ivm_ip} "oem_setup_env | mount|exit|exit" 2>&1)
		log_debug $LINENO "mount_info=${mount_info}"
		lu_dev_path=$(echo "$mount_info" | grep "/var/vio/SSP/${clustername}/*" | awk '{print $1}')
		#lu_rdev="${lu_dev_path}/VOL1/${lu_name[$i]}.${lu_udid[$i]}"
		log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ls $lu_dev_path/VOL1/${disk_[$i]}\""
		ls_rlt=$(ssh ${ivm_user}@${ivm_ip} "ls $lu_dev_path/VOL1/${disk_[$i]}" 2>"${error_log}")
		log_debug $LINENO "ls_rlt=${ls_rlt}"
		catchException "${error_log}"
		if [ "$error_result" != "" ]
		then
			rm -Rf ${tmp_path}"/"${tmp_name} > /dev/null 2>&1
			throwException "$error_result" "105014"
		fi
		log_debug $LINENO "CMD:expect ./ssh.exp ${ivm_user} ${ivm_ip} \"oem_setup_env|dd if=$lu_dev_path/VOL1/${disk_[$i]} of="${tmps_name}" bs=8M 2> ${error_log} > /dev/null &\" > /dev/null 2>&1"
		expect ./ssh.exp ${ivm_user} ${ivm_ip} "oem_setup_env|dd if=$lu_dev_path/VOL1/${disk_[$i]} of="${tmps_name}" bs=8M 2> ${error_log} > /dev/null &" > /dev/null 2>&1
		#p=1
		while [ ${cp_size} -lt ${disk_size} ]
		do
				log_info $LINENO "sleep 15"
				sleep 15
				ps_rlt=$(ssh ${ivm_user}@${ivm_ip} "ps -ef|grep \"dd if=$lu_dev_path/VOL1/${disk_[$i]} of="${tmps_name}"\" | grep -v grep")
				if [ "${ps_rlt}" == "" ]
				then
					dd_rlt=$(ssh ${ivm_user}@${ivm_ip} "cat ${error_log}" 2> ${error_log})
					catchException "${error_log}"
					if [ "$error_result" != "" ]
					then
						rm -Rf ${tmp_path}"/"${tmp_name} > /dev/null 2>&1
						ssh ${ivm_user}@${ivm_ip} "rm -f ${error_log}" >> $out_log 2>&1
						throwException "$error_result" "105070"
					fi
					if [ "$(echo "${dd_rlt}" | grep -v "records in" | grep -v "records out")" != "" ]
					then
						rm -Rf ${tmp_path}"/"${tmp_name} > /dev/null 2>&1
						ssh ${ivm_user}@${ivm_ip} "rm -f ${error_log}" >> $out_log 2>&1
						throwException "$(echo "$dd_rlt" | grep -v "records in" | grep -v "records out")" "105070"
					else
						break
					fi
				fi
				cp_size=$(ssh ${ivm_user}@${ivm_ip} "ls -l ${tmp_path}"/"${tmp_name}" 2> ${error_log} | awk '{array[$9]=$5/1024/1024; size=0; for(key in array) size=size+array[key]} END {print size}')
				log_debug $LINENO "cp_size=${cp_size}"
				catchException "${error_log}"
				if [ "${error_result}" != "" ]
				then
					ssh ${ivm_user}@${ivm_ip} "kill $(ps -ef|grep \"dd if=/dev/r${disk_[$i]} of="${tmps_name}"\" | grep -v grep | awk '{print $2}')" > /dev/null 2>&1
					ssh ${ivm_user}@${ivm_ip} "rm -f ${error_log}" >> $out_log 2>&1
					rm -Rf ${tmp_path}"/"${tmp_name} > /dev/null 2>&1
					throwException "Copy template failure" "105070"
				fi
				if [ "$(echo ${cp_size}" "$(echo ${disk_size} | awk '{printf "%0.2f",$1/5*i}' i="$p") | awk '{if($1>=$2) print 0}')" = "0" ]
				then
					progress=$(expr $progress + 14)
					echo "1|${progress}|SUCCESS"
					p=$(expr $p + 1)
				fi
		done
		files=${files}","${tmps_name}"|"${storagetype[$i]}
		log_debug $LINENO "files=${files}"
	fi
	i=$(expr $i + 1)
done

#####################################################################################
#####                                                                           #####
#####                             create tmp cfg                                #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "create tmp cfg"
tmp_cfg=${tmp_path}"/"${tmp_name}"/"${tmp_name}".cfg"
log_debug $LINENO "CMD:expect ./crt_tmp_cfg.exp ${ivm_user} ${ivm_ip} \"oem_setup_env ; echo \"id=$tmp_id\" > ${tmp_cfg} ; echo \"files=${files#*,}\" >> ${tmp_cfg} ; echo \"type=0\" >> ${tmp_cfg} ; echo \"desc=${tmp_des}\" >> ${tmp_cfg}\" 2>&1"
result=$(expect ./crt_tmp_cfg.exp ${ivm_user} ${ivm_ip} "oem_setup_env ; echo \"id=$tmp_id\" > ${tmp_cfg} ; echo \"files=${files#*,}\" >> ${tmp_cfg} ; echo \"type=0\" >> ${tmp_cfg} ; echo \"desc=${tmp_des}\" >> ${tmp_cfg}" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	throwException "$result" "105071"
fi

#####################################################################################
#####                                                                           #####
#####                          		unmount nfs	                                #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "unmount nfs"
unmount_nfs

if [ "$log_flag" == "0" ]
then
	ssh ${ivm_user}@${ivm_ip} "rm -f ${error_log}" >> $out_log 2>&1
	rm -f $error_log 2> /dev/null
	rm -f $out_log 2> /dev/null
fi

echo "1|100|SUCCESS"






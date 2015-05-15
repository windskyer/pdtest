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
out_log="out_convert_${DateNow}_${random}.log"
error_log="error_convert_${DateNow}_${random}.log"

#####################################################################################
#####                                                                           #####
#####                          		 mount nfs	                                #####
#####                                                                           #####
#####################################################################################
echo "$(date) :  mount nfs" > "$out_log"
mount_nfs
if [ "$template_path" != "" ]
then
	tmp_path=$template_path
fi
# echo "tmp_path===$tmp_path"

#####################################################################################
#####                                                                           #####
#####                           check vm state                                  #####
#####                                                                           #####
#####################################################################################
echo "$(date) : check vm state" > $out_log
lpar_state=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar --filter lpar_ids=${lpar_id} -F state" 2>&1)
if [ $? -ne 0 ]
then
	throwException "$lpar_state" "105068"
fi
echo "lpar_state==$lpar_state" >> $out_log 
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
echo "$(date) : check template" >> $out_log
result=$(ssh ${ivm_user}@${ivm_ip} "ls ${tmp_path}" 2>&1)
if [ $? -ne 0 ]
then
	throwException "$result" "105009"
fi
# echo $temp_path
echo "1|7|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                  get virtual_scsi_adapters server id                      #####
#####                                                                           #####
#####################################################################################
echo "$(date) : Get virtual_scsi_adapters server id" >> $out_log
server_vscsi_id=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r prof --filter lpar_ids=${lpar_id} -F virtual_scsi_adapters" 2>&1)
if [ $? -ne 0 ]
then
	throwException "$server_vscsi_id" "105063"
fi
server_vscsi_id=$(echo "$server_vscsi_id" | awk -F'/' '{print $5}')
echo "server_vscsi_id=${server_vscsi_id}" >> $out_log
echo "1|9|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                              get disk name                                #####
#####                                                                           #####
#####################################################################################
echo "$(date) : Get lv name" >> $out_log

disk_name=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -all -type lv disk -field physloc lun backing -fmt :" | grep "C${server_vscsi_id}:" 2> "${error_log}") 
catchException "${error_log}"
throwException "$error_result" "105065"
echo "disk_name=${disk_name}" >> $out_log
if [ "$disk_name" == "" ]
then
	throwException "Virtual machine logical volume not found." "105065"
fi

len=0
echo "$disk_name" | awk -F":" '{for(i=2;i<=NF;i++) {if(i%2==0) printf $i","; else print $i}}' | while read param
do
	lun[$len]=$(echo $param | awk -F"," '{print $1}')
    lun[$len]=$(echo ${lun[$len]#*x} | awk '{num=$0; i=length($0); while(substr(num,i,1)==0) { num=substr(num,0,i-1); i--; } print num}')
    disk_[$len]=$(echo $param | awk -F"," '{print $2}')
	# echo disk: ${disk_[$j]}
	len=$(expr $len + 1)
done

i=0
while [ $i -lt $len ]
do
	j=$(expr $i + 1)
	while [ $j -lt $len ]
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


lv_name=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -all -type lv -field physloc backing -fmt :" | grep "C${server_vscsi_id}:" 2> "${error_log}")
catchException "${error_log}"
throwException "$error_result" "105065"

k=0
echo "$lv_name" | awk -F":" '{for(i=2;i<=NF;i++) print $i}' | while read param
do
	lv_[$k]=$param
	# echo lv: ${lv_[$k]}
	k=$(expr $k + 1)
done

pv_name=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -all -type disk -field physloc backing -fmt :" | grep "C${server_vscsi_id}:" 2> "${error_log}")
x=0
echo "$pv_name" | awk -F":" '{for(i=2;i<=NF;i++) print $i}' | while read param
do
	pv_[$x]=$param
	# echo pv:  ${pv_[$x]}
	x=$(expr $x + 1)
done
echo "1|12|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                            get disk ppsize                                #####
#####                                                                           #####
#####################################################################################
echo "$(date) : Get lv ppsize" >> $out_log
lv_size=0
i=0
while [ $i -lt $k ]
do
	lv_size_info=$(ssh ${ivm_user}@${ivm_ip} "ioscli lslv ${lv_[$i]} -field ppsize pps -fmt :" 2> ${error_log})
	catchException "${error_log}"
	throwException "$error_result" "105066"
	lv_ppsize=$(echo "$lv_size_info" | awk -F":" '{print $1}' | awk '{print $1}')
	lv_pps=$(echo "$lv_size_info" | awk -F":" '{print $2}')
	lv_size=$(expr $(echo $lv_ppsize $lv_pps | awk '{print $1*$2}') + $lv_size)
	i=$(expr $i + 1)
done


# echo $lv_size

echo "1|14|SUCCESS"

# lv_size_info=$(ssh ${ivm_user}@${ivm_ip} "ioscli lslv ${lv_[$i]} -field ppsize pps -fmt :" 2> ${error_log})

echo "lv_size=${lv_size}" >> $out_log

echo "$(date) : Get pv size" >> $out_log
pv_size=0
i=0
while [ $i -lt $x ]
do
	pv_size_info=$(exec ./ssh.exp ${ivm_user} ${ivm_ip} "oem_setup_env | bootinfo -s ${pv_[$i]}" | sed -n '/bootinfo/,/#/p' | grep -v "bootinfo"| grep -v '#' | awk '{print substr($0,0,length($0)-1)}')
	pv_size=$(expr $pv_size_info + $pv_size)
	i=$(expr $i+1)
done

# echo $pv_size
echo "1|15|SUCCESS"
echo "pv_size=${pv_size}" >> $out_log

echo "$(date) : Get all disk size" >> $out_log
disk_size=$(expr $lv_size + $pv_size)
echo "disk_size=${disk_size}" >> $out_log

# echo "disk_size=="$disk_size
echo "1|16|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                     check template path size                              #####     
#####                                                                           #####
#####################################################################################
echo "$(date) : check template path size" >> $out_log
free_size=$(ssh ${ivm_user}@${ivm_ip} "df -k ${tmp_path}" 2> ${error_log} | tail -1 | awk '{print $3/1024}')
catchException "${error_log}"
throwException "$error_result" "105070"
echo "free_size=${free_size}" >> $out_log
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
echo "$(date) : dd copy" >> $out_log
expect ./ssh.exp ${ivm_user} ${ivm_ip} "oem_setup_env|mkdir -p ${tmp_path}/${tmp_name}|chmod -R 777 ${tmp_path}/${tmp_name}" > /dev/null 2>&1
# if [ ! -d "${tmp_path}/${tmp_name}" ]
# then
	# result=$(mkdir -p ${tmp_path}"/"${tmp_name} 2>&1)
	# if [ "$(echo $?)" != "0" ]
	# then
		# throwException "$result" "105069"
	# fi
# fi

# result=$(chmod -R 777 ${tmp_path}"/"${tmp_name} 2>&1)
# if [ "$(echo $?)" != "0" ]
# then
	# throwException "$result" "105069"
# fi

i=0
while [ $i -lt $len ]
do
	tmps_name=${tmp_path}"/"${tmp_name}"/"${tmp_name}".img."$(expr $i + 1)
	num=0
	type="lv"
	while [ $num -lt $x ]
	do
		if [ "${pv_[$num]}" == "${disk_[$i]}" ]
		then
			type="pv"
			break
		fi
		num=$(expr $num + 1)
	done
	expect ./ssh.exp ${ivm_user} ${ivm_ip} "oem_setup_env|dd if=/dev/r${disk_[$i]} of="${tmps_name}" bs=8M 2> ${error_log} > /dev/null &" > /dev/null 2>&1
	cp_size=0
	progress=20
	p=1
	while [ ${cp_size} -lt ${disk_size} ]
	do
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
			cp_size=$(ssh ${ivm_user}@${ivm_ip} "ls -l ${tmps_name}" 2> ${error_log} | awk '{print $5/1024/1024}')
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
	files=${files}","${tmps_name}"|"$type
	i=$(expr $i + 1)
done

#####################################################################################
#####                                                                           #####
#####                             create tmp cfg                                #####
#####                                                                           #####
#####################################################################################
echo "$(date) : create tmp cfg" >> $out_log
tmp_cfg=${tmp_path}"/"${tmp_name}"/"${tmp_name}".cfg"
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
echo "$(date) : unmount nfs" >> $out_log
unmount_nfs

if [ "$log_flag" == "0" ]
then
	ssh ${ivm_user}@${ivm_ip} "rm -f ${error_log}" >> $out_log 2>&1
	rm -f $error_log 2> /dev/null
	rm -f $out_log 2> /dev/null
fi

echo "1|100|SUCCESS"






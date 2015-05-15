#!/usr/bin/ksh

echo "1|0|SUCCESS"

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
		
		if [ "$log_flag" == "0" ]
		then
			rm -f $error_log" 2> /dev/null
			rm -f $out_log" 2> /dev/null
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

if [ "$ivm_ip" == "" ]
then
	throwException "IP is null" "105070"
fi

if [ "$ivm_user" == "" ]
then
	throwException "User name is null" "105070"
fi

if [ "$lpar_id" == "" ]
then
	throwException "Lpar id is null" "105070"
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
#####                           check vm state                                  #####
#####                                                                           #####
#####################################################################################
echo "$(date) : check vm state" > $out_log
lpar_state=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar --filter lpar_ids=${lpar_id} -F state" 2> ${error_log})
catchException "${error_log}"
throwException "$error_result" "105070"
echo "lpar_state==$lpar_state" >> $out_log 
if [ "${lpar_state}" != "Not Activated" ]&&[ "${lpar_state}" != "Not Available" ]
then
	throwException "Please poweroff the lpar first." "105070"
fi


#####################################################################################
#####                                                                           #####
#####                         check template path                               #####
#####                                                                           #####
#####################################################################################
echo "$(date) : check template" >> $out_log
ssh ${ivm_user}@${ivm_ip} "ls ${tmp_path}" > /dev/null 2> ${error_log}
catchException "${error_log}"
if [ "$error_result" != "" ]
then
	throwException "The template path can not be found." "105009"
fi

#####################################################################################
#####                                                                           #####
#####                       get host serial number                              #####
#####                                                                           #####
#####################################################################################
echo "$(date) : check host serial number" >> $out_log
serial_num=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r sys -F serial_num" 2> "${error_log}")
catchException "${error_log}"
throwException "$error_result" "105060"
echo "serial_num=${serial_num}" >> $out_log

#####################################################################################
#####                                                                           #####
#####                  get virtual_scsi_adapters server id                      #####
#####                                                                           #####
#####################################################################################
echo "$(date) : Get virtual_scsi_adapters server id" >> $out_log
server_vscsi_id=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r prof --filter lpar_ids=${lpar_id} -F virtual_scsi_adapters" | awk -F'/' '{print $5}' 2> "${error_log}")
catchException "${error_log}"
throwException "$error_result" "105063"
echo "server_vscsi_id=${server_vscsi_id}" >> $out_log

#####################################################################################
#####                                                                           #####
#####                              get lv name                                  #####
#####                                                                           #####
#####################################################################################
echo "$(date) : Get lv name" >> $out_log
lv_name=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -all -type disk lv -field physloc backing -fmt :" | grep "C${server_vscsi_id}" | awk -F":" '{print $2}' 2> "${error_log}")
catchException "${error_log}"
throwException "$error_result" "105065"
echo "lv_name=${lv_name}" >> $out_log
if [ "$lv_name" == "" ]
then
	throwException "Virtual machine logical volume not found." "105065"
fi

#####################################################################################
#####                                                                           #####
#####                            get lv ppsize                                  #####
#####                                                                           #####
#####################################################################################
echo "$(date) : Get lv ppsize" >> $out_log
lv_size_info=$(ssh ${ivm_user}@${ivm_ip} "ioscli lslv ${lv_name} -field ppsize pps -fmt :" 2> ${error_log})
catchException "${error_log}"
throwException "$error_result" "105066"
lv_ppsize=$(echo "$lv_size_info" | awk -F":" '{print $1}' | awk '{print $1}')
lv_pps=$(echo "$lv_size_info" | awk -F":" '{print $2}')
lv_size=$(echo $lv_ppsize $lv_pps | awk '{print $1*$2}')
echo "lv_size=${lv_size}" >> $out_log


#####################################################################################
#####                                                                           #####
#####                     check template path size                              #####     
#####                                                                           #####
#####################################################################################
echo "$(date) : check template path size" >> $out_log
free_size=$(ssh ${ivm_user}@${ivm_ip} "df -k ${tmp_path}" 2> "${error_log}" | grep -v Filesystem | awk '{print $3/1024}')
catchException "${error_log}"
throwException "$error_result" "105070"
echo "free_size=${free_size}" >> $out_log

if [ $free_size -lt $lv_size ]
then
	throwException "Storage space is not enough !" "105070"
fi
echo "1|25|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                                 dd copy                                   #####
#####                                                                           #####
#####################################################################################
echo "$(date) : dd copy" >> $out_log
tmp_name="${tmp_name}.img"
expect ./ssh.exp ${ivm_user} ${ivm_ip} "oem_setup_env|dd if=/dev/${lv_name} of=${tmp_path}/\"${tmp_name}\" bs=10M 2> ${error_log} 1> /dev/null &" > /dev/null 2>&1


#####################################################################################
#####                                                                           #####
#####                             check dd copy                                 #####
#####                                                                           #####
#####################################################################################
cp_size=0
progress=25
i=1
while [ ${cp_size} -lt ${lv_size} ]
do
		sleep 15
		ps_rlt=$(ssh ${ivm_user}@${ivm_ip} "ps -ef|grep \"dd if=/dev/${lv_name} of=${tmp_path}/\"\"${tmp_name}\"\"\" | grep -v grep")
		if [ "${ps_rlt}" == "" ]
		then
			dd_rlt=$(ssh ${ivm_user}@${ivm_ip} "cat ${error_log}" 2> ${error_log})
			ssh ${ivm_user}@${ivm_ip} "rm -f ${error_log}" >> $out_log 2>&1
			catchException "${error_log}"
			throwException "$error_result" "105070"
			ssh ${ivm_user}@${ivm_ip} "rm -f ${error_log}"
			if [ "$(echo "${dd_rlt}" | grep -v "records in" | grep -v "records out")" != "" ]
			then
				ssh ${ivm_user}@${ivm_ip} "rm -f ${tmp_path}/\"${tmp_name}\""  > /dev/null 2>&1
				throwException "$dd_rlt" "105070"
			else
				break
			fi
		fi
		cp_size=$(ssh ${ivm_user}@${ivm_ip} "ls -l ${tmp_path}/\"${tmp_name}\" | awk '{print $5/1024/1024}'" 2> "${error_log}")
		catchException "${error_log}"
		if [ "${error_result}" != "" ]
		then
			ssh ${ivm_user}@${ivm_ip} "kill $(ps -ef|grep \"dd if=/dev/${lv_name} of=${tmp_path}/\"\"${tmp_name}\"\"\" | grep -v grep | awk '{print $2}') && rm -f ${tmp_path}/\"${tmp_name}\"" > /dev/null 2>&1
			echo "0|0|ERROR-105070:Copy template failure"
		#	rm -f ${error_log}
			exit 1
		fi
		if [ "$(echo ${cp_size}" "$(echo ${lv_size} | awk '{printf "%0.2f",$1/5*i}' i="$i") | awk '{if($1>=$2) print 0}')" = "0" ]
	  then
			progress=$(expr $progress + 10)
	    echo "1|${progress}|SUCCESS"
	    i=$(expr $i + 1)
	  fi
done

echo "1|75|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                             create tmp cfg                                #####
#####                                                                           #####
#####################################################################################
echo "$(date) : create tmp cfg" >> $out_log
tmp_size=$(ssh ${ivm_user}@${ivm_ip} "ls -l ${tmp_path}/\"${tmp_name}\"" | awk '{print $5/1024/1024}')
tmp_cfg=${tmp_path}"/"${tmp_name}.cfg"
expect ./ssh.exp ${ivm_user} ${ivm_ip} "oem_setup_env|echo id=$tmp_id > \"${tmp_cfg}\"|echo filename=\"${tmp_cfg}\" >> \"${tmp_cfg}\"|echo type=IMG >> \"${tmp_cfg}\"|echo size=$tmp_size >> \"${tmp_cfg}\"|echo desc=$tmp_des >> \"${tmp_cfg}\"" > /dev/null 2>&1 

if [ "$log_flag" == "0" ]
then
		rm -f $error_log" 2> /dev/null
		rm -f $out_log" 2> /dev/null
fi

echo "1|100|SUCCESS"

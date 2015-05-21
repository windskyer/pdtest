#!/usr/bin/ksh
#./ivm_vm_remove_vol.sh "172.30.126.12|padmin|24" 'lv:lvname1|pv:hdisk2|lu:sspcluster,ssppool,luudid'
#./ivm_vm_remove_vol.sh "172.30.126.12|padmin|24" 'lv:lvname1'
#./ivm_vm_remove_vol.sh "172.30.126.12|padmin|24" 'pv:hdisk2'
#./ivm_vm_remove_vol.sh "172.30.126.12|padmin|24" 'lu:sspcluster,ssppool,luudid'

. ./ivm_function.sh

log_flag=$(cat scrpits.properties 2> /dev/null | grep "LOG=" | awk -F"=" '{print $2}')
if [ "$log_flag" == "" ]
then
	log_flag=0
fi

DateNow=$(date +%Y%m%d%H%M%S)
random=$(perl -e 'my $random = int(rand(9999)); print "$random";')
out_log="${path_log}/out_ivm_vm_remove_vol_${DateNow}_${random}.log"
error_log="${path_log}/error_ivm_vm_remove_vol_${DateNow}_${random}.log"

log_debug $LINENO "$0 $*"

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
			echo "ERROR-${error_code}:"$(echo "$result" | awk -F']' '{print $2}') >&2
		else
			echo "ERROR-${error_code}: $result" >&2
		fi
		
		if [ "$log_flag" == "0" ]
		then
			rm -f "${error_log}" 2> /dev/null
			rm -f "$out_log" 2> /dev/null
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
    esac
done					

# check authorized and repair error authorized
check_authorized ${ivm_ip} ${ivm_user}

length=0
echo $2 | awk -F"|" '{for(i=1;i<=NF;i++) print $i}' | while read param
do
	storagetype=$(echo $param | awk -F":" '{print $1}' | awk -F"," '{print $1}')
	if [ "$storagetype" == "lv" ]
	then
		storage_type[$length]="LV"
		lv_name[$length]=$(echo $param | awk -F":" '{print $2}')
		length=$(expr $length + 1)
	fi
	
	if [ "$storagetype" == "pv" ]
	then
		storage_type[$length]="PV"
		pv_name[$length]=$(echo $param | awk -F":" '{print $2}')
		length=$(expr $length + 1)
	fi
	
	if [ "$storagetype" == "lu" ]
	then
		storage_type[$length]="LU"
		clustername[$length]=$(echo $param | awk -F":" '{print $2}' | awk -F"," '{print $1}')
		spname[$length]=$(echo $param | awk -F":" '{print $2}' | awk -F"," '{print $2}')
		lu_udid[$length]=$(echo $param | awk -F":" '{print $2}' | awk -F"," '{print $3}')
		length=$(expr $length + 1)
	fi
	
done


	#####################################################################################
	#####                                                                           #####
	#####                       get host serial number                              #####
	#####                                                                           #####
	#####################################################################################
	log_info $LINENO "check host serial number"
	log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"lssyscfg -r sys -F serial_num\""
	serial_num=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r sys -F serial_num" 2> /dev/null)
	log_debug $LINENO "serial_num=${serial_num}"

if [ "$lpar_id" != "" ]
then
	#####################################################################################
	#####                                                                           #####
	#####                  get virtual_scsi_adapters server id                      #####
	#####                                                                           #####
	#####################################################################################
	log_info $LINENO "Get virtual_scsi_adapters server id"
	log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"lssyscfg -r prof --filter lpar_ids=${lpar_id} -F virtual_scsi_adapters\" | awk -F'/' '{print \$5}'"
	server_vscsi_id=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r prof --filter lpar_ids=${lpar_id} -F virtual_scsi_adapters" | awk -F'/' '{print $5}' 2> /dev/null)
	log_debug $LINENO "server_vscsi_id=${server_vscsi_id}"
fi

i=0
while [ $i -lt $length ]
do
	if [ "${storage_type[$i]}" == "LV" ]
	then
		log_info $LINENO "vol type is lv"
		log_info $LINENO "Begin to unmmaping ${lv_name[$i]}"
		log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli rmvdev -vdev ${lv_name[$i]} -f\""
		lv_unmapping=$(ssh ${ivm_user}@${ivm_ip} "ioscli rmvdev -vdev ${lv_name[$i]} -f" 2> /dev/null)
		log_debug $LINENO "lv_unmapping=${lv_unmapping}"
		log_info $LINENO "Begin to remove ${lvs[$j]}"
		log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli rmlv -f ${lv_name[$i]}\""
		lv_remove=$(ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$i]}" 2> /dev/null)
		log_debug $LINENO "lv_remove=${lv_remove}"
	fi
	
	if [ "${storage_type[$i]}" == "PV" ]
	then
		log_info $LINENO "vol type is pv"
		log_info $LINENO "Begin to unmmaping ${pv_name[$i]}"
		log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli rmvdev -vdev ${pv_name[$i]} -f\""
		pv_unmapping=$(ssh ${ivm_user}@${ivm_ip} "ioscli rmvdev -vdev ${pv_name[$i]} -f" 2> /dev/null)
		log_debug $LINENO "pv_unmapping=${pv_unmapping}"
	fi
	
	if [ "${storage_type[$i]}" == "LU" ]
	then
		log_info $LINENO "vol type is LU"
		log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli lsmap -clustername ${clustername[$i]} -all -field Physloc backing vtd -fmt :\""
		ret=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -clustername ${clustername[$i]} -all -field Physloc backing vtd -fmt :" 2>&1)
		log_debug $LINENO "ret=${ret}"
		lu_vtd=$(echo "$ret"|grep "${serial_num}.*C${server_vscsi_id}:"|grep "${lu_udid[$i]}"|awk -F":" '{print $3}')
		log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli rmbdsp -vtd ${lu_vtd}\""
		lu_unmapping=$(ssh ${ivm_user}@${ivm_ip} "ioscli rmbdsp -vtd ${lu_vtd}" 2> /dev/null)
		log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli rmbdsp -clustername ${clustername[$i]} -sp ${spname[$i]} -luudid ${lu_udid[$i]}\""
		lu_remove=$(ssh ${ivm_user}@${ivm_ip} "ioscli rmbdsp -clustername ${clustername[$i]} -sp ${spname[$i]} -luudid ${lu_udid[$i]}" 2> "${error_log}")
		log_debug $LINENO "lu_remove=${lu_remove}"
		catchException "${error_log}"
		if [ "$error_result" != "" ]
		then
			throwException "$error_result" "105011"
		fi
		
	fi
	i=$(expr $i + 1)
done

if [ "$log_flag" == "0" ]
then
	rm -f "${error_log}" 2> /dev/null
	rm -f "$out_log" 2> /dev/null
fi




#!/usr/bin/ksh

#./ivm_vm_add_vol.sh "172.30.126.12|padmin|24" 'lv,size:rootvg,7000'
#./ivm_vm_add_vol.sh "172.30.126.12|padmin|24" 'lv,name:rootvg,lvname1'
#./ivm_vm_add_vol.sh "172.30.126.12|padmin|24" 'pv:hdisk2'
#./ivm_vm_add_vol.sh "172.30.126.12|padmin|24" 'lu,size:sspcluster,ssppool,size,luname,lutype'
#./ivm_vm_add_vol.sh "172.30.126.12|padmin|24" 'lu,name:sspcluster,ssppool,luudid'

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

aix_getinfo() {
	if [ $length -ne 0 ]
	then
		i=0
		while [ $i -lt $length ]
		do
			if [ "${storage_type[$i]}" == "LVSIZE" -o "${storage_type[$i]}" == "LVNAME" ]
			then
				echo "[\c"
				j=0
				while [ $j -lt $len ]
				do
					if [ "${lv_name[$i]}" == "${disk_[$j]}" ]
					then
						lv_num=$j
						break
					fi
					j=$(expr $j + 1)
				done
				echo  "{\c"
				echo  "\"serial_num\":\"$lv_num\", \c"
				echo  "\"vios_id\":\"$vios_id\", \c"
				echo  "\"lv_id\":\"${lv_id[$i]}\", \c"
				echo  "\"lv_name\":\"${lv_name[$i]}\", \c"
				echo  "\"lv_vg\":\"${lv_vg[$i]}\", \c"
				echo  "\"lv_state\":\"${lv_state[$i]}\", \c"
				echo  "\"lv_size\":\"${lv_size[$i]}\"\c"
				echo  "}\c"
			
				i=$(expr $i + 1)
				if [ "$i" != "${length}" ]
				then
					echo  ", \c"
				fi
				echo "]"
			fi
			
			if [ "${storage_type[$i]}" == "PV" ]
			then
				echo "[\c"
				j=0
				while [ $j -lt $len ]
				do
					if [ "${pv_name[$i]}" == "${disk_[$j]}" ]
					then
						pv_num=$j
						break
					fi
					j=$(expr $j + 1)
				done
				echo  "{\c"
				echo  "\"serial_num\":\"$pv_num\", \c"
				echo  "\"pv_name\":\"${pv_name[$i]}\"\c"
				echo  "}\c"
		
				i=$(expr $i + 1)
				if [ "$i" != "${length}" ]
				then
					echo  ", \c"
				fi
				echo "]"
			fi
		
			if [ "${storage_type[$i]}" == "LUSIZE" -o "${storage_type[$i]}" == "LUNAME" ]
			then
				echo "[\c"
				j=0
				while [ $j -lt $len ]
				do
					if [ "${lu_name[$i]}.${lu_udid[$i]}" == "${disk_[$j]}" ]
					then
						lu_num=$j
						break
					fi
					j=$(expr $j + 1)
				done
				echo  "{\c"
				echo  "\"serial_num\":\"$lu_num\", \c"
				echo  "\"luname\":\"${cluster_lu_name[$i]}\",\c"
				echo  "\"luudid\":\"${cluster_lu_udid[$i]}\",\c"
				echo  "\"provisiontype\":\"${cluster_lu_ProvisionType[$i]}\",\c"
				echo  "\"size\":\"${cluster_lu_size[$i]}\",\c"
				echo  "\"unusedsize\":\"${cluster_lu_unused[$i]}\"\c"
				echo  "}\c"
		
				i=$(expr $i + 1)
				if [ "$i" != "${length}" ]
				then
					echo  ", \c"
				fi
				echo "]"
			fi
		done
	fi
}

linux_getinfo() {
	if [ $length -ne 0 ]
	then
		i=0
		while [ $i -lt $length ]
		do
			if [ "${storage_type[$i]}" == "LVSIZE" -o "${storage_type[$i]}" == "LVNAME" ]
			then
				echo -e "[\c"
				j=0
				while [ $j -lt $len ]
				do
					if [ "${lv_name[$i]}" == "${disk_[$j]}" ]
					then
						lv_num=$j
						break
					fi
					j=$(expr $j + 1)
				done
				echo -e  "{\c"
				echo -e  "\"serial_num\":\"$lv_num\", \c"
				echo -e  "\"vios_id\":\"$vios_id\", \c"
				echo -e  "\"lv_id\":\"${lv_id[$i]}\", \c"
				echo -e  "\"lv_name\":\"${lv_name[$i]}\", \c"
				echo -e  "\"lv_vg\":\"${lv_vg[$i]}\", \c"
				echo -e  "\"lv_state\":\"${lv_state[$i]}\", \c"
				echo -e  "\"lv_size\":\"${lv_size[$i]}\"\c"
				echo -e "}\c"
			
				i=$(expr $i + 1)
				if [ "$i" != "${length}" ]
				then
					echo -e ", \c"
				fi
				echo "]"
			fi
			
			if [ "${storage_type[$i]}" == "PV" ]
			then
				echo -e "[\c"
				j=0
				while [ $j -lt $len ]
				do
					if [ "${pv_name[$i]}" == "${disk_[$j]}" ]
					then
						pv_num=$j
						break
					fi
					j=$(expr $j + 1)
				done
				echo -e "{\c"
				echo -e "\"serial_num\":\"$pv_num\", \c"
				echo -e "\"pv_name\":\"${pv_name[$i]}\"\c"
				echo -e "}\c"
		
				i=$(expr $i + 1)
				if [ "$i" != "${length}" ]
				then
					echo -e ", \c"
				fi
				echo "]"
			fi
		
			if [ "${storage_type[$i]}" == "LUSIZE" -o "${storage_type[$i]}" == "LUNAME" ]
			then
				echo -e "[\c"
				j=0
				while [ $j -lt $len ]
				do
					if [ "${lu_name[$i]}.${lu_udid[$i]}" == "${disk_[$j]}" ]
					then
						lu_num=$j
						break
					fi
					j=$(expr $j + 1)
				done
				echo -e "{\c"
				echo -e "\"serial_num\":\"$lu_num\", \c"
				echo -e "\"luname\":\"${cluster_lu_name[$i]}\",\c"
				echo -e "\"luudid\":\"${cluster_lu_udid[$i]}\",\c"
				echo -e "\"provisiontype\":\"${cluster_lu_ProvisionType[$i]}\",\c"
				echo -e "\"size\":\"${cluster_lu_size[$i]}\",\c"
				echo -e "\"unusedsize\":\"${cluster_lu_unused[$i]}\"\c"
				echo -e "}\c"
		
				i=$(expr $i + 1)
				if [ "$i" != "${length}" ]
				then
					echo -e ", \c"
				fi
				echo "]"
			fi
		done
	fi
}

info_length=0

echo $1 |awk -F"|" '{for(i=1;i<=NF;i++) print $i}' | while read param
do
	case $info_length in
		0)
				info_length=1;
				ivm_ip=$param;;
		1)
				info_length=2;        
				ivm_user=$param;;
		2)
				info_length=3;
				lpar_id=$param;;
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

# storagetype=$(echo $2|awk -F"," '{print $1}')
# if [ "$storagetype" == "lv" ]
# then
	# lvtype=$(echo $2|awk -F"," '{print $2}')
# fi

# length=0
# new_lv_num=0
# new_pv_num=0
# new_lu_num=0

# echo $3 |awk -F"|" '{for(i=1;i<=NF;i++) print $i}' | while read param
# do   
	# if [ "$param" != "" ]
	# then
		# num=$(echo $param | awk -F, '{print NF}')
		# if [ "$storagetype" == "lv" ] && [ "$num" == "2" ]
		# then
			# if [ "$lvtype" == "size" ]
			# then
				# new_vg_name[$new_lv_num]=$(echo $param | awk -F"," '{print $1}') 
				# new_lv_size[$new_lv_num]=$(echo $param | awk -F"," '{print $2}')
				# new_lv_num=$(expr $new_lv_num + 1 )
			# fi
			# if [ "$lvtype" == "name" ]
			# then
				# new_vg_name[$new_lv_num]=$(echo $param | awk -F"," '{print $1}') 
				# new_lv_name[$new_lv_num]=$(echo $param | awk -F"," '{print $2}') 
				# new_lv_num=$(expr $new_lv_num + 1 )
			# fi
		# else
			# if [ "$storagetype" == "pv" ] && [ "$num" == "1" ]
			# then
				# new_pv_name[$new_pv_num]=$(echo $param) 
				# new_pv_num=$(expr $new_pv_num + 1 )
			# fi
		# fi
		
	# fi
# done

length=0
echo $2 | awk -F"|" '{for(i=1;i<=NF;i++) print $i}' | while read param
do
	storagetype=$(echo $param | awk -F":" '{print $1}' | awk -F"," '{print $1}')
	if [ "$storagetype" == "lv" ]
	then
		if [ "$(echo $param | awk -F":" '{print $1}' | awk -F"," '{print $2}')" == "size" ]
		then
				storage_type[$length]="LVSIZE"
				lv_vg[$length]=$(echo $param | awk -F":" '{print $2}' | awk -F"," '{print $1}')
				lv_size[$length]=$(echo $param | awk -F":" '{print $2}' | awk -F"," '{print $2}')
				length=$(expr $length + 1)
		else
				storage_type[$length]="LVNAME"
				lv_vg[$length]=$(echo $param | awk -F":" '{print $2}' | awk -F"," '{print $1}')
				lv_name[$length]=$(echo $param | awk -F":" '{print $2}' | awk -F"," '{print $2}')
				length=$(expr $length + 1)
		fi
	fi
	
	if [ "$storagetype" == "pv" ]
	then
			storage_type[$length]="PV"
			pv_name[$length]=$(echo $param | awk -F":" '{print $2}')
			length=$(expr $length + 1)
	fi
	
	if [ "$storagetype" == "lu" ]
	then
		if [ "$(echo $param | awk -F":" '{print $1}' | awk -F"," '{print $2}')" == "size" ]
		then
				storage_type[$length]="LUSIZE"
				clustername[$length]=$(echo $param | awk -F":" '{print $2}' | awk -F"," '{print $1}')
				spname[$length]=$(echo $param | awk -F":" '{print $2}' | awk -F"," '{print $2}')
				lu_size[$length]=$(echo $param | awk -F":" '{print $2}' | awk -F"," '{print $3}')
				lu_name[$length]=$(echo $param | awk -F":" '{print $2}' | awk -F"," '{print $4}')
				lu_mode[$length]=$(echo $param | awk -F":" '{print $2}' | awk -F"," '{print $5}')
				length=$(expr $length + 1)
		else
				storage_type[$length]="LUNAME"
				clustername[$length]=$(echo $param | awk -F":" '{print $2}' | awk -F"," '{print $1}')
				spname[$length]=$(echo $param | awk -F":" '{print $2}' | awk -F"," '{print $2}')
				lu_udid[$length]=$(echo $param | awk -F":" '{print $2}' | awk -F"," '{print $3}')
				length=$(expr $length + 1)
		fi
	fi
done


log_flag=$(cat scrpits.properties 2> /dev/null | grep "LOG=" | awk -F"=" '{print $2}')
if [ "$log_flag" == "" ]
then
	log_flag=0
fi

DateNow=$(date +%Y%m%d%H%M%S)
random=$(perl -e 'my $random = int(rand(9999)); print "$random";')
out_log="${path_log}/out_ivm_vm_add_vol_${DateNow}_${random}.log"
error_log="${path_log}/error_ivm_vm_add_vol_${DateNow}_${random}.log"

log_debug $LINENO "$0 $*"
# check authorized and repair error authorized
check_authorized ${ivm_ip} ${ivm_user}

#####################################################################################
#####                                                                           #####
#####                            get vios' id                                   #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "get vios' id"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"lssyscfg -r lpar -F lpar_id,lpar_env\" | awk -F, '{if(\$2=="vioserver") print \$1}'"
vios_id=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar -F lpar_id,lpar_env" 2> $error_log | awk -F, '{if($2=="vioserver") print $1}')
if [ "$(echo $?)" != "0" ]
then
	if [ "$vios_id" != "" ]
	then
		throwException "$vios_id" "105061"
	else
		catchException "${error_log}"
		throwException "$error_result" "105061"
	fi
fi
log_debug $LINENO "vios_id=${vios_id}"

#####################################################################################
#####                                                                           #####
#####                       get host serial number                              #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "check host serial number"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"lssyscfg -r sys -F serial_num\""
serial_num=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r sys -F serial_num" 2> $error_log)
if [ "$(echo $?)" != "0" ]
then
	if [ "$serial_num" != "" ]
	then
		throwException "$serial_num" "105060"
	else
		catchException "${error_log}"
		throwException "$error_result" "105060"
	fi
fi
log_debug $LINENO "serial_num=${serial_num}"


#####################################################################################
#####                                                                           #####
#####                  get virtual_scsi_adapters server id                      #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "Get virtual_scsi_adapters server id"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"lssyscfg -r prof --filter lpar_ids=${lpar_id} -F virtual_scsi_adapters\" | awk -F'/' '{print \$5}'"
server_vscsi_id=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r prof --filter lpar_ids=${lpar_id} -F virtual_scsi_adapters" | awk -F'/' '{print $5}' 2> "${error_log}")
if [ "$(echo $?)" != "0" ]
then
	if [ "$server_vscsi_id" != "" ]
	then
		throwException "$server_vscsi_id" "105063"
	else
		catchException "${error_log}"
		throwException "$error_result" "105063"
	fi
fi
log_debug $LINENO "server_vscsi_id=${server_vscsi_id}"


#####################################################################################
#####                                                                           #####
#####                            get vios' adapter                              #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "get vios' adapter"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli lsmap -all -fmt :\" | grep ${serial_num} | grep "C${server_vscsi_id}:" | awk -F":" '{print \$1}'"
vadapter_vios=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -all -fmt :" | grep ${serial_num} | grep "C${server_vscsi_id}:" | awk -F":" '{print $1}' 2> "${error_log}")
if [ "$(echo $?)" != "0" ]
then
	if [ "$vadapter_vios" != "" ]
	then
		throwException "$vadapter_vios" "105064"
	else
		catchException "${error_log}"
		throwException "$error_result" "105064"
	fi
fi
log_debug $LINENO  "vadapter_vios=${vadapter_vios}"
#echo "1|50|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                            new create lv in vg                            #####
#####                                                                           #####
#####################################################################################
i=0
while [ $i -lt $length ]
do
	log_info $LINENO "storage_type is LVSIZE"
	if [ "${storage_type[$i]}" == "LVSIZE" ]
	then
		log_info $LINENO "Go to LV..."
		#####################################################################################
		#####                                                                           #####
		#####                              check vg                                     #####
		#####                                                                           #####
		#####################################################################################
		log_info $LINENO "check vg"
		#add 'head -n 1' for ios2231
		log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli lsvg ${lv_vg[$i]} -field freepps -fmt :\" | head -n 1 | awk '{print substr(\$2,2,length(\$2))}'"
		vg_free_size=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsvg ${lv_vg[$i]} -field freepps -fmt :" 2> ${error_log} | head -n 1 | awk '{print substr($2,2,length($2))}')
		log_debug $LINENO "vg_free_size=${vg_free_size}"
		catchException "${error_log}"
		time=0
		while [ "$(echo ${error_result} | grep "Volume group is locked")" != "" ]||[ "$(echo ${error_result} | grep "ODM lock")" != "" ]
		do
			sleep 1
			vg_free_size=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsvg ${lv_vg[$i]} -field freepps -fmt :" 2> ${error_log} | head -n 1 | awk '{print substr($2,2,length($2))}')
			catchException "${error_log}"
			time=$(expr $time + 1)
			if [ $time -gt 30 ]
			then
				break
			fi
		done
		if [ "$error_result" != "" ]
		then
			j=0
			while [ $j -lt $i ]
			do
				if [ "${storage_type[$j]}" == "LVSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
				fi
				if [ "${storage_type[$j]}" == "LUSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmbdsp -clustername ${clustername[$j]} -sp ${spname[$j]} -luudid ${lu_udid[$j]}" > /dev/null 2>&1
				fi
				j=$(expr $j + 1)
			done
		fi
		throwException "$error_result" "105010"
			
		if [ $vg_free_size -lt ${lv_size[$i]} ]
		then
			j=0
			while [ $j -lt $i ]
			do
				if [ "${storage_type[$j]}" == "LVSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
				fi
				if [ "${storage_type[$j]}" == "LUSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmbdsp -clustername ${clustername[$j]} -sp ${spname[$j]} -luudid ${lu_udid[$j]}" > /dev/null 2>&1
				fi
				j=$(expr $j + 1)
			done
			throwException "Storage ${lv_vg[$i]} is not enough !" "105010"
		fi
		
		#####################################################################################
		#####                                                                           #####
		#####                              create lv                                    #####
		#####                                                                           #####
		#####################################################################################
		log_info $LINENO "create lv ${lpar_name}"
		log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli mklv ${lv_vg[$i]} ${lv_size[$i]}M\""
		lv_name[$i]=$(ssh ${ivm_user}@${ivm_ip} "ioscli mklv ${lv_vg[$i]} ${lv_size[$i]}M" 2> "${error_log}")
		log_debug $LINENO "lv_name[$i]=${lv_name[$i]}"
		catchException "${error_log}"
		time=0
		while [ "$(echo ${error_result} | grep "Volume group is locked")" != "" ]
		do
			sleep 1
			lv_name[$i]=$(ssh ${ivm_user}@${ivm_ip} "ioscli mklv ${lv_vg[$i]} ${lv_size[$i]}M" 2> "${error_log}")
			catchException "${error_log}"
			time=$(expr $time + 1)
			if [ $time -gt 30 ]
			then
				break
			fi
		done
		if [ "$error_result" != "" ]
		then
			j=0
			while [ $j -lt $i ]
			do
				if [ "${storage_type[$j]}" == "LVSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
				fi
				if [ "${storage_type[$j]}" == "LUSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmbdsp -clustername ${clustername[$j]} -sp ${spname[$j]} -luudid ${lu_udid[$j]}" > /dev/null 2>&1
				fi
				j=$(expr $j + 1)
			done
		fi
		throwException "$error_result" "105011"
		dd_name[$i]=${lv_name[$i]}
		log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli lslv ${lv_name[$i]} -field lvid vgname ppsize pps lvstate -fmt :\""
		lslv=$(ssh ${ivm_user}@${ivm_ip} "ioscli lslv ${lv_name[$i]} -field lvid vgname ppsize pps lvstate -fmt :")
		log_debug $LINENO "lslv=${lslv}"
		if [ "$lslv" == "" ]
		then
			echo "Unable to find  00 in the Device Configuration Database" >&2
			exit 1
		fi
		ppsize=$(echo "${lslv}" | awk -F":" '{print $3}' | awk '{print $1}')
		lv_id[$i]=$(echo "${lslv}" | awk -F":" '{print $1}')
		lv_name[$i]=${lv_name[$i]}
		lv_vg[$i]=$(echo "${lslv}" | awk -F":" '{print $2}')
		lv_state[$i]=$(echo "${lslv}" | awk -F":" '{print $5}')
		case ${lv_state[$i]} in
			"opened/syncd")
				lv_state[$i]=1;;
			"closed/syncd")
				lv_state[$i]=2;;
			*)
				lv_state[$i]=3;;
		esac
		lv_size[$i]=$(echo "${lslv}" | awk -F":" '{print ppsize*$4}' ppsize="$ppsize")
	fi
	
	log_info $LINENO "storage_type is LVNAME"
	if [ "${storage_type[$i]}" == "LVNAME" ]
	then
		#####################################################################################
		#####                                                                           #####
		#####                              check lv                                     #####
		#####                                                                           #####
		#####################################################################################
		log_info $LINENO "check lv"
		log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli lsvg -lv ${lv_vg[$i]} -fmt :\"| awk -F":" '{print \$1}'"
		vg_lv_list=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsvg -lv ${lv_vg[$i]} -fmt :"| awk -F":" '{print $1}' 2> "${error_log}")
		log_debug $LINENO "vg_lv_list=${vg_lv_list}"
		catchException "${error_log}"
		time=0
		while [ "$(echo ${error_result} | grep "Volume group is locked")" != "" ]||[ "$(echo ${error_result} | grep "ODM lock")" != "" ]
		do
			sleep 1
			vg_lv_list=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsvg -lv ${lv_vg[$i]} -fmt :" 2> ${error_log} | awk -F":" '{print $1}' )
			catchException "${error_log}"
			time=$(expr $time + 1)
			if [ $time -gt 30 ]
			then
				break
			fi
		done
		if [ "$error_result" != "" ]
		then
			j=0
			while [ $j -lt $i ]
			do
				if [ "${storage_type[$j]}" == "LVSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
				fi
				if [ "${storage_type[$j]}" == "LUSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmbdsp -clustername ${clustername[$j]} -sp ${spname[$j]} -luudid ${lu_udid[$j]}" > /dev/null 2>&1
				fi
				j=$(expr $j + 1)
			done
		fi
		throwException "$error_result" "105011"
				
		if [ "$(echo $vg_lv_list | awk '{ for(i=1;i<=NF;i++) { if($i == lvname) { print $i } } }' lvname=${lv_name[$i]})" == "" ]
		then
			j=0
			while [ $j -lt $i ]
			do
				if [ "${storage_type[$j]}" == "LVSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
				fi
				if [ "${storage_type[$j]}" == "LUSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmbdsp -clustername ${clustername[$j]} -sp ${spname[$j]} -luudid ${lu_udid[$j]}" > /dev/null 2>&1
				fi
				j=$(expr $j + 1)
			done
			throwException "LV ${lv_name[$i]} is not existing in VG ${lv_vg[$i]} !" "105010"
		fi
		dd_name[$i]=${lv_name[$i]}
		log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli lslv ${lv_name[$i]} -field lvid vgname ppsize pps lvstate -fmt :\""
		lslv=$(ssh ${ivm_user}@${ivm_ip} "ioscli lslv ${lv_name[$i]} -field lvid vgname ppsize pps lvstate -fmt :")
		log_debug $LINENO "lslv=${lslv}"
		if [ "$lslv" == "" ]
		then
			echo "Unable to find  00 in the Device Configuration Database" >&2
			exit 1
		fi
		ppsize=$(echo "${lslv}" | awk -F":" '{print $3}' | awk '{print $1}')
		lv_id[$i]=$(echo "${lslv}" | awk -F":" '{print $1}')
		lv_name[$i]=${lv_name[$i]}
		lv_vg[$i]=$(echo "${lslv}" | awk -F":" '{print $2}')
		lv_state[$i]=$(echo "${lslv}" | awk -F":" '{print $5}')
		case ${lv_state[$i]} in
			"opened/syncd")
				lv_state[$i]=1;;
			"closed/syncd")
				lv_state[$i]=2;;
			*)
				lv_state[$i]=3;;
		esac
		lv_size[$i]=$(echo "${lslv}" | awk -F":" '{print ppsize*$4}' ppsize="$ppsize")
	fi
	
	log_info $LINENO "storage_type is PV"
	if [ "${storage_type[$i]}" == "PV" ]
	then
		log_info $LINENO "Go to PV..."
		#####################################################################################
		#####                                                                           #####
		#####                              check pv                                     #####
		#####                                                                           #####
		#####################################################################################
		log_info $LINENO "check pv"
		log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli lspv -avail -field name -fmt :\""
		lspv_name=$(ssh ${ivm_user}@${ivm_ip} "ioscli lspv -avail -field name -fmt :" 2> ${error_log})
		log_debug $LINENO "lspv_name=${lspv_name}"
		catchException "${error_log}"
		if [ "$error_result" != "" ]
		then
			j=0
			while [ $j -lt $i ]
			do
				if [ "${storage_type[$j]}" == "LVSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
				fi
				if [ "${storage_type[$j]}" == "LUSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmbdsp -clustername ${clustername[$j]} -sp ${spname[$j]} -luudid ${lu_udid[$j]}" > /dev/null 2>&1
				fi
				j=$(expr $j + 1)
			done
		fi
		throwException "$error_result" "105067"
		log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli lsmap -all -type disk -field backing -fmt :\" | awk -F":" '{for(i=1;i<=NF;i++) print \$i}'"
		pv_map=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -all -type disk -field backing -fmt :" 2> ${error_log}  | awk -F":" '{for(i=1;i<=NF;i++) print $i}')
		log_debug $LINENO "pv_map=${pv_map}"
		catchException "${error_log}"
		if [ "$error_result" != "" ]
		then
			j=0
			while [ $j -lt $i ]
			do
				if [ "${storage_type[$j]}" == "LVSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
				fi
				if [ "${storage_type[$j]}" == "LUSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmbdsp -clustername ${clustername[$j]} -sp ${spname[$j]} -luudid ${lu_udid[$j]}" > /dev/null 2>&1
				fi
				j=$(expr $j + 1)
			done
		fi
		throwException "$error_result" "105067"
		if [ "$(echo $pv_map | sed 's/://')" != "" ]
		then
			echo "$pv_map" | awk -F":" '{for(i=1;i<=NF;i++) print $i}' | while read line
			do
				if [ "$line" != "" ]
				then
					lspv_name=$(echo $lspv_name | awk '{ for(i=1;i<=NF;i++) { if($i != pv_name) { print $i } } }' pv_name="$line")
				fi
			done
		fi
		
		free_flag=0
		for pv in $lspv_name
		do
			if [ "${pv_name[$i]}" == "$pv" ]
			then
				free_flag=1
			fi
		done
		if [ "$free_flag" == "0" ]
		then
			j=0
			while [ $j -lt $i ]
			do
				if [ "${storage_type[$j]}" == "LVSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
				fi
				if [ "${storage_type[$j]}" == "LUSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmbdsp -clustername ${clustername[$j]} -sp ${spname[$j]} -luudid ${lu_udid[$j]}" > /dev/null 2>&1
				fi
				j=$(expr $j + 1)
			done
			throwException "The ${pv_name[$i]} is in used." "105067"
		fi
		dd_name[$i]=${pv_name[$i]}
	fi
	
	log_info $LINENO "storage_type is LUSIZE"
	if [ "${storage_type[$i]}" == "LUSIZE" ]
	then
		#####################################################################################
		#####                                                                           #####
		#####                              check ssp                                    #####
		#####                                                                           #####
		#####################################################################################
		log_info $LINENO "check ssp ${clustername[$i]}"
		log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli lssp -clustername ${clustername[$i]} -field pool size free total overcommit lus type id -fmt :\" | awk -F":" '{if(\$1==sp_name) print \$3}' sp_name=${spname[$i]}"
		ssp_free_size=$(ssh ${ivm_user}@${ivm_ip} "ioscli lssp -clustername ${clustername[$i]} -field pool size free total overcommit lus type id -fmt :" | awk -F":" '{if($1==sp_name) print $3}' sp_name=${spname[$i]} 2> "${error_log}")
		log_debug $LINENO "ssp_free_size=${ssp_free_size}"
		catchException "${error_log}"
		if [ "$error_result" != "" ]
		then
			j=0
			while [ $j -lt $i ]
			do
				if [ "${storage_type[$j]}" == "LVSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
				fi
				if [ "${storage_type[$j]}" == "LUSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmbdsp -clustername ${clustername[$j]} -sp ${spname[$j]} -luudid ${lu_udid[$j]}" > /dev/null 2>&1
				fi
				j=$(expr $j + 1)
			done
		fi
		throwException "$error_result" "105010"
			
		if [ "$ssp_free_size" -lt "${lu_size[$i]}" ]
		then
			j=0
			while [ $j -lt $i ]
			do
				if [ "${storage_type[$j]}" == "LVSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
				fi
				if [ "${storage_type[$j]}" == "LUSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmbdsp -clustername ${clustername[$j]} -sp ${spname[$j]} -luudid ${lu_udid[$j]}" > /dev/null 2>&1
				fi
				j=$(expr $j + 1)
			done
			throwException "Storage SSP ${clustername[$i]} is not enough !" "105010"
		fi

		#####################################################################################
		#####                                                                           #####
		#####                              create lu                                    #####
		#####                                                                           #####
		#####################################################################################
		log_info $LINENO "create lu ${lu_name}"
		if [ "${lu_mode[$i]}" == "thick" ]
		then
			log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli mkbdsp -clustername ${clustername[$i]} -sp ${spname[$i]} ${lu_size[$i]} -bd ${lu_name[$i]} -${lu_mode[$i]}\""
			ssp_lu_info=$(ssh ${ivm_user}@${ivm_ip} "ioscli mkbdsp -clustername ${clustername[$i]} -sp ${spname[$i]} ${lu_size[$i]} -bd ${lu_name[$i]} -${lu_mode[$i]}" 2> "${error_log}")
			log_debug $LINENO "ssp_lu_info=${ssp_lu_info}"
		else
			log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli mkbdsp -clustername ${clustername[$i]} -sp ${spname[$i]} ${lu_size[$i]} -bd ${lu_name[$i]}\""
			ssp_lu_info=$(ssh ${ivm_user}@${ivm_ip} "ioscli mkbdsp -clustername ${clustername[$i]} -sp ${spname[$i]} ${lu_size[$i]} -bd ${lu_name[$i]}" 2> "${error_log}")
			log_debug $LINENO "ssp_lu_info=${ssp_lu_info}"
		fi
		catchException "${error_log}"
		if [ "$error_result" != "" ]
		then
			j=0
			while [ $j -lt $i ]
			do
				if [ "${storage_type[$j]}" == "LVSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
				fi
				if [ "${storage_type[$j]}" == "LUSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmbdsp -clustername ${clustername[$j]} -sp ${spname[$j]} -luudid ${lu_udid[$j]}" > /dev/null 2>&1
				fi
				j=$(expr $j + 1)
			done
		fi
		throwException "$error_result" "105011"
		lu_udid[$i]=$(echo "$ssp_lu_info"|grep "Lu Udid"|awk -F":" '{print $2}')
		
		mount_info=$(expect ./ssh.exp ${ivm_user} ${ivm_ip} "oem_setup_env | mount|exit|exit" 2>&1)
		log_debug $LINENO "mount_info=${mount_info}"
		lu_dev_path=$(echo "$mount_info" | grep "/var/vio/SSP/${clustername[$i]}/*" | awk '{print $1}')
		lu_rdev[$i]="${lu_dev_path}/VOL1/${lu_name[$i]}.${lu_udid[$i]}"
		dd_name[$i]=${lu_rdev[$i]}
		
		log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli lssp -clustername ${clustername} -sp ${spname} -bd -fmt ':'\"|grep ${lu_udid}"
		lu=$(ssh ${ivm_user}@${ivm_ip} "ioscli lssp -clustername ${clustername} -sp ${spname} -bd -fmt ':'"|grep ${lu_udid} 2> "${error_log}")
		log_debug $LINENO "lu=${lu}"
		catchException "${error_log}"
		if [ "$error_result" != "" ]
		then
			j=0
			while [ $j -lt $i ]
			do
				if [ "${storage_type[$j]}" == "LVSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
				fi
				if [ "${storage_type[$j]}" == "LUSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmbdsp -clustername ${clustername[$j]} -sp ${spname[$j]} -luudid ${lu_udid[$j]}" > /dev/null 2>&1
				fi
				j=$(expr $j + 1)
			done
		fi
		throwException "$error_result" "105011"
		if [ "${lu_udid[$i]}" != "" ]
		then
			cluster_lu_name[$i]=$(echo $lu | awk -F ':' '{print $1}')
			cluster_lu_size[$i]=$(echo $lu | awk -F ':' '{print $2}')
			cluster_lu_ProvisionType[$i]=$(echo $lu | awk -F ':' '{print $3}')
			cluster_lu_used[$i]=$(echo $lu | awk -F ':' '{print $4}')
			cluster_lu_unused[$i]=$(echo $lu | awk -F ':' '{print $5}')
			cluster_lu_udid[$i]=$(echo $lu | awk -F ':' '{print $6}')
		fi
	fi
	
	log_info $LINENO "storage_type is LUNAME"
	if [ "${storage_type[$i]}" == "LUNAME" ]
	then
		#####################################################################################
		#####                                                                           #####
		#####                              check lu                                     #####
		#####                                                                           #####
		#####################################################################################
		log_info $LINENO "check lu ${lu_udid[$i]}"
		log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli lssp -clustername ${clustername[$i]} -sp ${spname[$i]} -bd -field luname luudid -fmt :\""
		ssp_lu_list=$(ssh ${ivm_user}@${ivm_ip} "ioscli lssp -clustername ${clustername[$i]} -sp ${spname[$i]} -bd -field luname luudid -fmt :" 2> "${error_log}")
		log_debug $LINENO "ssp_lu_list=${ssp_lu_list}"
		catchException "${error_log}"
		if [ "$error_result" != "" ]
		then
			j=0
			while [ $j -lt $i ]
			do
				if [ "${storage_type[$j]}" == "LVSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
				fi
				if [ "${storage_type[$j]}" == "LUSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmbdsp -clustername ${clustername[$j]} -sp ${spname[$j]} -luudid ${lu_udid[$j]}" > /dev/null 2>&1
				fi
				j=$(expr $j + 1)
			done
		fi
		throwException "$error_result" "105011"
				
		lu_name[$i]=$(echo "$ssp_lu_list" | awk -F":" '{ if($2 == luudid) { print $1 } }' luudid=${lu_udid[$i]})
		if [ "${lu_name[$i]}" == "" ]
		then
			j=0
			while [ $j -lt $i ]
			do
				if [ "${storage_type[$j]}" == "LVSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
				fi
				if [ "${storage_type[$j]}" == "LUSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmbdsp -clustername ${clustername[$j]} -sp ${spname[$j]} -luudid ${lu_udid[$j]}" > /dev/null 2>&1
				fi
				j=$(expr $j + 1)
			done
			throwException "LU ${lu_udid[$i]} is not existing in SSP ${clustername[$i]}" "105010"
		fi	
		
		mount_info=$(expect ./ssh.exp ${ivm_user} ${ivm_ip} "oem_setup_env | mount|exit|exit" 2>&1)
		log_debug $LINENO "mount_info=${mount_info}"
		lu_dev_path=$(echo "$mount_info" | grep "/var/vio/SSP/${clustername[$i]}/*" | awk '{print $1}')
		lu_rdev[$i]="${lu_dev_path}/VOL1/${lu_name[$i]}.${lu_udid[$i]}"
		dd_name[$i]=${lu_rdev[$i]}
		
		log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli lssp -clustername ${clustername} -sp ${spname} -bd -fmt ':'\"|grep ${lu_udid}"
		lu=$(ssh ${ivm_user}@${ivm_ip} "ioscli lssp -clustername ${clustername} -sp ${spname} -bd -fmt ':'"|grep ${lu_udid} 2> "${error_log}")
		log_debug $LINENO "lu=${lu}"
		catchException "${error_log}"
		if [ "$error_result" != "" ]
		then
			j=0
			while [ $j -lt $i ]
			do
				if [ "${storage_type[$j]}" == "LVSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
				fi
				if [ "${storage_type[$j]}" == "LUSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmbdsp -clustername ${clustername[$j]} -sp ${spname[$j]} -luudid ${lu_udid[$j]}" > /dev/null 2>&1
				fi
				j=$(expr $j + 1)
			done
		fi
		throwException "$error_result" "105011"
		if [ "${lu_udid[$i]}" != "" ]
		then
			cluster_lu_name[$i]=$(echo $lu | awk -F ':' '{print $1}')
			cluster_lu_size[$i]=$(echo $lu | awk -F ':' '{print $2}')
			cluster_lu_ProvisionType[$i]=$(echo $lu | awk -F ':' '{print $3}')
			cluster_lu_used[$i]=$(echo $lu | awk -F ':' '{print $4}')
			cluster_lu_unused[$i]=$(echo $lu | awk -F ':' '{print $5}')
			cluster_lu_udid[$i]=$(echo $lu | awk -F ':' '{print $6}')
		fi
	fi
	i=$(expr $i + 1)
done
	
#####################################################################################
#####                                                                           #####
#####                             create mapping                                #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "create mapping"

i=0
while [ $i -lt $length ]
do
	log_info $LINENO "storage_type is ${storage_type[$i]}"
	if [ "${storage_type[$i]}" == "LVSIZE" -o "${storage_type[$i]}" == "LVNAME" -o "${storage_type[$i]}" == "PV" ]
	then
		log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli mkvdev -vdev ${dd_name[$i]} -vadapter ${vadapter_vios}\""
		mapping_name=$(ssh ${ivm_user}@${ivm_ip} "ioscli mkvdev -vdev ${dd_name[$i]} -vadapter ${vadapter_vios}" 2> "${error_log}")
		log_debug $LINENO "mapping_name=${mapping_name}"
		catchException "${error_log}"
		time=0
		while [ "$(echo ${error_result} | grep "Volume group is locked")" != "" ]||[ "$(echo ${error_result} | grep "ODM lock")" != "" ]
		do
			sleep 1
			mapping_name=$(ssh ${ivm_user}@${ivm_ip} "ioscli mkvdev -vdev ${dd_name[$i]} -vadapter ${vadapter_vios}" 2> "${error_log}")
			catchException "${error_log}"
			time=$(expr $time + 1)
			if [ "$time" -gt 30 ]
			then
				break
			fi
		done
		if [ "${error_result}" != "" ]
		then
			j=0
			while [ $j -lt $length ]
			do
				if [ "${storage_type[$j]}" == "LVSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmvdev -vdev ${lv_name[$j]} -f" > /dev/null 2>&1
					ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
				fi
				if [ $j -lt $i ]
				then
					if [ "${storage_type[$j]}" == "LVNAME" ]
					then
						ssh ${ivm_user}@${ivm_ip} "ioscli rmvdev -vdev ${lv_name[$j]} -f" > /dev/null 2>&1
					fi
				fi
				if [ "${storage_type[$j]}" == "LUSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmbdsp -clustername ${clustername[$j]} -sp ${spname[$j]} -luudid ${lu_udid[$j]}" > /dev/null 2>&1
				fi
				if [ $j -lt $i ]
				then
					if [ "${storage_type[$j]}" == "LUNAME" ]
					then
						ret=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -clustername ${clustername[$j]} -all -field backing vtd -fmt :" 2>&1)
						lu_vtd=$(echo "$ret"|grep "${serial_num}.*C${server_vscsi_id}:"|grep "${lu_udid[$j]}"|awk -F":" '{print $2}')
						lu_unmapping=$(ssh ${ivm_user}@${ivm_ip} "ioscli rmbdsp -vtd ${lu_vtd}" 2> /dev/null)
					fi
				fi
				if [ $j -lt $i ]
				then
					if [ "${storage_type[$j]}" == "PV" ]
					then
						ssh ${ivm_user}@${ivm_ip} "ioscli rmvdev -vdev ${pv_name[$j]}" > /dev/null 2>&1
					fi
				fi
				j=$(expr $j + 1)
			done
		fi
		throwException "$error_result" "105015"
	else
		log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli mkbdsp -clustername ${clustername[$i]} -sp ${spname[$i]} -luudid ${lu_udid[$i]} -vadapter ${vadapter_vios}\""
		lu_map_info=$(ssh ${ivm_user}@${ivm_ip} "ioscli mkbdsp -clustername ${clustername[$i]} -sp ${spname[$i]} -luudid ${lu_udid[$i]} -vadapter ${vadapter_vios}" 2> "${error_log}")
		log_debug $LINENO "lu_map_info=${lu_map_info}"
		catchException "${error_log}"
		if [ "${error_result}" != "" ]
		then
			j=0
			while [ $j -lt $length ]
			do
				if [ "${storage_type[$j]}" == "LVSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmvdev -vdev ${lv_name[$j]} -f" > /dev/null 2>&1
					ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
				fi
				if [ $j -lt $i ]
				then
					if [ "${storage_type[$j]}" == "LVNAME" ]
					then
						ssh ${ivm_user}@${ivm_ip} "ioscli rmvdev -vdev ${lv_name[$j]} -f" > /dev/null 2>&1
					fi
				fi
				if [ "${storage_type[$j]}" == "LUSIZE" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmbdsp -clustername ${clustername[$j]} -sp ${spname[$j]} -luudid ${lu_udid[$j]}" > /dev/null 2>&1
				fi
				if [ $j -lt $i ]
				then
					if [ "${storage_type[$j]}" == "LUNAME" ]
					then
						ret=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -clustername ${clustername[$j]} -all -field Physloc backing vtd -fmt :" 2>&1)
						lu_vtd=$(echo "$ret"|grep "${serial_num}.*C${server_vscsi_id}:"|grep "${lu_udid[$j]}"|awk -F":" '{print $3}')
						lu_unmapping=$(ssh ${ivm_user}@${ivm_ip} "ioscli rmbdsp -vtd ${lu_vtd}" 2> /dev/null)
					fi
				fi
				if [ $j -lt $i ]
				then
					if [ "${storage_type[$j]}" == "PV" ]
					then
						ssh ${ivm_user}@${ivm_ip} "ioscli rmvdev -vdev ${pv_name[$j]}" > /dev/null 2>&1
					fi
				fi
				j=$(expr $j + 1)
			done
		fi
		throwException "$error_result" "105015"
	fi
	i=$(expr $i + 1)
done	
	

#####################################################################################
#####                                                                           #####
#####                              get disk info                                #####
#####                                                                           #####
#####################################################################################
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli lsmap -vadapter $vadapter_vios -type lv disk cl_disk -field physloc lun backing -fmt :\""
disk_map_info=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -vadapter $vadapter_vios -type lv disk cl_disk -field physloc lun backing -fmt :" 2>&1)
if [ $? -ne 0 ]
then
	j=0
	while [ $j -lt $length ]
	do
		if [ "${storage_type[$j]}" == "LVSIZE" ]
		then
			ssh ${ivm_user}@${ivm_ip} "ioscli rmvdev -vdev ${lv_name[$j]} -f" > /dev/null 2>&1
			ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
		fi
		if [ "${storage_type[$j]}" == "LVNAME" ]
		then
			ssh ${ivm_user}@${ivm_ip} "ioscli rmvdev -vdev ${lv_name[$j]} -f" > /dev/null 2>&1
		fi
		if [ "${storage_type[$j]}" == "LUSIZE" ]
		then
			ssh ${ivm_user}@${ivm_ip} "ioscli rmbdsp -clustername ${clustername[$j]} -sp ${spname[$j]} -luudid ${lu_udid[$j]}" > /dev/null 2>&1
		fi
		if [ "${storage_type[$j]}" == "LUNAME" ]
		then
			ret=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -clustername ${clustername[$j]} -all -field Physloc backing vtd -fmt :" 2>&1)
			lu_vtd=$(echo "$ret"|grep "${serial_num}.*C${server_vscsi_id}:"|grep "${lu_udid[$j]}"|awk -F":" '{print $3}')
			lu_unmapping=$(ssh ${ivm_user}@${ivm_ip} "ioscli rmbdsp -vtd ${lu_vtd}" 2> /dev/null)
		fi
		if [ "${storage_type[$j]}" == "PV" ]
		then
			ssh ${ivm_user}@${ivm_ip} "ioscli rmvdev -vdev ${pv_name[$j]}" > /dev/null 2>&1
		fi
		j=$(expr $j + 1)
	done
	throwException "$disk_map_info" "105015"
fi
disk_map_info=$(echo "$disk_map_info" | grep -v ^$)
log_debug $LINENO "disk_map_info=${disk_map_info}"

len=0
echo "$disk_map_info" | awk -F":" '{for(i=2;i<=NF;i++) {if(i%2==0) printf $i","; else print $i}}' | while read param
do
	lun[$len]=$(echo $param | awk -F"," '{print $1}')
	#lun[$len]=$(echo ${lun[$len]#*x} | awk '{num=$0; i=length($0); while(substr(num,i,1)==0) { num=substr(num,0,i-1); i--; } print num}')
	if [ $(uname -s) == "AIX" ]
	then
		lun[$len]=$(echo ${lun[$len]} | awk '{num=$0; i=length($0); while(substr(num,i,1)==0) { num=substr(num,0,i-1);i--; } printf "%d",num}')
	fi
	if [ $(uname -s) == "Linux" ]
	then
		lun[$len]=$(echo ${lun[$len]} | awk --posix '{num=$0; i=length($0); while(substr(num,i,1)==0) { num=substr(num,0,i-1);i--; } printf "%d",num}')
	fi
	disk_[$len]=$(echo $param | awk -F"," '{print $2}')
	len=$(expr $len + 1)
done

i=0
while [ $i -lt $len ]
do
	j=$(expr $i + 1)
	while [ $j -lt $len ]
	do
		if [ "${lun[$i]}" -gt "${lun[$j]}" ]
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

# i=0
# while [ $i -lt $len ]
# do
	# echo "disk_[$i]==${disk_[$i]}"
	# i=$(expr $i + 1)
# done



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
	*) echo "unknown";;
esac

if [ "$log_flag" == "0" ]
then
	rm -f "${error_log}" 2> /dev/null
	rm -f "$out_log" 2> /dev/null
fi

# echo "1|100|SUCCESS"
######################  new add end:$1 mount lv/pv ######################

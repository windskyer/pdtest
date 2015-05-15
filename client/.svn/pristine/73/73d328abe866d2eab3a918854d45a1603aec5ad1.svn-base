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
			echo "0|0|ERROR-${error_code}: "$(echo "$result" | awk -F']' '{print $2}')
		else
			echo "0|0|ERROR-${error_code}: $result"
		fi
		
		unmount_nfs
		if [ "$log_flag" == "0" ]
		then
			rm -f "${error_log}" 2> /dev/null
			rm -f "$out_log" 2> /dev/null
		fi

		exit 1
	fi

}


mkvoptCheck() {
	#####################################################################################
	#####                                                                           #####
	#####                              check dd cp                                  #####
	#####                                                                           #####
	#####################################################################################
	cp_size=0
	progress=31
	i=1
	while [ ${cp_size} -lt ${iso_size} ]
	do
		sleep 10
		ps_rlt=$(ssh ${ivm_user}@${ivm_ip} "ps -ef | grep mkvopt | grep ${new_template_name} | grep -v grep")
		if [ "${ps_rlt}" == "" ]
		then
			catchException "${error_log}"
			if [ "$(echo "$error_result" | grep -v "already exists" | grep -v ^$)" != "" ]
			then
				ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
				j=0
				while [ $j -lt $length ]
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
				throwException "$error_result" "105014"
			fi
			break
		fi
		cp_size=$(ssh ${ivm_user}@${ivm_ip} "ls -l ${cdrom_path}/${new_template_name}"  | awk '{print $5}' 2>&1)
		if [ $? -ne 0 ]
		then
			ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
			j=0
			while [ $j -lt $length ]
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
			throwException "$cp_size" "105014"
		fi
		if [ "$(echo ${cp_size}" "$(echo ${iso_size} | awk '{printf "%0.2f",$1/5*i}' i="$i") | awk '{if($1>=$2) print 0}')" = "0" ]
		then
			progress=$(expr $progress + 10)
			echo "1|${progress}|SUCCESS"
			i=$(expr $i + 1)
		fi
	done
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
                                lpar_name=$param;;
                        3)
                                j=4;
                                proc_mode=$param;;
                        4)
                                j=5;
                                min_proc_units=$param;;
                        5)
                                j=6;
                                desired_proc_units=$param;;
                        6)
                                j=7;
                                max_proc_units=$param;;
                        7)
                                j=8;
                                min_procs=$param;;
                        8)
                                j=9;
                                desired_procs=$param;;
                        9)
                                j=10;
                                max_procs=$param;;
                        10)
                                j=11;
                                min_mem=$param;;
                        11)
                                j=12;
                                desired_mem=$param;;
                        12)
                                j=13;
                                max_mem=$param;;
                        13)
								j=14;
                                sharing_mode=$param;;
                        14)
                                j=15;
                                template_path=$param;;
                        15)
                                j=16;
                                template_dir=$param;;
						16)
                                j=17;
                                auto_start=$param;;
        esac
done

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

vlan_len=0
echo $3 |awk -F"|" '{for(i=1;i<=NF;i++) print $i}' | while read param
do
	if [ "$param" != "" ]
	then
		vlan_id[$vlan_len]=$param
		vlan_len=$(expr $vlan_len + 1)
	fi
done

j=0
for nfs_info in $(echo $4 |awk -F"|" '{for(i=1;i<=NF;i++) print $i}')
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

log_flag=$(cat scrpits.properties 2> /dev/null | grep "LOG=" | awk -F"=" '{print $2}')
if [ "$log_flag" == "" ]
then
	log_flag=0
fi

DateNow=$(date +%Y%m%d%H%M%S)
random=$(perl -e 'my $random = int(rand(9999)); print "$random";')
out_log="${path_log}/out_ivm_create_vm_iso_v2.0_${lpar_name}_${DateNow}_${random}.log"
error_log="${path_log}/error_ivm_create_vm_iso_v2.0_${lpar_name}_${DateNow}_${random}.log"
cdrom_path="/var/vio/VMLibrary"

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

#####################################################################################
#####                                                                           #####
#####                              check iso                                    #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "check template"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"cat ${template_path}/${template_dir}/${template_dir}.cfg\""
cat_result=$(ssh ${ivm_user}@${ivm_ip} "cat ${template_path}/${template_dir}/${template_dir}.cfg" 2>&1)
if [ $? -ne 0 ]
then
	throwException "The iso file can not be found." "105009"
fi
log_debug $LINENO "cat_result=${cat_result}"

tmp_file=$(echo "$cat_result" | awk -F"=" '{if($1=="files") print $2}' | awk -F"|" '{print $1}')
template_name=${tmp_file##*/}
# template_path=${tmp_file%/*}

template_name_len=$(echo "$template_name" | awk '{print length($0)}')
if [ $template_name_len -gt 37 ]
then
	s=$(expr $template_name_len - 37)
	new_template_name=$(echo "$template_name" | awk '{print substr($0,0,length($0)-s)}' s="$s")
else
	new_template_name=$template_name
fi
echo "1|5|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                              create lv                                    #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "create storage"
i=0
progress=5
while [ $i -lt $length ]
do
	if [ "${storage_type[$i]}" == "LVSIZE" ]
	then
		log_info $LINENO "storage_type is LVSIZE"
		log_info $LINENO "Go to LV..."
		#####################################################################################
		#####                                                                           #####
		#####                              check vg                                     #####
		#####                                                                           #####
		#####################################################################################
		log_info $LINENO "check vg"
		vg_free_size=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsvg ${lv_vg[$i]} -field freepps -fmt :" 2> ${error_log} | head -n 1 | awk '{print substr($2,2,length($2))}')
		log_info $LINENO "vg_free_size=${vg_free_size}"
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
		progress=$(expr $progress + 1)
		echo "1|$progress|SUCCESS"
		
		#####################################################################################
		#####                                                                           #####
		#####                              create lv                                    #####
		#####                                                                           #####
		#####################################################################################
		log_info $LINENO "create lv ${lpar_name}"
		log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli mklv ${lv_vg[$i]} ${lv_size[$i]}M\""
		lv_name[$i]=$(ssh ${ivm_user}@${ivm_ip} "ioscli mklv ${lv_vg[$i]} ${lv_size[$i]}M" 2> ${error_log})
		dd_name[$i]=${lv_name[$i]}
		catchException "${error_log}"
		time=0
		while [ "$(echo ${error_result} | grep "Volume group is locked")" != "" ]
		do
			sleep 1
			lv_name[$i]=$(ssh ${ivm_user}@${ivm_ip} "ioscli mklv ${lv_vg[$i]} ${lv_size[$i]}M" 2> ${error_log})
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
		progress=$(expr $progress + 1)
		echo "1|$progress|SUCCESS"
		# echo "create lv ${dd_name[$i]} ok"
	fi
	
	if [ "${storage_type[$i]}" == "LVNAME" ]
	then
		log_info $LINENO "storage_type is LVNAME"
		#####################################################################################
		#####                                                                           #####
		#####                              check lv                                     #####
		#####                                                                           #####
		#####################################################################################
		log_info $LINENO "check lv"
		vg_lv_list=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsvg -lv ${lv_vg[$i]} -fmt :"| awk -F":" '{print $1}' 2> "${error_log}")
		log_info $LINENO "vg_lv_list=${vg_lv_list}"
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
		throwException "$error_result" "105011"
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
		
		progress=$(expr $progress + 1)
		echo "1|$progress|SUCCESS"
				
	fi
	
	if [ "${storage_type[$i]}" == "PV" ]
	then
		log_info $LINENO "storage_type is PV"
		log_info $LINENO "Go to PV..."
		#####################################################################################
		#####                                                                           #####
		#####                              check pv                                     #####
		#####                                                                           #####
		#####################################################################################
		log_info $LINENO "check pv"
		lspv=$(ssh ${ivm_user}@${ivm_ip} "ioscli lspv -avail -field name -fmt :" 2> ${error_log})
		log_info $LINENO "lspv=${lspv}"
		catchException "${error_log}"
		if [ "$error_result" != "" ]
		then
			# ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
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
			throwException "$error_result" "105067"
		fi
		pv_map=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -all -type disk -field backing -fmt : " 2> ${error_log} | awk -F":" '{for(i=1;i<=NF;i++) print $i}')
		log_info $LINENO "pv_map=${pv_map}"
		catchException "${error_log}"
		if [ "$error_result" != "" ]
		then
			# ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
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
			throwException "$error_result" "105067"
		fi
		if [ "$(echo $pv_map | sed 's/://')" != "" ]
		then
			echo "$pv_map" | awk -F":" '{for(i=1;i<=NF;i++) print $i}' | while read line
			do
				if [ "$line" != "" ]
				then
					lspv=$(echo $lspv | awk '{ for(i=1;i<=NF;i++) { if($i != pv_name) { print $i } } }' pv_name="$line")
				fi
			done
		fi
		
		flag=$(echo "$lspv" | awk '{if($1 == pv_name) print 1}' pv_name="${pv_name[$i]}")
		if [ "$flag" != "1" ]
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
			throwException "The ${lv_name[$j]} has already been used" "105067"
		fi
		dd_name[$i]=${pv_name[$i]}
		# echo "check pv ${dd_name[$i]} ok"
		progress=$(expr $progress + 1)
		echo "1|$progress|SUCCESS"
	fi
	
	if [ "${storage_type[$i]}" == "LUSIZE" ]
	then
		log_info $LINENO "storage_type is LUSIZE"
		#####################################################################################
		#####                                                                           #####
		#####                              check ssp                                    #####
		#####                                                                           #####
		#####################################################################################
		log_info $LINENO "check ssp ${clustername[$i]}"
		ssp_free_size=$(ssh ${ivm_user}@${ivm_ip} "ioscli lssp -clustername ${clustername[$i]} -field pool size free total overcommit lus type id -fmt :" | awk -F":" '{if($1==sp_name) print $3}' sp_name=${spname[$i]} 2> "${error_log}")
		log_info $LINENO "ssp_free_size=${ssp_free_size}"
		catchException "${error_log}"
		if [ "$error_result" != "" ]
		then
			# ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
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
			throwException "$error_result" "105010"
		fi
		
		if [ $ssp_free_size -lt ${lu_size[$i]} ]
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
		progress=$(expr $progress + 1)
		echo "1|$progress|SUCCESS"

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
		else
			log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli mkbdsp -clustername ${clustername[$i]} -sp ${spname[$i]} ${lu_size[$i]} -bd ${lu_name[$i]}\""
			ssp_lu_info=$(ssh ${ivm_user}@${ivm_ip} "ioscli mkbdsp -clustername ${clustername[$i]} -sp ${spname[$i]} ${lu_size[$i]} -bd ${lu_name[$i]}" 2> "${error_log}")
		fi
		log_info $LINENO "ssp_lu_info=${ssp_lu_info}"
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
		log_info $LINENO "mount_info=${mount_info}"
		lu_dev_path=$(echo "$mount_info" | grep "/var/vio/SSP/${clustername[$i]}/*" | awk '{print $1}')
		lu_rdev[$i]="${lu_dev_path}/VOL1/${lu_name[$i]}.${lu_udid[$i]}"
		dd_name[$i]=${lu_rdev[$i]}
		
		progress=$(expr $progress + 1)
		echo "1|$progress|SUCCESS"
	fi
	if [ "${storage_type[$i]}" == "LUNAME" ]
	then
		log_info $LINENO "storage_type is LUNAME"
		#####################################################################################
		#####                                                                           #####
		#####                              check lu                                     #####
		#####                                                                           #####
		#####################################################################################
		log_info $LINENO "check lu ${lu_udid[$i]}"
		ssp_lu_list=$(ssh ${ivm_user}@${ivm_ip} "ioscli lssp -clustername ${clustername[$i]} -sp ${spname[$i]} -bd -field luname luudid -fmt :" 2> "${error_log}")
		log_info $LINENO "ssp_lu_list=${ssp_lu_list}"
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
		log_info $LINENO "mount_info=${mount_info}"
		lu_dev_path=$(echo "$mount_info" | grep "/var/vio/SSP/${clustername[$i]}/*" | awk '{print $1}')
		lu_rdev[$i]="${lu_dev_path}/VOL1/${lu_name[$i]}.${lu_udid[$i]}"
		dd_name[$i]=${lu_rdev[$i]}
		progress=$(expr $progress + 1)
		echo "1|$progress|SUCCESS"
	fi
	
	i=$(expr $i + 1)
done

#####################################################################################
#####                                                                           #####
#####                       get host serial number                              #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "check host serial number"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"lssyscfg -r sys -F serial_num\""
serial_num=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r sys -F serial_num" 2> ${error_log})
log_debug $LINENO "serial_num=${serial_num}"
catchException "${error_log}"
if [ "${error_result}" != "" ]
then
	j=0
	while [ $j -lt $length ]
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
	throwException "$error_result" "105060"
fi
echo "1|25|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                               create vm                                   #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "create vm"
if [ "$proc_mode" != "ded" ]
then
	log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"mksyscfg -r lpar -i name=\"${lpar_name}\",max_virtual_slots=30,lpar_env=aixlinux,auto_start=${auto_start},profile_name=\"${lpar_name}\",max_virtual_slots=20,proc_mode=${proc_mode},min_procs=${min_procs},min_proc_units=${min_proc_units},desired_procs=${desired_procs},desired_proc_units=${desired_proc_units},max_procs=${max_procs},max_proc_units=${max_proc_units},sharing_mode=${sharing_mode},uncap_weight=127,min_mem=${min_mem},desired_mem=${desired_mem},max_mem=${max_mem}\""
	ssh ${ivm_user}@${ivm_ip} "mksyscfg -r lpar -i name=\"${lpar_name}\",max_virtual_slots=30,lpar_env=aixlinux,auto_start=${auto_start},profile_name=\"${lpar_name}\",max_virtual_slots=20,proc_mode=${proc_mode},min_procs=${min_procs},min_proc_units=${min_proc_units},desired_procs=${desired_procs},desired_proc_units=${desired_proc_units},max_procs=${max_procs},max_proc_units=${max_proc_units},sharing_mode=${sharing_mode},uncap_weight=127,min_mem=${min_mem},desired_mem=${desired_mem},max_mem=${max_mem}" 2> ${error_log}
else
	log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"mksyscfg -r lpar -i name=\"${lpar_name}\",max_virtual_slots=30,lpar_env=aixlinux,auto_start=${auto_start},profile_name=\"${lpar_name}\",max_virtual_slots=20,proc_mode=${proc_mode},min_procs=${min_procs},desired_procs=${desired_procs},max_procs=${max_procs},sharing_mode=${sharing_mode},min_mem=${min_mem},desired_mem=${desired_mem},max_mem=${max_mem}\""
	ssh ${ivm_user}@${ivm_ip} "mksyscfg -r lpar -i name=\"${lpar_name}\",max_virtual_slots=30,lpar_env=aixlinux,auto_start=${auto_start},profile_name=\"${lpar_name}\",max_virtual_slots=20,proc_mode=${proc_mode},min_procs=${min_procs},desired_procs=${desired_procs},max_procs=${max_procs},sharing_mode=${sharing_mode},min_mem=${min_mem},desired_mem=${desired_mem},max_mem=${max_mem}" 2> ${error_log}
fi
catchException "${error_log}"
if [ "${error_result}" != "" ]
then
	j=0
	while [ $j -lt $length ]
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
	throwException "$error_result" "105012"
fi
throwException "$error_result" "105012"
echo "1|26|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                             check lpar id                                 #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "check lpar id"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"lssyscfg -r lpar -F lpar_id --filter lpar_names=\"${lpar_name}\"\""
lpar_id=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar -F lpar_id --filter lpar_names=\"${lpar_name}\"" 2> ${error_log})
log_debug $LINENO "lpar_id=${lpar_id}"
catchException "${error_log}"
if [ "${error_result}" != "" ]
then
	ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
	j=0
	while [ $j -lt $length ]
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
	throwException "$error_result" "105061"
fi
echo "1|27|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                       create virtual_eth_adapters                         #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "create virtual_eth_adapters"
i=0
slot=15
while [ $i -lt $vlan_len ]
do
	# echo "slot==$slot"
	if [ "$i" == "0" ]
	then
		log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"chsyscfg -r prof -i virtual_eth_adapters=${slot}/0/${vlan_id[$i]}//0/1,lpar_id=${lpar_id}\""
		ssh ${ivm_user}@${ivm_ip} "chsyscfg -r prof -i virtual_eth_adapters=${slot}/0/${vlan_id[$i]}//0/1,lpar_id=${lpar_id}" 2> ${error_log}
	else
		log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"chsyscfg -r prof -i virtual_eth_adapters+=${slot}/0/${vlan_id[$i]}//0/1,lpar_id=${lpar_id}\""
		ssh ${ivm_user}@${ivm_ip} "chsyscfg -r prof -i virtual_eth_adapters+=${slot}/0/${vlan_id[$i]}//0/1,lpar_id=${lpar_id}" 2> ${error_log}
	fi
	catchException "${error_log}"
	#if Power8 cpu,create veth have "Unhandled firmware error"
	if [ "${error_result}" != "" ] && [ "$(echo "$error_result" | grep "VIOSE03FF0000-0149")" == "" ]
	then
		ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
		j=0
		while [ $j -lt $length ]
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
		throwException "$error_result" "105013"
	fi
	i=$(expr $i + 1)
	slot=$(expr $slot + 1)
done
echo "1|28|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                  get virtual_scsi_adapters server id                      #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "Get virtual_scsi_adapters server id"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"lssyscfg -r prof --filter lpar_ids=${lpar_id} -F virtual_scsi_adapters\" | awk -F'/' '{print \$5}'"
server_vscsi_id=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r prof --filter lpar_ids=${lpar_id} -F virtual_scsi_adapters"  2> ${error_log} | awk -F'/' '{print $5}')
log_debug $LINENO "server_vscsi_id=${server_vscsi_id}"
catchException "${error_log}"
if [ "${error_result}" != "" ]
then
	ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
	j=0
	while [ $j -lt $length ]
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
	throwException "$error_result" "105063"
fi
echo "1|29|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                            get vios' adapter                              #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "get vios' adapter"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli lsmap -all -fmt :\" | grep ${serial_num} | grep "C${server_vscsi_id}:" | awk -F":" '{print \$1}'"
vadapter_vios=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -all -fmt :" 2> ${error_log} | grep ${serial_num} | grep "C${server_vscsi_id}:" | awk -F":" '{print $1}')
log_debug $LINENO "vadapter_vios=${vadapter_vios}"
catchException "${error_log}"
if [ "${error_result}" != "" ]
then
	ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
	j=0
	while [ $j -lt $length ]
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
	throwException "$error_result" "105064"
fi
echo "1|30|SUCCESS"


######################################################################################
######                                                                           #####
######                          check vmlibrary		                             #####
######                                                                           #####
######################################################################################
check_repo

######################################################################################
######                                                                           #####
######                          create virtual cdrom                             #####
######                                                                           #####
######################################################################################
log_info $LINENO "create virtual cdrom"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli mkvdev -fbo -vadapter ${vadapter_vios}\" | awk '{print \$1}'"
vadapter_vcd=$(ssh ${ivm_user}@${ivm_ip} "ioscli mkvdev -fbo -vadapter ${vadapter_vios}" 2> ${error_log} | awk '{print $1}')
log_debug $LINENO "vadapter_vcd=${vadapter_vcd}"
catchException "${error_log}"
if [ "${error_result}" != "" ]
then
	ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
	j=0
	while [ $j -lt $length ]
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
	throwException "$error_result" "105017"
fi
echo "1|31|SUCCESS"

######################################################################################
######                                                                           #####
######                             	 copy iso                                 	 #####
######                                                                           #####
######################################################################################
log_info $LINENO "copy iso"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ls -l ${template_path}/${template_dir}/${template_name}\" | awk '{print \$5}'"
iso_size=$(ssh ${ivm_user}@${ivm_ip} "ls -l ${template_path}/${template_dir}/${template_name}" 2> ${error_log} | awk '{print $5}')
log_debug $LINENO "iso_size=${iso_size}"
catchException "${error_log}"
if [ "$error_result" != "" ]
then
	ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
	j=0
	while [ $j -lt $length ]
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
	throwException "$error_result" "105014"
fi
ls_result=$(ssh ${ivm_user}@${ivm_ip} "ls -l ${cdrom_path}/${new_template_name}" 2> ${error_log})
catchException "${error_log}"
if [ "$error_result" == "" ]
then
	if [ "$(echo $ls_result | awk '{print $5}')" != "$iso_size" ]
	then
		lsvopt=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsvopt -field vtd media -fmt :" 2>&1)
		if [ $? -ne 0 ]
		then
			ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
			j=0
			while [ $j -lt $length ]
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
			throwException "$lsvopt" "105014"
		fi
		iso_vtd=$(echo "$lsvopt" | awk -F":" '{if($2==iso) print $1}' iso="$template_name")
		
		if [ "$iso_vtd" != "" ]
		then
			for vopt_vtd in $iso_vtd
			do
				
				result=$(ssh ${ivm_user}@${ivm_ip} "ioscli unloadopt -release -vtd $vopt_vtd" 2>&1)
				if [ $? -ne 0 ]
				then
					ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
					j=0
					while [ $j -lt $length ]
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
					throwException "$result" "105014"
				fi
			done
		fi
		result=$(ssh ${ivm_user}@${ivm_ip} "ioscli rmvopt -f -name ${template_name}" 2>&1)
		if [ $? -ne 0 ]
		then
			ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
			j=0
			while [ $j -lt $length ]
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
			throwException "$result" "105014"
		fi
		ssh ${ivm_user}@${ivm_ip} "ioscli mkvopt -name ${new_template_name} -file ${template_path}/${template_dir}/${template_name}" 2> $error_log &
		mkvoptCheck
	fi
else
	ssh ${ivm_user}@${ivm_ip} "ioscli mkvopt -name ${new_template_name} -file ${template_path}/${template_dir}/${template_name}" 2> $error_log &
	mkvoptCheck
fi
echo "1|85|SUCCESS"

######################################################################################
######                                                                           #####
######                            change access                             	 #####
######                                                                           #####
######################################################################################
log_info $LINENO "change access"
log_debug $LINENO "CMD:expect ./ssh.exp ${ivm_user} ${ivm_ip} \"oem_setup_env|chmod 444 ${cdrom_path}/${new_template_name}\""
result=$(expect ./ssh.exp ${ivm_user} ${ivm_ip} "oem_setup_env|chmod 444 ${cdrom_path}/${new_template_name}" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	throwException "$result" "105017"
fi
log_debug $LINENO "result=${result}"
echo "1|87|SUCCESS"

######################################################################################
######                                                                           #####
######                                mount iso                                	 #####
######                                                                           #####
######################################################################################
log_info $LINENO "mount iso"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli loadopt -disk ${new_template_name} -vtd ${vadapter_vcd}\""
mount_result=$(ssh ${ivm_user}@${ivm_ip} "ioscli loadopt -disk ${new_template_name} -vtd ${vadapter_vcd}" 2> ${error_log})
log_debug $LINENO "mount_result=${mount_result}"
catchException "${error_log}"
if [ "$error_result" != "" ]
then
	ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
	j=0
	while [ $j -lt $length ]
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
	throwException "$error_result" "105018"
fi
echo "1|89|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                             create mapping                                #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "create mapping"
i=0
while [ $i -lt $length ]
do
	if [ "${storage_type[$i]}" == "LVSIZE" -o "${storage_type[$i]}" == "LVNAME" -o "${storage_type[$i]}" == "PV" ]
	then
		log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli mkvdev -vdev ${dd_name[$i]} -vadapter ${vadapter_vios}\""
		mapping_name=$(ssh ${ivm_user}@${ivm_ip} "ioscli mkvdev -vdev ${dd_name[$i]} -vadapter ${vadapter_vios}" 2> ${error_log})
		log_debug $LINENO "mapping_name=${mapping_name}"
		catchException "${error_log}"
		time=0
		while [ "$(echo ${error_result} | grep "Volume group is locked")" != "" ]||[ "$(echo ${error_result} | grep "ODM lock")" != "" ]
		do
			sleep 1
			mapping_name=$(ssh ${ivm_user}@${ivm_ip} "ioscli mkvdev -vdev ${dd_name[$i]} -vadapter ${vadapter_vios}" 2> ${error_log})
			catchException "${error_log}"
			time=$(expr $time + 1)
			if [ $time -gt 30 ]
			then
				break
			fi
		done
		if [ "${error_result}" != "" ]
		then
			ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
			j=0
			while [ $j -lt $length ]
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
		throwException "$error_result" "105015"
		i=$(expr $i + 1)
	else
		log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli mkbdsp -clustername ${clustername[$i]} -sp ${spname[$i]} -luudid ${lu_udid[$i]} -vadapter ${vadapter_vios}\""
		lu_map_info=$(ssh ${ivm_user}@${ivm_ip} "ioscli mkbdsp -clustername ${clustername[$i]} -sp ${spname[$i]} -luudid ${lu_udid[$i]} -vadapter ${vadapter_vios}" 2> "${error_log}")
		log_debug $LINENO "lu_map_info=${lu_map_info}"
		catchException "${error_log}"
		if [ "${error_result}" != "" ]
		then
			ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
			j=0
			while [ $j -lt $length ]
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
		throwException "$error_result" "105015"
		i=$(expr $i + 1)
	fi
done
echo "1|95|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                          		unmount nfs	                                #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "unmount nfs"
unmount_nfs

if [ "$log_flag" == "0" ]
then
	rm -f "${error_log}" 2> /dev/null
	rm -f "$out_log" 2> /dev/null
fi

echo "1|100|SUCCESS"

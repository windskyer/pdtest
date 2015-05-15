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
			echo "0|0|ERROR-${error_code}: "$(echo "$result" | awk -F']' '{print $2}')
		else
			echo "0|0|ERROR-${error_code}: $result"
		fi
		
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
		ps_rlt=$(${ivm_user}@${ivm_ip} "ps -ef | grep mkvopt | grep ${template_name} | grep -v grep")
		if [ "${ps_rlt}" == "" ]
		then
			catchException "${error_log}"
			if [ "$(echo "$error_result" | grep -v "already exists" | grep -v ^$)" != "" ]
			then
				ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
				j=0
				while [ $j -lt $length ]
				do
					if [ "${lv_vg[$j]}" != "" ]
					then
						ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
					fi
					j=$(expr $j + 1)
				done
				throwException "$error_result" "105014"
			fi
			break
		fi
		cp_size=$(ssh ${ivm_user}@${ivm_ip} "ls -l ${cdrom_path}/${template_name}"  | awk '{print $5}' 2>&1)
		if [ $? -ne 0 ]
		then
			ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
			j=0
			while [ $j -lt $length ]
			do
				if [ "${lv_vg[$j]}" != "" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
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


ddcopyCheck() {
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
		ps_rlt=$(ssh ${ivm_user}@${ivm_ip} "ps -ef | grep cp | grep \"${cdrom_path}/${template_name}\" | grep -v grep" 2> "${error_log}")
		if [ "${ps_rlt}" == "" ]
		then
			dd_rlt=$(ssh ${ivm_user}@${ivm_ip} "cat \"${error_log}\"" 2> ${error_log})
			ssh ${ivm_user}@${ivm_ip} "rm -f \"${error_log}\"" 2> /dev/null
			catchException "${error_log}"
			if [ "$error_result" != "" ]
			then
				ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
				j=0
				while [ $j -lt $length ]
				do
					if [ "${lv_vg[$j]}" != "" ]
					then
						ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
					fi
					j=$(expr $j + 1)
				done
				throwException "$error_result" "105014"
			fi
			
			if [ "${dd_rlt}" != "" ]
			then
				if [ "$error_result" != "" ]
				then
					ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
					j=0
					while [ $j -lt $length ]
					do
						if [ "${lv_vg[$j]}" != "" ]
						then
							ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
						fi
						j=$(expr $j + 1)
					done
					throwException "$dd_rlt" "105014"
				fi
			else
				break
			fi
		fi
		cp_size=$(ssh ${ivm_user}@${ivm_ip} "ls -l ${cdrom_path}/${template_name}" | awk '{print $5}' 2> "${error_log}")
		catchException "${error_log}"
		if [ "${error_result}" != "" ]
		then
			ssh ${ivm_user}@${ivm_ip} "kill $(ps -ef | grep cp | grep \"${cdrom_path}/${template_name}\" | grep -v grep | awk '{print $2}')" > /dev/null 2>&1
			ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
			j=0
			while [ $j -lt $length ]
			do
				if [ "${lv_vg[$j]}" != "" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
				fi
				j=$(expr $j + 1)
			done
			throwException "$error_result" "105014"
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
                                template_name=$param;;
        esac
done

length=0
echo $2 |awk -F"|" '{for(i=1;i<=NF;i++) print $i}' | while read param
do
	num=$(echo $param | awk -F"," '{print NF}')
	if [ "$num" == "2" ]
	then
		lv_vg[$length]=$(echo $param | awk -F"," '{print $1}')
		lv_size[$length]=$(echo $param | awk -F"," '{print $2}')
		length=$(expr $length + 1)
	else
		if [ "$num" == "1" ]
		then
			pv_name[$length]=$param
			length=$(expr $length + 1)
		else
			throwException "Disk name is null." "105005"
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

log_flag=$(cat scrpits.properties 2> /dev/null | grep "LOG=" | awk -F"=" '{print $2}')
if [ "$log_flag" == "" ]
then
	log_flag=0
fi

DateNow=$(date +%Y%m%d%H%M%S)
random=$(perl -e 'my $random = int(rand(9999)); print "$random";')
out_log="out_create_iso_${lpar_name}_${DateNow}_${random}.log"
error_log="error_create_iso_${lpar_name}_${DateNow}_${random}.log"
cdrom_path="/var/vio/VMLibrary"


#####################################################################################
#####                                                                           #####
#####                              check iso                                    #####
#####                                                                           #####
#####################################################################################
echo "$(date) : check template" > $out_log
cat_result=$(ssh ${ivm_user}@${ivm_ip} "cat ${template_path}/${template_name}/${template_name}.cfg" 2> "${error_log}")
catchException "${error_log}"
if [ "$error_result" != "" ]
then
	throwException "The iso file can not be found." "105009"
fi

tmp_file=$(echo "$cat_result" | awk -F"=" '{if($1=="files") print $2}' | awk -F"|" '{print $1}')
template_name=${tmp_file##*/}
template_path=${tmp_file%/*}

template_name_len=$(echo "$template_name" | awk '{print length($0)}')
if [ $template_name_len -gt 37 ]
then
	s=$(expr $template_name_len - 37)
	template_name=$(echo "$template_name" | awk '{print substr($0,0,length($0)-s)}' s="$s")
fi
echo "1|5|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                              create lv                                    #####
#####                                                                           #####
#####################################################################################
echo "$(date) : create lv" >> $out_log
i=0
progress=5
while [ $i -lt $length ]
do
	if [ "${lv_vg[$i]}" != "" ]
	then
		echo "$(date) : Go to LV..." >> "$out_log"
		#####################################################################################
		#####                                                                           #####
		#####                              check vg                                     #####
		#####                                                                           #####
		#####################################################################################
		echo "$(date) : check vg" >> "$out_log"
		vg_free_size=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsvg ${lv_vg[$i]} -field freepps -fmt :" 2> ${error_log} | awk '{print substr($2,2,length($2))}')
		catchException "${error_log}"
		time=0
		while [ "$(echo ${error_result} | grep "Volume group is locked")" != "" ]||[ "$(echo ${error_result} | grep "ODM lock")" != "" ]
		do
			sleep 1
			vg_free_size=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsvg ${lv_vg[$i]} -field freepps -fmt :" 2> ${error_log} | awk '{print substr($2,2,length($2))}')
			catchException "${error_log}"
			time=$(expr $time + 1)
			if [ $time -gt 30 ]
			then
				break
			fi
		done
		if [ "$error_result" != "" ]
		then
			# ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
			j=0
			while [ $j -lt $i ]
			do
				if [ "${lv_vg[$j]}" != "" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
				fi
				j=$(expr $j + 1)
			done
		fi
		throwException "$error_result" "105010"
			
		if [ $vg_free_size -lt ${lv_size[$i]} ]
		then
			# ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
			j=0
			while [ $j -lt $i ]
			do
				if [ "${lv_vg[$j]}" != "" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
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
		echo "$(date) : create lv ${lpar_name}" >> "$out_log"
		lv_name[$i]=$(ssh ${ivm_user}@${ivm_ip} "ioscli mklv ${lv_vg[$i]} ${lv_size[$i]}M" 2> "${error_log}")
		dd_name[$i]=${lv_name[$i]}
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
			# ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
			j=0
			while [ $j -lt $i ]
			do
				if [ "${lv_vg[$j]}" != "" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
				fi
				j=$(expr $j + 1)
			done
		fi
		throwException "$error_result" "105011"
		progress=$(expr $progress + 1)
		echo "1|$progress|SUCCESS"
		# echo "create lv ${dd_name[$i]} ok"
	else
		echo "$(date) : Go to PV..." >> "$out_log"
		#####################################################################################
		#####                                                                           #####
		#####                              check pv                                     #####
		#####                                                                           #####
		#####################################################################################
		echo "$(date) : check pv" >> "$out_log"
		lspv=$(ssh ${ivm_user}@${ivm_ip} "ioscli lspv -avail -field name -fmt :" 2> ${error_log})
		catchException "${error_log}"
		if [ "$error_result" != "" ]
		then
			# ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
			j=0
			while [ $j -lt $i ]
			do
				if [ "${lv_vg[$j]}" != "" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
				fi
				j=$(expr $j + 1)
			done
			throwException "$error_result" "105067"
		fi
		pv_map=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -all -type disk -field backing -fmt : " 2> ${error_log} | awk -F":" '{for(i=1;i<=NF;i++) print $i}')
		catchException "${error_log}"
		if [ "$error_result" != "" ]
		then
			# ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
			j=0
			while [ $j -lt $i ]
			do
				if [ "${lv_vg[$j]}" != "" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
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
				if [ "${lv_vg[$j]}" != "" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
				fi
				j=$(expr $j + 1)
			done
			throwException "The ${lv_name[$j]} has already been used" "105067"
		fi
		dd_name[$i]=${pv_name[$i]}
		# echo "check pv ${dd_name[$i]} ok"
	fi
	i=$(expr $i + 1)
done

#####################################################################################
#####                                                                           #####
#####                       get host serial number                              #####
#####                                                                           #####
#####################################################################################
echo "$(date) : check host serial number" >> $out_log
serial_num=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r sys -F serial_num" 2> "${error_log}")
catchException "${error_log}"
if [ "${error_result}" != "" ]
then
	j=0
	while [ $j -lt $length ]
	do
		if [ "${lv_vg[$j]}" != "" ]
		then
			ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
		fi
		j=$(expr $j + 1)
	done
	throwException "$error_result" "105060"
fi
echo "serial_num=${serial_num}" >> $out_log
echo "1|25|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                               create vm                                   #####
#####                                                                           #####
#####################################################################################
echo "$(date) : create vm" >> $out_log
if [ "$proc_mode" != "ded" ]
then
	ssh ${ivm_user}@${ivm_ip} "mksyscfg -r lpar -i name=\"${lpar_name}\",max_virtual_slots=30,lpar_env=aixlinux,auto_start=0,profile_name=\"${lpar_name}\",max_virtual_slots=20,proc_mode=${proc_mode},min_procs=${min_procs},min_proc_units=${min_proc_units},desired_procs=${desired_procs},desired_proc_units=${desired_proc_units},max_procs=${max_procs},max_proc_units=${max_proc_units},sharing_mode=${sharing_mode},uncap_weight=127,min_mem=${min_mem},desired_mem=${desired_mem},max_mem=${max_mem}" 2> "${error_log}"
else
	ssh ${ivm_user}@${ivm_ip} "mksyscfg -r lpar -i name=\"${lpar_name}\",max_virtual_slots=30,lpar_env=aixlinux,auto_start=0,profile_name=\"${lpar_name}\",max_virtual_slots=20,proc_mode=${proc_mode},min_procs=${min_procs},desired_procs=${desired_procs},max_procs=${max_procs},sharing_mode=${sharing_mode},min_mem=${min_mem},desired_mem=${desired_mem},max_mem=${max_mem}" 2> "${error_log}"
fi
catchException "${error_log}"
if [ "${error_result}" != "" ]
then
	j=0
	while [ $j -lt $length ]
	do
		if [ "${lv_vg[$j]}" != "" ]
		then
			ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
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
echo "$(date) : check lpar id" >> $out_log
lpar_id=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar -F lpar_id --filter lpar_names=\"${lpar_name}\"" 2> "${error_log}")
catchException "${error_log}"
if [ "${error_result}" != "" ]
then
	ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
	j=0
	while [ $j -lt $length ]
	do
		if [ "${lv_vg[$j]}" != "" ]
		then
			ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
		fi
		j=$(expr $j + 1)
	done
	throwException "$error_result" "105061"
fi
echo "$(date) : lpar_id : ${lpar_id}" >> $out_log
echo "1|27|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                       create virtual_eth_adapters                         #####
#####                                                                           #####
#####################################################################################
echo "$(date) : create virtual_eth_adapters" >> $out_log
i=0
slot=15
while [ $i -lt $vlan_len ]
do
	# echo "slot==$slot"
	if [ "$i" == "0" ]
	then
		ssh ${ivm_user}@${ivm_ip} "chsyscfg -r prof -i virtual_eth_adapters=${slot}/0/${vlan_id[$i]}//0/1,lpar_id=${lpar_id}" 2> "${error_log}"
	else
		ssh ${ivm_user}@${ivm_ip} "chsyscfg -r prof -i virtual_eth_adapters+=${slot}/0/${vlan_id[$i]}//0/1,lpar_id=${lpar_id}" 2> "${error_log}"
	fi
	catchException "${error_log}"
	if [ "${error_result}" != "" ]
	then
		ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
		j=0
		while [ $j -lt $length ]
		do
			if [ "${lv_vg[$j]}" != "" ]
			then
				ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
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
echo "$(date) : Get virtual_scsi_adapters server id" >> $out_log
server_vscsi_id=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r prof --filter lpar_ids=${lpar_id} -F virtual_scsi_adapters" | awk -F'/' '{print $5}' 2> "${error_log}")
catchException "${error_log}"
if [ "${error_result}" != "" ]
then
	ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
	j=0
	while [ $j -lt $length ]
	do
		if [ "${lv_vg[$j]}" != "" ]
		then
			ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
		fi
		j=$(expr $j + 1)
	done
	throwException "$error_result" "105063"
fi
echo "server_vscsi_id=${server_vscsi_id}" >> $out_log
echo "1|29|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                            get vios' adapter                              #####
#####                                                                           #####
#####################################################################################
echo "$(date) : get vios' adapter" >> $out_log
vadapter_vios=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -all -fmt :" | grep ${serial_num} | grep "C${server_vscsi_id}:" | awk -F":" '{print $1}' 2> "${error_log}")
catchException "${error_log}"
if [ "${error_result}" != "" ]
then
	ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
	j=0
	while [ $j -lt $length ]
	do
		if [ "${lv_vg[$j]}" != "" ]
		then
			ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
		fi
		j=$(expr $j + 1)
	done
	throwException "$error_result" "105064"
fi
echo "vadapter_vios=${vadapter_vios}" >> $out_log
echo "1|30|SUCCESS"

######################################################################################
######                                                                           #####
######                          create virtual cdrom                             #####
######                                                                           #####
######################################################################################
echo "$(date) : create virtual cdrom" >> $out_log
vadapter_vcd=$(ssh ${ivm_user}@${ivm_ip} "ioscli mkvdev -fbo -vadapter ${vadapter_vios}" 2> "${error_log}" | awk '{print $1}')
catchException "${error_log}"
if [ "${error_result}" != "" ]
then
	ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
	j=0
	while [ $j -lt $length ]
	do
		if [ "${lv_vg[$j]}" != "" ]
		then
			ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
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
echo "$(date) : copy iso" >> $out_log
iso_size=$(ssh ${ivm_user}@${ivm_ip} "ls -l ${template_path}/${template_name}" | awk '{print $5}' 2> "${error_log}")
# echo "iso_size=======$iso_size"
catchException "${error_log}"
if [ "$error_result" != "" ]
then
	ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
	j=0
	while [ $j -lt $length ]
	do
		if [ "${lv_vg[$j]}" != "" ]
		then
			ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
		fi
		j=$(expr $j + 1)
	done
	throwException "$error_result" "105014"
fi
ls_result=$(ssh ${ivm_user}@${ivm_ip} "ls -l ${cdrom_path}/${template_name}" 2> "${error_log}")


# echo "tmp_size=======$(echo $ls_result | awk '{print $5}')"
catchException "${error_log}"
if [ "$error_result" == "" ]
then
	if [ "$(echo $ls_result | awk '{print $5}')" != "$iso_size" ]
	then
		# expect ./ssh.exp ${ivm_user} ${ivm_ip} "oem_setup_env|cp ${template_path}/${template_name} ${cdrom_path} > /dev/null 2> ${error_log} &" >> $out_log 2>&1
		# sleep 10
		lsvopt=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsvopt -field vtd media -fmt :" 2>&1)
		if [ $? -ne 0 ]
		then
			ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
			j=0
			while [ $j -lt $length ]
			do
				if [ "${lv_vg[$j]}" != "" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
				fi
				j=$(expr $j + 1)
			done
			throwException "$lsvopt" "105014"
		fi
		# echo "lsvopt=====$lsvopt"
		iso_vtd=$(echo "$lsvopt" | awk -F":" '{if($2==iso) print $1}' iso="$template_name")
		# echo "iso_vtd=====$iso_vtd"
		if [ "$iso_vtd" != "" ]
		then
			for vopt_vtd in $iso_vtd
			do
				# echo "vopt_vtd==$vopt_vtd"
				result=$(ssh ${ivm_user}@${ivm_ip} "ioscli unloadopt -release -vtd $vopt_vtd" 2>&1)
				if [ $? -ne 0 ]
				then
					ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
					j=0
					while [ $j -lt $length ]
					do
						if [ "${lv_vg[$j]}" != "" ]
						then
							ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
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
				if [ "${lv_vg[$j]}" != "" ]
				then
					ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
				fi
				j=$(expr $j + 1)
			done
			throwException "$result" "105014"
		fi
		ssh ${ivm_user}@${ivm_ip} "ioscli mkvopt -name ${template_name} -file ${template_path}/${template_name} -ro" 2> $error_log &
		# ddcopyCheck
		mkvoptCheck
	fi
else
	# expect ./ssh.exp ${ivm_user} ${ivm_ip} "oem_setup_env|cp ${template_path}/${template_name} ${cdrom_path} > /dev/null 2> ${error_log} &" >> $out_log 2>&1
	# sleep 10
	# ddcopyCheck
	ssh ${ivm_user}@${ivm_ip} "ioscli mkvopt -name ${template_name} -file ${template_path}/${template_name} -ro" 2> $error_log &
	mkvoptCheck
fi

# ls_result=$(ssh ${ivm_user}@${ivm_ip} "ls -l ${cdrom_path}/${template_name}" 2> ${error_log})
# catchException "${error_log}"
# if [ "$error_result" != "" ]
# then
	# ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
	# j=0
	# while [ $j -lt $length ]
	# do
		# if [ "${lv_vg[$j]}" != "" ]
		# then
			# ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
		# fi
		# j=$(expr $j + 1)
	# done
	# throwException "$error_result" "105014"
# fi
# if [ "$(echo $ls_result | awk '{print $1}')" != "-r--r--r--" ]
# then
	# expect ./ssh.exp ${ivm_user} ${ivm_ip} "oem_setup_env|chmod 444 ${cdrom_path}/${template_name}" > /dev/null 2>&1
# fi

echo "1|85|SUCCESS"

######################################################################################
######                                                                           #####
######                                mount iso                                	 #####
######                                                                           #####
######################################################################################
echo "$(date) : mount iso" >> $out_log
mount_result=$(ssh ${ivm_user}@${ivm_ip} "ioscli loadopt -disk ${template_name} -vtd ${vadapter_vcd}" 2> "${error_log}")
catchException "${error_log}"
if [ "$error_result" != "" ]
then
	ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id}"  > /dev/null 2>&1
	j=0
	while [ $j -lt $length ]
	do
		if [ "${lv_vg[$j]}" != "" ]
		then
			ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
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
echo "$(date) : create mapping" >> "$out_log"
i=0
while [ $i -lt $length ]
do
	mapping_name=$(ssh ${ivm_user}@${ivm_ip} "ioscli mkvdev -vdev ${dd_name[$i]} -vadapter ${vadapter_vios}" 2> "${error_log}")
	catchException "${error_log}"
	time=0
	while [ "$(echo ${error_result} | grep "Volume group is locked")" != "" ]||[ "$(echo ${error_result} | grep "ODM lock")" != "" ]
	do
		sleep 1
		mapping_name=$(ssh ${ivm_user}@${ivm_ip} "ioscli mkvdev -vdev ${dd_name[$i]} -vadapter ${vadapter_vios}" 2> "${error_log}")
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
			if [ "${lv_vg[$j]}" != "" ]
			then
				ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name[$j]}" > /dev/null 2>&1
			fi
			j=$(expr $j + 1)
		done
	fi
	throwException "$error_result" "105015"
	i=$(expr $i + 1)
done
echo "1|95|SUCCESS"

if [ "$log_flag" == "0" ]
then
	rm -f "${error_log}" 2> /dev/null
	rm -f "$out_log" 2> /dev/null
fi

echo "1|100|SUCCESS"

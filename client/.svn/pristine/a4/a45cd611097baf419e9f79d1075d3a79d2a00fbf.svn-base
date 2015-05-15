#!/usr/bin/ksh
#paras:    ./hmc_reconfig_add_storage.sh "hmcip|hmcuser|managedsystem|vioid|lparid"  "vg_name1,lv_size1|vg_name2,lv_size2... or pv_name1|pv_name2..."
#example1:./hmc_reconfig_add_storage.sh "172.30.126.19|hscroot|p730-1|lparid"  "rootvg,512|datavg,1024"
#example2./hmc_reconfig_add_storage.sh "172.30.126.19|hscroot|p730-1|lparid" "hdisk8|hdisk13"

. ./hmc_function.sh

aix_getinfo() {
	echo "[\c"
	i=0
	while [ $i -lt $new_lv_num ]
	do
		echo  "{\c"
		echo  "\"vios_id\":\"$vios_id\", \c"
		echo  "\"lv_id\":\"${lv_id[$i]}\", \c"
		echo  "\"lv_name\":\"${lv_name[$i]}\", \c"
		echo  "\"lv_vg\":\"${lv_vg[$i]}\", \c"
		echo  "\"lv_state\":\"${lv_state[$i]}\", \c"
		echo  "\"lv_size\":\"${lv_size[$i]}\"\c"
		echo  "}\c"
		
		i=$(expr $i + 1)
		if [ "$i" != "${new_lv_num}" ]
		then
			echo  ", \c"
		fi
	done
	echo "]"
	
}

linux_getinfo() {
	echo -e "[\c"
	i=0
	while [ $i -lt $new_lv_num ]
	do
		echo -e "{\c"
		echo -e "\"vios_id\":\"$vios_id\", \c"
		echo -e "\"lv_id\":\"${lv_id[$i]}\", \c"
		echo -e "\"lv_name\":\"${lv_name[$i]}\", \c"
		echo -e "\"lv_vg\":\"${lv_vg[$i]}\", \c"
		echo -e "\"lv_state\":\"${lv_state[$i]}\", \c"
		echo -e "\"lv_size\":\"${lv_size[$i]}\"\c"
		echo -e "}\c"
		
		i=$(expr $i + 1)
		if [ "$i" != "${new_lv_num}" ]
		then
			echo -e ", \c"
		fi
	done
	echo -e "]"
}

info_length=0

echo $1 |awk -F"|" '{for(i=1;i<=NF;i++) print $i}' | while read param
do
	case $info_length in
		0)
				info_length=1;
				hmc_ip=$param;;
		1)
				info_length=2;        
				hmc_user=$param;;
		2)
				info_length=3;
				host_id=$param;;
		3)
				info_length=4;
				lpar_id=$param;;
	esac
done

length=0
new_lv_num=0
new_pv_num=0

echo $2 |awk -F"|" '{for(i=1;i<=NF;i++) print $i}' | while read param
do   	
	if [ "$param" != "" ]
	then
		num=$(echo $param | awk -F, '{print NF}')
		if [ "$num" == "2" ]
		then
			new_vg_name[$new_lv_num]=$(echo $param | awk -F"," '{print $1}') 
			new_lv_size[$new_lv_num]=$(echo $param | awk -F"," '{print $2}')
			new_lv_num=$(expr $new_lv_num + 1 )
		else
			if [ "$num" == "1" ]
			then
				new_pv_name[$new_pv_num]=$(echo $param) 
				new_pv_num=$(expr $new_pv_num + 1 )
			fi
		fi
		
	fi
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
	throwException "Host name is null" "105433"
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

#####################################################################################
#####                                                                           #####
#####                             get lpar name                                 #####
#####                                                                           #####
#####################################################################################
lpar_name=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m ${host_id} -r lpar --filter lpar_ids=${lpar_id} -F name" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	throwException "$lpar_name" "105438"
fi

out_log="out_hmc_add_storage_${lpar_name}_${DateNow}_${random}.log"
error_log="error_hmc_add_storage_${lpar_name}_${DateNow}_${random}.log"

#####################################################################################
#####                                                                           #####
#####                   get vm virtual_scsi_adapters info                       #####
#####                                                                           #####
#####################################################################################
echo "$(date) : Get vm virtual_scsi_adapters info" >> $out_log
vm_vscsi_info=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m ${host_id} -r prof --filter lpar_ids=${lpar_id} -F virtual_scsi_adapters:" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	throwException "$vm_vscsi_info" "105436"
fi

if [ "$vm_vscsi_info" == "none" ]
then
	throwException "Virtual scsi adapters of ${lpar_name} is none" "105436"
fi

vscsi_id=$(echo "$vm_vscsi_info" | awk -F'/' '{print $5}')
vios_id=$(echo "$vm_vscsi_info" | awk -F'/' '{print $3}')
vm_vscsi_id=$(echo "$vm_vscsi_info" | awk -F'/' '{print $1}')
echo "vscsi_id=${vscsi_id}" >> ${out_log}
echo "vios_id=${vios_id}" >> ${out_log}
echo "vm_vscsi_id=${vm_vscsi_id}" >> ${out_log}


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
server_vscsi_id=$(echo "$server_vscsi_info" | awk -F"/" '{if(($1==vscsi_id && $3==lpar_id && $4==lpar_name && $5==vm_vscsi_id) || ($1==vscsi_id && $3=="any")) print $1}' vscsi_id="$vscsi_id" lpar_id="${lpar_id}" lpar_name="${lpar_name}" vm_vscsi_id="$vm_vscsi_id")
if [ "$(echo $server_vscsi_id | sed 's/ //g')" == "" ]
then
	throwException "The lpar's profile does not match to the vios' profile." "105440"
fi
echo "server_vscsi_id=${server_vscsi_id}" >> $out_log

#####################################################################################
#####                                                                           #####
#####                            get vios' adapter                              #####
#####                                                                           #####
#####################################################################################
echo "$(date) : get vios' adapter" >> $out_log
vadapter_vios=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"lsmap -all -fmt :\"" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	throwException "$vadapter_vios" "105413"
fi
vadapter_vios=$(echo "$vadapter_vios" | grep "C${server_vscsi_id}:" | awk -F: '{print $1}')
if [ "$vadapter_vios" == "" ]
then
	throwException "Virtual adapter not found in vios." "105413"
fi
echo "vadapter_vios=${vadapter_vios}" >> $out_log
#echo "1|50|SUCCESS"


########Check all lv total size in same vg##########
if [ "${new_lv_num}" != "0" ]
then
	j=0
	for param in $(echo $2 |awk -F"|" '{for(i=1;i<=NF;i++) print $i}' | awk -F"," '{lvsize[$1]+=$2} END{for(key in lvsize)  print key","lvsize[key]}')
	do
		if [ "$param" != "" ]
		then
			total_vg_name[$j]=$(echo $param | awk -F"," '{print $1}') 
			total_lv_size[$j]=$(echo $param | awk -F"," '{print $2}')
			######################################################################################
			######                                                                           #####
			######                            check vg   		  	                         #####
			######                                                                           #####
			######################################################################################
			echo "$(date) : check vg" >> $out_log
			vg_free_size[$j]=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"lsvg ${total_vg_name[$j]} -field freepps -fmt :\"" 2>&1)
			if [ "$(echo $?)" != "0" ]
			then
				time=0
				error_flag=1
				while [ "$(echo ${vg_free_size[$j]} | grep "Volume group is locked")" != "" ]||[ "$(echo ${vg_free_size} | grep "ODM lock")" != "" ]
				do
					sleep 1
					vg_free_size[$j]=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"lsvg ${total_vg_name[$j]} -field freepps -fmt :\"" 2>&1)
					if [ "$(echo $?)" == "0" ]
					then
						error_flag=0
						break
					fi
					time=$(expr $time + 1)
					if [ $time -gt 30 ]
					then
						break
					fi
				done

				if [ "$error_flag" == "1" ]
				then
					throwException "${vg_free_size[$j]}" "105418"
				fi
			fi			
			vg_free_size[$j]=$(echo "${vg_free_size[$j]}" | awk '{print substr($2,2,length($2))}')
			if [ ${vg_free_size[$j]} -lt ${total_lv_size[$j]} ]
			then
				throwException "Storage ${total_vg_name[$j]} is not enough !" "105418"
			fi
		fi
		j=$(expr $j + 1 )
	done
fi
#echo "1|60|SUCCESS"


######################  new add begin:$1 mount lv/pv  ######################
if [ "${new_lv_num}" != "0" ]
then
	# echo "extend lv"
    
    i=0
    while [ $i -lt $new_lv_num ]
    do
		######################################################################################
		######                                                                           #####
		######                                create lv                                  #####
		######                                                                           #####
		######################################################################################
		echo "$(date) : create lv" >> $out_log
		new_lv_name[$i]=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"mklv ${new_vg_name[$i]} ${new_lv_size[$i]}M\"" 2>&1)
		if [ "$(echo $?)" != "0" ]
		then
			time=0
			error_flag=1
			while [ "$(echo ${new_lv_name[$i]} | grep "Volume group is locked")" != "" ]||[ "$(echo ${new_lv_name[$i]} | grep "ODM lock")" != "" ]
			do
				sleep 1
				new_lv_name[$i]=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"mklv ${new_vg_name[$i]} ${new_lv_size[$i]}M\"" 2>&1)
				if [ "$(echo $?)" == "0" ]
				then
					error_flag=0
					break
				fi
				time=$(expr $time + 1)
				if [ $time -gt 30 ]
				then
					break
				fi
			done
		
			if [ "$error_flag" == "1" ]
			then
				j=0
				while [ $j -lt $i ]
				do
					if [ "${new_vg_name[$j]}" != "" ]
					then
						ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmlv -f ${new_lv_name[$j]}\"" > /dev/null 2>&1
					fi
					j=$(expr $j + 1)
				done
				throwException "${new_lv_name[$i]}" "105419"
			fi
		fi
			
		######################################################################################
		######                                                                           #####
		######                                 mount lv                                  #####
		######                                                                           #####
		######################################################################################
		echo "$(date) : mount lv" >> $out_log
		vadapter_vcd=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"mkvdev -vdev ${new_lv_name[$i]} -vadapter ${vadapter_vios}\"" 2>&1)
		if [ "$(echo $?)" != "0" ]
		then
			time=0
			error_flag=1
			while [ "$(echo ${error_result} | grep "Volume group is locked")" != "" ]||[ "$(echo ${error_result} | grep "ODM lock")" != "" ]
			do
				sleep 1
				vadapter_vcd=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"mkvdev -vdev ${new_lv_name[$i]} -vadapter ${vadapter_vios}\"" 2> "${error_log}")
				if [ "$(echo $?)" == "0" ]
				then
					error_flag=0
					break
				fi
				time=$(expr $time + 1)
				if [ $time -gt 30 ]
				then
					break
				fi
			done
			if [ "$error_flag" == "1" ]
			then
				j=0
				while [ $j -lt $i ]
				do
					if [ "${new_vg_name[$j]}" != "" ]
					then
						ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmlv -f ${new_lv_name[$j]}\"" > /dev/null 2>&1
					fi
					j=$(expr $j + 1)
				done
				throwException "${new_lv_name[$i]}" "105422"
			fi
		fi
		
		lslv=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"lslv ${new_lv_name[$i]} -field lvid vgname ppsize pps lvstate -fmt :\"" 2>&1)
		if [ "$(echo $?)" != "0" ]
		then
			j=0
			while [ $j -lt $i ]
			do
				if [ "${new_vg_name[$j]}" != "" ]
				then
					ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmlv -f ${new_lv_name[$j]}\"" > /dev/null 2>&1
				fi
				j=$(expr $j + 1)
			done
			throwException "$lslv" "105451"
		fi
		ppsize=$(echo "${lslv}" | awk -F":" '{print $3}' | awk '{print $1}')
		lv_id[$i]=$(echo "${lslv}" | awk -F":" '{print $1}')
		lv_name[$i]=${new_lv_name[$i]}
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
		i=$(expr $i + 1)
    done
    # echo "1|60|SUCCESS"
	
fi

if [ "$new_pv_num" != "0" ]
then
	#echo "extend pv"
    i=0
    while [ $i -lt $new_pv_num ]
    do
		echo "$(date) : Go to PV..." >> "$out_log"
		#####################################################################################
		#####                                                                           #####
		#####                              check pv                                     #####
		#####                                                                           #####
		#####################################################################################
		echo "$(date) : check pv" >> "$out_log"
		lspv=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"lspv -avail -field name -fmt :\"" 2>&1)
		if [ "$(echo $?)" != "0" ]
		then
			if [ "${new_lv_num}" != "0" ]
			then
				j=0
				while [ $j -lt $new_lv_num ]
				do
					ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmlv -f ${new_lv_name[$j]}\"" > /dev/null 2>&1
					j=$(expr $j + 1)
				done
			fi
			throwException "$lspv" "105420"
		fi
		#echo "lspv=${lspv}"
		
		pv_map=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"lsmap -all -type disk -field backing -fmt :\"" 2>&1)
		if [ "$(echo $?)" != "0" ]
		then
			if [ "${new_lv_num}" != "0" ]
			then
				j=0
				while [ $j -lt $new_lv_num ]
				do
					ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmlv -f ${new_lv_name[$j]}\"" > /dev/null 2>&1
					j=$(expr $j + 1)
				done
			fi
			throwException "$pv_map" "105420"
		fi
		#echo "pv_map=${pv_map}"
		
		pv_map=$(echo "$pv_map" | awk -F":" '{for(i=1;i<=NF;i++) print $i}')
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
		#echo "lspv=${lspv}"
		
		flag=$(echo "$lspv" | awk '{if($1 == pv_name) print 1}' pv_name="${new_pv_name[$i]}")
		if [ "$flag" != "1" ]
		then
			if [ "${new_lv_num}" != "0" ]
			then
				j=0
				while [ $j -lt $new_lv_num ]
				do
					ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmlv -f ${new_lv_name[$j]}\"" > /dev/null 2>&1
					j=$(expr $j + 1)
				done
			fi
			throwException "The ${new_pv_name[$i]} has already been used or not existing" "105420"
		fi
		i=$(expr $i + 1)
	done
	
	#####################################################################################
	#####                                                                           #####
	#####                             create mapping                                #####
	#####                                                                           #####
	#####################################################################################
	echo "$(date) : create mapping" >> "$out_log"
	i=0
	while [ $i -lt $new_pv_num ]
	do
		mapping_name=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"mkvdev -vdev ${new_pv_name[$i]} -vadapter ${vadapter_vios}\"" 2>&1)
		if [ "$(echo $?)" != "0" ]
		then
			if [ "${new_lv_num}" != "0" ]
			then
				j=0
				while [ $j -lt $new_lv_num ]
				do
					ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmlv -f ${new_lv_name[$j]}\"" > /dev/null 2>&1
					j=$(expr $j + 1)
				done
			fi
			j=0
			while [ $j -lt $i ]
			do
				ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m ${host_id} --id ${vios_id} -c \"rmvdev -vdev ${new_pv_name[$j]}\"" > /dev/null 2>&1
				j=$(expr $j + 1)
			done
			throwException "$mapping_name" "105422"
		fi
		i=$(expr $i + 1)
    done
    #echo "1|70|SUCCESS"
fi

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
	rm -f $error_log 2> /dev/null
	rm -f $out_log 2> /dev/null
fi

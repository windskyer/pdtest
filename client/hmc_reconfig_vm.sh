#!/usr/bin/ksh
# ./hmc_reconfig_vm.sh "172.30.125.2|hscroot|p720-2|10|0.2|0.2|0.2|2|2|2|1024|1024|1024|128|"
# ./hmc_reconfig_vm.sh "172.30.125.2|hscroot|p720-1|8|0.2|0.2|0.2|2|2|2|1024|1024|1024|128|"

# ./hmc_reconfig_vm.sh "172.30.125.2|hscroot|p720-2|4|0.1|0.1|0.8|1|1|8|1024|1024|1024|128|" "lv10,12288|lv13,2048"
# ./hmc_reconfig_vm.sh "172.30.125.2|hscroot|p720-1|8|0.2|0.2|0.2|2|2|2|1024|1024|1024|128|" "lv06,10240"

echo "1|25|SUCCESS"

. ./hmc_function.sh

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
				4)
				        info_length=5;
				        rec_min_proc_units=$param;;
				5)
				        info_length=6;
				        rec_desired_proc_units=$param;;
				6)
				        info_length=7;
				        rec_max_proc_units=$param;;
				7)
				        info_length=8;
				        rec_min_proc=$param;;
				8)
				        info_length=9;
				        rec_desired_proc=$param;;
				9)
				        info_length=10;
				        rec_max_proc=$param;;
				10)
				        info_length=11;
				        rec_min_mem=$param;;
				11)
				        info_length=12;
				        rec_desired_mem=$param;;
				12)
				        info_length=13;
				        rec_max_mem=$param;;
				13)
						info_length=14;
						rec_uncap_weight=$param;;
				14)
						info_length=15;
						rec_share_mode=$param;;
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
out_log="out_reconfig_${lpar_id}_${DateNow}_${random}.log"
error_log="error_reconfig_${DateNow}_${random}.log"

case $rec_share_mode in
		0)
				rec_share_mode="share_idle_procs_active";;
		1)
				rec_share_mode="share_idle_procs";;
		2)
				rec_share_mode="share_idle_procs_always";;
		3)
				rec_share_mode="keep_idle_procs";;
		"")
				rec_share_mode="";;
		*)
				throwException "Value for attribute sharing_mode is not valid." "105483";;
esac

prof_name=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m $host_id -r prof --filter lpar_ids=${lpar_id} -F name" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	throwException "$prof_name" "105474"
fi

lpar_name=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m $host_id -r lpar --filter lpar_ids=${lpar_id} -F name" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	throwException "$lpar_name" "105438"
fi
echo "1|45|SUCCESS"

############################  new add begin   #######################
lv_num=0
echo $2 |awk -F"|" '{for(i=1;i<=NF;i++) print $i}' | while read param
do   
	if [ "$param" != "" ]
	then
		lv_name[$lv_num]=$(echo $param | awk -F"," '{print $1}') 
		rec_stosize[$lv_num]=$(echo $param | awk -F"," '{print $2}')
		if [ "${rec_stosize[$lv_num]}" == "" ]
		then
			throwException "Lv size of ${lv_name[$lv_num]} is null." "105484"
		fi
		
		lv_num=$(expr $lv_num + 1 )
	fi 
done

############################  new add end   #######################

reconfig_cpu_mem()
{
    #####################################################################################
    #####                                                                           #####
    #####                            reconfig cpu                                   #####
    #####                                                                           #####
    #####################################################################################
    echo "$(date) : reconfig cpu" > $out_log
    proc_mode=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m $host_id -r prof -F proc_mode --filter lpar_ids=${lpar_id}" 2>&1)
    if [ "$(echo $?)" != "0" ]
    then
    	throwException "$proc_mode" "105485"
    fi
	
	reconfig_cpu_cmd="chsyscfg -m $host_id -r prof -i "
	
	cpu_conf=""
	
	if [ "$rec_min_proc_units" != "" ]
	then
		cpu_conf=${cpu_conf}",min_proc_units=${rec_min_proc_units}"
	fi
	
	if [ "$rec_desired_proc_units" != "" ]
	then
		cpu_conf=${cpu_conf}",desired_proc_units=${rec_desired_proc_units}"
	fi
	
	if [ "$rec_max_proc_units" != "" ]
	then
		cpu_conf=${cpu_conf}",max_proc_units=${rec_max_proc_units}"
	fi
	
	if [ "$rec_min_proc" != "" ]
	then
		cpu_conf=${cpu_conf}",min_procs=${rec_min_proc}"
	fi
	
	if [ "$rec_desired_proc" != "" ]
	then
		cpu_conf=${cpu_conf}",desired_procs=${rec_desired_proc}"
	fi
	
	if [ "$rec_max_proc" != "" ]
	then
		cpu_conf=${cpu_conf}",max_procs=${rec_max_proc}"
	fi
	echo "cpu_conf==$cpu_conf" >> $out_log
	
	if [ "$cpu_conf" != "" ]
	then
		cpu_conf=$(echo $cpu_conf | awk '{print substr($0,2,length($0))}')
		
		reconfig_cpu_cmd=${reconfig_cpu_cmd}${cpu_conf}",lpar_id=${lpar_id},name=${prof_name}"
		
		echo "reconfig_cpu_cmd==$reconfig_cpu_cmd" >> $out_log
		
		ssh_result=$(ssh ${hmc_user}@${hmc_ip} "$reconfig_cpu_cmd" 2>&1)
		if [ "$(echo $?)" != "0" ]
		then
			throwException "$ssh_result" "105485"
		fi
	fi
	

    if [ "$proc_mode" != "ded" ]
    then
    	if [ "$rec_uncap_weight" != "" ]
    	then
    		ssh_result=$(ssh ${hmc_user}@${hmc_ip} "chsyscfg -m $host_id -r prof -i uncap_weight=${rec_uncap_weight},lpar_id=${lpar_id},name=$prof_name" 2>&1)
    		if [ "$(echo $?)" != "0" ]
    		then
    			throwException "$ssh_result" "105485"
    		fi
    	fi
    else
    	if [ "$rec_share_mode" != "" ]
    	then
    		ssh_result=$(ssh ${hmc_user}@${hmc_ip} "chhwres -m $host_id -r proc -o s -a sharing_mode=${rec_share_mode} --id ${lpar_id}" 2>&1)
    		if [ "$(echo $?)" != "0" ]
    		then
    			throwException "$ssh_result" "105485"
    		fi
    	fi
    fi
    
    #####################################################################################
    #####                                                                           #####
    #####                            reconfig mem                                   #####
    #####                                                                           #####
    #####################################################################################
    echo "$(date) : reconfig mem" >> $out_log
	
	reconfig_mem_cmd="chsyscfg -m $host_id -r prof -i "
	
	mem_conf=""
	if [ "$rec_min_mem" != "" ]
	then
		mem_conf=${mem_conf}",min_mem=${rec_min_mem}"
	fi
	if [ "$rec_desired_mem" != "" ]
	then
		mem_conf=${mem_conf}",desired_mem=${rec_desired_mem}"
	fi
	if [ "$rec_max_mem" != "" ]
	then
		mem_conf=${mem_conf}",max_mem=${rec_max_mem}"
	fi
	
	echo "mem_conf==$mem_conf" >> $out_log
	
	if [ "$mem_conf" != "" ]
	then
		mem_conf=$(echo $mem_conf | awk '{print substr($0,2,length($0))}')
		
		reconfig_mem_cmd=${reconfig_mem_cmd}${mem_conf}",lpar_id=${lpar_id},name=${prof_name}"
		
		echo "reconfig_mem_cmd==$reconfig_mem_cmd" >> $out_log
		
		ssh_result=$(ssh ${hmc_user}@${hmc_ip} "$reconfig_mem_cmd" 2>&1)
		if [ "$(echo $?)" != "0" ]
		then
			throwException "$ssh_result" "105486"
		fi
	fi
}

get_serial_number()
{
    	#####################################################################################
    	#####                                                                           #####
    	#####                       get host serial number                              #####
    	#####                                                                           #####
    	#####################################################################################
    	echo "$(date) : check host serial number" >> $out_log
    	serial_num=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m $host_id -r sys -F serial_num" 2>&1)
		if [ "$(echo $?)" != "0" ]
		then
			throwException "$serial_num" "105406"
		fi
    	echo "serial_num=${serial_num}" >> $out_log
}

get_virtual_scsi_adapters_server_id()
{		
		#####################################################################################
		#####                                                                           #####
		#####                  get lpar virtual_scsi_adapters info                      #####
		#####                                                                           #####
		#####################################################################################
		echo "$(date) : Get lpar virtual_scsi_adapters info" >> $out_log
		vm_vscsi_info=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m $host_id -r prof --filter lpar_ids=${lpar_id} -F virtual_scsi_adapters" 2>&1)
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
#		echo $server_vscsi_info
		vscsi_id=$(echo "$server_vscsi_info" | awk -F"/" '{if(($1==vscsi_id && $3==lpar_id && $4==lpar_name && $5==vm_vscsi_id) || ($1==vscsi_id && $3=="any")) print $1}' vscsi_id="$vscsi_id" lpar_id="${lpar_id}" lpar_name="${lpar_name}" vm_vscsi_id="$vm_vscsi_id")
		if [ "$vscsi_id" == "" ]
		then
			throwException "The lpar's profile does not match to the vios' profile." "105440"
		fi

}

get_lv_name()
{
    	#####################################################################################
    	#####                                                                           #####
    	#####                              get lv names of lpar                         #####
    	#####                                                                           #####
    	#####################################################################################
    	lv_info=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id ${vios_id} -c \"lsmap -all -type lv -field physloc backing -fmt :\"" 2>&1)
		if [ "$(echo $?)" != "0" ]
		then
			throwException "$lv_info" "105441"
		fi
    	lv_names=$(echo "$lv_info" | grep "C${vscsi_id}:" | awk -F":" '{for(i=2;i<=NF;i++) print $i}')
    	echo "lv_names=${lv_names}" >> $out_log
    	
    	#####################################################################################
    	#####                                                                           #####
    	#####                    judge reconfig lv is in  lpar                          #####
    	#####                                                                           #####
    	#####################################################################################
    	i=0
		while [ $i -lt $lv_num ]
		do
			lv_in_test=$(echo "$lv_names" | grep -x "${lv_name[$i]}")
			if [ "$lv_in_test" == "" ]
			then
				throwException "reconfig lv name is not in partition backing device" "105487"
			fi
			i=$(expr $i + 1)
		done
}

get_lv_ppsize()
{
   i=0
   while [ $i -lt $lv_num ]
   do
    	#####################################################################################
    	#####                                                                           #####
    	#####                     get lv ppsize  and vg_name                            #####
    	#####                                                                           #####
    	#####################################################################################
    	lv_size_info[$i]=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id ${vios_id} -c \"lslv ${lv_name[$i]} -field ppsize pps -fmt :\"" 2>&1) 
    	if [ "$(echo $?)" != "0" ]
    	then
    		throwException "${lv_size_info[$i]}" "105441"
    	fi
    	lv_ppsize[$i]=$(echo "${lv_size_info[$i]}" | awk -F":" '{print $1}' | awk '{print $1}')
    	lv_pps[$i]=$(echo "${lv_size_info[$i]}" | awk -F":" '{print $2}')
    
    #	rec_pps=$(echo ${rec_stosize} ${lv_ppsize} | awk '{printf "%.1f",$1/$2}' | awk -F"." '{if($2>=5) print $1+1}')
		rec_pps[$i]=$(echo ${rec_stosize[$i]} ${lv_ppsize[$i]} | awk '{printf "%.1f",$1/$2}')
    	new_pps[$i]=$(echo ${rec_pps[$i]} ${lv_pps[$i]} | awk '{printf "%d", $1-$2}')
    	
    	echo "rec_stosize[$i]==${rec_stosize[$i]}" >> $out_log
    	echo "lv_ppsize[$i]==${lv_ppsize[$i]}" >> $out_log
    	echo "lv_pps[$i]==${lv_pps[$i]}" >> $out_log
    	echo "rec_pps[$i]==${rec_pps[$i]}" >> $out_log
    	echo "new_pps[$i]==${new_pps[$i]}" >> $out_log
    	
    	vg_name[$i]=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id ${vios_id} -c \"lslv ${lv_name[$i]} -field vgname\"" 2>&1)
		if [ "$(echo $?)" != "0" ]
    	then
    		throwException "${vg_name[$i]}" "105441"
    	fi
		vg_name[$i]=$(echo "${vg_name[$i]}" | awk -F":" '{print $2}'| sed 's/ //g')
#      echo "${lv_name[$i]} is in vg: ${vg_name[$i]}"
      
		i=$(expr $i + 1)
   done 
}

judge_lv_samevg()
{
       lv_info=""
       i=0
       while [ $i -lt $lv_num ]
       do
			    lv_info=${lv_info}"|"${vg_name[$i]}","${new_pps[$i]}
			    i=$(expr $i + 1)    
       done 
       
		   lv_info=$(echo "$lv_info" | awk '{print substr($0,2,length($0))}')
		   # echo "lv_info==$lv_info"
		   lv_info=$(echo "$lv_info" | awk -F"|" '{for(i=1;i<=NF;i++) print $i}' | awk -F"," '{lvsize[$1]+=$2} END {for(key in lvsize) print key","lvsize[key]}')
		   # echo "lv_info==$lv_info"
		   for param in $lv_info
		   do
		   	vg_name=$(echo "$param" | awk -F"," '{print $1}')
		   	use_pps=$(echo "$param" | awk -F"," '{print $2}')
		   	samevg_freesize=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id ${vios_id} -c \"lsvg $vg_name -field freepps\"" 2>&1)
		   	if [ "$(echo $?)" != "0" ]
		   	then
		   		throwException "${samevg_freesize}" "105488"
		   	fi
		   	samevg_freesize=$(echo "$samevg_freesize" | awk '{print $3}')
		   	# echo "samevg_freesize==$samevg_freesize"
		   	if [ $use_pps -gt $samevg_freesize ]
		   	then
		   		throwException "Total size of lv in ${vg_name} is larger than vg free size." "105418"
		   	fi
		   done

}

expand_lv_size()
{
    	#####################################################################################
    	#####                                                                           #####
    	#####                           expand lv size                                  #####
    	#####                                                                           #####
    	#####################################################################################
		i=0
		while [ $i -lt $lv_num ]
		do
			if [ ${new_pps[$i]} -gt 0 ]
			then
				ssh_result=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id ${vios_id} -c \"extendlv ${lv_name[$i]} ${new_pps[$i]}\"" 2>&1)
				if [ "$(echo $?)" != "0" ]
				then
					throwException "$ssh_result" "105489"
				fi
				
			elif [ ${new_pps[$i]} -lt 0 ]
			then
				throwException "reconfig size is smaller than current size." "105489"
			fi
			i=$(expr $i + 1)
		done
}  
  	
reconfig_storage()
{
    #####################################################################################
    #####                                                                           #####
    #####                            reconfig sto                                   #####
    #####                                                                           #####
    #####################################################################################
    if [ "$rec_stosize" != "" ]
    then
        get_virtual_scsi_adapters_server_id
   	    get_lv_name
        get_lv_ppsize
        judge_lv_samevg
        expand_lv_size
    fi
}

if [ "$2" != "" ]
then
    reconfig_storage
fi
reconfig_cpu_mem

if [ "$log_flag" == "0" ]
then
	rm -f "${error_log}" 2> /dev/null
	rm -f "$out_log" 2> /dev/null
fi
    
echo "1|100|SUCCESS"

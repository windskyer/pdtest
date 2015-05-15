#!/usr/bin/ksh

. ./ivm_function.sh

echo "1|35|SUCCESS"

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
			echo "0|0|ERROR-${error_code}: ${result}"
		fi
		
		if [ "$log_flag" == "0" ]
		then
			rm -f "${error_log}" 2> /dev/null
			rm -f "$out_log" 2> /dev/null
		fi
		exit 1
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
				3)
				        info_length=4;
				        rec_min_proc_units=$param;;
				4)
				        info_length=5;
				        rec_desired_proc_units=$param;;
				5)
				        info_length=6;
				        rec_max_proc_units=$param;;
				6)
				        info_length=7;
				        rec_min_proc=$param;;
				7)
				        info_length=8;
				        rec_desired_proc=$param;;
				8)
				        info_length=9;
				        rec_max_proc=$param;;
				9)
				        info_length=10;
				        rec_min_mem=$param;;
				10)
				        info_length=11;
				        rec_desired_mem=$param;;
				11)
				        info_length=12;
				        rec_max_mem=$param;;
				12)
				        info_length=13;
				        rec_stosize=$param;;
				13)
								info_length=14;
								rec_uncap_weight=$param;;
				14)
								info_length=15;
								rec_share_mode=$param;;
		esac
done

if [ "$ivm_ip" == "" ]
then
	throwException "IP is null" "105050"
fi

if [ "$ivm_user" == "" ]
then
	throwException "User name is null" "105050"
fi

if [ "$lpar_id" == "" ]
then
	throwException "Lpar id is null" "105050"
fi

log_flag=$(cat scrpits.properties 2> /dev/null | grep "LOG=" | awk -F"=" '{print $2}')
if [ "$log_flag" == "" ]
then
	log_flag=0
fi

DateNow=$(date +%Y%m%d%H%M%S)
random=$(perl -e 'my $random = int(rand(9999)); print "$random";')
out_log="${path_log}/out_reconfig_vm_${DateNow}_${random}.log"
error_log="${path_log}/error_reconfig_vm_${DateNow}_${random}.log"

log_debug $LINENO "$0 $*"

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
				throwException "Value for attribute sharing_mode is not valid." "105053";;
esac

#####################################################################################
#####                                                                           #####
#####                            reconfig cpu                                   #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "reconfig cpu"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"lssyscfg -r prof -F proc_mode --filter lpar_ids=${lpar_id}\""
proc_mode=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r prof -F proc_mode --filter lpar_ids=${lpar_id}" 2> ${error_log})
log_debug $LINENO "proc_mode=${proc_mode}"
catchException "${error_log}"
throwException "$error_result" "105050"

if [ "$proc_mode" != "ded" ]
then
	if [ "$rec_uncap_weight" != "" ]
	then
		log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"chsyscfg -r prof -i uncap_weight=${rec_uncap_weight},lpar_id=${lpar_id}\""
		ssh ${ivm_user}@${ivm_ip} "chsyscfg -r prof -i uncap_weight=${rec_uncap_weight},lpar_id=${lpar_id}" 2> ${error_log}
		catchException "${error_log}"
		throwException "$error_result" "105050"
	fi
	if [ "$rec_min_proc_units" != "" ]&&[ "$rec_desired_proc_units" != "" ]&&[ "$rec_max_proc_units" != "" ]&&[ "$rec_min_proc" != "" ]&&[ "$rec_desired_proc" != "" ]&&[ "$rec_max_proc" != "" ]
	then
		log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"chsyscfg -r prof -i min_proc_units=${rec_min_proc_units},desired_proc_units=${rec_desired_proc_units},max_proc_units=${rec_max_proc_units},min_procs=${rec_min_proc},desired_procs=${rec_desired_proc},max_procs=${rec_max_proc},lpar_id=${lpar_id}\""
		ssh ${ivm_user}@${ivm_ip} "chsyscfg -r prof -i min_proc_units=${rec_min_proc_units},desired_proc_units=${rec_desired_proc_units},max_proc_units=${rec_max_proc_units},min_procs=${rec_min_proc},desired_procs=${rec_desired_proc},max_procs=${rec_max_proc},lpar_id=${lpar_id}" 2> ${error_log}
		catchException "${error_log}"
		throwException "$error_result" "105050"
	fi
else
	if [ "$rec_share_mode" != "" ]
	then
		log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"chhwres -r proc -o s -a sharing_mode=${rec_share_mode} --id ${lpar_id}\""
		ssh ${ivm_user}@${ivm_ip} "chhwres -r proc -o s -a sharing_mode=${rec_share_mode} --id ${lpar_id}" 2> ${error_log}
		catchException "${error_log}"
		throwException "$error_result" "105050"
	fi
	if [ "$rec_min_proc" != "" ]&&[ "$rec_desired_proc" != "" ]&&[ "$rec_max_proc" != "" ]
	then
		log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"chsyscfg -r prof -i min_procs=${rec_min_proc},desired_procs=${rec_desired_proc},max_procs=${rec_max_proc},lpar_id=${lpar_id}\""
		ssh ${ivm_user}@${ivm_ip} "chsyscfg -r prof -i min_procs=${rec_min_proc},desired_procs=${rec_desired_proc},max_procs=${rec_max_proc},lpar_id=${lpar_id}" 2> ${error_log}
		catchException "${error_log}"
		throwException "$error_result" "105050"
	fi
fi

#####################################################################################
#####                                                                           #####
#####                            reconfig mem                                   #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "reconfig mem"
if [ "$rec_min_mem" != "" ]&&[ "$rec_desired_mem" != "" ]&&[ "$rec_max_mem" != "" ]
then
	log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"chsyscfg -r prof -i min_mem=${rec_min_mem},desired_mem=${rec_desired_mem},max_mem=${rec_max_mem},lpar_id=${lpar_id}\""
	ssh ${ivm_user}@${ivm_ip} "chsyscfg -r prof -i min_mem=${rec_min_mem},desired_mem=${rec_desired_mem},max_mem=${rec_max_mem},lpar_id=${lpar_id}" 2> ${error_log}
	catchException "${error_log}"
	throwException "$error_result" "105051"
fi


#####################################################################################
#####                                                                           #####
#####                            reconfig sto                                   #####
#####                                                                           #####
#####################################################################################
if [ "$rec_stosize" != "" ]
then

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
	lv_name=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -all -type disk lv -field physloc backing -fmt :" | grep "C${server_vscsi_id}" | awk -F":" '{print $2}' 2> "${error_log}")
	catchException "${error_log}"
	throwException "$error_result" "105065"
	echo "lv_name=${lv_name}" >> $out_log
	#####################################################################################
	#####                                                                           #####
	#####                            get lv ppsize                                  #####
	#####                                                                           #####
	#####################################################################################
	lv_size_info=$(ssh ${ivm_user}@${ivm_ip} "ioscli lslv ${lv_name} -field ppsize pps -fmt :" 2> ${error_log})
	catchException "${error_log}"
	throwException "$error_result" "105066"
	lv_ppsize=$(echo "$lv_size_info" | awk -F":" '{print $1}' | awk '{print $1}')
	lv_pps=$(echo "$lv_size_info" | awk -F":" '{print $2}')

#	rec_pps=$(echo $rec_stosize $lv_ppsize | awk '{printf "%.1f",$1/$2}' | awk -F"." '{if($2>=5) print $1+1}')
  rec_pps=$(echo $rec_stosize $lv_ppsize | awk '{printf "%.1f",$1/$2}')
	new_pps=$(echo $rec_pps $lv_pps | awk '{printf "%d", $1-$2}')
	
	echo "rec_stosize==$rec_stosize" >> $out_log
	echo "lv_ppsize==$lv_ppsize" >> $out_log
	echo "lv_pps==$lv_pps" >> $out_log
	echo "rec_pps==$rec_pps" >> $out_log
	echo "new_pps==$new_pps" >> $out_log
	
	#####################################################################################
	#####                                                                           #####
	#####                           expand lv size                                  #####
	#####                                                                           #####
	#####################################################################################
  if [ $new_pps -gt 0 ]
  then
		ssh ${ivm_user}@${ivm_ip} "ioscli extendlv ${lv_name} ${new_pps}" 2> ${error_log}
		catchException "${error_log}"
		if [ "$(echo $error_result | grep Warning)" == "" ]
		then
			throwException "$error_result" "105052"
		fi
	fi
fi

if [ "$log_flag" == "0" ]
then
	rm -f "${error_log}" 2> /dev/null
	rm -f "$out_log" 2> /dev/null
fi

echo "1|100|SUCCESS"

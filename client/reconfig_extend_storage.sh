#!/usr/bin/ksh
#paras:    ./reconfig_dlpar.sh "ip|user|id|proc_units|proc|mem|weight|share_mode" "lv_name1,rec_stosize1|lv_name2,rec_stosize2..." 

#example1: ./reconfig_extend_storage.sh "172.30.126.13|padmin|4|0.2|2|1024|128|" "lv02,10496"
#example2: ./reconfig_extend_storage.sh "172.30.126.13|padmin|5|0.2|2|1024|128|" "aix1_lv1,2048|aix1_lv2,3072"


#extend lv,pv
#./$0 $1 $2 :abstract rec_stosize from $1,then add it into $2s,$2 is 'lv_name1,rec_stosize1|...' 'vg_name,lv_size|pv_name'


echo "1|15|SUCCESS"

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
				        rec_desired_proc_units=$param;;
				4)
				        info_length=5;
				        rec_desired_proc=$param;;
				5)
				        info_length=7;
				        rec_desired_mem=$param;;
#				6)
#				        info_length=7;;
#				        rec_stosize=$param;;
				7)
								info_length=8;
								rec_uncap_weight=$param;;
				8)
								info_length=9;
								rec_share_mode=$param;;
		esac
done

######################  new add begin  ######################
lv_num=1
echo $2 |awk -F"|" '{for(i=1;i<=NF;i++) print $i}' | while read param
do   
   if [ "$param" != "" ]
   then
       lv_name[$lv_num]=$(echo $param | awk -F"," '{print $1}') 
       rec_stosize[$lv_num]=$(echo $param | awk -F"," '{print $2}')
       lv_num=$(expr $lv_num + 1 )
   fi
   
#   i=1
#   while [ $i -lt $lv_num ]                    #right
#	 do
#	    echo ${lv_name[$i]}
#	    echo ${rec_stosize[$i]}
#	    i=$(expr $i + 1)
#	 done

done



######################  new add end  ######################


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
out_log="out_create_reconfig_${DateNow}_${random}.log"
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
				throwException "Value for attribute sharing_mode is not valid.";;
esac

#####################################################################################
#####                                                                           #####
#####                            reconfig cpu                                   #####
#####                                                                           #####
#####################################################################################
echo "$(date) : reconfig cpu" > $out_log
proc_mode=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r prof -F proc_mode --filter lpar_ids=${lpar_id}" 2> ${error_log})
catchException "${error_log}"
throwException "$error_result" "105050"

if [ "$proc_mode" != "ded" ]
then
	if [ "$rec_uncap_weight" != "" ]
	then
		ssh ${ivm_user}@${ivm_ip} "chhwres -r proc -o s -a uncap_weight=${rec_uncap_weight} --id ${lpar_id}" 2> ${error_log}
		catchException "${error_log}"
		throwException "$error_result" "105050"
	fi
	if [ "$rec_desired_proc_units" != "" ]&&[ "$rec_desired_proc" != "" ]
	then
		ssh ${ivm_user}@${ivm_ip} "chsyscfg -r prof -i desired_proc_units=${rec_desired_proc_units},desired_procs=${rec_desired_proc},lpar_id=${lpar_id}" 2> ${error_log}
		catchException "${error_log}"
		throwException "$error_result" "105050"
	fi
else
	if [ "$rec_share_mode" != "" ]
	then
		ssh ${ivm_user}@${ivm_ip} "chhwres -r proc -o s -a sharing_mode=${rec_share_mode} --id ${lpar_id}" 2> ${error_log}
		catchException "${error_log}"
		throwException "$error_result" "105050"
	fi
	if [ "$rec_desired_proc" != "" ]
	then
		ssh ${ivm_user}@${ivm_ip} "chsyscfg -r prof -i desired_procs=${rec_desired_proc},lpar_id=${lpar_id}" 2> ${error_log}
		catchException "${error_log}"
		throwException "$error_result" "105050"
	fi
fi

#####################################################################################
#####                                                                           #####
#####                            reconfig mem                                   #####
#####                                                                           #####
#####################################################################################
echo "$(date) : reconfig mem" >> $out_log
if [ "$rec_desired_mem" != "" ]
then
	ssh ${ivm_user}@${ivm_ip} "chsyscfg -r prof -i desired_mem=${rec_desired_mem},lpar_id=${lpar_id}" 2> ${error_log}
	catchException "${error_log}"
	throwException "$error_result" "105051"
fi


#####################################################################################
#####                                                                           #####
#####                            reconfig sto                                   #####
#####                                                                           #####
#####################################################################################
	  
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
	  #####                              get lv names                                  #####
	  #####                                                                           #####
	  #####################################################################################
	  lv_names=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -all -type lv -field physloc backing -fmt :" | grep "C${server_vscsi_id}"  2> "${error_log}")
	  catchException "${error_log}"
	  throwException "$error_result" "105065"
	  echo "lv_names=${lv_names}" >> $out_log
	  
i=1
while [ $i -le $lv_num ]
do
#	 echo ${lv_name[$i]}
	 lv_in_test=$(echo $lv_names | grep "${lv_name[$i]}")
	 if [ "$lv_in_test" == "" ]
	 then
	     catchException "${error_log}"
	     throwException "$error_result" "105065"
	 else
	     if [ "${rec_stosize[$i]}" != "" ]
       then
	          #####################################################################################
	          #####                                                                           #####
	          #####                            get lv ppsize                                  #####
	          #####                                                                           #####
	          #####################################################################################
	          lv_size_info[$i]=$(ssh ${ivm_user}@${ivm_ip} "ioscli lslv ${lv_name[$i]} -field ppsize pps -fmt :" 2> ${error_log})
	          catchException "${error_log}"
	          throwException "$error_result" "105066"
	          lv_ppsize[$i]=$(echo "${lv_size_info[$i]}" | awk -F":" '{print $1}' | awk '{print $1}')
	          lv_pps[$i]=$(echo "${lv_size_info[$i]}" | awk -F":" '{print $2}')
            
            rec_pps[$i]=$(echo ${rec_stosize[$i]} ${lv_ppsize[$i]} | awk '{printf "%.1f",$1/$2}')
	          new_pps[$i]=$(echo ${rec_pps[$i]} ${lv_pps[$i]} | awk '{printf "%d", $1-$2}')
	          
	          echo "rec_stosize[$i]==${rec_stosize[$i]}"  >> $out_log
	          echo "lv_ppsize[$i]==${lv_ppsize[$i]}" >> $out_log
	          echo "lv_pps[$i]==${lv_pps[$i]}" >> $out_log
	          echo "rec_pps[$i]==${rec_pps[$i]}" >> $out_log
	          echo "new_pps[$i]==${new_pps[$i]}" >> $out_log
	        
	          #####################################################################################
	          #####                                                                           #####
	          #####                           expand lv size                                  #####
	          #####                                                                           #####
	          #####################################################################################
            if [ ${new_pps[$i]} -gt 0 ]
            then
	          	ssh ${ivm_user}@${ivm_ip} "ioscli extendlv ${lv_name[$i]} ${new_pps[$i]}" 2> ${error_log}
	          	catchException "${error_log}"
	          	if [ "$(echo $error_result | grep Warning)" == "" ]
	          	then
	          		throwException "$error_result" "105052"
	          	fi
	          fi
	        
	        
	     fi
	 fi
	 i=$(expr $i + 1)
done	  
	  

if [ "$log_flag" == "0" ]
then
	rm -f "${error_log}" 2> /dev/null
	rm -f "$out_log" 2> /dev/null
fi

echo "1|40|SUCCESS"



#####################################################################################
#####                                                                           #####
#####                            get vios' adapter                              #####
#####                                                                           #####
#####################################################################################
echo "$(date) : get vios' adapter" >> $out_log
vadapter_vios=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -all" | grep ${serial_num} | grep "C${server_vscsi_id}" | awk '{print $1}' 2> "${error_log}")
catchException "${error_log}"
throwException "$error_result" "105064"
echo "vadapter_vios=${vadapter_vios}" >> $out_log
echo "1|50|SUCCESS"



echo "1|100|SUCCESS"
######################  new add end:$3 mount lv/pv ######################
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

ddcopyCheck() {
	#####################################################################################
	#####                                                                           #####
	#####                              check dd cp                                  #####
	#####                                                                           #####
	#####################################################################################
	cp_size=0
	progress=20
	i=1
	while [ ${cp_size} -lt ${iso_size} ]
	do
			sleep 10
			ps_rlt=$(ssh ${ivm_user}@${ivm_ip} "ps -ef | grep cp | grep \"${cdrom_path}/${template_name}\" | grep -v grep" 2> "${error_log}")
			if [ "${ps_rlt}" == "" ]
			then
				dd_rlt=$(ssh ${ivm_user}@${ivm_ip} "cat \"${error_log}\"" 2> ${error_log})
				catchException "${error_log}"
				throwException "$error_result" "105014"
				ssh ${ivm_user}@${ivm_ip} "rm -f \"${error_log}\"" 2> /dev/null
				if [ "${dd_rlt}" != "" ]
				then
					ssh ${ivm_user}@${ivm_ip} "rm -f ${cdrom_path}/${template_name} && rmsyscfg -r lpar --id ${lpar_id} && ioscli rmlv -f ${lv_name}"  > /dev/null 2>&1
					throwException "$dd_rlt" "105014"
				else
					break
				fi
			fi
			cp_size=$(ssh ${ivm_user}@${ivm_ip} "ls -l ${cdrom_path}/${template_name} | awk '{print $5/1024/1024}'" 2> "${error_log}")
			catchException "${error_log}"
			if [ "${error_result}" != "" ]
			then
				ssh ${ivm_user}@${ivm_ip} "kill $(ps -ef | grep cp | grep \"${cdrom_path}/${template_name}\" | grep -v grep | awk '{print $2}') && rm -f ${cdrom_path}/${template_name} && rmsyscfg -r lpar --id ${lpar_id} && ioscli rmlv -f ${lv_name}" > /dev/null 2>&1
				throwException "$error_result" "105014"
			fi
			if [ "$(echo ${cp_size}" "$(echo ${iso_size} | awk '{printf "%0.2f",$1/5*i}' i="$i") | awk '{if($1>=$2) print 0}')" = "0" ]
		  then
				progress=$(expr $progress + 15)
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
                                vg_name=$param;;
                        4)
                                j=5;
                                lv_size=$param;;
                        5)
                                j=6;
                                proc_mode=$param;;
                        6)
                                j=7;
                                min_proc_units=$param;;
                        7)
                                j=8;
                                desired_proc_units=$param;;
                        8)
                                j=9;
                                max_proc_units=$param;;
                        9)
                                j=10;
                                min_procs=$param;;
                        10)
                                j=11;
                                desired_procs=$param;;
                        11)
                                j=12;
                                max_procs=$param;;
                        12)
                                j=13;
                                min_mem=$param;;
                        13)
                                j=14;
                                desired_mem=$param;;
                        14)
                                j=15;
                                max_mem=$param;;
                        15)
                        				j=16;
                                sharing_mode=$param;;
                        16)
                                j=17;
                                vlan_id=$param;;
                        17)
                                j=18;
                                template_path=$param;;
                        18)
                                j=19;
                                template_name=$param;;
        esac
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

iso_name=${template_name%.*}
iso_suffix=${template_name##*.}
template_name_len=$(echo "$template_name" | awk '{print length($0)}')
iso_name_len=$(echo "$iso_name" | awk '{print length($0)}')
iso_suffix_len=$(echo "$iso_suffix" | awk '{print length($0)}')
if [ $template_name_len -gt 37 ]
then
	s=$(expr $template_name_len - 37)
	iso_name=$(echo "$template_name" | awk '{print substr($0,0,length($0)-s)}' s="$s")
else
	s=$(expr 37 - $template_name_len)
	if [ "$s" == "0" ]
	then
		iso_name=$template_name
	else
		s=$(expr $s - 1)
		if [ $s -ge 4 ]
		then
			random_num=$(perl -e 'my $random = int(rand(9999)); print "$random";')
		else
			i=0
			while [ $i -lt $s ]
			do
				random_str=${random_str}"9"
				i=$(expr $i + 1)
			done
			export random_str=${random_str}
			random_num=$(perl -e 'my $random = int(rand($ENV{"random_str"})); print "$random";')
		fi
		iso_name=${iso_name}"_"${random_num}"."${iso_suffix}
	fi
fi
echo "1|5|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                              check vg                                     #####     
#####                                                                           #####
#####################################################################################
echo "$(date) : check vg" > $out_log
vg_free_size=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsvg ${vg_name} -field freepps -fmt :" 2> "${error_log}" | awk '{print substr($2,2,length($2))}')
catchException "${error_log}"
time=0
while [ "$(echo ${error_result} | grep "Volume group is locked")" != "" ]||[ "$(echo ${error_result} | grep "ODM lock")" != "" ]
do
	sleep 1
	vg_free_size=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsvg ${vg_name} -field freepps -fmt :" 2> "${error_log}" | awk '{print substr($2,2,length($2))}')
	catchException "${error_log}"
	time=$(expr $time + 1)
	if [ $time -gt 30 ]
	then
		break
	fi
done
throwException "$error_result" "105010"

if [ $vg_free_size -lt $lv_size ]
then
	throwException "Storage space is not enough !" "105010"
fi
echo "1|6|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                              create lv                                    #####
#####                                                                           #####
#####################################################################################
echo "$(date) : create lv" >> $out_log
lv_name=$(ssh ${ivm_user}@${ivm_ip} "ioscli mklv ${vg_name} ${lv_size}M" 2> "${error_log}")
catchException "${error_log}"
echo "error_result===$error_result"
time=0
while [ "$(echo ${error_result} | grep "Volume group is locked")" != "" ]||[ "$(echo ${error_result} | grep "ODM lock")" != "" ]
do
	sleep 1
	lv_name=$(ssh ${ivm_user}@${ivm_ip} "ioscli mklv ${vg_name} ${lv_size}M" 2> "${error_log}")
	catchException "${error_log}"
	time=$(expr $time + 1)
	if [ $time -gt 30 ]
	then
		break
	fi
done
throwException "$error_result" "105011"
echo "1|8|SUCCESS"


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
	ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name}" > /dev/null 2>&1
fi
throwException "$error_result" "105060"
echo "serial_num=${serial_num}" >> $out_log
echo "1|9|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                               create vm                                   #####
#####                                                                           #####
#####################################################################################
echo "$(date) : create vm" >> $out_log
if [ "$proc_mode" != "ded" ]
then
	ssh ${ivm_user}@${ivm_ip} "mksyscfg -r lpar -i name=\"${lpar_name}\",lpar_env=aixlinux,auto_start=0,profile_name=\"${lpar_name}\",max_virtual_slots=20,proc_mode=${proc_mode},min_procs=${min_procs},min_proc_units=${min_proc_units},desired_procs=${desired_procs},desired_proc_units=${desired_proc_units},max_procs=${max_procs},max_proc_units=${max_proc_units},sharing_mode=${sharing_mode},uncap_weight=127,min_mem=${min_mem},desired_mem=${desired_mem},max_mem=${max_mem}" 2> "${error_log}"
else
	ssh ${ivm_user}@${ivm_ip} "mksyscfg -r lpar -i name=\"${lpar_name}\",lpar_env=aixlinux,auto_start=0,profile_name=\"${lpar_name}\",max_virtual_slots=20,proc_mode=${proc_mode},min_procs=${min_procs},desired_procs=${desired_procs},max_procs=${max_procs},sharing_mode=${sharing_mode},min_mem=${min_mem},desired_mem=${desired_mem},max_mem=${max_mem}" 2> "${error_log}"
fi
catchException "${error_log}"
if [ "${error_result}" != "" ]
then
	ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lv_name}"  > /dev/null 2>&1
fi
throwException "$error_result" "105012"
echo "1|10|SUCCESS"


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
	ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar -n \"${lpar_name}\" && ioscli rmlv -f ${lv_name}"  > /dev/null 2>&1
fi
throwException "$error_result" "105061"
echo "$(date) : lpar_id : ${lpar_id}" >> $out_log
echo "1|13|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                       create virtual_eth_adapters                         #####
#####                                                                           #####
#####################################################################################
echo "$(date) : create virtual_eth_adapters" >> $out_log
ssh ${ivm_user}@${ivm_ip} "chsyscfg -r prof -i virtual_eth_adapters=19/0/${vlan_id}//0/1,lpar_id=${lpar_id}" 2> "${error_log}"
catchException "${error_log}"
if [ "${error_result}" != "" ]
then
	ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id} && ioscli rmlv -f ${lv_name}"  > /dev/null 2>&1
fi
throwException "$error_result" "105013"
echo "1|14|SUCCESS"


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
	ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id} && ioscli rmlv -f ${lv_name}"  > /dev/null 2>&1
fi
throwException "$error_result" "105063"
echo "server_vscsi_id=${server_vscsi_id}" >> $out_log
echo "1|15|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                            get vios' adapter                              #####
#####                                                                           #####
#####################################################################################
echo "$(date) : get vios' adapter" >> $out_log
vadapter_vios=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -all" | grep ${serial_num} | grep "C${server_vscsi_id}" | awk '{print $1}' 2> "${error_log}")
catchException "${error_log}"
if [ "${error_result}" != "" ]
then
	ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id} && ioscli rmlv -f ${lv_name}"  > /dev/null 2>&1
fi
throwException "$error_result" "105064"
echo "vadapter_vios=${vadapter_vios}" >> $out_log
echo "1|16|SUCCESS"

######################################################################################
#####                                                                            #####
#####                             create mapping                                 #####
#####                                                                            #####
######################################################################################
echo "$(date) : create mapping" >> $out_log
mapping_name=$(ssh ${ivm_user}@${ivm_ip} "ioscli mkvdev -vdev ${lv_name} -vadapter ${vadapter_vios}" 2> "${error_log}")
catchException "${error_log}"
time=0
while [ "$(echo ${error_result} | grep "Volume group is locked")" != "" ]||[ "$(echo ${error_result} | grep "ODM lock")" != "" ]
do
	sleep 1
	mapping_name=$(ssh ${ivm_user}@${ivm_ip} "ioscli mkvdev -vdev ${lv_name} -vadapter ${vadapter_vios}" 2> "${error_log}")
	catchException "${error_log}"
	time=$(expr $time + 1)
	if [ $time -gt 30 ]
	then
		break
	fi
done
if [ "${error_result}" != "" ]
then
	ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id} && ioscli rmlv -f ${lv_name}"  > /dev/null 2>&1
fi
throwException "$error_result" "105015"
echo "1|17|SUCCESS"

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
	ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id} && ioscli rmlv -f ${lv_name}"  > /dev/null 2>&1
fi
throwException "$error_result" "105017"
echo "1|20|SUCCESS"

######################################################################################
######                                                                           #####
######                             	 copy iso                                 	 #####
######                                                                           #####
######################################################################################
echo "$(date) : copy iso" >> $out_log
iso_size=$(ssh ${ivm_user}@${ivm_ip} "ls -l ${template_path}/${template_name} | awk '{print $5/1024/1024}'" 2> "${error_log}")
catchException "${error_log}"
throwException "$error_result" "105014"
ls_result=$(ssh ${ivm_user}@${ivm_ip} "ls -l ${cdrom_path}/${template_name}" 2> "${error_log}")
catchException "${error_log}"
if [ "$error_result" == "" ]
then
	if [ "$(echo $ls_result | awk '{print $5/1024/1024}')" != "$iso_size" ]
	then
		expect ./ssh.exp ${ivm_user} ${ivm_ip} "oem_setup_env|cp ${template_path}/${template_name} ${cdrom_path} > /dev/null 2> \"${error_log}\" &" > /dev/null 2>&1
		ddcopyCheck
	fi
else
	expect ./ssh.exp ${ivm_user} ${ivm_ip} "oem_setup_env|cp ${template_path}/${template_name} ${cdrom_path} > /dev/null 2> \"${error_log}\" &" > /dev/null 2>&1
	ddcopyCheck
fi

ls_result=$(ssh ${ivm_user}@${ivm_ip} "ls -l ${cdrom_path}/${template_name}" 2> \"${error_log}\")
catchException "${error_log}"
throwException "$error_result" "105014"
if [ "$(echo $ls_result | awk '{print $1}')" != "-r--r--r--" ]
then
	expect ./ssh.exp ${ivm_user} ${ivm_ip} "oem_setup_env|chmod 444 ${cdrom_path}/${template_name}" > /dev/null 2>&1
fi

echo "1|85|SUCCESS"

######################################################################################
######                                                                           #####
######                                mount iso                                	 #####
######                                                                           #####
######################################################################################
echo "$(date) : mount iso" >> $out_log
mount_result=$(ssh ${ivm_user}@${ivm_ip} "ioscli loadopt -disk ${template_name} -vtd ${vadapter_vcd}" 2> "${error_log}")
catchException "${error_log}"
if [ "${error_result}" != "" ]
then
	ssh ${ivm_user}@${ivm_ip} "rmsyscfg -r lpar --id ${lpar_id} && ioscli rmlv -f ${lv_name}" > /dev/null 2>&1
fi
throwException "$error_result" "105015"

if [ "$log_flag" == "0" ]
then
	rm -f "${error_log}" 2> /dev/null
	rm -f "$out_log" 2> /dev/null
fi

echo "1|100|SUCCESS"

#!/usr/bin/ksh

#./mount_iso.sh '172.30.126.13|padmin|8|/template|redhat-iso'

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
			echo "0|0|ERROR-${error_code}: "$(echo "$result" | awk -F']' '{print $2}') >&2
		else
			echo "0|0|ERROR-${error_code}: $result"                                    >&2
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
                                lpar_id=$param;;
                        3)
                                j=4;
                                template_path=$param;;
                        4)
                                j=5;
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
out_log="out_mount_iso_${lpar_id}_${DateNow}_${random}.log"
error_log="error_mount_iso_${lpar_id}_${DateNow}_${random}.log"
cdrom_path="/var/vio/VMLibrary"


#####################################################################################
#####                                                                           #####
#####                              check iso                                    #####
#####                                                                           #####
#####################################################################################
echo "$(date) : check template" > $out_log
cat_result=$(ssh ${ivm_user}@${ivm_ip} "cat ${template_path}/${template_name}/${template_name}.cfg" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	throwException "$cat_result" "105009"
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
#####                       get host serial number                              #####
#####                                                                           #####
#####################################################################################
echo "$(date) : check host serial number" >> $out_log
serial_num=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r sys -F serial_num" 2> "${error_log}")
catchException "${error_log}"
throwException "$error_result" "105060"
echo "serial_num=${serial_num}" >> $out_log
echo "1|10|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                             check lpar id                                 #####
#####                                                                           #####
#####################################################################################
#echo "$(date) : check lpar id" >> $out_log
#lpar_id=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar -F lpar_id --filter lpar_ids=\"${lpar_id}\"" 2> "${error_log}")
#catchException "${error_log}"
#throwException "$error_result" "105061"
#echo "$(date) : lpar_id : ${lpar_id}" >> $out_log
#echo "1|15|SUCCESS"


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
echo "1|20|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                            get vios' adapter                              #####
#####                                                                           #####
#####################################################################################
echo "$(date) : get vios' adapter" >> $out_log
vadapter_vios=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -all -fmt :" | grep ${serial_num} | grep "C${server_vscsi_id}:" | awk -F":" '{print $1}' 2> "${error_log}")
catchException "${error_log}"
throwException "$error_result" "105064"
echo "vadapter_vios=${vadapter_vios}" >> $out_log
echo "1|30|SUCCESS"


######################################################################################
######                                                                           #####
######                             	 copy iso                                 	 #####
######                                                                           #####
######################################################################################
echo "$(date) : copy iso" >> $out_log
iso_size=$(ssh ${ivm_user}@${ivm_ip} "ls -l ${template_path}/${template_name} " | awk '{print $5/1024/1024}' 2> "${error_log}")
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

echo "1|50|SUCCESS"


######################################################################################
######                                                                           #####
######                          get virtual cdrom                             	 #####
######                                                                           #####
######################################################################################
vadapter_vcd=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -vadapter ${vadapter_vios} -field vtd "| grep -i vtopt | head -1 | awk '{print $2}' 2> "${error_log}")
catchException "${error_log}"
throwException "$error_result" "105083"

if [ "$vadapter_vcd" == "" ]
then
	vadapter_vcd=$(ssh ${ivm_user}@${ivm_ip} "ioscli mkvdev -fbo -vadapter ${vadapter_vios}" | awk '{print $1}' 2> "${error_log}") 
	catchException "${error_log}"
	throwException "$error_result" "105017"
fi
echo "1|55|SUCCESS"

######################################################################################
######                                                                           #####
######                          check if iso mounted                           	 #####
######                                                                           #####
######################################################################################
mount_isofile=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -vadapter ${vadapter_vios} -type file_opt -field backing -fmt :" 2> "${error_log}")
if [ "${mount_isofile}" != "" ]
then
		if [ ${mount_isofile} == "${cdrom_path}/${template_name}" ]
		then
		     echo "the mounted iso is the same as iso in cdrom." >> $out_log
		     echo "1|100|SUCCESS"
		     exit 0
		else
			ssh ${ivm_user}@${ivm_ip} "ioscli unloadopt -vtd ${vadapter_vcd} -release" 2> "${error_log}"
			catchException "${error_log}"
			throwException "$error_result" "105084"
		fi
fi
echo "1|70|SUCCESS"

######################################################################################
######                                                                           #####
######                                mount iso                                	 #####
######                                                                           #####
######################################################################################
echo "$(date) : mount iso" >> $out_log
mount_result=$(ssh ${ivm_user}@${ivm_ip} "ioscli loadopt -disk ${template_name} -vtd ${vadapter_vcd}" 2> "${error_log}")
catchException "${error_log}"
throwException "$error_result" "105018"

if [ "$log_flag" == "0" ]
then
	rm -f "${error_log}" 2> /dev/null
	rm -f "$out_log" 2> /dev/null
fi

echo "1|100|SUCCESS"

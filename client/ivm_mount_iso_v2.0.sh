#!/usr/bin/ksh

#./mount_iso.sh '172.30.126.13|padmin|8|/template|redhat-iso'

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
			echo "0|0|ERROR-${error_code}: "$(echo "$result" | awk -F']' '{print $2}') >&2
		else
			echo "0|0|ERROR-${error_code}: $result"                                    >&2
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
	progress=40
	i=1
	while [ ${cp_size} -lt ${iso_size} ]
	do
		sleep 5
		ps_rlt=$(ssh ${ivm_user}@${ivm_ip} "ps -ef" | grep mkvopt | grep ${new_iso_name} | grep -v grep 2> /dev/null)
		echo "ps_rlt==$ps_rlt"
		if [ "${ps_rlt}" == "" ]
		then
			catchException "${error_log}"
			if [ "$(echo "$error_result" | grep -v "already exists" | grep -v ^$)" != "" ]
			then
				throwException "$error_result" "105014"
			fi
			break
		fi
		cp_size=$(ssh ${ivm_user}@${ivm_ip} "ls -l ${cdrom_path}/${new_iso_name}" | awk '{print $5}' 2>&1)
		if [ $? -ne 0 ]
		then
			throwException "$cp_size" "105014"
		fi
		if [ "$(echo ${cp_size}" "$(echo ${iso_size} | awk '{printf "%0.2f",$1/5*i}' i="$i") | awk '{if($1>=$2) print 0}')" = "0" ]
		then
			progress=$(expr $progress + 5)
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
			5)
					j=6;
					iso_name=$param;;
        esac
done

j=0
for nfs_info in $(echo $2 |awk -F"|" '{for(i=1;i<=NF;i++) print $i}')
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
out_log="${path_log}/out_ivm_mount_iso_v2.0_${DateNow}_${random}.log"
error_log="${path_log}/error_ivm_mount_iso_v2.0_${DateNow}_${random}.log"
cdrom_path="/var/vio/VMLibrary"

log_debug $LINENO "$0 $*"
# check authorized and repair error authorized
check_authorized ${ivm_ip} ${ivm_user}
#check NFSServer status and restart that had stop NFSServer proc
nfs_server_check ${nfs_ip} ${nfs_name} ${nfs_passwd}


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
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ls ${template_path}/${template_name}/${iso_name}\""
cat_result=$(ssh ${ivm_user}@${ivm_ip} "ls ${template_path}/${template_name}/${iso_name}" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	throwException "$cat_result" "105009"
fi
log_debug $LINENO "cat_result=${cat_result}"
iso_name_len=$(echo "$iso_name" | awk '{print length($0)}')

if [ $iso_name_len -gt 37 ]
then
	s=$(expr $iso_name_len - 37)
	new_iso_name=$(echo "$iso_name" | awk '{print substr($0,0,length($0)-s)}' s="$s")
else
	new_iso_name=$iso_name
fi
# echo $new_iso_name | awk '{print length($0)}'
echo "1|5|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                       get host serial number                              #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "check host serial number"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"lssyscfg -r sys -F serial_num\""
serial_num=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r sys -F serial_num" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	throwException "$serial_num" "105060"
fi
log_debug $LINENO "serial_num=${serial_num}"
echo "1|10|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                  get virtual_scsi_adapters server id                      #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "Get virtual_scsi_adapters server id"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"lssyscfg -r prof --filter lpar_ids=${lpar_id} -F virtual_scsi_adapters\""
server_vscsi_id=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r prof --filter lpar_ids=${lpar_id} -F virtual_scsi_adapters" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	throwException "$server_vscsi_id" "105063"
fi
server_vscsi_id=$(echo "$server_vscsi_id" | awk -F'/' '{print $5}')
log_debug $LINENO "server_vscsi_id=${server_vscsi_id}"
echo "1|20|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                            get vios' adapter                              #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "get vios' adapter"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli lsmap -all -fmt :\" | grep ${serial_num} | grep "C${server_vscsi_id}:" | awk -F":" '{print \$1}'"
vadapter_vios=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -all -fmt :" | grep ${serial_num} | grep "C${server_vscsi_id}:" | awk -F":" '{print $1}' 2> ${error_log})
catchException "${error_log}"
throwException "$error_result" "105064"
log_debug $LINENO "vadapter_vios=${vadapter_vios}"
echo "1|30|SUCCESS"

######################################################################################
######                                                                           #####
######                          check vmlibrary		                             #####
######                                                                           #####
######################################################################################
check_repo

######################################################################################
######                                                                           #####
######                          get virtual cdrom                             	 #####
######                                                                           #####
######################################################################################
log_info $LINENO "get virtual cdrom"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli lsmap -vadapter ${vadapter_vios} -field vtd\""
vadapter_vcd=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -vadapter ${vadapter_vios} -field vtd " 2>&1)
if [ "$(echo $?)" != "0" ]
then
	throwException "$vadapter_vcd" "105083"
fi
vadapter_vcd=$(echo "$vadapter_vcd" | grep -i vtopt | head -1 | awk '{print $2}')
log_debug $LINENO "vadapter_vcd=${vadapter_vcd}"
if [ "$vadapter_vcd" == "" ]
then
	log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli mkvdev -fbo -vadapter ${vadapter_vios}\""
	vadapter_vcd=$(ssh ${ivm_user}@${ivm_ip} "ioscli mkvdev -fbo -vadapter ${vadapter_vios}" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		throwException "$vadapter_vcd" "105017"
	fi
	vadapter_vcd=$(echo "$vadapter_vcd" | awk '{print $1}')
	log_debug $LINENO "vadapter_vcd=${vadapter_vcd}"
fi
echo "1|35|SUCCESS"

######################################################################################
######                                                                           #####
######                          check if iso mounted                           	 #####
######                                                                           #####
######################################################################################
log_info $LINENO "check if iso mounted"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli lsmap -vadapter ${vadapter_vios} -type file_opt -field backing -fmt :\""
mount_isofile=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -vadapter ${vadapter_vios} -type file_opt -field backing -fmt :" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	throwException "$mount_isofile" "105084"
fi
log_debug $LINENO "mount_isofile=${mount_isofile}"

if [ "${mount_isofile}" != "" ]
then
		# if [ "${mount_isofile}" == "${cdrom_path}/${new_iso_name}" ]
		# then
		     # echo "the mounted iso is the same as iso in cdrom." >> $out_log
		     # echo "1|100|SUCCESS"
		     # exit 0
		# else
		result=$(ssh ${ivm_user}@${ivm_ip} "ioscli unloadopt -vtd ${vadapter_vcd} -release" 2>&1)
		if [ "$(echo $?)" != "0" ]
		then
			throwException "$result" "105084"
		fi
		# fi
fi
echo "1|40|SUCCESS"


######################################################################################
######                                                                           #####
######                             	 copy iso                                 	 #####
######                                                                           #####
######################################################################################
log_info $LINENO "copy iso"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ls -l ${template_path}/${template_name}/${iso_name}\""
iso_size=$(ssh ${ivm_user}@${ivm_ip} "ls -l ${template_path}/${template_name}/${iso_name}" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	throwException "$iso_size" "105014"
fi
iso_size=$(echo "$iso_size" | awk '{print $5}')
log_debug $LINENO "iso_size=${iso_size}"

# echo "iso_size==$iso_size"
# ssh ${ivm_user}@${ivm_ip} "ls -l ${cdrom_path}/${new_iso_name}"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ls -l ${cdrom_path}/${new_iso_name}\""
ls_result=$(ssh ${ivm_user}@${ivm_ip} "ls -l ${cdrom_path}/${new_iso_name}" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	echo "1"
	log_debug $LINENO "ls_result=${ls_result}"
	log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli mkvopt -name ${new_iso_name} -file ${template_path}/${template_name}/${iso_name}\""
	ssh ${ivm_user}@${ivm_ip} "ioscli mkvopt -name ${new_iso_name} -file ${template_path}/${template_name}/${iso_name}" 2> $error_log &
	mkvoptCheck
else
	if [ "$(echo $ls_result | awk '{print $5}')" != "$iso_size" ]
	then
		echo "2"
		log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli lsvopt -field vtd media -fmt :\""
		lsvopt=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsvopt -field vtd media -fmt :" 2>&1)
		if [ $? -ne 0 ]
		then
			throwException "$lsvopt" "105014"
		fi
		log_debug $LINENO "lsvopt=${lsvopt}"
		iso_vtd=$(echo "$lsvopt" | awk -F":" '{if($2==iso) print $1}' iso="$new_iso_name")
		log_debug $LINENO "iso_vtd=${iso_vtd}"
		if [ "$iso_vtd" != "" ]
		then
			for vopt_vtd in $iso_vtd
			do
				log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli unloadopt -release -vtd $vopt_vtd\""
				result=$(ssh ${ivm_user}@${ivm_ip} "ioscli unloadopt -release -vtd $vopt_vtd" 2>&1)
				if [ $? -ne 0 ]
				then
					throwException "$result" "105014"
				fi
			done
		fi
		log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli rmvopt -f -name ${new_iso_name}\""
		result=$(ssh ${ivm_user}@${ivm_ip} "ioscli rmvopt -f -name ${new_iso_name}" 2>&1)
		if [ $? -ne 0 ]
		then
			throwException "$result" "105014"
		fi
		log_debug $LINENO "result=${result}"
		log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli mkvopt -name ${new_iso_name} -file ${template_path}/${template_name}/${iso_name}\""
		ssh ${ivm_user}@${ivm_ip} "ioscli mkvopt -name ${new_iso_name} -file ${template_path}/${template_name}/${iso_name}" 2> $error_log &
		mkvoptCheck
	fi
fi

echo "1|70|SUCCESS"

######################################################################################
######                                                                           #####
######                            change access                             	 #####
######                                                                           #####
######################################################################################
log_debug $LINENO "CMD:expect ./ssh.exp ${ivm_user} ${ivm_ip} \"oem_setup_env|chmod 444 ${cdrom_path}/${new_iso_name}\""
result=$(expect ./ssh.exp ${ivm_user} ${ivm_ip} "oem_setup_env|chmod 444 ${cdrom_path}/${new_iso_name}" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	throwException "$result" "105017"
fi
log_debug $LINENO "result=${result}"
echo "1|75|SUCCESS"

######################################################################################
######                                                                           #####
######                                mount iso                                	 #####
######                                                                           #####
######################################################################################
log_info $LINENO "mount iso"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli loadopt -disk ${new_iso_name} -vtd ${vadapter_vcd} -release\""
mount_result=$(ssh ${ivm_user}@${ivm_ip} "ioscli loadopt -disk ${new_iso_name} -vtd ${vadapter_vcd} -release" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	throwException "$mount_result" "105018"
fi
log_debug $LINENO "mount_result=${mount_result}"
echo "1|80|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                          		unmount nfs	                                #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "unmount nfs"
unmount_nfs
echo "1|90|SUCCESS"

if [ "$log_flag" == "0" ]
then
	rm -f "${error_log}" 2> /dev/null
	rm -f "$out_log" 2> /dev/null
fi

echo "1|100|SUCCESS"

#!/usr/bin/ksh
#example1: ./unmount_iso.sh "172.30.126.10|padmin|13|0|0"   ,unmount iso only/no force,
#example2: ./unmount_iso.sh "172.30.126.10|padmin|13|0|1"   ,unmount iso only/force,
#example4: ./unmount_iso.sh "172.30.126.10|padmin|13|1|0"   ,unmount iso/no force, remove optical device
#example4: ./unmount_iso.sh "172.30.126.10|padmin|13|1|1"   ,unmount iso/force, remove optical device

. ./ivm_function.sh

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
                                remove_flag=$param;;
                        4)
                                j=5;
                                unmount_flag=$param;;                                
                        

        esac
done

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
			echo "0|0|ERROR-${error_code}: $result"   >&2
		fi
		
		if [ "$log_flag" == "0" ]
		then
			rm -f "${error_log}" 2> /dev/null
			rm -f "$out_log" 2> /dev/null
		fi

		exit 1
	fi

}

unmount_iso()
{
	######################################################################################
	######                                                                           #####
	######                          unmount iso file                              	 #####
	######                                                                           #####
	######################################################################################
	log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli lsmap -vadapter ${vadapter_vios} -field vtd | grep vtopt \" | awk '{print \$2}'"
	vadapter_vcd=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -vadapter ${vadapter_vios} -field vtd | grep vtopt " | awk '{print $2}' 2> "${error_log}")
	log_debug $LINENO "vadapter_vcd=${vadapter_vcd}"
	catchException "${error_log}"
	throwException "$error_result" "105083"
	if [ "${vadapter_vcd}" != "" ]
	then
	   if [ "${unmount_flag}" == "0" ]
	   then
			log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli unloadopt -vtd ${vadapter_vcd}\""
		   ssh ${ivm_user}@${ivm_ip} "ioscli unloadopt -vtd ${vadapter_vcd}" 2> "${error_log}"
		   catchException "${error_log}"
		   throwException "$error_result" "105084"
		    
		elif [ "${unmount_flag}" == "1" ]
		then
			log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli unloadopt -vtd ${vadapter_vcd} -release\""
			ssh ${ivm_user}@${ivm_ip} "ioscli unloadopt -vtd ${vadapter_vcd} -release" 2> "${error_log}"
			catchException "${error_log}"
			throwException "$error_result" "105084"
		fi
	 
#	else
#		throwException "Virtual optical equipment not found." "105064"
	fi

}

remove_vtopt()
{
	######################################################################################
	######                                                                           #####
	######                          remove optical device                          	 #####
	######                                                                           #####
	######################################################################################
	for vcd in $vadapter_vcd
	do	
		if [ "$vcd" != "" ]
		then
			ssh ${ivm_user}@${ivm_ip} "ioscli rmvdev -vtd ${vcd}" > /dev/null 2> "${error_log}"
			catchException "${error_log}"
			throwException "$error_result" "105085"
		fi
	done

}

log_flag=$(cat scrpits.properties 2> /dev/null | grep "LOG=" | awk -F"=" '{print $2}')
if [ "$log_flag" == "" ]
then
	log_flag=0
fi

DateNow=$(date +%Y%m%d%H%M%S)
random=$(perl -e 'my $random = int(rand(9999)); print "$random";')
out_log="${path_log}/out_unmount_iso_${DateNow}_${random}.log"
error_log="${path_log}/error_unmount_iso_${DateNow}_${random}.log"
cdrom_path="/var/vio/VMLibrary"

log_debug $LINENO "$0 $*"

if [ "$ivm_ip" == "" ]
then
	throwException "ivm_ip is null" "105053"
fi

if [ "$ivm_user" == "" ]
then
	throwException "ivm_user is null" "105053" 
fi

if [ "$lpar_id" == "" ]
then
	throwException "Lpar id is null" "105053"
fi

lpar_check=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar -F lpar_id | grep $lpar_id" 2> "${error_log}")
if [ "$(echo $?)" != "0" ]
then
	throwException "Lpar id is not exist." "105053"
fi

#####################################################################################
#####                                                                           #####
#####                       get host serial number                              #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "check host serial number"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"lssyscfg -r sys -F serial_num\""
serial_num=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r sys -F serial_num" 2> "${error_log}")
catchException "${error_log}"
throwException "$error_result" "105060"
log_debug $LINENO "serial_num=${serial_num}"
#echo "1|10|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                  get virtual_scsi_adapters server id                      #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "Get virtual_scsi_adapters server id"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"lssyscfg -r prof --filter lpar_ids=${lpar_id} -F virtual_scsi_adapters\" | awk -F'/' '{print \$5}'"
server_vscsi_id=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r prof --filter lpar_ids=${lpar_id} -F virtual_scsi_adapters" | awk -F'/' '{print $5}' 2> "${error_log}")
catchException "${error_log}"
throwException "$error_result" "105063"
log_debug $LINENO "server_vscsi_id=${server_vscsi_id}"
#echo "1|20|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                            get vios' adapter                              #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "get vios' adapter"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli lsmap -all -fmt :\" | grep ${serial_num} | grep "C${server_vscsi_id}:" | awk -F":" '{print \$1}'"
vadapter_vios=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -all -fmt :" | grep ${serial_num} | grep "C${server_vscsi_id}:" | awk -F":" '{print $1}' 2> "${error_log}")
catchException "${error_log}"
throwException "$error_result" "105064"
log_debug $LINENO "vadapter_vios=${vadapter_vios}"
#echo "1|30|SUCCESS"

unmount_iso

if [ "$remove_flag" == "1" ]
then
    remove_vtopt
fi

if [ "$log_flag" == "0" ]
then
	rm -f "${error_log}" 2> /dev/null
	rm -f "$out_log" 2> /dev/null
fi

#!/usr/bin/ksh
#./ivm_migrate_active.sh "172.24.23.38|padmin|2|172.24.23.39|padmin"

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
			echo "0|0|ERROR-${error_code}:"$(echo "$result" | awk -F']' '{print $2}')
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

j=0
echo $1 |awk -F"|" '{for(i=1;i<=NF;i++) print $i}' | while read param
do
        case $j in
                        0)
                                j=1;
                                ivm_source_ip=$param;;
                        1)
                                j=2;        
                                ivm_source_user=$param;;
                        2)
                                j=3;
                                lpar_id=$param;;
                        3)
                        				j=4;
                                ivm_target_ip=$param;;
                        4)
                        				j=5;
                                ivm_target_user=$param;;
        esac
done

log_flag=$(cat scrpits.properties 2> /dev/null | grep "LOG=" | awk -F"=" '{print $2}')
if [ "$log_flag" == "" ]
then
	log_flag=0
fi

DateNow=$(date +%Y%m%d%H%M%S)
random=$(perl -e 'my $random = int(rand(9999)); print "$random";')
out_log="${path_log}/out_ivm_migrate_active_${DateNow}_${random}.log"
error_log="${path_log}/error_ivm_migrate_active_${DateNow}_${random}.log"

log_debug $LINENO "$0 $*"

echo "1|10|SUCCESS"

######################################################################################
######                                                                           #####
######                       judge parameter:null or not                         #####
######                                                                           #####
######################################################################################

if [ "$ivm_source_ip" == "" ]
then
	throwException "ivm_source_ip is null" "105005"
fi

if [ "$ivm_source_user" == "" ]
then
	throwException "ivm_source_user name is null" "105005"
fi

if [ "$lpar_id" == "" ]
then
	throwException "Lpar id is null" "105005"
fi

if [ "$ivm_target_ip" == "" ]
then
	throwException "ivm_target_ip is null" "105005"
fi

if [ "$ivm_target_user" == "" ]
then
	throwException "ivm_target_user name is null" "105005"
fi
echo "1|20|SUCCESS"

# check source host authorized and repair error authorized
check_authorized ${ivm_source_ip} ${ivm_source_user}

ssh ${ivm_source_user}@${ivm_source_ip} "lssyscfg -r lpar --filter lpar_ids=$lpar_id" > /dev/null 2> ${error_log}
catchException "${error_log}"
throwException "$error_result" "105005"


######################################################################################
######                                                                           #####
######                              check rmc state                              #####
######                                                                           #####
######################################################################################
log_info $LINENO "check rmc state"
log_debug $LINENO "CMD:ssh ${ivm_source_user}@${ivm_source_ip} \"lssyscfg -r lpar --filter lpar_ids=$lpar_id -F rmc_state\""
rmc_state=$(ssh ${ivm_source_user}@${ivm_source_ip} "lssyscfg -r lpar --filter lpar_ids=$lpar_id -F rmc_state" 2> ${error_log})
if [ "$rmc_state" != "active" -a "$rmc_state" != "inactive" ]
then
   throwException "rmc state or vm status is not ready." "105068"
fi
log_debug $LINENO "rmc_state=${rmc_state}"
echo "1|30|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                       get target host type_model                          #####
#####                                                                           #####
#####################################################################################

# check target host authorized and repair error authorized
check_authorized ${ivm_target_ip} ${ivm_target_user}

log_info $LINENO "check target host type_model"
log_debug $LINENO "CMD:ssh ${ivm_target_user}@${ivm_target_ip} \"lssyscfg -r sys -F type_model\""
type_model=$(ssh ${ivm_target_user}@${ivm_target_ip} "lssyscfg -r sys -F type_model " 2> "${error_log}")
log_debug $LINENO "type_model=${type_model}"
echo "1|40|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                       get target host serial number                       #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "check target host serial number"
log_debug $LINENO "CMD:ssh ${ivm_target_user}@${ivm_target_ip} \"lssyscfg -r sys -F serial_num\""
serial_num=$(ssh ${ivm_target_user}@${ivm_target_ip} "lssyscfg -r sys -F serial_num " 2> "${error_log}")
log_debug $LINENO "serial_num=${serial_num}"
echo "1|60|SUCCESS"


#####################################################################################
#####                                                                           #####
#####                       validate a partition migration                     #####
#####                                                                           #####
#####################################################################################
#rmc_state=$(ssh ${ivm_source_user}@${ivm_source_ip} "lssyscfg -r lpar --filter lpar_ids=$lpar_id -F rmc_state" 2> ${error_log})
#if [ "$rmc_state" == "active" -o "$rmc_state" == "inactive" ]
#then
#    pass
#else
#   throwException "rmc state or vm status is not ready." "105070"
#fi

#####################################################################################
#####                                                                           #####
#####                       start a partition migration                         #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "start a partition migration"
log_debug $LINENO "CMD:ssh ${ivm_source_user}@${ivm_source_ip} \"migrlpar -o m -t ${type_model}*${serial_num} --ip ${ivm_target_ip} -u ${ivm_target_user} --id $lpar_id\""
migr_start=$(ssh ${ivm_source_user}@${ivm_source_ip} "migrlpar -o m -t ${type_model}*${serial_num} --ip ${ivm_target_ip} -u ${ivm_target_user} --id $lpar_id" 2> "${error_log}")
log_debug $LINENO "migr_start=${migr_start}"
catchException "${error_log}"
throwException "$error_result" "105086"

if [ "$migr_validate" == "" ]
then
	echo "1|100|SUCCESS"
	if [ "$log_flag" == "0" ]
	then
		rm -f "${error_log}" 2> /dev/null
		rm -f "$out_log" 2> /dev/null
	fi
	exit 0
else
	catchException "${error_log}"
	throwException "$error_result" "105086"
	if [ "$log_flag" == "0" ]
	then
		rm -f "${error_log}" 2> /dev/null
		rm -f "$out_log" 2> /dev/null
	fi
	exit 0
fi


###########################new add begin###############################
###########################new add begin###############################
#########                   start rsct_rm on target vios          #####
log_info $LINENO "start rsct_rm on target vios"
start_target=$(ssh ${ivm_target_user}@${ivm_target_ip} "oem_setup_env <<eof
startsrc -g rsct_rm
<<eof"  >$out_log 2> "${error_log}")

###########################new add end###############################
###########################new add end###############################



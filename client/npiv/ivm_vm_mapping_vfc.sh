#!/usr/bin/ksh

. ../ivm_function.sh

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
			echo "ERROR-${error_code}:"$(echo "$result" | awk -F']' '{print $2}') >&2
		else
			echo "ERROR-${error_code}: $result" >&2
		fi
		
		if [ "$log_flag" == "0" ]
		then
			rm -f "${error_log}" 2> /dev/null
			rm -f "$out_log" 2> /dev/null
		fi
		exit 1
	fi

}

log_flag=$(cat ../scrpits.properties 2> /dev/null | grep "LOG=" | awk -F"=" '{print $2}')
if [ "$log_flag" == "" ]
then
	log_flag=0
fi

ivm_ip=$1
ivm_user=$2
lpar_id=$3
vfchost=$4
fc_port=$5

if [ "$ivm_ip" == "" ]
then
	throwException "IP is null" "105053"
fi

if [ "$ivm_user" == "" ]
then
	throwException "User name is null" "105053"
fi

if [ "$lpar_id" == "" ]
then
	throwException "Lpar id is null" "105053"
fi

if [ "$vfchost" == "" ]
then
	throwException "vfchost is null" "105053"
fi

if [ "$fc_port" == "" ]
then
	throwException "FC port is null" "105053"
fi

DateNow=$(date +%Y%m%d%H%M%S)
random=$(perl -e 'my $random = int(rand(9999)); print "$random";')
out_log="${path_log}/out_ivm_vm_mapping_vfc_${DateNow}_${random}.log"
error_log="${path_log}/error_ivm_vm_mapping_vfc_${DateNow}_${random}.log"

log_debug $LINENO "$0 $*"

check_authorized ${ivm_ip} ${ivm_user}

lpar_state=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar -F state --filter lpar_ids=$lpar_id")
rmc_state=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar -F rmc_state,dlpar_io_capable --filter lpar_ids=${lpar_id}")

# echo "rmc_state==$rmc_state"

if [ "$lpar_state" != "Not Activated" ]&&[ "$rmc_state" != "active,1" ]
then
	throwException "Lpar does not support dynamic modification, please shutdown first." "105068"
fi

#####################################################################################
#####                                                                           #####
#####                             create NPIV mapping                           #####
#####                                                                           #####
#####################################################################################
log_debug $LINENO "create mapping"
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli vfcmap -vadapter ${vfchost} -fcp ${fc_port}\""
mapping_result=$(ssh ${ivm_user}@${ivm_ip} "ioscli vfcmap -vadapter ${vfchost} -fcp ${fc_port}" 2> ${error_log})
log_debug $LINENO "mapping_result=${mapping_result}"
catchException "${error_log}"
throwException "$error_result" "105018"


if [ "$log_flag" == "0" ]
then
	rm -f "${error_log}" 2> /dev/null
	rm -f "$out_log" 2> /dev/null
fi

#ivm_vm_mapping_vfc.sh 172.24.23.31 padmin 3 vfchost0 fcs4

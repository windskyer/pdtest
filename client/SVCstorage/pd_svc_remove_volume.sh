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

info_length=0
echo $1 | awk -F"|" '{for(i=1;i<=NF;i++) print $i}' | while read param
do
		case $info_length in
				0)
				        info_length=1;
				        svc_ip=$param;;
				1)
				        info_length=2;        
				        svc_user=$param;;
				2)
						info_length=3;
						key_file=$param;;
		esac
done

volume_id=$2


log_flag=$(cat ../scrpits.properties 2> /dev/null | grep "LOG=" | awk -F"=" '{print $2}')
if [ "$log_flag" == "" ]
then
	log_flag=0
fi

if [ "$volume_id" == "" ]
then
	throwException "volume_id is null" "100000"
fi

random=$(perl -e 'my $random = int(rand(9999)); print "$random";')
DateNow=$(date +%Y%m%d%H%M%S)
out_log="${path_log}/out_pd_svc_remove_volume_${DateNow}_${random}.log"
error_log="${path_log}/error_pd_svc_remove_volume_${DateNow}_${random}.log"

log_debug $LINENO "$0 $*"

#####################################################################################
#####                                                                           #####
#####                        SVC remove volume                                  #####
#####                                                                           #####
#####################################################################################
remove_map_info=$(ssh -i ${key_file} ${svc_user}@${svc_ip} "svctask rmvdisk $volume_id" 2> "${error_log}")
log_debug $LINENO "remove_map_info=${remove_map_info}"
catchException "${error_log}"
if [ "$error_result" != "" ]
then
	throwException "$error_result" "100000"
fi
sleep 2


if [ "$log_flag" == "0" ]
then
	rm -f "${error_log}" 2> /dev/null
	rm -f "$out_log" 2> /dev/null
fi

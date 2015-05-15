#!/usr/bin/ksh

. ../ivm_function.sh

aix_getinfo() {
i=0
echo  "[\c"
if [ "$diskgrp_length" != "0" ]
then
	while [ $i -lt $diskgrp_length ]
	do
		echo  "{\c"
		echo  "\"poolid\":\"${poolid[$i]}\", \c"
		echo  "\"poolname\":\"${poolname[$i]}\", \c"
		echo  "\"capactity\":\"${capactity[$i]}\", \c"
		echo  "\"used\":\"${used[$i]}\", \c"
		echo  "\"virtual_capacity\":\"${virtual_capacity[$i]}\", \c"
		echo  "\"virtual_used\":\"${virtual_used[$i]}\", \c"
		echo  "\"volume_copies_number\":\"${volume_copies_number[$i]}\", \c"
		echo  "\"free_capacity\":\"${free_capacity[$i]}\", \c"
		echo  "\"storage_pool_state\":\"${storage_pool_state[$i]}\" \c"
		echo "}\c"
		i=$(expr $i + 1)
		if [ "$i" != "$diskgrp_length" ]
		then
			echo ", \c"
		fi
	done
fi
echo "]"
}

linux_getinfo() {
i=0
echo -e "[\c"
if [ "$diskgrp_length" != "0" ]
then
	while [ $i -lt $diskgrp_length ]
	do
		echo -e "{\c"
		echo -e "\"poolid\":\"${poolid[$i]}\", \c"
		echo -e "\"poolname\":\"${poolname[$i]}\", \c"
		echo -e "\"capactity\":\"${capactity[$i]}\", \c"
		echo -e "\"used\":\"${used[$i]}\", \c"
		echo -e "\"virtual_capacity\":\"${virtual_capacity[$i]}\", \c"
		echo -e "\"virtual_used\":\"${virtual_used[$i]}\", \c"
		echo -e "\"volume_copies_number\":\"${volume_copies_number[$i]}\", \c"
		echo -e "\"free_capacity\":\"${free_capacity[$i]}\", \c"
		echo -e "\"storage_pool_state\":\"${storage_pool_state[$i]}\" \c"
		echo -e "}\c"
		i=$(expr $i + 1)
		if [ "$i" != "$diskgrp_length" ]
		then
			echo -e ", \c"
		fi
	done
fi
echo -e "]"
}


info_length=0
echo $1 |awk -F"|" '{for(i=1;i<=NF;i++) print $i}' | while read param
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

diskgrp_id=$2

log_flag=$(cat ../scrpits.properties 2> /dev/null | grep "LOG=" | awk -F"=" '{print $2}')
if [ "$log_flag" == "" ]
then
	log_flag=0
fi

# if [ "$diskgrp_id" == "" ]
# then
	# throwException "diskgrp_id is null" "100000"
# fi

random=$(perl -e 'my $random = int(rand(9999)); print "$random";')
DateNow=$(date +%Y%m%d%H%M%S)
out_log="${path_log}/out_pd_svc_get_diskgrp_info_${DateNow}_${random}.log"
error_log="${path_log}/error_pd_svc_get_diskgrp_info_${DateNow}_${random}.log"

log_debug $LINENO "$0 $*"

#####################################################################################
#####                                                                           #####
#####                       get diskgrp info                                    #####
#####                                                                           #####
#####################################################################################
if [ "${diskgrp_id}" == "" ]
then
	log_debug $LINENO "CMD:ssh -i ${key_file} ${svc_user}@${svc_ip} \"lsmdiskgrp -nohdr -bytes -delim :\""
	svc_diskgrp_info=$(ssh -i ${key_file} ${svc_user}@${svc_ip} "lsmdiskgrp -nohdr -bytes -delim :")
else
	log_debug $LINENO "CMD:ssh -i ${key_file} ${svc_user}@${svc_ip} \"lsmdiskgrp -nohdr -bytes -delim : -filtervalue id=$diskgrp_id\""
	svc_diskgrp_info=$(ssh -i ${key_file} ${svc_user}@${svc_ip} "lsmdiskgrp -nohdr -bytes -delim : -filtervalue id=$diskgrp_id")
fi
log_debug $LINENO "svc_diskgrp_info=${svc_diskgrp_info}"

diskgrp_length=0
if [ "${svc_diskgrp_info}" != "" ]
then
	echo "$svc_diskgrp_info" | while read diskgrp_info
	do
		if [ "$diskgrp_info" != "" ]
		then
			poolid[${diskgrp_length}]=$(echo "$diskgrp_info" | awk -F":" '{print $1}')
			poolname[${diskgrp_length}]=$(echo "$diskgrp_info" | awk -F":" '{print $2}')
			storage_pool_state[${diskgrp_length}]=$(echo "$diskgrp_info" | awk -F":" '{print $3}')
			free_capacity[${diskgrp_length}]=$(echo "$diskgrp_info" | awk -F":" '{print $8}')
			capactity[${diskgrp_length}]=$(echo "$diskgrp_info" | awk -F":" '{print $6}')
			used[${diskgrp_length}]=$(echo "$diskgrp_info" | awk -F":" '{print $10}')
			virtual_capacity[${diskgrp_length}]=""
			virtual_used[${diskgrp_length}]=$(echo "$diskgrp_info" | awk -F":" '{print $9}')
			volume_copies_number[${diskgrp_length}]=$(echo "$diskgrp_info" | awk -F":" '{print $5}')
			
		fi
	diskgrp_length=$(expr $diskgrp_length + 1)
	done
else
	echo "[]"
	exit 1
fi

case $(uname -s) in
	AIX)
		aix_getinfo;;
	Linux)
		linux_getinfo;;
	*BSD)
		bsd_getinfo;;
	SunOS)
		sun_getinfo;;
	HP-UX)
		hp_getinfo;;
	*) echo "unknown";;
esac

if [ "$log_flag" == "0" ]
then
	rm -f "${error_log}" 2> /dev/null
	rm -f "$out_log" 2> /dev/null
fi

#!/usr/bin/ksh

. ../ivm_function.sh

aix_getinfo() {
i=0
echo "[\c"
if [ "$host_length" != "0" ]
then
	while [ $i -lt $host_length ]
	do
		echo "{\c"
		echo "\"host_id\":\"${host_id[$i]}\", \c"
		echo "\"host_name\":\"${host_name[$i]}\", \c"
		echo "\"host_status\":\"${host_status[$i]}\", \c"
		echo "\"host_type\":\"${host_type[$i]}\", \c"
		echo "\"port_mask\":\"${port_mask[$i]}\", \c"
		wwpn_length=0
		echo ${hostwwpnList[$i]} |awk -F":" '{for(i=1;i<=NF;i++) if ( i%3 != 0) {printf $i":"} else {printf $i"\n"}}'| while read param
		do
			port_name[$wwpn_length]=$(echo "$param"|awk -F":" '{print $1}')
			nodes_logged_in[$wwpn_length]=$(echo "$param"|awk -F":" '{print $2}')
			port_status[$wwpn_length]=$(echo "$param"|awk -F":" '{print $3}')
			port_type[$wwpn_length]=""
			wwpn_length=$(expr $wwpn_length + 1)
		done
		
		echo "\"wwpn\": \c"
		echo "[\c"
		j=0
		while [ $j -lt $wwpn_length ]
		do
			echo "{\c"
			echo "\"port_name\":\"${port_name[$j]}\", \c"
			echo "\"nodes_logged_in\":\"${nodes_logged_in[$j]}\", \c"
			echo "\"port_type\":\"${port_type[$j]}\", \c"
			echo "\"port_status\":\"${port_status[$j]}\" \c"
			
			echo "}\c"
			
			j=$(expr $j + 1)
			if [ "$j" != "$wwpn_length" ]
			then
				echo ", \c"
			fi
		done
		echo "]\c"
		
		echo "}\c"
		i=$(expr $i + 1)
		if [ "$i" != "$host_length" ]
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
if [ "$host_length" != "0" ]
then
	while [ $i -lt $host_length ]
	do
		echo -e "{\c"
		echo -e "\"host_id\":\"${host_id[$i]}\", \c"
		echo -e "\"host_name\":\"${host_name[$i]}\", \c"
		echo -e "\"host_status\":\"${host_status[$i]}\", \c"
		echo -e "\"host_type\":\"${host_type[$i]}\", \c"
		echo -e "\"port_mask\":\"${port_mask[$i]}\", \c"
		wwpn_length=0
		echo ${hostwwpnList[$i]} |awk -F":" '{for(i=1;i<=NF;i++) if ( i%3 != 0) {printf $i":"} else {printf $i"\n"}}'| while read param
		do
			port_name[$wwpn_length]=$(echo "$param"|awk -F":" '{print $1}')
			nodes_logged_in[$wwpn_length]=$(echo "$param"|awk -F":" '{print $2}')
			port_status[$wwpn_length]=$(echo "$param"|awk -F":" '{print $3}')
			port_type[$wwpn_length]=""
			wwpn_length=$(expr $wwpn_length + 1)
		done
		
		echo -e "\"wwpn\": \c"
		echo -e "[\c"
		j=0
		while [ $j -lt $wwpn_length ]
		do
			echo -e "{\c"
			echo -e "\"port_name\":\"${port_name[$j]}\", \c"
			echo -e "\"nodes_logged_in\":\"${nodes_logged_in[$j]}\", \c"
			echo -e "\"port_type\":\"${port_type[$j]}\", \c"
			echo -e "\"port_status\":\"${port_status[$j]}\" \c"
			
			echo -e "}\c"
			
			j=$(expr $j + 1)
			if [ "$j" != "$wwpn_length" ]
			then
				echo -e ", \c"
			fi
		done
		echo -e "]\c"
		
		echo -e "}\c"
		i=$(expr $i + 1)
		if [ "$i" != "$host_length" ]
		then
			echo -e ", \c"
		fi
	done
fi
echo -e "]"
}

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

host_len=0
echo $2 |awk -F"|" '{for(i=1;i<=NF;i++) print $i}' | while read param
do
		case $host_len in
				0)
				        host_len=1;
				        host_name=$param;;
				1)
				        host_len=2;        
				        host_type=$param;;
		esac
done


wwpn_list=$3
wwpn_list=$(echo "$wwpn_list"|sed 's/|/:/g')
# wwpn_len=0
# echo $3 |awk -F"|" '{for(i=1;i<=NF;i++) print $i}' | while read param
# do
	# if [ "$param" != "" ]
	# then
		# wwpn_id[$wwpn_len]=$param
		# wwpn_len=$(expr $wwpn_len + 1)
	# fi
# done


log_flag=$(cat ../scrpits.properties 2> /dev/null | grep "LOG=" | awk -F"=" '{print $2}')
if [ "$log_flag" == "" ]
then
	log_flag=0
fi

random=$(perl -e 'my $random = int(rand(9999)); print "$random";')
DateNow=$(date +%Y%m%d%H%M%S)
out_log="${path_log}/out_pd_svc_regist_host_${DateNow}_${random}.log"
error_log="${path_log}/error_pd_svc_regist_host_${DateNow}_${random}.log"

log_debug $LINENO "$0 $*"

#####################################################################################
#####                                                                           #####
#####                       regist SVC host	                                    #####
#####                                                                           #####
#####################################################################################
regist_host_info=$(ssh -i ${key_file} ${svc_user}@${svc_ip} "svctask mkhost -force -hbawwpn ${wwpn_list} -name $host_name -type $host_type" 2> "${error_log}")
log_debug $LINENO "regist_host_info=${regist_host_info}"
catchException "${error_log}"
if [ "$error_result" != "" ]
then
	throwException "$error_result" "100000"
fi
host_id=$(echo "$regist_host_info"|grep "successfully"|awk -F'[][]' '{print $2}')
if [ "$host_id" == "" ]
then
	throwException "Get host id in SVC failed" "100000"
fi
#echo "$svc_host_info"


#####################################################################################
#####                                                                           #####
#####                       get host wwpn info                                  #####
#####                                                                           #####
#####################################################################################
svc_host_info=$(ssh -i ${key_file} ${svc_user}@${svc_ip} 'svcinfo lshost -nohdr -delim : -filtervalue id='$host_id'|while IFS=":"; read -a hosts; do printf "%s:%s:%s:" ${hosts[0]} ${hosts[1]} ${hosts[4]}; svcinfo lshost -delim : ${hosts[0]}|while IFS=":";read -a host; do [[ ${host[0]} =~ type ]] && printf "%s" ${host[1]}; [[ ${host[0]} =~ WWPN ]] && printf ":%s:" ${host[1]}; [[ ${host[0]} =~ node_logged_in_count ]] && printf "%s:" ${host[1]}; [[ ${host[0]} =~ state ]] && printf "%s" ${host[1]}; done; printf "\n"; done' 2> "${error_log}")
log_debug $LINENO "svc_host_info=${svc_host_info}"
catchException "${error_log}"
if [ "$error_result" != "" ]
then
	throwException "$error_result" "100000"
fi

echo "svc_host_info=${svc_host_info}" >> "$out_log"
#echo "$svc_host_info"
host_length=0
if [ "${svc_host_info}" != "" ]
then
	echo "$svc_host_info" | while read host_info
	do
		#echo $host_info
		if [ "$host_info" != "" ]
		then
			host_id[$host_length]=$(echo "$host_info" | awk -F":" '{print $1}')
			host_name[$host_length]=$(echo "$host_info" | awk -F":" '{print $2}')
			host_status[$host_length]=$(echo "$host_info" | awk -F":" '{print $3}')
			host_type[$host_length]=$(echo "$host_info" | awk -F":" '{print $4}')
			port_mask[$host_length]=""
			port_type[$host_length]=""
			hostwwpnList[$host_length]=$(echo "$host_info"|awk -F":" '{for(i=5;i<=NF;i++)  if (i!=NF) {printf $i":"} else {printf $i}}')
			# port_name[$host_length]=$(echo "$host_info" | awk -F":" '{print $5}')
			# nodes_logged_in[$host_length]=$(echo "$host_info" | awk -F":" '{print $6}')
			# port_status[$host_length]=$(echo "$host_info" | awk -F":" '{print $7}')
			host_length=$(expr $host_length + 1)
		fi
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

#!/usr/bin/ksh

. ../ivm_function.sh

aix_getinfo() {
i=0
echo  "[\c"
if [ "$volume_length" != "0" ]
then
	while [ $i -lt $volume_length ]
	do
		echo  "{\c"
		echo  "\"hostMappings\":\"\", \c"
		echo  "\"volumeId\":\"${volumeId[$i]}\", \c"
		echo  "\"volumeName\":\"${volumeName[$i]}\", \c"
		echo  "\"volumeStatus\":\"${volumeStatus[$i]}\", \c"
		echo  "\"volumePool\":\"${volumePool[$i]}\", \c"
		echo  "\"volumeUid\":\"${volumeUid[$i]}\", \c"
		echo  "\"volumeCapacity\":\"${volumeCapacity[$i]}\", \c"
		echo  "\"volumeExpand\":\"${volumeExpand[$i]}\", \c"
		map_length=0
		echo ${hostMapList[$i]} |awk -F":" '{for(i=1;i<=NF;i++) if ( i%4 != 0) {printf $i":"} else {printf $i"\n"}}'| while read param
		do
			scsiId[$map_length]=$(echo "$param"|awk -F":" '{print $1}')
			hostId[$map_length]=$(echo "$param"|awk -F":" '{print $2}')
			cachingIoGroupId[$map_length]=$(echo "$param"|awk -F":" '{print $4}')
			map_length=$(expr $map_length + 1)
		done
		
		echo  "\"hostMapList\": \c"
		echo  "[\c"
		j=0
		while [ $j -lt $map_length ]
		do
			echo  "{\c"
			#echo  "\"hostMapList\":\"${hostMapList[$i]}\", \c"
	
			
			echo  "\"scsiId\":\"${scsiId[$j]}\", \c"
			echo  "\"hostId\":\"${hostId[$j]}\", \c"
			echo  "\"cachingIoGroupId\":\"${cachingIoGroupId[$j]}\" \c"
		
			echo "}\c"
			
			j=$(expr $j + 1)
			if [ "$j" != "$map_length" ]
			then
				echo ", \c"
			fi
			
		done
		echo "]\c"
		
		echo "}\c"
		i=$(expr $i + 1)
		if [ "$i" != "$volume_length" ]
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
if [ "$volume_length" != "0" ]
then
	while [ $i -lt $volume_length ]
	do
		echo -e "{\c"
		echo -e "\"hostMappings\":\"\", \c"
		echo -e "\"volumeId\":\"${volumeId[$i]}\", \c"
		echo -e "\"volumeName\":\"${volumeName[$i]}\", \c"
		echo -e "\"volumeStatus\":\"${volumeStatus[$i]}\", \c"
		echo -e "\"volumePool\":\"${volumePool[$i]}\", \c"
		echo -e "\"volumeUid\":\"${volumeUid[$i]}\", \c"
		echo -e "\"volumeCapacity\":\"${volumeCapacity[$i]}\", \c"
		echo -e "\"volumeExpand\":\"${volumeExpand[$i]}\", \c"
		map_length=0
		echo ${hostMapList[$i]} |awk -F":" '{for(i=1;i<=NF;i++) if ( i%4 != 0) {printf $i":"} else {printf $i"\n"}}'| while read param
		do
			scsiId[$map_length]=$(echo "$param"|awk -F":" '{print $1}')
			hostId[$map_length]=$(echo "$param"|awk -F":" '{print $2}')
			cachingIoGroupId[$map_length]=$(echo "$param"|awk -F":" '{print $4}')
			map_length=$(expr $map_length + 1)
		done
		
		echo -e "\"hostMapList\": \c"
		echo -e "[\c"
		j=0
		while [ $j -lt $map_length ]
		do
			echo -e "{\c"
			#echo  "\"hostMapList\":\"${hostMapList[$i]}\", \c"
	
			
			echo -e "\"scsiId\":\"${scsiId[$j]}\", \c"
			echo -e "\"hostId\":\"${hostId[$j]}\", \c"
			echo -e "\"cachingIoGroupId\":\"${cachingIoGroupId[$j]}\" \c"
		
			echo -e "}\c"
			
			j=$(expr $j + 1)
			if [ "$j" != "$map_length" ]
			then
				echo -e ", \c"
			fi
			
		done
		echo -e "]\c"
		
		echo -e "}\c"
		i=$(expr $i + 1)
		if [ "$i" != "$volume_length" ]
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


volume_len=0
echo $2 | awk -F"|" '{for(i=1;i<=NF;i++) print $i}' | while read param
do
		case $volume_len in
				0)
				        volume_len=1;
				        vol_name=$param;;
				1)
				        volume_len=2;
				        vol_diskgrp=$param;;
				2)
				        volume_len=3;        
				        vol_size=$param;;
				3)
				        volume_len=4;        
				        vol_preset=$param;;						
		esac
done


# host_len=0
# echo $3 |awk -F"|" '{for(i=1;i<=NF;i++) print $i}' | while read param
# do
	# if [ "$param" != "" ]
	# then
		# host_id[$host_len]=$param
		# host_len=$(expr $host_len + 1)
	# fi
# done

log_flag=$(cat ../scrpits.properties 2> /dev/null | grep "LOG=" | awk -F"=" '{print $2}')
if [ "$log_flag" == "" ]
then
	log_flag=0
fi

random=$(perl -e 'my $random = int(rand(9999)); print "$random";')
DateNow=$(date +%Y%m%d%H%M%S)
out_log="${path_log}/out_pd_svc_create_volume_${DateNow}_${random}.log"
error_log="${path_log}/error_pd_svc_create_volume_${DateNow}_${random}.log"

log_debug $LINENO "$0 $*"

#####################################################################################
#####                                                                           #####
#####                        SVC create volume                                  #####
#####                                                                           #####
#####################################################################################
if [ "$vol_preset" == "0" ]
then
	volume_info=$(ssh -i ${key_file} ${svc_user}@${svc_ip} "svctask mkvdisk -name $vol_name -iogrp 0 -mdiskgrp $vol_diskgrp -size $vol_size -unit b" 2> "${error_log}")
elif [ "$vol_preset" == "1" ]
then
	volume_info=$(ssh -i ${key_file} ${svc_user}@${svc_ip} "svctask mkvdisk -name $vol_name -autoexpand  -rsize 2% -iogrp 0 -mdiskgrp $vol_diskgrp -size $vol_size -unit b" 2> "${error_log}")
else
	:
fi
catchException "${error_log}"
if [ "$error_result" != "" ]
then
	throwException "$error_result" "100000"
fi
log_debug $LINENO "volume_info=${volume_info}"
volume_id=$(echo "$volume_info"|grep "successfully"|awk -F'[][]' '{print $2}')
if [ "$volume_id" == "" ]
then
	throwException "Get Volume id in SVC failed" "100000"
fi

sleep 2

#####################################################################################
#####                                                                           #####
#####                       get volume info                                     #####
#####                                                                           #####
#####################################################################################
svc_volume_info=$(ssh -i ${key_file} ${svc_user}@${svc_ip} 'svcinfo lsvdisk -delim : -nohdr -bytes -filtervalue id='$volume_id'|while IFS=":" ;  read -a volume;  do  printf "%s:%s:%s:%s:%s:%s:%s:%s" ${volume[0]} ${volume[1]} ${volume[4]} ${volume[5]} ${volume[6]} ${volume[7]} ${volume[13]} ${volume[15]} ;  svcinfo lsvdisk -delim : ${volume[0]}| while IFS=":" ; read -a volinfo;  do [[ ${volinfo[0]} == autoexpand && ${volinfo[1]} == on ]] && printf ":%s"  ${volinfo[1]}; [[ ${volinfo[0]} == autoexpand && ${volinfo[1]} != on ]] && printf ":off"; done; svcinfo lsvdiskhostmap -delim : -nohdr ${volume[0]}|while IFS=":" ; read -a host;  do  if [[ ${host[0]} == "" ]];  then  print "\n";  else  printf ":%s:%s:%s:%s"  ${host[2]} ${host[3]} ${host[4]} ${host[6]};  fi;  done;  printf "\n";  done')
log_debug $LINENO "svc_volume_info=${svc_volume_info}"
#echo "$svc_volume_info"
volume_length=0
if [ "${svc_volume_info}" != "" ]
then
	echo "$svc_volume_info" | while read volume_info
	do
		if [ "$volume_info" != "" ]
		then
			hostMappings=""
			volumeId[$volume_length]=$(echo "$volume_info"|awk -F":" '{print $1}')
			volumeName[$volume_length]=$(echo "$volume_info"|awk -F":" '{print $2}')
			volumeStatus[$volume_length]=$(echo "$volume_info"|awk -F":" '{print $3}')
			volumePool[$volume_length]=$(echo "$volume_info"|awk -F":" '{print $5}')
			volumeUid[$volume_length]=$(echo "$volume_info"|awk -F":" '{print $7}')
			volumeCapacity[$volume_length]=$(echo "$volume_info"|awk -F":" '{print $6}')
			volumeExpand[$volume_length]=$(echo "$volume_info"|awk -F":" '{print $9}')
			hostMapList[$volume_length]=$(echo "$volume_info"|awk -F":" '{for(i=10;i<=NF;i++)  if (i!=NF) {printf $i":"} else {printf $i}}')
			volume_length=$(expr $volume_length + 1)
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

#!/usr/bin/ksh

. ./ivm_function.sh

aix_getinfo() {
	i=0
	echo  "[\c"
	while [ $i -lt $length ]
	do
		echo  "{\c"
		echo  "\"iso_file\":\"${iso_file[$i]}\", \c"
		echo  "\"iso_size\":\"${iso_size[$i]}\"\c"
		
		i=$(expr $i + 1)
		if [ "$i" == "$length" ]
		then
			echo  "}\c"
		else
			echo  "}, \c"
		fi
	done
	
	echo  "]"
}

linux_getinfo() {
	i=0
	echo -e "[\c"
	while [ $i -lt $length ]
	do
		echo -e "{\c"
		echo -e "\"iso_file\":\"${iso_file[$i]}\", \c"
		echo -e "\"iso_size\":\"${iso_size[$i]}\"\c"
		
		i=$(expr $i + 1)
		if [ "$i" == "$length" ]
		then
			echo -e "}\c"
		else
			echo -e "}, \c"
		fi
	done
	
	echo -e "]"
}

j=0
for param in $(echo $1 |awk -F"|" '{for(i=1;i<=NF;i++) print $i}')
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
        esac
done

log_flag=$(cat scrpits.properties 2> /dev/null | grep "LOG=" | awk -F"=" '{print $2}')
if [ "$log_flag" == "" ]
then
	log_flag=0
fi

DateNow=$(date +%Y%m%d%H%M%S)
random=$(perl -e 'my $random = int(rand(9999)); print "$random";')
out_log="${path_log}/out_ivm_get_opt_dev_info_${DateNow}_${random}.log"
error_log="${path_log}/error_ivm_get_opt_dev_info_${DateNow}_${random}.log"

log_debug $LINENO "$0 $*"

#####################################################################################
#####                                                                           #####
#####                  get virtual_scsi_adapters server id                      #####
#####                                                                           #####
#####################################################################################
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"lssyscfg -r prof --filter lpar_ids=${lpar_id} -F virtual_scsi_adapters\""
server_vscsi_id=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r prof --filter lpar_ids=${lpar_id} -F virtual_scsi_adapters" 2>&1)
if [ $? -ne 0 ]
then
	print_error "ERROR-105063: $server_vscsi_id"
fi
log_debug $LINENO "server_vscsi_id=${server_vscsi_id}"
server_vscsi_id=$(echo "$server_vscsi_id" | awk -F'/' '{print $5}')
# echo "server_vscsi_id=${server_vscsi_id}"


#####################################################################################
#####                                                                           #####
#####                            get vios' adapter                              #####
#####                                                                           #####
#####################################################################################
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli lsmap -all -fmt :\""
vadapter_vios=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -all -fmt :" 2>&1)
if [ $? -ne 0 ]
then
	print_error "ERROR-105064: $vadapter_vios"
fi
log_debug $LINENO "vadapter_vios=${vadapter_vios}"
vadapter_vios=$(echo "$vadapter_vios" | grep "C${server_vscsi_id}:" | awk -F":" '{print $1}')
# echo "vadapter_vios=${vadapter_vios}"


######################################################################################
######                                                                           #####
######                          		get vopt                              	 #####
######                                                                           #####
######################################################################################
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli lsmap -vadapter ${vadapter_vios} -field vtd\""
vadapter_vcd=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -vadapter ${vadapter_vios} -field vtd" 2>&1)
if [ $? -ne 0 ]
then
	print_error "ERROR-105083: $vadapter_vcd"
fi
log_debug $LINENO "vadapter_vcd=${vadapter_vcd}"
vadapter_vcd=$(echo "$vadapter_vcd" | grep vtopt | awk '{print $2}')

######################################################################################
######                                                                           #####
######                          	get iso file                              	 #####
######                                                                           #####
######################################################################################
length=0
for vcd in $vadapter_vcd
do
	log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli lsvopt -vtd $vcd -field media size -fmt :\""
	vopt_iso=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsvopt -vtd $vcd -field media size -fmt :" 2>&1)
	if [ $? -ne 0 ]
	then
		print_error "ERROR-105084: $vopt_iso"
	fi
	log_debug $LINENO "vopt_iso=${vopt_iso}"
	iso_file[$length]=$(echo $vopt_iso | awk -F":" '{print $1}')
	iso_size[$length]=$(echo $vopt_iso | awk -F":" '{print $2}')
	
	if [ "${iso_file[$length]}" == "No Media" ]
	then
		continue
	fi
	
	if [ "${iso_size[$length]}" == "n/a" ]
	then
		iso_size[$length]=0
	fi
	
	if [ "${iso_size[$length]}" == "unknown" ]
	then
		ssh ${ivm_user}@${ivm_ip} "ioscli unloadopt -release -vtd $vcd" 2> /dev/null 2>&1
		continue
	fi
	
	length=$(expr $length + 1)
done


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

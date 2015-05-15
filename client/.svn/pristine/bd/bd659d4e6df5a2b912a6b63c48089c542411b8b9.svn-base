#!/usr/bin/ksh
#./hmc_migrate_active.sh "172.30.126.19|hscroot|p730-1|8|p730-2"
# host:     lssyscfg -r sys -F name
# lpar:     lssyscfg -r lpar -m p730-1 -F name,lpar_id
# rmc state:lssyscfg -r lpar -m p730-1 --filter lpar_ids=8 -F rmc_state
# flush rmc:/usr/sbin/rsct/install/bin/recfgct

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
			echo "0|0|ERROR-${error_code}:"$(echo "$result" | awk -F']' '{print $2}')
		else
			echo "0|0|ERROR-${error_code}: ${result}"
		fi
		
		if [ "$log_flag" == "0" ]
		then
			rm -f "${error_log}" 2> /dev/null
			rm -f "$out_log" 2> /dev/null
		fi
		rm -f ${cdrom_path}/${config_iso} 2> /dev/null
		rm -f ${ovf_xml} 2> /dev/null
		rm -f ${template_path}/${config_iso} 2> /dev/null
		exit 1
	fi

}

j=0
echo $1 |awk -F"|" '{for(i=1;i<=NF;i++) print $i}' | while read param
do
        case $j in
                        0)
                                j=1;
                                hmc_source_ip=$param;;
                        1)
                                j=2;        
                                hmc_source_user=$param;;                                
                        2)
                                j=3;        
                                hmc_source_host=$param;;
                        3)
                                j=5;
                                lpar_id=$param;;
                        5)
                                j=6;        
                                hmc_target_host=$param;;
        esac
done

DateNow=$(date +%Y%m%d%H%M%S)
random=$(perl -e 'my $random = int(rand(9999)); print "$random";')
out_log="out_migrate_${lpar_id}_${DateNow}_${random}.log"
error_log="error_migrate_${lpar_id}_${DateNow}_${random}.log"
cdrom_path="/var/vio/VMLibrary"
echo "1|10|SUCCESS"

######################################################################################
######                                                                           #####
######                       judge parameter:null or not                         #####
######                                                                           #####
######################################################################################

if [ "$hmc_source_ip" == "" ]
then
	throwException "hmc_source_ip is null" "105401"
fi

if [ "$hmc_source_host" == "" ]
then
	throwException "hmc_source_host is null" "105433" 
fi

if [ "$hmc_source_user" == "" ]
then
	throwException "hmc_source_user name is null" "105402"
fi

if [ "$lpar_id" == "" ]
then
	throwException "Lpar id is null" "105434"
fi


if [ "$hmc_target_host" == "" ]
then
	throwException "hmc_target_host is null" "105433" 
fi

echo "1|20|SUCCESS"

result=$(ssh ${hmc_source_user}@${hmc_source_ip} "lssyscfg -r lpar -m $hmc_source_host --filter lpar_ids=$lpar_id" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	throwException "$result" "105469"
fi


######################################################################################
######                                                                           #####
######                              check rmc state                              #####
######                                                                           #####
######################################################################################
rmc_state=$(ssh ${hmc_source_user}@${hmc_source_ip} "lssyscfg -r lpar -m $hmc_source_host --filter lpar_ids=$lpar_id -F rmc_state" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	throwException "$rmc_state" "105475"
fi

if [ "$rmc_state" != "active" -a "$rmc_state" != "inactive" ]
then
   throwException "rmc state or vm status is not ready." "105475"
fi


#####################################################################################
#####                                                                           #####
#####                       validate a partition migration                     #####
#####                                                                           #####
#####################################################################################
#rmc_state=$(ssh ${hmc_source_user}@${hmc_source_ip} "lssyscfg -r lpar --filter lpar_ids=$lpar_id -F rmc_state" 2> ${error_log})
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
#migr_start=$(ssh ${hmc_source_user}@${hmc_source_ip} "migrlpar -o m -m $hmc_source_host -t $hmc_target_host --id $lpar_id" 2> "${error_log}")
migr_start=$(ssh ${hmc_source_user}@${hmc_source_ip} "migrlpar -o m -m $hmc_source_host -t $hmc_target_host --id $lpar_id" 2>&1)

if [ "$(echo $?)" == "0" ]
then
	echo "1|100|SUCCESS"
	exit 0
else
	throwException "$migr_start" "105482"
	exit 0
fi







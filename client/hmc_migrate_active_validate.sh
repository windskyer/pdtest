#!/usr/bin/ksh
#./hmc_migrate_active_validate.sh "172.30.126.19|hscroot|p730-1|8|p730-2"
# host:     lssyscfg -r sys -F name
# lpar:     lssyscfg -r lpar -m p730-1 -F name,lpar_id
# rmc state:lssyscfg -r lpar -m p730-1 --filter lpar_ids=8 -F rmc_state
# flush rmc:/usr/sbin/rsct/install/bin/recfgct

. ./hmc_function.sh

#echo "1|0|SUCCESS"

validate_migrate_aix()
{
  echo "{\c"
  echo "\"migrate_state\":\"$1\",\c"
  echo "\"migrate_desc\":\""$2"\"\c"
  echo "}"
}

validate_migrate_linux()
{
  echo -e "{\c"
  echo -e "\"migrate_state\":\"$1\",\c"
  echo -e "\"migrate_desc\":\""$2"\"\c"
  echo -e "}"
}

print_info()
{
   case $(uname -s) in
	AIX)
			validate_migrate_aix $1 "$2";;
	Linux)
			validate_migrate_linux $1 "$2";;
  esac
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
                                j=4;
                                lpar_id=$param;;
                        4)
                                j=5;        
                                hmc_target_host=$param;;
        esac
done

log_flag=$(cat scrpits.properties 2> /dev/null | grep "LOG=" | awk -F"=" '{print $2}')
if [ "$log_flag" == "" ]
then
	log_flag=0
fi

DateNow=$(date +%Y%m%d%H%M%S)
random=$(perl -e 'my $random = int(rand(9999)); print "$random";')
out_log="out_mount_iso_${lpar_id}_${DateNow}_${random}.log"
error_log="error_mount_iso_${lpar_id}_${DateNow}_${random}.log"
#echo "1|10|SUCCESS"

######################################################################################
######                                                                           #####
######                       judge parameter:null or not                         #####
######                                                                           #####
######################################################################################

if [ "$hmc_source_ip" == "" ]
then
	echoError "hmc_source_ip is null" "105401"
fi

if [ "$hmc_source_host" == "" ]
then
	echoError "hmc_source_host is null" "105433"
fi

if [ "$hmc_source_user" == "" ]
then
	echoError "hmc_source_user is null" "105402"
fi

if [ "$lpar_id" == "" ]
then
	echoError "Lpar id is null" "105434"
fi

if [ "$hmc_target_host" == "" ]
then
	echoError "hmc_target_host is null" "105433"
fi

#echo "1|20|SUCCESS"

result=$(ssh ${hmc_source_user}@${hmc_source_ip} "lssyscfg -r lpar -m $hmc_source_host --filter lpar_ids=$lpar_id" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	echoError "$result" "105469"
fi


######################################################################################
######                                                                           #####
######                              check rmc state                              #####
######                                                                           #####
######################################################################################
rmc_state=$(ssh ${hmc_source_user}@${hmc_source_ip} "lssyscfg -r lpar -m $hmc_source_host --filter lpar_ids=$lpar_id -F rmc_state" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	echoError "$rmc_state" "105475"
fi

if [ "$rmc_state" != "active" ]&&[ "$rmc_state" != "inactive" ]
then
   print_info 0 "Rmc state or vm status is not ready."
   exit 1
fi

#####################################################################################
#####                                                                           #####
#####              get target host type_model and serial number                 #####
#####                                                                           #####
#####################################################################################
echo "$(date) : check target host type_model" >> "$out_log"
host_num=$(ssh ${hmc_source_user}@${hmc_source_ip} "lssyscfg -r sys -m $hmc_source_host -F type_model,serial_num" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	echoError "$host_num" "105406"
fi
host_num=$(echo "$host_num" | sed 's/,/\*/')
echo "host_num=${host_num}" >> "$out_log"
#echo "1|40|SUCCESS"

#####################################################################################
#####                                                                           #####
#####                       validate a partition migration                      #####
#####                                                                           #####
#####################################################################################
migr_validate=$(ssh ${hmc_source_user}@${hmc_source_ip} "migrlpar -o v -m $hmc_source_host -t $hmc_target_host --id $lpar_id" 2>&1)

if [ "$(echo $?)" != "0" ]
then
   #echo "1|100|SUCCESS"
   print_info 0 "$migr_validate"
else
   #echo "1|100|SUCCESS"
   print_info 1
fi

if [ "$log_flag" == "0" ]
then
	rm -f "${error_log}" 2> /dev/null
	rm -f "$out_log" 2> /dev/null
fi






#!/usr/bin/ksh

echo "1|35|SUCCESS"

. ./hmc_function.sh

hmc_ip=$1
hmc_user=$2
host_id=$3
lpar_id=$4

log_flag=$(cat ./scrpits.properties 2> /dev/null | grep "LOG=" | awk -F"=" '{print $2}')
if [ "$log_flag" == "" ]
then
	log_flag=0
fi

if [ "$hmc_ip" == "" ]
then
	throwException "IP is null" "105401"
fi

if [ "$hmc_user" == "" ]
then
	throwException "User name is null" "105402"
fi

if [ "$host_id" == "" ]
then
	throwException "Host id is null" "105433"
fi

if [ "$lpar_id" == "" ]
then
	throwException "Lpar id is null" "105434"
fi

DateNow=$(date +%Y%m%d%H%M%S)
random=$(perl -e 'my $random = int(rand(9999)); print "$random";')
out_log="out_startup_sms_${DateNow}_${random}.log"
error_log="error_startup_sms_${DateNow}_${random}.log"

lpar_name=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m $host_id -r prof --filter lpar_ids=${lpar_id} -F name" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	throwException "$lpar_name" "105438"
fi

lpar_state=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m $host_id -r lpar --filter lpar_ids=${lpar_id} -F state" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	throwException "$lpar_state" "105435"
fi

echo "1|50|SUCCESS"

desc="The vm state is "$lpar_state

while [ "$lpar_state" != "Open Firmware" ]
do
		lpar_state=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -m $host_id -r lpar --filter lpar_ids=${lpar_id} -F state" 2>&1)
		if [ "$(echo $?)" != "0" ]
		then
			throwException "$lpar_state" "105435"
		fi
		case $lpar_state in
				Starting)
							desc=$desc", wait running state";
							waitRunning;;
				Running)
							desc=$desc", shutdown";
							shutDown;;
				"Shutting Down")
							desc=$desc", wait shutdown";
							waitShutDown;;
				"Open Firmware")
							echo "1|100|SUCCESS: $desc";
							exit 0;;
				Error)
							throwException "Virtual machine state is error." "105465";;
				"Not Available")
							throwException "Virtual machine state is not available." "105466";;
				"Not Activated")
							desc=$desc", startup with sms";
							startupSms;;
		esac
done

if [ "$log_flag" == "0" ]
then
	rm -f $error_log
fi

echo "1|100|SUCCESS: $desc"
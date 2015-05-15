#!/usr/bin/ksh
#./hmc_get_dlpar_state.sh 172.30.125.2 hscroot p720-1 1

hmc_ip=$1
hmc_user=$2
host_id=$3
lpar_id=$4

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
			echo "0|0|ERROR-${error_code}: "$(echo "$result" | awk -F']' '{print $2}')
		else
			echo "0|0|ERROR-${error_code}: $result"
		fi
		
		if [ "$log_flag" == "0" ]
		then
			rm -f "${error_log}" 2> /dev/null
			rm -f "$out_log" 2> /dev/null
		fi

		exit 1
	fi

}

get_dlpar_state_aix()
{
  echo "{\"lpar_dlpar_state\": \c"
  echo "\"$1\" }"
}

get_dlpar_state_linux()
{
  echo -e "{\"lpar_dlpar_state\": \c"
  echo -e "\"$1\" }"
}

print_info()
{
   case $(uname -s) in
	AIX)
			get_dlpar_state_aix $1;;
  Linux)
			get_dlpar_state_linux $1;;
  esac
}

log_flag=$(cat scrpits.properties 2> /dev/null | grep "LOG=" | awk -F"=" '{print $2}')
if [ "$log_flag" == "" ]
then
	log_flag=0
fi

DateNow=$(date +%Y%m%d%H%M%S)
out_log="out_dlparstate_${DateNow}.log"
error_log="error_dlparstate_${DateNow}.log"

lpar_info=$(ssh ${hmc_user}@${hmc_ip} "lssyscfg -r lpar -m $host_id --filter lpar_ids=$lpar_id -F name:lpar_id:lpar_env:state:rmc_ipaddr:rmc_state" 2> ${error_log})


dlpar_state=$(echo $lpar_info | awk -F: '{print $NF}' )

case ${dlpar_state} in

	active)
			print_info active;;
  inactive)
			print_info inactive;;
	unknown)
			print_info unknown;;
  none)
			print_info none;;		
esac

if [ "$log_flag" == "0" ]
then
	rm -f "${error_log}" 2> /dev/null
	rm -f "$out_log" 2> /dev/null
fi

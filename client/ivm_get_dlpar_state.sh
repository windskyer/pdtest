#!/usr/bin/ksh
#./ivm_get_dlpar_state.sh 172.30.126.10 padmin 1

. ./ivm_function.sh

ivm_ip=$1
ivm_user=$2
lpar_id=$3

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

DateNow=$(date +%Y%m%d%H%M%S)
random=$(perl -e 'my $random = int(rand(9999)); print "$random";')
out_log="${path_log}/out_ivm_get_dlpar_state_${DateNow}_${random}.log"
error_log="${path_log}/error_ivm_get_dlpar_state_${DateNow}_${random}.log"

lpar_info=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar --filter lpar_ids=$lpar_id -F name,lpar_id,lpar_env,state,rmc_ipaddr,rmc_state" 2> ${error_log})


dlpar_state=$(echo $lpar_info | awk -F"," '{print $NF}' )

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

rm -f "${error_log}" 2> /dev/null
rm -f "$out_log" 2> /dev/null

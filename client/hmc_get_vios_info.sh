#!/usr/bin/ksh

. ./hmc_function.sh

hmc_ip=$1
hmc_user=$2
host_id=$3

DateNow=$(date +%Y%m%d%H%M%S)
out_log="out_startup_${DateNow}.log"
error_log="error_hmc_get_vios_info_${DateNow}.log"

get_hmc_vios 2> $error_log
catchException $error_log
echoError "$error_result"


aix_getinfo() {
	i=0
	echo "[\c"
	while [ $i -lt $vios_len ]
	do
		echo "{\c"
		echo "\"vios_id\":\"${viosId[$i]}\", \c"
		echo "\"vios_name\":\"${viosName[$i]}\", \c"
		echo "\"vios_active\":\"${viosActive[$i]}\", \c"
		echo "\"vios_state\":\"${viosState[$i]}\", \c"
		echo "\"vios_ip\":\"${viosIp[$i]}\"\c"
		echo "}\c"
		
		i=$(expr $i + 1)
		if [ "$i" != "$vios_len" ]
		then
			echo ", \c"
		fi
	done
	echo "]"
}

linux_getinfo() {
	i=0
	echo -e "[\c"
	while [ $i -lt $vios_len ]
	do
		echo -e "{\c"
		echo -e "\"vios_id\":\"${viosId[$i]}\", \c"
		echo -e "\"vios_name\":\"${viosName[$i]}\", \c"
		echo -e "\"vios_active\":\"${viosActive[$i]}\", \c"
		echo -e "\"vios_state\":\"${viosState[$i]}\", \c"
		echo -e "\"vios_ip\":\"${viosIp[$i]}\"\c"
		echo -e "}\c"
		
		i=$(expr $i + 1)
		if [ "$i" != "$vios_len" ]
		then
			echo -e ", \c"
		fi
	done
	echo "]"
}

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
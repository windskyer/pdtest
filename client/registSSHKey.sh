#!/usr/bin/ksh

. ./ivm_function.sh

catchException() {    
	error_result=$(cat $1)
}

ipaddr=$1
user=$2
passwd=$3

log_flag=$(cat scrpits.properties 2> /dev/null | grep "LOG=" | awk -F"=" '{print $2}')
if [ "$log_flag" == "" ]
then
	log_flag=0
fi

DateNow=$(date +%Y%m%d%H%M%S)
random=$(perl -e 'my $random = int(rand(9999)); print "$random";')
out_log="${path_log}/out_registSSHKey_${DateNow}_${random}.log"

log_debug $LINENO "$0 $*"

ping -c 3 $ipaddr > /dev/null 2>&1
if [ "$(echo $?)" != "0" ]
then
	echo "$ipaddr unable to connect." >&2
	exit 1
fi

if [ -f ~/.ssh/known_hosts ]
then
	known_host=$(cat ~/.ssh/known_hosts | sed -e '/'$ipaddr'/d')
	echo "$known_host" > ~/.ssh/known_hosts
fi 
log_debug $LINENO "known_host=${known_host}"

regist_result=$(expect ./registSSHKey.exp $ipaddr $user $passwd 2>&1)
log_debug $LINENO "regist_result=${regist_result}"
if [ "$regist_result" != "" ]
then
	if [ "$(echo $regist_result | grep "Permission denied")" != "" ]
	then
		echo "Permission denied" >&2
	fi
fi

if [ "$log_flag" == "0" ]
then
	rm -f "$out_log" 2> /dev/null
fi
#!/usr/bin/ksh

. ../ivm_function.sh

aix_getinfo() {
	echo "[\c"
	echo "{\c"
	echo "\"key_path\":\"${defaultkeyfile}\"\c"
	echo "}\c"
	echo "]"
}

linux_getinfo() {
	echo -e "[\c"
	echo -e "{\c"
	echo -e "\"key_path\":\"${defaultkeyfile}\"\c"
	echo -e "}\c"
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

ipaddr=$1
user=$2
keyfile=$3

log_flag=$(cat ../scrpits.properties 2> /dev/null | grep "LOG=" | awk -F"=" '{print $2}')
if [ "$log_flag" == "" ]
then
	log_flag=0
fi

DateNow=$(date +%Y%m%d%H%M%S)
random=$(perl -e 'my $random = int(rand(9999)); print "$random";')
out_log="${path_log}/out_pd_svc_regist_user_sshkey_${DateNow}_${random}.log"
error_log="${path_log}/error_pd_svc_regist_user_sshkey_${DateNow}_${random}.log"


ping -c 3 $ipaddr > /dev/null 2>&1
if [ "$(echo $?)" != "0" ]
then
	echo "$ipaddr unable to connect." >&2
	exit 1
fi

if [ ! -f "$keyfile" ]
then
	throwException "keyfile is null" "100000"
fi

home=`(cd ~ && pwd)`
if [ "${home}" == "/" ]
then
	home=""
fi

defaultkeypath="$home/.ssh"
if [ ! -d "$defaultkeypath" ]
then
	mkdir -p "$defaultkeypath"
fi
defaultkeyname=svc_$(echo "${ipaddr}"|sed 's/\./_/g')_"${user}"
defaultkeyfile="$defaultkeypath/$defaultkeyname"

hostfile="$home/.ssh/known_hosts"
if [ -f "$hostfile" ]
then
known_host=$(cat $hostfile | sed -e '/'$ipaddr'/d')
echo "$known_host" > "$hostfile"
fi

keyname=$(basename $keyfile)
keypath=$(dirname $keyfile)


if [ "$keyfile" != "$defaultkeyfile" ]
then
	if [ -f "$defaultkeyfile" ]
	then
		rm -rf "$defaultkeyfile"
	fi
	cp "$keyfile" "$defaultkeyfile"
fi

#chmod sshkey 600 for IVM2231
chmod 600 "$defaultkeyfile"

expect ./pd_svc_regist_user_sshkey.exp $ipaddr $user $defaultkeyfile >> $out_log 2>&1
catchException $out_log
if [ "$error_result" != "" ]
then
	if [ "$(echo $error_result | grep "Permission denied")" != "" ]
	then
		if [ -f "$defaultkeyfile" ]
		then
			rm -rf "$defaultkeyfile"
		fi
		throwException "Permission denied" "100000"
	fi
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

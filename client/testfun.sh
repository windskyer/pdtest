#!/usr/bin/ksh


# test vg_lock_check and nfs_server_check functions in ivm_function.sh


ivm_ip=$1
ivm_user=$2
passwd=$3
if [ "$passwd" == "" ] 
then
        passwd='$(java -Djava.ext.dirs="/powerdirector/tomcat/webapps/ROOT/WEB-INF/lib:/usr/java7_64/jre/lib/ext" -cp /powerdirector/tomcat/webapps/ROOT/WEB-INF/classes com.teamsun.pc.web.common.utils.MutualTrustSupport ${ivm_ip})'
fi

# quote function incoude all;
. ./ivm_function.sh

log_flag=$(cat scrpits.properties 2> /dev/null | grep "LOG=" | awk -F"=" '{print $2}')
if [ "$log_flag" == "" ]
then
	log_flag=0
fi

DateNow=$(date +%Y%m%d%H%M%S)
random=$(perl -e 'my $random = int(rand(9999)); print "$random";')
out_log="${path_log}/out_test_fun_${lpar_name}_${DateNow}_${random}.log"
error_log="${path_log}/error_test_fun_${lpar_name}_${DateNow}_${random}.log"
cdrom_path="/var/vio/VMLibrary"

log_debug $LINENO "$0 $*"

nfs_ip="${ivm_ip}"
nfs_user="${ivm_user}"

# call nfs_server_check function to check nfs server five proces wheather if exists;
# nfs_server_check ip user
#nfs_server_check ${nfs_ip} ${nfs_user} ${passwd}

# call check_authorized function to check nauthoeized wheather if exists;
# authoorized_check ip user
check_authorized ${ivm_ip} ${ivm_user} ${passwd}




 

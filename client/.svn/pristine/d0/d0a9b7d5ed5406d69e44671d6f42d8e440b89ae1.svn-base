#!/usr/bin/ksh


# test vg_lock_check and nfs_server_check functions in ivm_function.sh

ivm_ip=$1
ivm_user=$2
vg_name=$3

passwd='$(java -Djava.ext.dirs="/powerdirector/tomcat/webapps/ROOT/WEB-INF/lib:/usr/java7_64/jre/lib/ext" -cp /powerdirector/tomcat/webapps/ROOT/WEB-INF/classes com.teamsun.pc.web.common.utils.MutualTrustSupport ${ivm_ip})'

# quote function incoude all;
. ./ivm_function.sh

# call vg_lock_check function to check vg wheather if lock ;and try active lock vg
# vg_lock_check ip user vgname
# vg_lock_check ${ivm_ip} ${ivm_user} ${vg_name} 


# call nfs_server_check function to check nfs server five proces wheather if exists;
# nfs_server_check ip user
#nfs_server_check ${ivm_ip} ${ivm_user}

# call check_authorized function to check nauthoeized wheather if exists;
# authoorized_check ip user
check_authorized ${ivm_ip} ${ivm_user}
 
 

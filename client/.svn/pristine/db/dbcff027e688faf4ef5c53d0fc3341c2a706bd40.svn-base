#!/usr/bin/ksh

ivm_ip=$1
ivm_user=$2
passwd=$3
if [ "${passwd}" == "" ] 
then
	passwd=$(java -Djava.ext.dirs="/powerdirector/tomcat/webapps/ROOT/WEB-INF/lib:/usr/java7_64/jre/lib/ext" -cp /powerdirector/tomcat/webapps/ROOT/WEB-INF/classes com.teamsun.pc.web.common.utils.MutualTrustSupport ${ivm_ip})
fi

# quote function incoude all;
. ./ivm_function.sh

# call check_authorized function to check nauthoeized wheather if exists; authoorized_check ip user
check_authorized ${ivm_ip} ${ivm_user} ${passwd}


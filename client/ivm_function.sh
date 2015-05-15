#!/usr/bin/ksh

# catchException() {
        
	# error_result=$(cat $1)
	        
# }

# throwException() {
            
	# result=$1
	# error_code=$2
	           
	# if [ "${result}" != "" ]
	# then
		# if [ "$(echo "$result" | grep "VIOSE" | sed 's/ //g')" != "" ]
		# then
			# echo "0|0|ERROR-${error_code}:"$(echo "$result" | awk -F']' '{print $2}')
		# else
			# echo "0|0|ERROR-${error_code}: ${result}"
		# fi
		
		# if [ "$log_flag" == "0" ]
		# then
			# rm -f "${error_log}" 2> /dev/null
			# rm -f "$out_log" 2> /dev/null
		# fi
		# ssh ${ivm_user}@${ivm_ip} "rm -f ${cdrom_path}/${config_iso}" 2> /dev/null
		# rm -f ${ovf_xml} 2> /dev/null
		# rm -f ${template_path}/${config_iso} 2> /dev/null
		# exit 1
	# fi

# }


check_repo()
{
size=$1
lsrep_check=$(ssh ${ivm_user}@${ivm_ip} "oem_setup_env <<eof
ls -d /var/vio/VMLibrary
<<eof " 2>/dev/null)
if [ "$lsrep_check" == "" ]
then
	if [ "$size" == "" ]
	then
		creat_result=$(ssh ${ivm_user}@${ivm_ip} "ioscli rmrep; ioscli mkrep -sp rootvg -size "20"G" 2>&1)
    else
		creat_result=$(ssh ${ivm_user}@${ivm_ip} "ioscli rmrep; ioscli mkrep -sp rootvg -size "$size"G" 2>&1)
		
	fi
fi
}


print_error() {
	echo "$1" >&2
	exit 1
}

pd_nfs="/pd_nfs"

formatPath() {

	path=$1
	
	last_char=$(echo $path | awk '{print substr($0,length($0))}')
	while [ "$last_char" == "/" ]
	do
		path=$(echo $path | awk '{print substr($0,0,length($0)-1)}')
		last_char=$(echo $path | awk '{print substr($0,length($0)-1,length($0))}')
	done
	
}

mount_nfs() {
	
	formatPath "$nfs_path"
	nfs_path=$path
	
	ping -c 3 $nfs_ip > /dev/null 2>&1
	if [ $? -ne 0 ]
	then
		throwException "Unable to connect nfs server." "10000"
		#result="Unable to connect nfs server."
		#error_code=10000
		#echo "0|0|ERROR-${error_code}: ${result}"
		#if [ "$log_flag" == "0" ]
		#then
			#rm -f "${error_log}" 2> /dev/null
			#rm -f "$out_log" 2> /dev/null
		#fi
		#exit 1
	fi
	
	#check showmount
	show_mount=$(ssh ${ivm_user}@${ivm_ip} "ioscli showmount ${nfs_ip}" 2>&1)
	if [ "$?" != "0" ]
	then
		throwException "Cannot mount remote NFS directory, check the NFS configuration." "10000"
		#result="Cannot mount remote NFS directory, check the NFS configuration."
		#error_code=10000
		#echo "0|0|ERROR-${error_code}: ${result}"
		#if [ "$log_flag" == "0" ]
		#then
			#rm -f "${error_log}" 2> /dev/null
			#rm -f "$out_log" 2> /dev/null
		#fi
		#exit 1
	fi
	
	if [ "$nfs_ip" != "" -a "$nfs_path" != "" ]
	then
		if [ "$ivm_ip" != "$nfs_ip" ]
		then
			template_path=$pd_nfs"/nfs_${DateNow}_${random}"
			
			mntClient_host=$(ssh ${ivm_user}@${ivm_ip} "ioscli hostname" 2>&1)
			if [ $? -ne 0 ]
			then
				throwException "$mntClient_host" "10000"
			fi
			
			mount_check=$(ssh ${ivm_user}@${ivm_ip} "ioscli mount" 2>&1)
			if [ $? -ne 0 ]
			then
				throwException "$mount_check" "10000"
			fi
			# echo "mount_check==$mount_check"
			mount_check=$(echo "$mount_check" | awk '{print substr($0,0,length($0)-1)}' | awk '{if($1==nfs_ip && $2==nfs_path) print $3}' nfs_ip="$nfs_ip" nfs_path="$nfs_path" | tail -1)
			# echo "mount_check==$mount_check"
			# if [ "$mount_check" == "" ]
			# then
				
				hosts_check=$(expect ./ssh_password.exp ${nfs_ip} ${nfs_name} ${nfs_passwd} "exportfs -a|cat /etc/hosts|exit" 2>&1)
				if [ $? -ne 0 ]
				then
					throwException "$hosts_check" "10000"
				fi
				# echo "hosts_check==$hosts_check"
				hosts_check=$(echo "$hosts_check" | awk '{print substr($0,0,length($0)-1)}' | awk '{if($1==ivm_ip && $2==mntClient_host) print $0}' ivm_ip="$ivm_ip" mntClient_host="$mntClient_host")
				# hosts_check=$(echo "$hosts_check" | grep $ivm_ip | grep $mntClient_host)	
				if [ "$hosts_check" == "" ]
				then
					write_hosts=$(expect ./ssh_password.exp ${nfs_ip} ${nfs_name} ${nfs_passwd} "echo \"${ivm_ip} $mntClient_host\" >> /etc/hosts|exit" 2>&1)
					if [ $? -ne 0 ]
					then
						throwException "$write_hosts" "10000"
					fi
				fi
			
				ls_check=$(ssh ${ivm_user}@${ivm_ip} "ls $template_path" 2>&1)
				if [ $? -ne 0 ]
				then
					new_path=$(expect ./ssh.exp ${ivm_user} ${ivm_ip} "oem_setup_env|mkdir -p $template_path|exit|exit")
				fi
				# echo "new_path==$new_path"
			
				mount_result=$(ssh ${ivm_user}@${ivm_ip} "ioscli mount ${nfs_ip}:${nfs_path} ${template_path}" 2>&1)
				if [ $? -ne 0 ]
				then
					if [ "$(ssh ${ivm_user}@${ivm_ip} "ls ${template_path}" 2>&1)" == "" ]
					then
						expect ./ssh.exp ${ivm_user} ${ivm_ip} "oem_setup_env|rm -Rf ${template_path}|exit|exit" > /dev/null 2>&1
					fi
					throwException "NFS client ${nfs_ip} mount failed." "10000"
				fi
			# else
				# template_path=$mount_check
			# fi
		else
			template_path=$nfs_path
		fi
	else
		echo "0|0|ERROR-10000: NFS server parameters is error." >&2
		exit 1
	fi
	
}

unmount_nfs() {
	
	if [ "$ivm_ip" != "$nfs_ip" ]
    then
    	mount_info=$(expect ./ssh.exp ${ivm_user} ${ivm_ip} "oem_setup_env|mount|exit|exit" 2>&1)
        mount_flag=$(echo "$mount_info" | awk '{print substr($0,0,length($0)-1)}' | awk '{if($1 == node && $2 == mounted && $3 == mountedpoint) print $0}' node=$nfs_ip mounted=$nfs_path mountedpoint=$template_path)
        if [ "$mount_flag" == "" ]
        then
        	sleep 2
    	else
        	info=$(expect ./ssh.exp ${ivm_user} ${ivm_ip} "oem_setup_env|umount -f ${template_path}|exit|exit" 2>&1)
        	sleep 2
        	mount_info=$(expect ./ssh.exp ${ivm_user} ${ivm_ip} "oem_setup_env|mount|exit|exit" 2>&1)
        	#echo "$mount_info"
        	mount_flag=$(echo "$mount_info" | awk '{print substr($0,0,length($0)-1)}' | awk '{if($1 == node && $2 == mounted && $3 == mountedpoint) print $0}' node=$nfs_ip mounted=$nfs_path mountedpoint=$template_path)
        	#echo "mount_flag=$mount_flag"
        	template_info=$(ssh ${ivm_user}@${ivm_ip} "ls ${template_path}" 2>&1)
        	#echo "template_info=$template_info"
        	if [ "$mount_flag" == "" ] && [ "$template_info" == "" ]
        	then
            	expect ./ssh.exp ${ivm_user} ${ivm_ip} "oem_setup_env|rm -Rf ${template_path}|exit|exit" > /dev/null 2>&1
        	fi
    	fi
    fi

}


path_log="/powerdirector/script_log"
if [ ! -d "${path_log}" ]; then
	mkdir -p ${path_log}
fi

if [ -f "../scrpits.properties" ];then
	loglevel=$(cat ../scrpits.properties 2> /dev/null | grep "Level=" | awk -F"=" '{print $2}')
else
	loglevel=$(cat scrpits.properties 2> /dev/null | grep "Level=" | awk -F"=" '{print $2}')
fi
if [ "$loglevel" == "" ]
then
	loglevel="INFO"
fi



_get_log_num()
{
	tmp_loglevel=$1
	if [ ${tmp_loglevel} == "DEBUG" ]
	then
		lognum=10
	elif [ ${tmp_loglevel} == "INFO" ]
	then
		lognum=20
        elif [ ${tmp_loglevel} == "WARN" ]
        then
                lognum=30
        elif [ ${tmp_loglevel} == "ERROR" ]
        then
                lognum=40
	else
		lognum=40
	fi
	echo ${lognum} ${tmp_loglevel}

}

_write_log()
{
	_F_LOG_LEVEL_NUM=$(_get_log_num ${loglevel} | awk '{print $1}')
	_F_LOG_LEVEL_NAME=$(_get_log_num ${loglevel} | awk '{print $2}')
	_LOG_LEVEL_NUM=$(_get_log_num $2 | awk '{print $1}')
	_LOG_LEVEL_NAME=$(_get_log_num $2 | awk '{print $2}')
	
	if [ "${_LOG_LEVEL_NUM}" -ge "${_F_LOG_LEVEL_NUM}" ]
	then 
        	echo "$(date "+%Y-%m-%d %H:%M:%S") $0:$1 $2: [$3]" >> $out_log
	fi
}

log_debug()
{
	_write_log $1 DEBUG "$2"
}


log_info()
{
	_write_log $1 INFO "$2" 
}


log_warn()
{
	_write_log $1 WARN "$2"
}

log_error()
{
	_write_log $1 ERROR "$2"
}

vg_lock_check()
{
# check vg lock
# vg_lock_check 172.24.23.39 padmin rootvg

ivm_ip=$1
ivm_user=$2
vg_name=$3
pd_path='/powerdirector/tomcat/webapps/ROOT/shellscripts'

out_time=60
log_debug $LINENO "CMD:expect ${pd_path}/oem_cmd.exp ${ivm_ip} ${ivm_user} "" "lsvg ${vg_name}" ${out_time} 2>&1 "
vg_info=$(expect ${pd_path}/oem_cmd.exp ${ivm_ip} ${ivm_user} "" "lsvg ${vg_name}" ${out_time} 2>&1)
log_debug $LINENO "vg_info=${vg_info}"

lock_vg=$(echo "${vg_info}" | grep locked)
off_vg=$(echo "${vg_info}" | grep "use varyonvg command")

if [ "${off_vg}" != "" ] || [ "${lock_vg}" != "" ] 
then
        # try active vg 
		log_debug $LINENO "CMD:expect ${pd_path}/oem_cmd.exp ${ivm_ip} ${ivm_user} "" "chvg -u ${vg_name}" 2>&1 "
        vg_varyon=$(expect ${pd_path}/oem_cmd.exp ${ivm_ip} ${ivm_user} "" "chvg -u ${vg_name}" 2>&1)
        log_debug $LINENO "vg_varyon=${vg_varyon}"
        
        log_debug $LINENO "CMD:expect ${pd_path}/oem_cmd.exp ${ivm_ip} ${ivm_user} "" "varyonvg ${vg_name}" 2>&1 "
        vg_chvgu=$(expect ${pd_path}/oem_cmd.exp ${ivm_ip} ${ivm_user} "" "varyonvg ${vg_name}" 2>&1)
        log_debug $LINENO "vg_chvgu=${vg_chvgu}"
        
        log_debug $LINENO "CMD:expect ${pd_path}/oem_cmd.exp ${ivm_ip} ${ivm_user} "" "lsvg ${vg_name}" ${out_time} 2>&1 "
        vg_info=$(expect ${pd_path}/oem_cmd.exp ${ivm_ip} ${ivm_user} "" "lsvg ${vg_name}" ${out_time} 2>&1)
        log_debug $LINENO "vg_info=${vg_info}"
        
		lock_vg=$(echo "${vg_info}" | grep locked)
		off_vg=$(echo "${vg_info}" | grep "use varyonvg command")
        
        if [ "${off_vg}" != "" ] || [ "${lock_vg}" != "" ] 
        then
    		echo "error:${vg_name} status had locked or vgoff ,please try cmd:chvg -u -vgname,auto add surplus hdisk to vgname">>${error_log}
        fi
fi

}


nfs_server_check()
{
# nfs_server_check 172.24.23.39 padmin

ivm_ip=$1
ivm_user=$2
pd_path='/powerdirector/tomcat/webapps/ROOT/shellscripts'
# check NFS Server proce status
nfs_check()
{
j=0
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} "lssrc -g nfs | grep -E 'biod|nfsd|rpc.mountd|rpc.statd|rpc.lockd' " "
nfs_status=$(ssh ${ivm_user}@${ivm_ip} "lssrc -g nfs | grep -E 'biod|nfsd|rpc.mountd|rpc.statd|rpc.lockd' ")
log_debug $LINENO "nfs_status=${nfs_status}"

echo "${nfs_status}" | awk '{print $1,$4}' | while read nfs_name nfs_sta
do
        if [ "${nfs_name}" == "biod" ] || [ "${nfs_name}" == "nfsd" ] || [ "${nfs_name}" == "rpc.mountd" ] || [ "${nfs_name}" == "rpc.statd" ] || [ "${nfs_name}" == "rpc.lockd" ] 
        then
	        if [ "${nfs_sta}" == "active" ] 
	        then
	                j=$((j+1))
	        fi
        fi
done
}

nfs_check
if [ "${j}" -ne "5" ] 
then
		log_debug $LINENO "CMD:expect ${pd_path}/oem_cmd.exp ${ivm_ip} ${ivm_user} "" "stopsrc -g nfs" "
        stop_nfs=$(expect ${pd_path}/oem_cmd.exp ${ivm_ip} ${ivm_user} "" "stopsrc -g nfs")
        log_debug $LINENO "stop_nfs=${stop_nfs}"
        
        sleep 10
        log_debug $LINENO "CMD:expect ${pd_path}/oem_cmd.exp ${ivm_ip} ${ivm_user} "" "startsrc -g nfs" "
        start_nfs=$(expect ${pd_path}/oem_cmd.exp ${ivm_ip} ${ivm_user} "" "startsrc -g nfs")
		log_debug $LINENO "start_nfs=${start_nfs}"
		
        nfs_check
        if [ "${j}" -ne "5" ] 
        then
                echo "error:NFS Server restart fail not 5 proc start " >> ${error_log}
        fi
fi
}


check_authorized()
{
# /powerdirector/tomcat/webapps/ROOT/shellscripts/check_authorized.sh '172.24.23.10' 'padmin'
        ipaddr=$1
        user=$2
        passwd=$3
		if [ "${passwd}" == "" ] 
		then
			passwd=$(java -Djava.ext.dirs="/powerdirector/tomcat/webapps/ROOT/WEB-INF/lib:/usr/java7_64/jre/lib/ext" -cp /powerdirector/tomcat/webapps/ROOT/WEB-INF/classes com.teamsun.pc.web.common.utils.MutualTrustSupport ${ipaddr} 2>/dev/null)
		fi
    	# echo "passwd= ${passwd}"     
        pd_path='/powerdirector/tomcat/webapps/ROOT/shellscripts'
        # error log and out log
        # DateNow=$(date +%Y%m%d%H%M%S)
        # random=$(perl -e 'my $random = int(rand(9999)); print "$random";')
        #out_log="out_registKey_${DateNow}_${random}.log"
#error out
        catchException() {    
                error_result=$(cat $1)
        }
        
# ping net status
        ping -c 3 $ipaddr > /dev/null 2>&1
        if [ "$(echo $?)" != "0" ] 
        then
                echo "$ipaddr unable to connect." >>${out_log}
                exit 1
        fi

# check authorized use error password
        pwd_cmd=$(expect $pd_path/cmd_line.exp $ipaddr $user "##3@@4#432sdf_werji##" "pwd" 2>/dev/null)
        pwd_grep=$(echo "${pwd_cmd}"| grep 'home/padmin')
        
# authorized is wrong
    if [ "${pwd_grep}" == "" ] 
    then
        # echo "$ipaddr no trust ,start check every trust"
        # local /.ssh status
        loc_ssh=$(ls -la ~/ | grep '\.ssh' | awk '{print substr($1,2)}')
        if [ "$loc_ssh" != "" ] 
        then
                if [ "$loc_ssh" == "rwx------" ] 
                then
                        sign[0]=0
                else
                        chmod 700 ~/.ssh 2>&1
                        sign[0]=0
                fi
        else
                pwd_cmd=$(expect $pd_path/cmd_line.exp $ipaddr $user $passwd "pwd" 2>/dev/null)
                pwd_grep=$(echo "${pwd_cmd}"| grep 'home/padmin')
                if [ "$pwd_grep" == "" ] 
                then
                        sign[0]=1
                else
                        sign[0]=0
                fi
        fi
        # echo " local id_dsa status"
        dsa_info=$(ls -l ~/.ssh/id_dsa 2>/dev/null)
        if [ "$?" -eq "0" ] 
        then
                id_dsa=$(echo "${dsa_info}" | awk '{print $1}' )
                if [ "$id_dsa" == "-rw-------" ] 
                then
                        sign[1]=0
                else
                        chmod 600 ~/.ssh/id_dsa 2>&1
                        sign[1]=0
                fi
        else
                rm -rf ~/.ssh/id_dsa* 2>&1
                known_host=$(ssh-keygen -t dsa -f //.ssh/id_dsa -q -N "")
                if [ "$?" -ne "0" ] 
                then
                        sign[1]=1
                else
                        sign[1]=0
                fi
        fi
                        
        # echo " local id_dsa.pub status"
        pub_info=$(ls -l ~/.ssh/id_dsa.pub 2>/dev/null)
        if [ "$?" -eq "0" ] 
        then
                pub=$(echo "{pub_info}" | awk '{print $1}')
                if [ "$pub" == "-rw-r--r--" ] 
                then
                        sign[1]=0
                else
                        chmod 644 ~/.ssh/id_dsa.pub 2>&1
                        sign[1]=0
                fi
        else
                known_host=$((sleep 2;echo "y")|ssh-keygen -t dsa -f //.ssh/id_dsa -q -N "")
                if [ "$?" -ne "0" ] 
                then
                        sign[1]=1
                else
                        sign[1]=0
                        # keys_pub=$(cat ~/.ssh/id_dsa.pub)
                fi
        fi
        keys_pub=$(cat ~/.ssh/id_dsa.pub)
        # echo " local known_hosts status"
        known_info=$(ls -l ~/.ssh/known_hosts 2>/dev/null)
        if [ "$?" -eq "0" ] 
        then
                known=$(echo "${known_info}" | awk '{print $1}')
                if [ "$known" == "-rw-r--r--" ] 
                then
                        sign[2]=0
                else
                        chmod 644 ~/.ssh/known_hosts
                fi

                known_host=$(cat ~/.ssh/known_hosts | sed -e '/'$ipaddr'/d')
        else    
                pwd_cmd=$(expect $pd_path/cmd_line.exp $ipaddr $user $passwd "pwd" 2>/dev/null)
                pwd_grep=$(echo "${pwd_cmd}"| grep 'home/padmin')
                if [ "$pwd_grep" == "" ] 
                then
                        sign[2]=1
                else
                        sign[2]=0
                fi
        fi
                
        # echo " local ssh config file"
        sshconfig=$(cat /etc/ssh/sshd_config|grep -E 'RSAAuthentication|PubkeyAuthentication' | grep -E -v '^#.*RSAAuthentication|^#.*PubkeyAuthentication')
        if [ "$sshconfig" != "" ] 
        then
                sshconfig=$(cat /etc/ssh/sshd_config| sed 's/^RSAAuthentication/#RSAAuthentication/g' | sed 's/^PubkeyAuthentication/#PubkeyAuthentication/g')
                echo "$sshconfig" > /etc/ssh/sshd_config
                if [ "$?" -ne "0" ] 
                then
                        sign[3]=1
                else
                        sign[3]=0
                fi
        else
                sign[3]=0
        fi

        # echo " check remote ~/.ssh dir weather exits"
        re_ssh=$(expect $pd_path/cmd_line.exp $ipaddr $user $passwd "ls -la ~/" 2>/dev/null)
        ssh_grep=$(echo ${re_ssh} |grep -E "\.ssh" | grep -v grep | awk '{print substr($1,2)}')
        if [ "$ssh_grep" != "" ] 
        then
                if [ "$ssh_grep" != "rwxr-xr-x" ] 
                then
                        re_ssh=$(expect $pd_path/oem_cmd.exp $ipaddr $user $passwd "chmod 755 ~/.ssh" 2>/dev/null)
                        if [ "$?" -ne "0" ] 
                        then
                                sign[4]=1
                        else
                                sign[4]=0
                        fi
                else
                        sign[4]=0
                fi
        else
                sign[4]=1
                re_ssh=$(expect $pd_path/oem_cmd.exp $ipaddr $user $passwd "mkdir -m 755 ~/.ssh " 2>/dev/null)
                if [ "$?" -ne "0" ] 
                then
                        sign[4]=1
                else
                        sign[4]=0
                fi
        fi
        
        # echo " remote .ssh authorized_key2 file"
        re_keys2=$(expect $pd_path/cmd_line.exp $ipaddr $user $passwd "ls -la ~/.ssh/authorized_keys2" 2>/dev/null)
        keys2_grep=$(echo "$re_keys2" | grep authorized_keys2 |grep -v "ls" | awk '{print substr($1,2)}')
        if [ "$keys2_grep" != "" ] 
        then
                if [ "$keys2_grep" != "rw-r--r--" ] 
                then
                        re_keys2=$(expect $pd_path/oem_cmd.exp $ipaddr $user $passwd "chmod 644 ~/.ssh/authorized_keys2 " 2>/dev/null)
                        if [ "$?" -ne "0" ] 
                        then
                                sign[5]=1
                        else
                                sign[5]=0
                        fi
                else
                        sign[5]=0
                fi
        else
                re_keys2=$(expect $pd_path/oem_cmd.exp $ipaddr $user $passwd "touch ~/.ssh/authorized_keys2 ;chmod 644 ~/.ssh/authorized_keys2 " 2>/dev/null)
                if [ "$?" -ne "0" ] 
                then
                        sign[5]=1
                else
                sign[5]=0
                fi
        fi

        # rebuild authorized use registSSHKey.exp
		log_debug $LINENO "CMD:expect "$pd_path"/registSSHKey_v2.0.exp "$ipaddr" "$user" "$passwd" "${keys_pub}" 2>/dev/null"
    	expect "$pd_path"/registSSHKey_v2.0.exp "$ipaddr" "$user" "$passwd" "${keys_pub}" 2>/dev/null
    	# log_debug $LINENO "rebuild_ssh=${rebuild_ssh}"

	fi
}


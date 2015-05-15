#!/usr/bin/ksh
#usage: viosinfoCollect.sh -u <ivm_user> -i <ivm_ip> -l <log_tar_filename>
# viosinfoCollect.sh -i 172.24.23.31 -u padmin -l cmdlog.tar


while   getopts  u:i:l:  opt
do
  case  "$opt"   in
  u)   	ivm_user=$OPTARG;;
		#echo  "found  the -u option, with  the value :$OPTARG" ;;

  i)   	ivm_ip=$OPTARG;;
		#echo  "found  the -i option ,with  the value :$OPTARG " ;;
  l)   	tar_file=$OPTARG;;
		#echo  "found  the -l option ,with  the value :$OPTARG " ;;		
  esac
done


configfile_noexist()
{
	echo "command config file does not exist."
	exit 1
}


ioscli_file="commands.ioscli"
if [ ! -f  "$ioscli_file" ]
then
    configfile_noexist
fi

noioscli_file="commands.noioscli"
if [ ! -f  "$noioscli_file" ]
then
    configfile_noexist
fi

DateNow=$(date +%Y%m%d%H%M%S)
out_log="out_viosinfoCollect_${DateNow}.log"
error_log="error_viosinfoCollect_${DateNow}.log"

######################################################################################
######                                                                           #####
######                           check ip :local or remote                       #####
######                                                                           #####
######################################################################################

ips=$(ifconfig -a | grep -w 'inet'| grep -v '127.0.0.1' | awk '{ print $2}' )
ip_num=$(echo "$ips" | wc -l)
if [ "${ivm_ip}" == "" ]
then
	isLocal="true"	
	ivm_ip=$(echo "$ips" | head -1 )
	ivm_user="padmin"
else
	current_ip_num=0
	for ip in `echo $ips`
	do
		current_ip_num=$( expr $current_ip_num + 1 )
		#echo "current_ip_num is:" $current_ip_num
		#echo $ip	
		if [ "$ip" == "${ivm_ip}" ]
		then
			isLocal="true"
			#echo "isLocal---:$isLocal"
			break
		else	
			isLocal="false"
			#echo "isLocal+++:$isLocal"
			continue
		fi	
	done
fi
#if [ $current_ip_num -eq ${ip_num} ]
#then
#	isLocal="false"
#fi	

######################################################################################
######                                                                           #####
######                            vios info function                             #####
######                                                                           #####
######################################################################################



common_cmd_info_ioscli_remote()
{	
	cmd=$1
	echo "======================"
	echo "[${ivm_user}] execute command [$cmd] on ${ivm_ip} at $DateNow"	
	#ouput=$(echo "`$1`")	
	ouput=$(ssh ${ivm_user}@${ivm_ip} "ioscli ${cmd} " )
	if [ `echo $?` -eq 0 ]
	then
		#if exec cmd successful, echo ouput of cmd."
		echo "Success: output is:"
		#echo "======================"
		echo "\t[$ouput]" 	
		echo "======================"
	else
		#if exec cmd failed,echo Warning."
		echo "Warning: [${ivm_user}] execute command [$cmd] failed on ${ivm_ip} at $DateNow"
	fi

}

common_cmd_info_noioscli_remote()
{	
	cmd=$1
	echo "======================"
	echo "[${ivm_user}] execute command [$cmd] on ${ivm_ip} at $DateNow"	
	#ouput=$(echo "`$1`")	
	ouput=$(ssh ${ivm_user}@${ivm_ip} "${cmd} " )
	if [ `echo $?` -eq 0 ]
	then
		#if exec cmd successful, echo ouput of cmd."
		echo "Success: output is:"
		#echo "======================"
		echo "\t[$ouput]" 	
		echo "======================"
	else
		#if exec cmd failed,echo Warning."
		echo "Warning: [${ivm_user}] execute command [$cmd] failed on ${ivm_ip} at $DateNow"
	fi

}

common_cmd_info_ioscli_local()
{	
	cmd=$1
	echo "======================"
	echo "[${ivm_user}] execute command [$cmd] on ${ivm_ip} at $DateNow"	
	#ouput=$(echo "`$1`")	
	ouput=$(su - ${ivm_user} <<eof
	ioscli ${cmd}
<<eof	)	
	#echo "---ouput of $cmd","++$ouput++"
	if [ `echo $?` -eq 0 ]
	then
		#if exec cmd successful, echo ouput of cmd."
		echo "Success: output is:"
		echo "======================"
		echo "\t[$ouput]" 	
		echo "======================"
	else
		#if exec cmd failed,echo Warning."
		echo "Warning: [${ivm_user}] execute command [$cmd] failed on ${ivm_ip} at $DateNow" >> $error_log
	fi
	
	if [ "$ouput" == "" ]
	then
		echo "Warning: [${ivm_user}] execute command [$cmd] failed on ${ivm_ip} at $DateNow" >> $error_log
	fi

}

common_cmd_info_noioscli_local()
{	
	cmd=$1
	echo "======================"
	echo "[${ivm_user}] execute command [$cmd] on ${ivm_ip} at $DateNow"	
	#ouput=$(echo "`$1`")	
	ouput=$(su - ${ivm_user} <<eof
	${cmd}
<<eof	)	
	if [ `echo $?` -eq 0 ]
	then
		#if exec cmd successful, echo ouput of cmd."
		echo "Success: output is:"
		
		echo "\t[$ouput]\n" 	
		echo "======================"
	else
		#if exec cmd failed,echo Warning."
		echo "Warning: [${ivm_user}] execute command [$cmd] failed on ${ivm_ip} at $DateNow\n"
	fi

}

ethernet_cmd_info()
{
	devices=$(lsdev | grep "Ethernet Network" | grep Available | awk '{print $1}')
	for device in `echo "$devices"`
	do
		if [ "$device" == "lo0" ]
		then
			continue
		fi
		
		if [ "$isLocal" == "true" ]
		then
			common_cmd_info_ioscli_local "entstat $device"
		else
			common_cmd_info_ioscli_remote "entstat $device"
		fi
	
	done
}

storage_cmd_info()
{
		vgs=$(lsvg)
		for vg in `echo $vgs`
		do
			current_vg_info=$(lsvg $vg)
			echo "======================"
			echo "VG INFO: $current_vg_info"
			echo "======================"
			current_vg_lv=$(lsvg -l $vg)
			echo "======================"
			echo "LV INFO of VG $vg: \n"
			echo "$current_vg_lv"
			echo "======================"
			current_vg_pv=$(lsvg -p $vg)
			echo "======================"
			echo "PV INFO of VG $vg: \n"
			echo "$current_vg_pv"	
			echo "======================"
		
		done
}

sshkey_file_info()
{	
	user=$1
	files=$(ls ~$user/.ssh)
	for file in `echo $files`
	do
		if [ -f ~$user/.ssh/$file ]
		then
			echo "context of [ ~$user/.ssh/$file ] is :\n"
			cat ~$user/.ssh/$file 	
		fi
	done
}

file_tar()
{
	if [ "$tar_file" != "" ]
	then
		tar -cvf $tar_file $out_log $error_log
	fi
}


get_cmd_info()
{
	if [ "$isLocal" == "true" ]
	then
######################################################################################
######                                                                           #####
######                 common commands that    need ioscli                       #####
######                                                                           #####
######################################################################################
		while read command
		do
			common_cmd_info_ioscli_local "$command"
		done <commands.ioscli		
		
		
######################################################################################
######                                                                           #####
######                 common commands that  do not  need ioscli                 #####
######                                                                           #####
######################################################################################
		while read command
		do
			common_cmd_info_noioscli_local "$command"
		done <commands.noioscli

######################################################################################
######                                                                           #####
######                       commands that  need to loop                         #####
######                                                                           #####
######################################################################################
		##common_cmd_info_ioscli_local "entstat ent0" 			##loop for all devices 
		ethernet_cmd_info
		storage_cmd_info
	else
		while read command
		do
			common_cmd_info_ioscli_remote "$command"
		done <commands.ioscli		

		while read command
		do
			common_cmd_info_noioscli_remote "$command"
		done <commands.noioscli
		
		ethernet_cmd_info
		storage_cmd_info

	fi
}

######################################################################################
######                                                                           #####
######                            main function                                  #####
######                                                                           #####
######################################################################################

case $(uname -s) in
	AIX)
		get_cmd_info		 >$out_log    2>$error_log	
		file_tar            >/dev/null
		
		sshkey_file_info	root		>>$out_log    2>>$error_log
		sshkey_file_info	padmin		>>$out_log    2>>$error_log
		;;		
	Linux)
		get_cmd_info;;
	*BSD)
		get_cmd_info;;
	SunOS)
		get_cmd_info;;
	HP-UX)
		get_cmd_info;;
	*) echo "unknown";;
esac

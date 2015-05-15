#!/usr/bin/ksh

. ./ivm_function.sh
. ./run.conf

j=0
echo $1 |awk -F"|" '{for(i=1;i<=NF;i++) print $i}' | while read param
do
        case $j in
			0)
					j=1;
					ivm_ip=$param;;
			1)
					j=2;        
					ivm_user=$param;;
			2)
					j=3;
					lpar_id=$param;;
			3)
					j=4;
					lpar_user=$param;;
			4)
					j=5;
					lpar_user_passwd=$param;;		
			5)
					j=6;
					server_xml_path=$param;;
			6)
					j=7;
					server_name=$param;;
			7)
					j=8;
					server_xml_name=$param;;
			8)
					j=9;
					back_file_name=$param;;
        esac
done

j=0
for nfs_info in $(echo $2 |awk -F"|" '{for(i=1;i<=NF;i++) print $i}')
do
	case $j in
		0)
				j=1;
				nfs_ip=$nfs_info;;
		1)
				j=2;        
				nfs_name=$nfs_info;;
		2)
				j=3;
				nfs_passwd=$nfs_info;;
		3)
				j=4;
				nfs_path=$nfs_info;;
	esac
done

DateNow=$(date +%Y%m%d%H%M%S)
random=$(perl -e 'my $random = int(rand(9999)); print "$random";')
cdrom_path="/var/vio/VMLibrary"
server_xml_iso_name="server_xml_"$DateNow"_"$random

if [ "$script_path" == "" ]
then
	script_path="/usr/auto-deploy"
fi

#####################################################################################
#####                                                                           #####
#####                          		 mount nfs	                                #####
#####                                                                           #####
#####################################################################################
mount_nfs


#####################################################################################
#####                                                                           #####
#####                  get virtual_scsi_adapters server id                      #####
#####                                                                           #####
#####################################################################################
server_vscsi_id=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r prof --filter lpar_ids=${lpar_id} -F virtual_scsi_adapters" 2>&1)
if [ $? -ne 0 ]
then
	unmount_nfs
	echo "$server_vscsi_id" >&2
	exit 1
fi
server_vscsi_id=$(echo $server_vscsi_id | awk -F"/" '{print $5}')

#####################################################################################
#####                                                                           #####
#####                            get vios' adapter                              #####
#####                                                                           #####
#####################################################################################
vadapter_vios=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -all -fmt :" 2>&1)
if [ $? -ne 0 ]
then
	unmount_nfs
	echo "$vadapter_vios" >&2
	exit 1
fi
vadapter_vios=$(echo "$vadapter_vios" | grep "C${server_vscsi_id}:" | awk -F":" '{print $1}')

######################################################################################
######                                                                           #####
######                          get virtual cdrom                             	 #####
######                                                                           #####
######################################################################################
vadapter_vcd=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -vadapter ${vadapter_vios} -field vtd " 2>&1)
if [ $? -ne 0 ]
then
	unmount_nfs
	echo "$vadapter_vcd" >&2
	exit 1
fi
vadapter_vcd=$(echo "$vadapter_vcd" | grep -i vtopt | head -1 | awk '{print $2}')

if [ "$vadapter_vcd" == "" ]
then
	vadapter_vcd=$(ssh ${ivm_user}@${ivm_ip} "ioscli mkvdev -fbo -vadapter ${vadapter_vios}" 2>&1)
	if [ $? -ne 0 ]
	then
		unmount_nfs
		echo "$vadapter_vcd" >&2
		exit 1
	fi
	vadapter_vcd=$(echo "$vadapter_vcd" | awk '{print $1}')
fi


#####################################################################################
#####                                                                           #####
#####                             	create iso                                	#####
#####                                                                           #####
#####################################################################################
result=$(expect ./ssh.exp ${ivm_user} ${ivm_ip} "oem_setup_env|mkisofs -r -o ${cdrom_path}/$server_xml_iso_name $template_path/$server_xml_path/$server_xml_name" 2>&1)
if [ $? -ne 0 ]
then
	unmount_nfs
	echo "$result" >&2
	exit 1
fi

#####################################################################################
#####                                                                           #####
#####                                mount iso                                	#####
#####                                                                           #####
#####################################################################################
mount_result=$(ssh ${ivm_user}@${ivm_ip} "ioscli loadopt -f -release -disk ${server_xml_iso_name} -vtd ${vadapter_vcd}" 2>&1)
if [ $? -ne 0 ]
then
	expect ./ssh.exp ${ivm_user} ${ivm_ip} "oem_setup_env|rm -f ${cdrom_path}/$server_xml_iso_name" > /dev/null 2>&1
	unmount_nfs
	echo "$mount_result" >&2
	exit 1
fi

#####################################################################################
#####                                                                           #####
#####                         	deploy apps	 		                       	    #####
#####                                                                           #####
#####################################################################################
result=$(./exec_script.exp "$ivm_user|$ivm_ip|$lpar_id|$lpar_user|$lpar_user_passwd|600" "$script_path" "liberty_upload_server_xml.sh,$server_name,$server_xml_name,$back_file_name" 2>&1)
flag=$?
if [ $flag -ne 0 ]
then
	case $flag in
		1)
			unmount_nfs
			expect ./ssh.exp ${ivm_user} ${ivm_ip} "oem_setup_env|rm -f ${cdrom_path}/$server_xml_iso_name" > /dev/null 2>&1
			echo "Login timeout." >&2
			exit 1;;
		99)
			unmount_nfs
			expect ./ssh.exp ${ivm_user} ${ivm_ip} "oem_setup_env|rm -f ${cdrom_path}/$server_xml_iso_name" > /dev/null 2>&1
			echo "Login incorrect." >&2
			exit 99;;
		*)
			error=$(echo "$result" | tr -d '\r')
			if [ "$(echo "$error" | grep "ERROR|")" != "" ]
			then
				error=$(echo "$error" | sed -n '/ERROR|/,$p')
				echo "$error" | while read line
				do
					if [ "$(echo "$line" | grep "|")" != "" ]
					then
						echo $(echo "$line" | awk -F"|" '{print $2}') >&2
					else
						if [ "$(echo "${line}" | grep "${lpar_user}@")" == "" ]
						then
							echo $(echo "${line}" | grep -v "${lpar_user}@") >&2
						fi
					fi
				done
				expect ./ssh.exp ${ivm_user} ${ivm_ip} "oem_setup_env|rm -f ${cdrom_path}/$server_xml_iso_name" > /dev/null 2>&1
				unmount_nfs
				exit 10
			fi
			;;
	esac
fi

#####################################################################################
#####                                                                           #####
#####                          		 mount nfs	                                #####
#####                                                                           #####
#####################################################################################
unmount_nfs

expect ./ssh.exp ${ivm_user} ${ivm_ip} "oem_setup_env|rm -f ${cdrom_path}/$server_xml_iso_name" > /dev/null 2>&1

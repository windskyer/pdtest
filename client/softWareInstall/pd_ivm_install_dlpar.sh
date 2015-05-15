#!/usr/bin/ksh

. ./run.conf

get_param_info() {
	j=0
	echo $param_info |awk -F"|" '{for(i=1;i<=NF;i++) print $i}' | while read param
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
						template_name=$param;;
				6)
						j=7;
						iso_name=$param;;
				7)
						j=8;
						software_name=$param;;
				8)
						j=9;
						software_ver=$param;;
				9)
						j=10;
						template_name1=$param;;
				10)
						j=11;
						iso_name1=$param;;
			esac
	done
}

check_result() {
	if [ $1 -ne 0 ]
	then
		echo "result==$result"
		case $1 in
			1)
				echo "Login timeout." >&2
				exit 1;;
			99)
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
					exit 10
				fi
				;;
		esac
	fi
}

mount_iso() {
	get_param_info $param_info
	
	if [ $3 -eq "1" ]
	then
		#echo "./ivm_mount_iso_v2.0.sh \"$ivm_ip|$ivm_user|$lpar_id||$template_name|$iso_name\" \"$nfs_info\" 2>&1"
		result=$(./ivm_mount_iso_v2.0.sh "$ivm_ip|$ivm_user|$lpar_id||$template_name|$iso_name" "$nfs_info" 2>&1)
		if [ "$(echo "$result" | grep ERROR)" != "" ]
		then
			error=$(echo "$result" | sed -n '/ERROR/,$p' | grep -Ev '\$|#')
			echo "$error" | awk -F":" '{print $2}' >&2
		fi
	else
		template_name=$template_name1
		iso_name=$iso_name1
		#echo "./ivm_mount_iso_v2.0.sh \"$ivm_ip|$ivm_user|$lpar_id||$template_name|$iso_name\" \"$nfs_info\" 2>&1"
		result=$(./ivm_mount_iso_v2.0.sh "$ivm_ip|$ivm_user|$lpar_id||$template_name|$iso_name" "$nfs_info" 2>&1)
		if [ "$(echo "$result" | grep ERROR)" != "" ]
		then
			error=$(echo "$result" | sed -n '/ERROR/,$p' | grep -Ev '\$|#')
			echo "$error" | awk -F":" '{print $2}' >&2
		fi
	fi
}

install() {
	get_param_info $param_info
	install_flag=$2
	
	#echo "./exec_script.exp \"$ivm_user|$ivm_ip|$lpar_id|$lpar_user|$lpar_user_passwd|600\" \"$script_path\" \"dlpar_install.sh,$script_path,$install_flag\" 2>&1"
	result=$(./exec_script.exp "$ivm_user|$ivm_ip|$lpar_id|$lpar_user|$lpar_user_passwd|600" "$script_path" "dlpar_install.sh,$script_path,$install_flag," 2>&1)
	#echo "result==$result"
	flag=$?
	#echo "install()::flag==$flag"
	check_result $flag
}

mount_step() {
	#echo "mount_iso dlpar iso"
	mount_iso $param_info $nfs_info 1
	if [ $? -ne 0 ]
	then
		echo "mount dlpar iso fail"
		exit 1
	fi
	
	install $param_info 1
	if [ $? -ne 0 ]
	then
		echo "cope dlpar iso fail"
		exit 1
	fi
	
	#echo "mount_iso linux iso"
	mount_iso $param_info $nfs_info 2
	if [ $? -ne 0 ]
	then
		echo "mount linux iso fail"
		exit 1
	fi

	install $param_info 2
	if [ $? -ne 0 ]
	then
		echo "install dlpar fail"
		exit 1
	fi
}

install_dlpar() {
	get_param_info $param_info
	
	result=$(./exec_script.exp "$ivm_user|$ivm_ip|$lpar_id|$lpar_user|$lpar_user_passwd|10" "$script_path" "get_os_info.sh,$script_path" 2>&1)
	flag=$?
	check_result $flag
	
	result=$(echo "$result" | tr -d '\r')

	os_id=$(echo "$result" | grep "^os_id" | awk -F"=" '{print $2}')
	os_release=$(echo "$result" | grep "^os_release" | awk -F"=" '{print $2}')
	#echo "install_dlpar()::os_id==$os_id,os_release==$os_release"
	
	is_redhat=$(echo "$os_id" | tr '[A-Z]' '[a-z]' | grep redhat)
	is_suse=$(echo "$os_id" | tr '[A-Z]' '[a-z]' | grep suse)
	if [ "$is_redhat" != "" -o "$is_suse" != "" ]
	then
		mount_step $param_info $nfs_info
	else
		echo "Is not supported on this operating system to install software."
		exit 1
	fi
}

DateNow=$(date +%Y%m%d%H%M%S)
random=$(perl -e 'my $random = int(rand(9999)); print "$random";')
if [ "$script_path" == "" ]
then
	script_path="/usr/auto-deploy"
fi

#172.30.126.12|padmin|4|root|root|wsdlpar|new_suse_dlpar.iso|dlpar||SUSE_11_sp2_ppc_dvd|SLES-11-SP2-DVD-ppc64-GM-DVD1.iso.1
param_info=$1
#172.30.126.13|root|teamsun|/template/
nfs_info=$2

install_dlpar $param_info $nfs_info
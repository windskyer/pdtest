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
						software_name=$param;;
				6)
						j=7;
						software_ver=$param;;
			esac
	done
}

check_result() {
	flag=$1
	if [ $flag -ne 0 ]
	then
		case $flag in
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

uninstall_dlpar() {
	get_param_info $param_info
	result=$(./exec_script.exp "$ivm_user|$ivm_ip|$lpar_id|$lpar_user|$lpar_user_passwd|600" "$script_path" "dlpar_uninstall.sh,$script_path" 2>&1)
	flag=$?
	check_result $flag
}

DateNow=$(date +%Y%m%d%H%M%S)
random=$(perl -e 'my $random = int(rand(9999)); print "$random";')
if [ "$script_path" == "" ]
then
	script_path="/usr/auto-deploy"
fi

param_info=$1
uninstall_dlpar $param_info $script_path
#!/usr/bin/ksh

. ./run.conf

check_result() {
	flag=$1
	if [ $flag -ne 0 ]
	then
		# echo "result==$result"
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
					url_scripts=$param;;
			6)
					j=7;
					copy_flag=$param;;
		esac
done

DateNow=$(date +%Y%m%d%H%M%S)
random=$(perl -e 'my $random = int(rand(9999)); print "$random";')
if [ "$script_path" == "" ]
then
	script_path="/usr/auto-deploy"
fi
scripts_tar_name=${url_scripts##*/}
scripts_tar_name=${scripts_tar_name%.*}

if [ "$copy_flag" == "1" ]
then
	if [ "$url_scripts" == "" -o "$scripts_tar_name" == "" ]
	then
		echo "The URL of scripts is invalid."
		exit 10
	fi

	result=$(./exec_copy_script.exp "$ivm_user|$ivm_ip|$lpar_id|$lpar_user|$lpar_user_passwd|$url_scripts|$scripts_tar_name|$script_path" 2>&1)
	flag=$?
	check_result $flag
else
	#echo "./exec_script.exp \"$ivm_user|$ivm_ip|$lpar_id|$lpar_user|$lpar_user_passwd|10\" \"$script_path\" \"get_os_info.sh,\""
	result=$(./exec_script.exp "$ivm_user|$ivm_ip|$lpar_id|$lpar_user|$lpar_user_passwd|10" "$script_path" "get_os_info.sh," 2>&1)
	flag=$?
	check_result $flag
fi

result=$(echo "$result" | tr -d '\r')

os_id=$(echo "$result" | grep "^os_id" | awk -F"=" '{print $2}')
os_release=$(echo "$result" | grep "^os_release" | awk -F"=" '{print $2}')

is_redhat=$(echo "$os_id" | tr '[A-Z]' '[a-z]' | grep redhat)
if [ "$is_redhat" != "" ]
then
	#####################################################################################
	#####                                                                           #####
	#####                             yum config	 	                       	    #####
	#####                                                                           #####
	#####################################################################################
	result=$(./exec_script.exp "$ivm_user|$ivm_ip|$lpar_id|$lpar_user|$lpar_user_passwd|10" "$script_path" "yum_config.sh," 2>&1)
	flag=$?
	check_result $flag
fi

echo "{\"os_id\":\"$os_id\", \"os_release\":\"$os_release\"}"

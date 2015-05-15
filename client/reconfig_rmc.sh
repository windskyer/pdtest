#!/usr/bin/ksh
# ./reconfig_rmc.sh "172.24.23.38|padmin|2|root|teamsun"

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
		esac
done
command=" /usr/sbin/rsct/install/bin/recfgct"


DateNow=$(date +%Y%m%d%H%M%S)
random=$(perl -e 'my $random = int(rand(9999)); print "$random";')

result=$(expect reconfig_rmc.exp "$ivm_ip|$ivm_user|$lpar_id|$lpar_user|$lpar_user_passwd" "$command")
flag=$?
check_result $flag


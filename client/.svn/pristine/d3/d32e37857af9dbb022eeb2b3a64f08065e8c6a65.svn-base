#!/usr/bin/ksh

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
        esac
done



DateNow=$(date +%Y%m%d%H%M%S)
random=$(perl -e 'my $random = int(rand(9999)); print "$random";')
java_bin_name="ibm-java-sdk-7.0-5.0-ppc64-archive.bin"
liberty_jar_name="wlp-developers-runtime-.*.jar:techpreview.jar"

if [ "$script_path" == "" ]
then
	script_path="/usr/auto-deploy"
fi

#####################################################################################
#####                                                                           #####
#####                         	  mount iso 		                       	    #####
#####                                                                           #####
#####################################################################################
result=$(./ivm_mount_iso_v2.0.sh "$ivm_ip|$ivm_user|$lpar_id||$template_name|$iso_name" "$2" 2>&1)
if [ "$(echo "$result" | grep ERROR)" != "" ]
then
	error=$(echo "$result" | sed -n '/ERROR/,$p' | grep -Ev '\$|#')
	# throwException "$error" "109001"
	echo "$error" | awk -F":" '{print $2}' >&2
	exit 1
fi

#####################################################################################
#####                                                                           #####
#####                         	install java 		                       	    #####
#####                                                                           #####
#####################################################################################
echo "./exec_script.exp \"$ivm_user|$ivm_ip|$lpar_id|$lpar_user|$lpar_user_passwd|600\" \"$script_path\" \"liberty_install_java.sh,$java_bin_name\""
result=$(./exec_script.exp "$ivm_user|$ivm_ip|$lpar_id|$lpar_user|$lpar_user_passwd|600" "$script_path" "liberty_install_java.sh,$java_bin_name" 2>&1)
flag=$?
echo "result==$result"
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


#####################################################################################
#####                                                                           #####
#####                         install software 		                       	    #####
#####                                                                           #####
#####################################################################################
echo "./exec_script.exp \"$ivm_user|$ivm_ip|$lpar_id|$lpar_user|$lpar_user_passwd|600\" \"$script_path\" \"liberty_install.sh,$script_path $liberty_jar_name\""
result=$(./exec_script.exp "$ivm_user|$ivm_ip|$lpar_id|$lpar_user|$lpar_user_passwd|600" "$script_path" "liberty_install.sh,$script_path $liberty_jar_name" 2>&1)
flag=$?
echo "result==$result"
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
#!/usr/bin/ksh

aix_getinfo() {
	i=0
	echo "[\c"
	while [ $i -lt $length ]
	do
		echo "{\c"
		echo "\"host_id\":\"${host_id[$i]}\", \c"
		echo "\"host_name\":\"${host_name[$i]}\"\c"
		echo "}\c"
		
		i=$(expr $i + 1)
		if [ "$i" != "$length" ]
		then
			echo ", \c"
		fi
	done
	echo "]"
}

linux_getinfo() {
	i=0
	echo -e "[\c"
	while [ $i -lt $length ]
	do
		echo -e "{\c"
		echo -e "\"host_id\":\"${host_id[$i]}\", \c"
		echo -e "\"host_name\":\"${host_name[$i]}\"\c"
		echo -e "}\c"
		
		i=$(expr $i + 1)
		if [ "$i" != "$length" ]
		then
			echo -e ", \c"
		fi
	done
	echo "]"
}

hmc_ip=$1
hmc_user=$2
hmc_passwd=$3

result=$(expect ./ssh_password.exp ${hmc_ip} ${hmc_user} ${hmc_passwd} "lssyscfg -r sys -F name,type_model,serial_num,state|echo \$?|exit" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	echo "Get host information failure." >&2
	exit 1
fi

if [ "$(echo "$result" | grep "Permission denied")" != "" ]||[ $(echo "$result" | grep "assword:" | wc -l | awk '{print $1}') -gt 1 ]
then
	echo "Permission denied" >&2
	exit 1
fi
# echo "result==$result"

# exe_judge=$(echo "$result" | sed -n '/'"echo \$?"'/,/'$hmc_user'/p')

exe_judge=$(echo "$result" | sed -n '/'"echo \$?"'/,/'$hmc_user'/p' | grep -v "echo \$?" | grep -v $hmc_user | awk '{print substr($0,0,length($0)-1)}')
exe_result=$(echo "$result" | sed -n '/'"lssyscfg -r sys"'/,/'$hmc_user'/p' | grep -v "lssyscfg -r sys" | grep -v $hmc_user | awk '{print substr($0,0,length($0)-1)}')
# echo "exe_judge==$exe_judge"
# echo "exe_result==$exe_result"
if [ "$exe_judge" != "0" ]
then
	echo "$exe_result" >&2
	exit 1
fi

# echo "exe_result==$exe_result"

length=0
if [ "$exe_result" != "" ]
then
	for host_info in $exe_result
	do
		if [ "$host_info" == "" ]
		then
			continue
		fi
		if [ "$(echo $host_info | awk -F"," '{print $4}')" == "Operating" ]
		then
			host_name[$length]=$(echo $host_info | awk -F"," '{print $1}')
			host_id[$length]=$(echo $host_info | awk -F"," '{print $2"*"$3}')
			
			# echo "host_name[$length]==${host_name[$length]}===================================================================="
			
			result=$(expect ./ssh_password.exp ${hmc_ip} ${hmc_user} ${hmc_passwd} "lssyscfg -m ${host_name[$length]} -r lpar -F lpar_id,lpar_env,state|echo \$?|exit" 2>&1)
			if [ "$(echo $?)" != "0" ]
			then
				echo "Get host information failure." >&2
				exit 1
			fi
			# echo "result===$result"
			
			exe_judge=$(echo "$result" | sed -n '/'"echo \$?"'/,/'$hmc_user'/p' | grep -v "echo \$?" | grep -v $hmc_user | awk '{print substr($0,0,length($0)-1)}')
			exe_hmc_result=$(echo "$result" | sed -n '/'"lssyscfg"'/,/'$hmc_user'/p' | grep -v "lssyscfg" | grep -v $hmc_user | awk '{print substr($0,0,length($0)-1)}')
			
			# echo "exe_judge==$exe_judge"
			# echo "exe_hmc_result==$exe_hmc_result"
			
			if [ "$exe_judge" != "0" ]
			then
				echo "$exe_hmc_result" >&2
				exit 1
			fi
			
			vios_info=$(echo "$exe_hmc_result" | awk -F"," '{if($2=="vioserver") printf $1","}' | awk '{print substr($0,0,length($0)-1)}')
			vios_num=$(echo "$vios_info" | awk -F"," '{print NF}')
			
			vios_run=$(echo "$exe_hmc_result" | awk -F"," '{if($2=="vioserver" && $3=="Running") printf $1","}' | awk '{print substr($0,0,length($0)-1)}')
			vios_run_num=$(echo "$vios_run" | awk -F"," '{print NF}')
			# echo "vios_info==$vios_info"
			# echo "vios_num==$vios_num"
			
			if [ $vios_num -gt 2 ]||[ "$vios_info" == "" ]||[ "$vios_num" != "$vios_run_num" ]
			then
				continue
			fi
			
			if [ "$vios_num" == "2" ]
			then
				flag_num=0
				for vios_id in $(echo "$vios_info" | awk -F"," '{for(i=1;i<=NF;i++) print $i}')
				do
					# echo "vios_id==$vios_id"
					sea_info=$(expect ./ssh_password.exp ${hmc_ip} ${hmc_user} ${hmc_passwd} "viosvrcmd -m ${host_name[$length]} --id $vios_id -c \"lsdev -type sea -field name -fmt :\"|echo \$?|exit")
					if [ "$(echo $?)" != "0" ]
					then
						echo "Get host information failure." >&2
						exit 1
					fi
					# echo "sea_info==$sea_info"
					exe_judge=$(echo "$sea_info" | sed -n '/'"echo \$?"'/,/'$hmc_user'/p' | grep -v "echo \$?" | grep -v $hmc_user | awk '{print substr($0,0,length($0)-1)}')
					sea_info=$(echo "$sea_info" | sed -n '/'"viosvrcmd"'/,/'$hmc_user'/p' | grep -v "viosvrcmd" | grep -v $hmc_user | awk '{print substr($0,0,length($0)-1)}')
					
					# echo "exe_judge==$exe_judge"
					# echo "sea_info==$sea_info"
					
					if [ "$exe_judge" != "0" ]
					then
						echo "$sea_info" >&2
						exit 1
					fi
					
					for sea in $sea_info
					do
						# active_flag=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $host_id --id $vios_id -c \"lsdev -dev $sea -attr ha_mode\"" | grep -v ^$ | grep -v value)
						# if [ "$active_flag" == "auto" ]
						# then
						flag=$(expect ./ssh_password.exp ${hmc_ip} ${hmc_user} ${hmc_passwd} "viosvrcmd -m ${host_name[$length]} --id $vios_id -c \"entstat -all $sea\"|echo \$?|exit" 2>&1)
						# echo "flag==$flag"
						exe_judge=$(echo "$flag" | sed -n '/'"echo \$?"'/,/'$hmc_user'/p' | grep -v "echo \$?" | grep -v $hmc_user | awk '{print substr($0,0,length($0)-1)}')
						flag=$(echo "$flag" | sed -n '/'"viosvrcmd"'/,/'$hmc_user'/p' | grep -v "viosvrcmd" | grep -v $hmc_user | awk '{print substr($0,0,length($0)-1)}')
						
						# echo "exe_judge==$exe_judge"
						# echo "flag==$flag"
						
						flag=$(echo "$flag" | grep Active | awk '{print $4}')
						# echo "flag==$flag"
						if [ "$flag" == "True" ]
						then
							active=1
							flag_num=$(expr $flag_num + 1)
							break
						fi
						# fi
					done
				done
				# echo "flag_num===$flag_num"
				if [ $flag_num -ge 2 ]||[ $flag_num -le 0 ]
				then
					continue
				fi
			fi
			length=$(expr $length + 1)
		fi
	done
fi


case $(uname -s) in
	AIX)
		aix_getinfo;;
	Linux)
		linux_getinfo;;
	*BSD)
		bsd_getinfo;;
	SunOS)
		sun_getinfo;;
	HP-UX)
		hp_getinfo;;
	*) echo "unknown";;
esac



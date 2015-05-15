#!/usr/bin/ksh

hmc_ip=$1
hmc_user=$2
managed_system=$3
vios_id=$4
vg_name=$5

if [ "$vg_name" != "" ]
then
	err=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $managed_system --id $vios_id -c \"lsvg $vg_name\"" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		echo "$err" >&2
		exit 1
	fi
fi

if [ "$vg_name" == "" ]
then
	vg_name_list=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $managed_system --id $vios_id -c \"oem_setup_env && lsvg -o\"" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		echo "$vg_name_list" >&2
		exit 1
	fi
else
	vg_name_list=$vg_name
fi

vg_length=0

if [ "$vg_name_list" != "" ]
then
	for vg in $vg_name_list
	do
		if [ "$vg" == "rootvg" ]
		then                 
			vg_info=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $managed_system --id $vios_id -c \"lsvg $vg -field vgstate vgid maxlvs numlvs totalpvs totalpps freepps usedpps pppervg maxpvs ppperpv -fmt :\"")
		else
			vg_info=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $managed_system --id $vios_id -c \"lsvg $vg -field vgstate vgid maxlvs numlvs totalpvs totalpps freepps usedpps pppervg maxpvs -fmt :\"")
		fi
		
		vg_lvs=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $managed_system --id $vios_id -c \"lsvg -lv $vg -field lvname -fmt :\"")

		name[$vg_length]=$vg
		ppsize[$vg_length]=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $managed_system --id $vios_id -c \"lsvg $vg\"" | grep "PP SIZE" | awk '{print $6}' | sed 's/ //g')
		state[$vg_length]=$(echo "$vg_info" | awk -F":" '{print $1}')
		vgid[$vg_length]=$(echo "$vg_info" | awk -F":" '{print $2}')
		maxlvs[$vg_length]=$(echo "$vg_info" | awk -F":" '{print $3}')
		numlvs[$vg_length]=$(echo "$vg_info" | awk -F":" '{print $4}')
		totalpvs[$vg_length]=$(echo "$vg_info" | awk -F":" '{print $5}')
		totalpps[$vg_length]=$(echo "$vg_info" | awk -F":" '{print $6}' | sed 's/(//g' | awk '{print $2}')
		freepps[$vg_length]=$(echo "$vg_info" | awk -F":" '{print $7}' | sed 's/(//g' | awk '{print $2}')
		usedpps[$vg_length]=$(echo "$vg_info" | awk -F":" '{print $8}' | sed 's/(//g' | awk '{print $2}')
		pppervg[$vg_length]=$(echo "$vg_info" | awk -F":" '{print $9}')
		maxpvs[$vg_length]=$(echo "$vg_info" | awk -F":" '{print $10}')
		ppperpv[$vg_length]=$(echo "$vg_info" | awk -F":" '{print $11}')
	
		if [ "$vg_lvs" != "" ]
		then
			lvs_num[$vg_length]=$(echo "$vg_lvs" | wc -l | sed 's/ //g')
			lv_name_list=$(echo "$vg_lvs" | grep -v $vg | grep -v "LV NAME")
			if [ "${lvs_num[$vg_length]}" != "0" ]
			then
				for lv in $lv_name_list
				do
					lv_info[$vg_length]=$(ssh ${hmc_user}@${hmc_ip} "viosvrcmd -m $managed_system --id $vios_id -c \"lslv $lv -field lvname maxlps ppsize pps -fmt :\"")"|"${lv_info[$vg_length]}
				done
				lv_info[$vg_length]=$(echo "${lv_info[$vg_length]}" | awk '{print substr($0,0,length($0)-1)}')
			fi
		fi
		vg_length=$(expr $vg_length + 1)
	done
else
	echo "[]"
	exit 1
fi

aix_getinfo() {
	i=0
	echo "[\c"
	if [ "$vg_length" != "0" ]
	then
		while [ $i -lt $vg_length ]
		do
			echo "{\c"
			echo "\"name\":\"${name[$i]}\", \c"
			echo "\"ppsize\":\"${ppsize[$i]}\", \c"
			echo "\"state\":\"${state[$i]}\", \c"
			echo "\"vgid\":\"${vgid[$i]}\", \c"
			echo "\"maxlvs\":\"${maxlvs[$i]}\", \c"
			echo "\"totalpvs\":\"${totalpvs[$i]}\", \c"
			echo "\"totalpps\":\"${totalpps[$i]}\", \c"
			echo "\"freepps\":\"${freepps[$i]}\", \c"
			echo "\"usedpps\":\"${usedpps[$i]}\", \c"
			echo "\"pppervg\":\"${pppervg[$i]}\", \c"
			echo "\"ppperpv\":\"${ppperpv[$i]}\", \c"
			echo "\"maxpvs\":\"${maxpvs[$i]}\", \c"
			echo "\"lv\":\c"
			echo "[\c"
			j=0
			if [ "${lv_info[$i]}" != "" ]
			then
				echo "${lv_info[$i]}" | awk -F"|" '{for(i=1;i<=NF;i++) print $i}' | while read lv
				do
					echo "{\c"
					echo "\"lv_name\":\"$(echo $lv | awk -F":" '{print $1}')\", \c"
					echo "\"lv_max_lps\":\"$(echo $lv | awk -F":" '{print $2}')\", \c"
					echo "\"lv_ppsize\":\"$(echo $lv | awk -F":" '{print $3}' | awk '{print $1}' | sed 's/ //g')\", \c"
					echo "\"lv_pps\":\"$(echo $lv | awk -F":" '{print $4}')\"\c"
					echo "}\c"
					j=$(expr $j + 1)
					if [ "$j" != "${lvs_num[$i]}" ]
					then
						echo ", \c"
					fi
				done
			fi
			echo "]\c"
			echo "}\c"
			i=$(expr $i + 1)
			if [ "$i" != "$vg_length" ]
			then
				echo ", \c"
			fi
		done
	fi
	echo "]"
}

linux_getinfo() {
	i=0
	echo -e "[\c"
	if [ "$vg_length" != "0" ]
	then
		while [ $i -lt $vg_length ]
		do
			echo -e "{\c"
			echo -e "\"name\":\"${name[$i]}\", \c"
			echo -e "\"ppsize\":\"${ppsize[$i]}\", \c"
			echo -e "\"state\":\"${state[$i]}\", \c"
			echo -e "\"vgid\":\"${vgid[$i]}\", \c"
			echo -e "\"maxlvs\":\"${maxlvs[$i]}\", \c"
			echo -e "\"totalpvs\":\"${totalpvs[$i]}\", \c"
			echo -e "\"totalpps\":\"${totalpps[$i]}\", \c"
			echo -e "\"freepps\":\"${freepps[$i]}\", \c"
			echo -e "\"usedpps\":\"${usedpps[$i]}\", \c"
			echo -e "\"pppervg\":\"${pppervg[$i]}\", \c"
			echo -e "\"ppperpv\":\"${ppperpv[$i]}\", \c"
			echo -e "\"maxpvs\":\"${maxpvs[$i]}\", \c"
			echo -e "\"lv\":\c"
			echo -e "[\c"
			j=0
			if [ "${lv_info[$i]}" != "" ]
			then
				echo "${lv_info[$i]}" | awk -F"|" '{for(i=1;i<=NF;i++) print $i}' | while read lv
				do
					echo -e "{\c"
					echo -e "\"lv_name\":\"$(echo $lv | awk -F":" '{print $1}')\", \c"
					echo -e "\"lv_max_lps\":\"$(echo $lv | awk -F":" '{print $2}')\", \c"
					echo -e "\"lv_ppsize\":\"$(echo $lv | awk -F":" '{print $3}' | awk '{print $1}' | sed 's/ //g')\", \c"
					echo -e "\"lv_pps\":\"$(echo $lv | awk -F":" '{print $4}')\"\c"
					echo -e "}\c"
					j=$(expr $j + 1)
					if [ "$j" != "${lvs_num[$i]}" ]
					then
						echo -e ", \c"
					fi
				done
			fi
			echo -e "]\c"
			echo -e "}\c"
			i=$(expr $i + 1)
			if [ "$i" != "$vg_length" ]
			then
				echo -e ", \c"
			fi
		done
	fi
	echo -e "]"
}


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
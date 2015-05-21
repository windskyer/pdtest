#!/usr/bin/ksh
debug=0

. ../ivm_function.sh

pd_error() {

       err=$1
	error_code=$2
	echo "0|0|ERROR-${err}: ${error_code}"
	exit 1

}

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

get_vg_info() {
	ivm_ip=$1
	ivm_user=$2
	vg_name=$3

	if [ "$vg_name" == "" ]
	then
		ret=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsvg" 2>&1)
		if [ "$(echo $?)" != "0" ]
		then
			pd_error "Get VG error" "1000055"
		fi
	else
		ret=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsvg |grep ${vg_name}" 2>&1)
		if [ "$(echo $?)" != "0" ]
		then
			pd_error "Get VG error" "1000056"
		fi
	fi

	echo $ret
	vg_name_list=$ret
	vg_length=0
	if [ "$vg_name_list" != "" ]
	then
		for vg in $(echo ${vg_name_list})
		do
			if [ "$vg" == "rootvg" ]
			then                 
				vg_info=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsvg $vg -field vgstate vgid maxlvs numlvs totalpvs totalpps freepps usedpps pppervg maxpvs ppperpv -fmt :" | head -n 1)
			else
				vg_info=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsvg $vg -field vgstate vgid maxlvs numlvs totalpvs totalpps freepps usedpps pppervg maxpvs -fmt :" | head -n 1)
			fi
			
			vg_lvs=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsvg -lv $vg -field lvname -fmt :")

			name[$vg_length]=$vg
			ppsize[$vg_length]=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsvg $vg" | grep "PP SIZE" | awk '{print $6}' | sed 's/ //g')
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
			
			lvs_num[$vg_length]=0
			if [ "$vg_lvs" != "" ]
			then
				lv_name_list=$(echo "$vg_lvs" | grep -v $vg | grep -v "LV NAME")
				for lv in $lv_name_list
				do
					if [ "$lv" == "VMLibrary" ]
					then
						continue
					fi
					lv_info[$vg_length]=$(ssh ${ivm_user}@${ivm_ip} "ioscli lslv $lv -field lvname maxlps ppsize pps -fmt :" 2> /dev/null)"|"${lv_info[$vg_length]}
					lvs_num[$vg_length]=$(expr ${lvs_num[$vg_length]} + 1)
				done
				lv_info[$vg_length]=$(echo "${lv_info[$vg_length]}" | awk '{print substr($0,0,length($0)-1)}')
				
			fi
			vg_length=$(expr $vg_length + 1)
		done
	else
		echo "[]"
		exit 1
	fi

	case $(uname -s) in
		AIX)
	    aix_getinfo;;
	  Linux)
	    linux_getinfo;;

	esac

}


vgm_create_vg () {
	
	ivm_user=$1
	ivm_ip=$2
	vgname=$3
	ppsize=$4
	vgpvsstr=$5
	
	ret=$(ssh ${ivm_user}@${ivm_ip} "ioscli mkvg -f -vg ${vgname} ${vgpvsstr}" 2>&1)

	if [ "$(echo $?)" != "0" ]
	then
		pd_error "Create vg error" "1000009"
	fi
}

add_vg_pv() {
	ivm_user=$2
	ivm_ip=$1
	vgname=$3
	vgaddpvsstr=$4

	addnode_ret=$(ssh ${ivm_user}@${ivm_ip} "ioscli extendvg ${vgname} ${vgaddpvsstr}" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		pd_error "$addnode_ret" "1000003"
	fi
}

del_vg_pv() {
	ivm_user=$2
	ivm_ip=$1
	vgname=$3
	vgdelpvsstr=$4
	log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli reducevg -rmlv -f ${vgname} ${vgdelpvsstr}\""
	del_ret=$(ssh ${ivm_user}@${ivm_ip} "ioscli reducevg -rmlv -f ${vgname} ${vgdelpvsstr}" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		pd_error "${del_ret}" "1000004"
	fi
	log_debug $LINENO "del_ret=${del_ret}"
}

lvm_create_lv()  {
	ivm_user=$1
	ivm_ip=$2
	vgname=$3
	lvname=$4
	lvsize=$5
	pvstr=$6

	ret=$(ssh ${ivm_user}@${ivm_ip} "ioscli mklv -lv $lvname ${vgname} ${lvsize} ${pvstr}" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		pd_error "$ret" "1000008"
	fi
}

lvm_rm_lv() {
	ivm_user=$1
	ivm_ip=$2
	vgname=$3
	lvstr=$4

	ret=$(ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lvstr}" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		pd_error "$ret" "1000030"
	fi
}

lvm_alter_lv() {
	ivm_user=$1
	ivm_ip=$2
	vgname=$3
	lvname=$4
	lv_newname=$5
	ret=$(ssh ${ivm_user}@${ivm_ip} "ioscli chlv -lv ${lv_newname} ${lvname}" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		pd_error "$ret" "1000033"
	fi
}

del_vg_param() {
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
						vgname=$param;;
			
	        esac
	done

	if [ "$ivm_ip" == "" -o "$ivm_user" == "" -o "$vgname" == "" ]
	then
		pd_error "param error" "100000"
	fi
	
	if [ $debug == 1 ]
	then
		echo $ivm_ip $ivm_user $vgname
	fi
}


ivm_vgm_del_vg() {

	del_vg_param $1
	
	
	check_authorized ${ivm_ip} ${ivm_user}
	
	log_info $LINENO "delete vg"
	log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli lsvg -pv ${vgname} -field PV_NAME -fmt ':'\""
	del_ret=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsvg -pv ${vgname} -field PV_NAME -fmt ':'" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		pd_error "Del vg error" "1000002"
	fi
	log_debug $LINENO "del_ret=${del_ret}"
	echo ${del_ret}|awk '{for(i=1;i<=NF;i++) print $i}'|while read param
	do
		del_vgs=${del_vgs}" "$param
	done
		
	del_vg_pv  $ivm_ip $ivm_user $vgname "${del_vgs}"
}

log_flag=$(cat ../scrpits.properties 2> /dev/null | grep "LOG=" | awk -F"=" '{print $2}')
if [ "$log_flag" == "" ]
then
	log_flag=0
fi

DateNow=$(date +%Y%m%d%H%M%S)
random=$(perl -e 'my $random = int(rand(9999)); print "$random";')
out_log="${path_log}/out_ivm_vgm_delete_vg_${DateNow}_${random}.log"
error_log="${path_log}/error_ivm_vgm_delete_vg_${DateNow}_${random}.log"

log_debug $LINENO "$0 $*"

ivm_vgm_del_vg $1
#ivm_vgm_del_vg '172.30.126.12|padmin|testvg'

if [ "$log_flag" == "0" ]
then
	rm -f "${error_log}" 2> /dev/null
	rm -f "$out_log" 2> /dev/null
fi

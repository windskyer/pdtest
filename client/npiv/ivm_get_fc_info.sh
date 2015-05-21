#!/usr/bin/ksh

. ../ivm_function.sh

aix_getinfo() {
i=0
echo "{\c"
echo "\"fcs\":\c"
echo "[\c"
if [ "$fc_length" != "0" ]
then
	while [ $i -lt $fc_length ]
	do
		echo "{\c"
		echo "\"name\":\"${fc_port[$i]}\", \c"
		echo "\"wwpn\":\"${fc_wwpn[$i]}\", \c"
		echo "\"speed\":\"${fc_speed[$i]}\", \c"
		echo "\"attach\":\"${fc_attach[$i]}\", \c"
		echo "\"physicalSlotNo\":\"${fc_phylocal[$i]}\", \c"
		echo "\"npiv\":\c"
		j=0
		if [ "$npiv_length" != "0" ]
		then
			is_npiv=0
			while [ $j -lt $npiv_length ]
			do
				if [ "${npiv_port[$j]}" == "${fc_port[$i]}" ]
				then
					is_npiv=1
					echo "{\c"
					echo "\"totalPorts\":\"${npiv_tports[$j]}\", \c"
					echo "\"availablePorts\":\"${npiv_aports[$j]}\" \c"
				fi
				j=$(expr $j + 1)
			done
			
			if [ "${is_npiv}" == "1" ]
			then
					echo "}\c"
			fi
			
			if [ "${is_npiv}" == "0" ]
			then
				echo "null\c"
			fi
		else
			echo "null\c"
		fi
		echo "}\c"
		i=$(expr $i + 1)
		if [ "$i" != "$fc_length" ]
		then
			echo ", \c"
		fi
	done
fi
echo "],\c"	

echo "\"vfcHost\":\c"
echo "[\c"
if [ "$vfchost_length" != "0" ]
then
	k=0
	g=0
	while [ $k -lt $vfchost_length ]
	do
		if [ "$lpar_id" != "" ]
		then
			if [ "$lpar_id" != "${vfchost_clientid[$k]}" ]
			then
				k=$(expr $k + 1)
				continue
			fi
		fi
		echo "{\c"
		echo "\"name\":\"${vfchost_name[$k]}\", \c"
		echo "\"status\":\"${vfchost_status[$k]}\", \c"
		echo "\"vPhysicalSlotNo\":\"${vfchost_physloc[$k]}\", \c"
		echo "\"vmId\":\"${vfchost_clientid[$k]}\", \c"
		vfchost_slot_num=$(echo "${vfchost_physloc[$k]}"|awk -F"-" '{print $3}'|sed 's/C//g')
		virtual_fc_adapters=$(ssh ${ivm_user}@${ivm_ip} lssyscfg -r prof --filter lpar_ids=${vfchost_clientid[$k]} -F virtual_fc_adapters 2> /dev/null)
		vfchost_vwwpn=$(echo "$virtual_fc_adapters"|awk -F"\",\"" '{for(i=1;i<=NF;i++) print $i}'|sed 's/"//g'| awk -F[/] '{if($5==slot_num) print $6}' slot_num=$vfchost_slot_num | awk -F"," '{print $1}')
		vfchost_client_slot_num=$(echo "$virtual_fc_adapters"|awk -F"\",\"" '{for(i=1;i<=NF;i++) print $i}'|sed 's/"//g'| awk -F[/] '{if($5==slot_num) print $1}' slot_num=$vfchost_slot_num)
		echo "\"SlotNo\":\"$vfchost_client_slot_num\", \c"
		echo "\"vWwpn\":\"$vfchost_vwwpn\", \c"
		echo "\"fcs\":\"${vfchost_fcport[$k]}\"\c"
		echo "}\c"
		g=$(expr $g + 1)
		if [ "$g" != "$vfchost_length" ]
		then
			echo ", \c"
		fi
		k=$(expr $k + 1)
	done
	
fi
echo "]\c"
echo "}"
}	

linux_getinfo() {
i=0
echo -e "{\c"
echo -e "\"fcs\":\c"
echo -e "[\c"
if [ "$fc_length" != "0" ]
then
	while [ $i -lt $fc_length ]
	do
		echo -e "{\c"
		echo -e "\"name\":\"${fc_port[$i]}\", \c"
		echo -e "\"wwpn\":\"${fc_wwpn[$i]}\", \c"
		echo -e "\"speed\":\"${fc_speed[$i]}\", \c"
		echo -e "\"attach\":\"${fc_attach[$i]}\", \c"
		echo -e "\"physicalSlotNo\":\"${fc_phylocal[$i]}\", \c"
		echo -e "\"npiv\":\c"
		j=0
		if [ "$npiv_length" != "0" ]
		then
			is_npiv=0
			while [ $j -lt $npiv_length ]
			do
				if [ "${npiv_port[$j]}" == "${fc_port[$i]}" ]
				then
					is_npiv=1
					echo -e "{\c"
					echo -e "\"totalPorts\":\"${npiv_tports[$j]}\", \c"
					echo -e "\"availablePorts\":\"${npiv_aports[$j]}\" \c"
				fi
				j=$(expr $j + 1)
			done
			
			if [ "${is_npiv}" == "1" ]
			then
					echo -e "}\c"
			fi
			
			if [ "${is_npiv}" == "0" ]
			then
				echo -e "null\c"
			fi
		else
			echo -e "null\c"
		fi
		echo -e "}\c"
		i=$(expr $i + 1)
		if [ "$i" != "$fc_length" ]
		then
			echo -e ", \c"
		fi
	done
fi
echo -e "],\c"	

echo -e "\"vfcHost\":\c"
echo -e "[\c"
if [ "$vfchost_length" != "0" ]
then
	k=0
	g=0
	while [ $k -lt $vfchost_length ]
	do
		if [ "$lpar_id" != "" ]
		then
			if [ "$lpar_id" != "${vfchost_clientid[$k]}" ]
			then
				k=$(expr $k + 1)
				continue
			fi
		fi
		echo -e "{\c"
		echo -e "\"name\":\"${vfchost_name[$k]}\", \c"
		echo -e "\"status\":\"${vfchost_status[$k]}\", \c"
		echo -e "\"vPhysicalSlotNo\":\"${vfchost_physloc[$k]}\", \c"
		echo -e "\"vmId\":\"${vfchost_clientid[$k]}\", \c"
		vfchost_slot_num=$(echo "${vfchost_physloc[$k]}"|awk -F"-" '{print $3}'|sed 's/C//g')
		virtual_fc_adapters=$(ssh ${ivm_user}@${ivm_ip} lssyscfg -r prof --filter lpar_ids=${vfchost_clientid[$k]} -F virtual_fc_adapters 2> /dev/null)
		vfchost_vwwpn=$(echo "$virtual_fc_adapters"|awk -F"\",\"" '{for(i=1;i<=NF;i++) print $i}'|sed 's/"//g'| awk -F[/] '{if($5==slot_num) print $6}' slot_num=$vfchost_slot_num | awk -F"," '{print $1}')
		vfchost_client_slot_num=$(echo "$virtual_fc_adapters"|awk -F"\",\"" '{for(i=1;i<=NF;i++) print $i}'|sed 's/"//g'| awk -F[/] '{if($5==slot_num) print $1}' slot_num=$vfchost_slot_num)
		echo -e "\"SlotNo\":\"$vfchost_client_slot_num\", \c"
		echo -e "\"vWwpn\":\"$vfchost_vwwpn\", \c"
		echo -e "\"fcs\":\"${vfchost_fcport[$k]}\"\c"
		echo -e "}\c"
		g=$(expr $g + 1)
		if [ "$g" != "$vfchost_length" ]
		then
			echo -e ", \c"
		fi
		k=$(expr $k + 1)
	done
	
fi
echo -e "]\c"
echo -e "}"
}


ivm_ip=$1
ivm_user=$2
lpar_id=$3


log_flag=$(cat ../scrpits.properties 2> /dev/null | grep "LOG=" | awk -F"=" '{print $2}')
if [ "$log_flag" == "" ]
then
	log_flag=0
fi

random=$(perl -e 'my $random = int(rand(9999)); print "$random";')
DateNow=$(date +%Y%m%d%H%M%S)
out_log="${path_log}/out_ivm_get_fc_info_${DateNow}_${random}.log"
error_log="${path_log}/error_ivm_get_fc_info_${DateNow}_${random}.log"

log_debug $LINENO "$0 $*"

check_authorized ${ivm_ip} ${ivm_user}

#####################################################################################
#####                                                                           #####
#####                       get NPIV port info                                  #####
#####                                                                           #####
#####################################################################################
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli lsnports -fmt :\""
vios_npiv_info=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsnports -fmt :" 2> /dev/null)
log_debug $LINENO "vios_npiv_info=${vios_npiv_info}"
npiv_length=0
if [ "${vios_npiv_info}" != "" ]
then
	echo "$vios_npiv_info" | while read npiv_info
	do
		if [ "$npiv_info" != "" ]
		then
			npiv_port[${npiv_length}]=$(echo "$npiv_info" | awk -F":" '{print $1}')
			npiv_physloc[${npiv_length}]=$(echo "$npiv_info" | awk -F":" '{print $2}')
			npiv_tports[${npiv_length}]=$(echo "$npiv_info" | awk -F":" '{print $4}')
			npiv_aports[${npiv_length}]=$(echo "$npiv_info" | awk -F":" '{print $5}')
			npiv_swwpns[${npiv_length}]=$(echo "$npiv_info" | awk -F":" '{print $6}')
			npiv_awwpns[${npiv_length}]=$(echo "$npiv_info" | awk -F":" '{print $7}')
		fi
	npiv_length=$(expr $npiv_length + 1)
	done
fi

#####################################################################################
#####                                                                           #####
#####                       get vfchost port info                               #####
#####                                                                           #####
#####################################################################################
log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli lsmap -npiv -all -fmt :\""
vios_vfchost_info=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -npiv -all -fmt :" 2> /dev/null)
log_debug $LINENO "vios_vfchost_info=${vios_vfchost_info}"
if [ "${lpar_id}" == "" ]
then
	vfchost_length=0
	if [ "${vios_vfchost_info}" != "" ]
	then
		echo "$vios_vfchost_info" | while read vfchost_info
		do
			if [ "$vfchost_info" != "" ]
			then
				vfchost_name[${vfchost_length}]=$(echo "$vfchost_info" | awk -F":" '{print $1}')
				vfchost_physloc[${vfchost_length}]=$(echo "$vfchost_info" | awk -F":" '{print $2}')
				vfchost_clientid[${vfchost_length}]=$(echo "$vfchost_info" | awk -F":" '{print $3}')
				vfchost_clientname[${vfchost_length}]=$(echo "$vfchost_info" | awk -F":" '{print $4}')
				vfchost_status[${vfchost_length}]=$(echo "$vfchost_info" | awk -F":" '{print $6}')
				vfchost_fcport[${vfchost_length}]=$(echo "$vfchost_info" | awk -F":" '{print $7}')
				vfchost_fcphysloc[${vfchost_length}]=$(echo "$vfchost_info" | awk -F":" '{print $8}')
			fi
		vfchost_length=$(expr $vfchost_length + 1)
		done
	fi
else
	vfchost_length=0
	if [ "${vios_vfchost_info}" != "" ]
	then
		echo "$vios_vfchost_info" | while read vfchost_info
		do
			if [ $(echo "$vfchost_info"|awk -F":" '{print $3}') == "${lpar_id}" ]
			then
				vfchost_name[${vfchost_length}]=$(echo "$vfchost_info" | awk -F":" '{print $1}')
				vfchost_physloc[${vfchost_length}]=$(echo "$vfchost_info" | awk -F":" '{print $2}')
				vfchost_clientid[${vfchost_length}]=$(echo "$vfchost_info" | awk -F":" '{print $3}')
				vfchost_clientname[${vfchost_length}]=$(echo "$vfchost_info" | awk -F":" '{print $4}')
				vfchost_status[${vfchost_length}]=$(echo "$vfchost_info" | awk -F":" '{print $6}')
				vfchost_fcport[${vfchost_length}]=$(echo "$vfchost_info" | awk -F":" '{print $7}')
				vfchost_fcphysloc[${vfchost_length}]=$(echo "$vfchost_info" | awk -F":" '{print $8}')
				vfchost_length=$(expr $vfchost_length + 1)
			fi
		#vfchost_length=$(expr $vfchost_length + 1)
		done
	fi
fi


#####################################################################################
#####                                                                           #####
#####                       get fc info                                         #####
#####                                                                           #####
#####################################################################################
if [ "${lpar_id}" == "" ]
then
	log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli lsdev -dev fcs* -fmt :\"|awk -F":" '{print \$1}'"
	vios_fc_ports=$(ssh ${ivm_user}@${ivm_ip} ioscli lsdev -dev fcs* -fmt :|awk -F":" '{print $1}' 2> /dev/null)
	log_debug $LINENO "vios_fc_ports=${vios_fc_ports}"
	fc_length=0
	if [ "${vios_fc_ports}" != "" ]
	then
		for fc_ports in ${vios_fc_ports}
		do
			if [ "$fc_ports" != "" ]
			then
				fc_port[${fc_length}]=${fc_ports}
				log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli lsdev -vpd -dev ${fc_ports}\""
				fc_detail=$(ssh ${ivm_user}@${ivm_ip} ioscli lsdev -vpd -dev ${fc_ports} 2> /dev/null)
				log_debug $LINENO "fc_detail=${fc_detail}"
				if [ "${fc_detail}" != "" ]
				then
					fc_wwpn[${fc_length}]=$(echo "$fc_detail"|grep "Network Address"|awk -F"." '{print $NF}' )
					fc_phylocal[${fc_length}]=$(echo "$fc_detail"|grep -w "${fc_ports}"|awk '{print $2}' )
					fc_speed[${fc_length}]=$(echo "$fc_detail"|grep -w "${fc_ports}"|awk '{print $3}' )
				fi
				fscsi_port=$(echo ${fc_ports}|sed 's/fcs/fscsi/')
				attach_result=$(expect ../ssh.exp ${ivm_user} ${ivm_ip} "oem_setup_env|lsattr -El ${fscsi_port}" 2>&1)
				log_debug $LINENO "attach_result=${attach_result}"
				fc_attach[${fc_length}]=$(echo "$result"|grep "attach"|awk '{print $2}')
			fi
		#echo "$fc_length ${fc_port[${fc_length}]} ${fc_wwpn[${fc_length}]} ${fc_phylocal[${fc_length}]} "
		fc_length=$(expr $fc_length + 1)
		done
	fi
else
	vios_fc_ports=$(echo ${vfchost_fcport[*]}|awk '{for(i=1;i<=NF;i++) print $i}'|sort|uniq)
	log_debug $LINENO "vios_fc_ports=${vios_fc_ports}"
	fc_length=0
	if [ "${vios_fc_ports}" != "" ]
	then
		for fc_ports in ${vios_fc_ports}
		do
			if [ "$fc_ports" != "" ]
			then
				fc_port[${fc_length}]=${fc_ports}
				log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli lsdev -vpd -dev ${fc_ports}\""
				fc_detail=$(ssh ${ivm_user}@${ivm_ip} ioscli lsdev -vpd -dev ${fc_ports} 2> /dev/null)
				if [ "${fc_detail}" != "" ]
				then
					fc_wwpn[${fc_length}]=$(echo "$fc_detail"|grep "Network Address"|awk -F"." '{print $NF}' )
					fc_phylocal[${fc_length}]=$(echo "$fc_detail"|grep -w "${fc_ports}"|awk '{print $2}' )
					fc_speed[${fc_length}]=$(echo "$fc_detail"|grep -w "${fc_ports}"|awk '{print $3}' )
				fi
			fi
		#echo "$fc_length ${fc_port[${fc_length}]} ${fc_wwpn[${fc_length}]} ${fc_phylocal[${fc_length}]} "
		fc_length=$(expr $fc_length + 1)
		done
	fi
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

if [ "$log_flag" == "0" ]
then
	rm -f "${error_log}" 2> /dev/null
	rm -f "$out_log" 2> /dev/null
fi

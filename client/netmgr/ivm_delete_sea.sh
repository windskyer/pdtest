#!/usr/bin/ksh
debug=0

. ../ivm_function.sh

pd_error() {

       err=$1
	error_code=$2
	echo "0|0|ERROR-${err}: ${error_code}"
	exit 1

}

create_sea () {
	
	ivm_user=$2
	ivm_ip=$1
	td=$3
	vea=$4
	dvea=$5
	pvid=$6
	
	seainfo=$(ssh ${ivm_user}@${ivm_ip} "ioscli mkvdev -sea $td -vadapter $vea -default $dvea -defaultid $pvid" 2>&1)

	if [ "$(echo $?)" != "0" ]
	then
		pd_error "$seainfo" "1000008"
	fi
	seaname=$(echo $seainfo|awk '{print $1}')	
	get_sea_info $ivm_ip $ivm_user $seaname
	show_sea_info
}

modify_ethernet_channel() {
	ivm_user=$2
	ivm_ip=$1
	ecname=$3
	mode=$4
	backupeth=$5
	eths=$6

	ecinfo=$(ssh ${ivm_user}@${ivm_ip} "ioscli chdev -dev ${ecname} -attr backup_adapter=$backupeth mode=${mode}" 2>&1)

	if [ "$(echo $?)" != "0" ]
	then
		pd_error "$seainfo" "1000009"
	fi
	get_lnagg_info ${ivm_ip} ${ivm_user} ${ecname}
	show_lnagg_info
}

create_ethernet_channel () {
	ivm_user=$2
	ivm_ip=$1
	mode=$3
	backupeth=$4
	eths=$5

	ecinfo=$(ssh ${ivm_user}@${ivm_ip} "ioscli mkvdev -lnagg ${eths} -attr backup_adapter=$backupeth mode=${mode}")

	if [ "$(echo $?)" != "0" ]
	then
		pd_error "$seainfo" "1000009"
	fi	
	ecname=$(echo $ecinfo|awk '{print $1}')
	get_lnagg_info ${ivm_ip} ${ivm_user} ${ecname}
	show_lnagg_info
}

get_sea_info() {
	ivm_ip=$1
	ivm_user=$2
	seaname=$3

	if [ "${seaname}" != "" ]
	then
		ret=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsdev -type sea -fmt ':'|grep ${seaname}" 2>&1)
	else
		ret=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsdev -type sea -fmt ':'" 2>&1)
	fi

	if [ "$(echo $?)" != "0" ]
	then
		pd_error "$ret" "1000606"
	fi
	#echo $ret
	
	seanum=0
       
	if [ "${ret}" != "" ]
        then
		echo "${ret}" | while read sea
		do
			seaname[$seanum]=$(echo $sea|awk -F':' '{print $1}')
			seastatus[$seanum]=$(echo $sea|awk -F':' '{print $2}')
			seatype[$seanum]=$(echo $sea|awk -F':' '{print $3}')
			
			seanum=$(expr $seanum + 1 )
		done
	fi

	i=0	
	while [ $i -lt $seanum ]
	do
		seapvid[$i]=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsdev -dev ${seaname[$i]} -attr pvid" | grep -v value | grep -v ^$)
		seadefualtVirtual[$i]=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsdev -dev ${seaname[$i]} -attr pvid_adapter" | grep -v value | grep -v ^$)
		seamemberPhysical[$i]=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsdev -dev ${seaname[$i]} -attr real_adapter" | grep -v value | grep -v ^$)
		seamemberVirtual[$i]=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsdev -dev ${seaname[$i]} -attr virt_adapters" | grep -v value | grep -v ^$)
		seaipseaname=$(echo ${seaname[$i]}|sed 's/t//g')
		seaipAddr[$i]=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsdev -dev ${seaipseaname} -attr netaddr" | grep -v value | grep -v ^$)		
		
		i=$(expr $i + 1 )
	done	
	
}

show_sea_info() {

	echo -e "["

	j=0
	while [ $j -lt $seanum ]
	do
	echo -e "{"
	echo -e "\"ethName\":\"${seaname[$j]}\","
	echo -e "\"ipAddr\":\"${seaipAddr[$j]}\","
	echo -e "\"defualtVirtual\":\"${seadefualtVirtual[$j]}\","
	echo -e "\"pvid\":\"${seapvid[$j]}\","
	echo -e "\"memberPhysical\":\"${seamemberPhysical[$j]}\","
	
	echo -e "\"memberVirtual\":["
	echo ${seamemberVirtual[$j]} | awk -F"," '{for(i=1;i<=NF;i++) {if(i<NF) {print $i "\"},"} else {print $i "\"}"}}}' | while read eth
	do
		echo -e "{"
		echo -e "\"ethName\":\"$eth"
	done
	echo -e "],"
	
	echo -e "\"status\":\"${seastatus[$j]}\""
	echo -e "}"

	j=$(expr $j + 1 ) 
	
	if [ $j != $seanum ]
	then
		echo -e ","
	fi
	done
	
	echo -e "]"
}

get_phyeth_info () {
	ivm_ip=$1
	ivm_user=$2

	#ret=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsdev -type ent4sea -fmt :| grep -v EtherChannel" 2>&1)
	ret=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsdev -fmt :|grep ent|grep -v EtherChannel|grep -v Virtual|grep -v Share" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		pd_error "$ret" "1000607"
	fi
	
	ent4seanum=0
       
	if [ "${ret}" != "" ]
        then
		echo "${ret}" | while read ent
		do
			ent4seaname[$ent4seanum]=$(echo $ent|awk -F':' '{print $1}')
			ent4seastatus[$ent4seanum]=$(echo $ent|awk -F':' '{print $2}')
			ent4seatype[$ent4seanum]=$(echo $ent|awk -F':' '{print $3}')
			
			ent4seanum=$(expr $ent4seanum + 1 )
		done
	fi

	i=0	
	while [ $i -lt $ent4seanum ]
	do
		ret=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsdev -dev ${ent4seaname[$i]} -vpd | grep 'Network Addres'")
		ent4sea_mac[$i]=${ret##*.}
		
		ret=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsdev -dev ${ent4seaname[$i]} -vpd | grep 'Hardware Location Code'")
		ent4sea_locationCode[$i]=${ret##*.}
		ent4sea_slot[$i]=$(echo $ent4sea_locationCode|awk -F'-' '{print $3}')
		i=$(expr $i + 1 )
	done		
}

show_phyeth_info() {



	echo -e "["

	j=0
	while [ $j -lt $ent4seanum ]
	do
	echo -e "{"
	echo -e "\"ethName\":\"${ent4seaname[$j]}\","
	echo -e "\"ethType\":\"${ent4seatype[$j]}\","
	echo -e "\"slotnum\":\"${ent4sea_slot[$j]}\","
	echo -e "\"locationCode\":\"${ent4sea_locationCode[$j]}\","
	echo -e "\"mac\":\"${ent4sea_mac[$j]}\","
	echo -e "\"status\":\"${ent4seastatus[$j]}\""
	echo -e "}"

	j=$(expr $j + 1 ) 
	
	if [ $j != $ent4seanum ]
	then
		echo -e ","
	fi
	done
	
	echo -e "]"

}

get_veth_info () {
	ivm_ip=$1
	ivm_user=$2

	vios_id=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar -F lpar_id,lpar_env" | grep 'vioserver' |awk -F',' '{print $1}' 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		pd_error "$ret" "1000601"
	fi

	
	eth_info=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r prof -F virtual_eth_adapters --filter lpar_ids=$vios_id" | sed 's/"//g' 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		pd_error "$ret" "1000609"
	fi

	j=0
	echo "$eth_info" | awk -F"," '{for(i=1;i<=NF;i++) print $i}' | while read eth
	do
		vethpvid[$j]=$(echo $eth | awk -F"/" '{print $3}')
		vethvid[$j]=$(echo $eth | awk -F"/" '{print $4}')
		vethslot[$j]=C$(echo $eth | awk -F"/" '{print $1}')
		vethtruck[$j]=$(echo $eth | awk -F"/" '{print $5}')
		vethieee[$j]=$(echo $eth | awk -F"/" '{print $2}')
		vethisreq[$j]=$(echo $eth | awk -F"/" '{print $6}')
		j=$(expr $j + 1)
	done
	vethnum=$j
	ret=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsdev -fmt :|grep ent|grep Virtual|grep -v Management" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		pd_error "$ret" "1000610"
	fi
	
	vent4seanum=0
       
	if [ "${ret}" != "" ]
        then
		echo "${ret}" | while read vent
		do
			vent4seaname[$vent4seanum]=$(echo $vent|awk -F':' '{print $1}')
			vent4seastatus[$vent4seanum]=$(echo $vent|awk -F':' '{print $2}')
			vent4seatype[$vent4seanum]=$(echo $vent|awk -F':' '{print $3}')
			
			vent4seanum=$(expr $vent4seanum + 1 )
		done
	fi

	i=0
	while [ $i -lt $vent4seanum ]
	do
		ret=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsdev -dev ${vent4seaname[$i]} -vpd | grep 'Hardware Location Code'")
		vent4sea_locationCode[$i]=${ret##*.}
		ret=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsdev -dev ${vent4seaname[$i]} -vpd | grep 'Network Addres'")
                vent4sea_mac[$i]=${ret##*.}

		ventslotnum[$i]=$(echo ${vent4sea_locationCode[$i]}|awk -F'-' '{print $3}')
		j=0
		while [ $j -lt $vethnum ]
		do
			if [ "${ventslotnum[$i]}" == "${vethslot[$j]}" ]
			then
				veth4seapvid[$i]=${vethpvid[$j]}
				veth4seavid[$i]=${vethvid[$j]}
				veth4seatruck[$i]=${vethtruck[$j]}
	
			fi
			j=$(expr $j + 1)		
		done	
	
		i=$(expr $i + 1)		
	done	
}

show_veth_info() {



	echo -e "["

	j=0
	while [ $j -lt $vent4seanum ]
	do
	echo -e "{"
	echo -e "\"truckMode\":\"${veth4seatruck[$j]}\","
	echo -e "\"ethName\":\"${vent4seaname[$j]}\","
	echo -e "\"slotNum\":\"${ventslotnum[$j]}\","
	echo -e "\"mac\":\"${vent4sea_mac[$j]}\","
	echo -e "\"ieeeCompatible\":\"${vethieeec[$j]}\","
	echo -e "\"isRequired\":\"${vethieeec[$j]}\","
	echo -e "\"locationCode\":\"${vethisreq[$j]}\","
	echo -e "\"pvid\":\"${veth4seapvid[$j]}\","
	echo -e "\"vids\":["


	echo ${veth4seavid[$j]} | awk -F"," '{for(i=1;i<=NF;i++) {if(i<NF) {print $i ","} else {print $i}}}' | while read eth
	do
		echo -e "\"ethName\":\"$eth"
	done
	echo "],"
	echo -e "\"status\":\"${vent4seastatus[$j]}\""
	echo -e "}"

	j=$(expr $j + 1 ) 
	
	if [ $j -lt $vent4seanum ]
	then
		echo -e ","
	fi
	done
	
	echo -e "]"

}

get_lnagg_info () {
	ivm_ip=$1
	ivm_user=$2
	ecname=$3
	if [ "${ecname}" != "" ]
	then 
		ret=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsdev |grep 'EtherChannel'|grep ${ecname}" 2>&1)
	else
		ret=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsdev |grep 'EtherChannel'" 2>&1)
	fi


#	if [ "$(echo $?)" != "0" ]
#	then
#		pd_error "$ret" "1000608"
#	fi
	
	lnaggnum=0
       
	if [ "${ret}" != "" ]
        then
		echo "${ret}" | while read ec
		do
			lnaggname[$lnaggnum]=$(echo $ec|awk '{print $1}')
			lnaggstatus[$lnaggnum]=$(echo $ec|awk '{print $2}')
			
			lnaggnum=$(expr $lnaggnum + 1 )
		done
	fi

	i=0
	while [ $i -lt $lnaggnum ]
	do
		combineMode[$i]=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsdev -dev ${lnaggname[$i]} -attr mode" | grep -v value | grep -v ^$)
		memberEth[$i]=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsdev -dev ${lnaggname[$i]} -attr adapter_names" | grep -v value | grep -v ^$)
		standbyEth[$i]=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsdev -dev ${lnaggname[$i]} -attr backup_adapter" | grep -v value | grep -v ^$)
		i=$(expr $i + 1)
	done
}

show_lnagg_info() {



	echo -e "["

	j=0
	while [ $j -lt $lnaggnum ]
	do
	echo -e "{"
	echo -e "\"combineMode\":\"${combineMode[$j]}\","
	echo -e "\"ethName\":\"${lnaggname[$j]}\","
	
	echo -e "\"memberEth\":["

        echo ${memberEth[$j]} | awk -F"," '{for(i=1;i<=NF;i++) {if(i<NF) {print $i "\"},"} else {print $i "\"}"}}}' | while read eth
        do
                echo -e "{"
                echo -e "\"ethName\":\"$eth"
        done

	echo -e "],"
	
	echo -e "\"standbyEth\":\"${standbyEth[$j]}\","
	echo -e "\"status\":\"${lnaggstatus[$j]}\""
	echo -e "}"

	j=$(expr $j + 1 ) 
	
	if [ $j != $lnaggnum ]
	then
		echo -e ","
	fi
	done
	
	echo -e "]"

}

net_manager_refresh () {
	ivm_user=$2
	ivm_ip=$1

	get_sea_info $ivm_ip $ivm_user
	get_phyeth_info $ivm_ip $ivm_user
	get_veth_info $ivm_ip $ivm_user
	get_lnagg_info $ivm_ip $ivm_user
echo "[{"
	echo -e "\"SEA\":"

show_sea_info
echo ","
	echo -e "\"physicalEth\":"
show_phyeth_info
echo ","
	echo -e "\"virtualEth\":"
show_veth_info
echo ","
	echo -e "\"EthChannel\":"
show_lnagg_info
echo "}]"	
}

modify_sea () {
	ivm_user=$2
	ivm_ip=$1
	seaname=$3
	td=$4
	vea=$5
	dvea=$6
	pvid=$7
	
	ret=$(ssh ${ivm_user}@${ivm_ip} "ioscli chdev -dev $seaname -attr virt_adapters=${vea}" 2>&1)

	if [ "$(echo $?)" != "0" ]
	then
		pd_error "$ret" "1000008"
	fi
}

rm_dev() {
	ivm_user=$2
	ivm_ip=$1
	devname=$3
	log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli rmdev -dev $devname -recursive\""
	ret=$(ssh ${ivm_user}@${ivm_ip} "ioscli rmdev -dev $devname -recursive" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		pd_error "$ret" "1000010"
	fi	
	log_debug $LINENO "ret=${ret}"
}



delete_sea_param() {
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
						devname=$param;;
			
	        esac
	done

	if [ "$ivm_ip" == "" -o "$ivm_user" == "" -o "$devname" == "" ]
	then
		pd_error "param error" "100000"
	fi
	
	if [ $debug == 1 ]
	then
		echo $ivm_ip $ivm_user $devname
	fi
}

delete_sea() {
	ivm_user=$2
	ivm_ip=$1
	devname=$3
	
	check_authorized ${ivm_ip} ${ivm_user}
	
	rm_dev $ivm_ip $ivm_user $devname
}

ivm_delete_sea() {

	delete_sea_param $1
	delete_sea $ivm_ip $ivm_user $devname
}

log_flag=$(cat ../scrpits.properties 2> /dev/null | grep "LOG=" | awk -F"=" '{print $2}')
if [ "$log_flag" == "" ]
then
	log_flag=0
fi

DateNow=$(date +%Y%m%d%H%M%S)
random=$(perl -e 'my $random = int(rand(9999)); print "$random";')
out_log="${path_log}/out_ivm_delete_sea_${DateNow}_${random}.log"
error_log="${path_log}/error_ivm_delete_sea_${DateNow}_${random}.log"

log_debug $LINENO "$0 $*"

ivm_delete_sea $1
#ivm_delete_sea '172.30.126.12|padmin|ent9'

if [ "$log_flag" == "0" ]
then
	rm -f "${error_log}" 2> /dev/null
	rm -f "$out_log" 2> /dev/null
fi

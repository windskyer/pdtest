#!/usr/bin/ksh
debug=0
. ../ivm_function.sh

cluster_error() {

       err=$1
	error_code=$2
	echo "0|0|ERROR-${err}: ${error_code}"
	exit 1

}

create_cluster () {
	
	ivm_user=$2
	ivm_ip=$1
	clustername=$3
	repopvs=$4
	spname=$5
	sppvsstr=$6
	hostname=$7
	
	echo ${ivm_user} ${ivm_ip} ${clustername} ${repopvs} ${spname} ${sppvsstr} ${hostname}
	cluster_ret=$(ssh ${ivm_user}@${ivm_ip} "ioscli cluster -create -clustername ${clustername} -repopvs ${repopvs} -spname ${spname} -sppvs ${sppvsstr} -hostname ${hostname}" 2>&1)

	if [ "$(echo $?)" != "0" ]
	then
		echo $cluster_ret
	fi
}

add_clusternode() {
	ivm_user=$2
	ivm_ip=$1
	clustername=$3
	hostname=$4

	addnode_ret=$(ssh ${ivm_user}@${ivm_ip} "ioscli cluster -addnode -clustername ${clustername} -hostname ${hostname}" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		cluster_error "Add cluster node error" "1000002"
	fi
}

rm_clusternode() {
	ivm_user=$2
	ivm_ip=$1
	clustername=$3
	hostname=$4

	addnode_ret=$(ssh ${ivm_user}@${ivm_ip} "ioscli cluster -rmnode -clustername ${clustername} -hostname ${hostname}" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		cluster_error "Add cluster node error" "1000002"
	fi
}

ssp_get_info() {
	ivm_user=$2
	ivm_ip=$1
	clustername=$3
	spname=$4

	ret=$(ssh ${ivm_user}@${ivm_ip} "ioscli lssp -clustername ${clustername} -field pool size free total overcommit lus type id -fmt ':'")
	#ret=$(ssh ${ivm_user}@${ivm_ip} "ioscli lssp -clustername ${clustername} -fmt ':'")
	if [ "$(echo $?)" != "0" ]
	then
		cluster_error "Ssp get info error" "1000503"
	fi

	
	cluster_poolname=$(echo $ret | awk -F ':' '{print $1}')
	cluster_poolsize=$(echo $ret | awk -F ':' '{print $2}')

	cluster_poolfree=$(echo $ret | awk -F ':' '{print $3}')
	cluster_totallusize=$(echo $ret | awk -F ':' '{print $4}')

	cluster_overcommit_size=$(echo $ret | awk -F ':' '{print $5}')
	cluster_totallus=$(echo $ret | awk -F ':' '{print $6}')

	cluster_pooltype=$(echo $ret | awk -F ':' '{print $7}')
	cluster_poolid=$(echo $ret | awk -F ':' '{print $8}')


	if  [ "${spname}" == "" ]
	then
		spname=${cluster_poolname}
	fi

	
	ret=$(ssh ${ivm_user}@${ivm_ip} "ioscli lspv | grep 'caavg_private'")
	if [ "$(echo $?)" != "0" ]
	then
		cluster_error "Ssp get info error" "1000103"
	fi

	cluster_metapvname=$(echo ${ret} | awk '{print $1}')
	cluster_metapvid=$(echo ${ret} | awk '{print $2}')
	cluster_metapvvg=$(echo ${ret} | awk '{print $3}')
	cluster_metapvstatus=$(echo ${ret} | awk '{print $4}')
	
	ret=$(ssh ${ivm_user}@${ivm_ip} "ioscli lspv -size | grep ${cluster_metapvname}")
	if [ "$(echo $?)" != "0" ]
	then
		cluster_error "Ssp get info error" "1000104"
	fi

	cluster_metapvsize=$(echo ${ret} | awk '{print $3}')
	
	ret=$(ssh ${ivm_user}@${ivm_ip} "ioscli lspv -clustername $clustername -sp $spname -state" | grep 'hdisk')
	if [ "$(echo $?)" != "0" ]
	then
		cluster_error "Ssp get info error" "1000105"
	fi

	cluster_pvnum=0
	echo "${ret}" | while read pv
	do
		cluster_pvname[$cluster_pvnum]=$(echo ${ret} | awk '{print $1}')
		cluster_pvsize[$cluster_pvnum]=$(echo ${ret} | awk '{print $2}')
		cluster_pvstate[$cluster_pvnum]=$(echo ${ret} | awk '{print $3}')
		cluster_pvudid[$cluster_pvnum]=$(echo ${ret} | awk '{print $4}')

		cluster_pvnum=$(expr $cluster_pvnum + 1 )

	done

	ret=$(ssh ${ivm_user}@${ivm_ip} "ioscli cluster -list -fmt ':'|grep ${clustername}")
	if [ "$(echo $?)" != "0" ]
	then
		cluster_error "Ssp get info error" "1000203"
	fi

	cluster_name=$(echo ${ret} | awk -F ':' '{print $1}')
	cluster_id=$(echo ${ret} | awk -F ':' '{print $2}')

	ret=$(ssh ${ivm_user}@${ivm_ip} "ioscli cluster -status -clustername ${clustername} -fmt ':'")
	if [ "$(echo $?)" != "0" ]
	then
		cluster_error "Ssp get info error" "1000303"
	fi

	cluster_nodenum=0
	echo "${ret}" | while read css
	do
		cluster_nodename[$cluster_nodenum]=$(echo $css | awk -F ':' '{print $3}')

		cluster_nodeip[$cluster_nodenum]=$(ssh ${ivm_user}@${ivm_ip} "cat /etc/hosts" | grep 'cluster_nodename[$cluster_nodenum]' | awk '{print $1}') 
		if [ "$(echo $?)" != "0" ]
		then
			cluster_error "Ssp get info error" "1000403"
		fi
		
		cluster_status[$cluster_nodenum]=$(echo $css | awk -F ':' '{print $2}')
		cluster_nodestatus[$cluster_nodenum]=$(echo $css | awk -F ':' '{print $6}')
		cluster_poolstatus[$cluster_nodenum]=$(echo $css | awk -F ':' '{print $7}')
		cluster_nodemtm[$cluster_nodenum]=$(echo $css | awk -F ':' '{print $4}')
		cluster_nodepn[$cluster_nodenum]=$(echo $css | awk -F ':' '{print $5}')
		
		cluster_nodenum=$(expr $cluster_nodenum + 1 )
	done

	ret=$(ssh ${ivm_user}@${ivm_ip} "ioscli lssp -clustername ${clustername} -sp ${spname} -bd -fmt ':'")
	if [ "$(echo $?)" != "0" ]
	then
		cluster_error "Ssp get info error" "1000603"
	fi
	
	cluster_lunum=0
	echo "${ret}" | while read lu
	do
		cluster_lu_name[$cluster_lunum]=$(echo $lu | awk -F ':' '{print $1}')
		cluster_lu_size[$cluster_lunum]=$(echo $lu | awk -F ':' '{print $2}')
		cluster_lu_ProvisionType[$cluster_lunum]=$(echo $lu | awk -F ':' '{print $3}')
		cluster_lu_used[$cluster_lunum]=$(echo $lu | awk -F ':' '{print $4}')
		cluster_lu_unused[$cluster_lunum]=$(echo $lu | awk -F ':' '{print $5}')
		cluster_lu_udid[$cluster_lunum]=$(echo $lu | awk -F ':' '{print $6}')
		
		cluster_lunum=$(expr $cluster_lunum + 1 )
	done


	echo "{\c"

	echo "\"metapv\":{\"hdiskName\":\"${cluster_metapvname}\",\"pvUniqueId\":\"${cluster_metapvid}\",\"size\":${cluster_metapvsize},\"state\":\"${cluster_metapvstatus}\"}"

	echo "\"nodes\":["
	i=0
	while [ $i -lt $cluster_nodenum ]
	do
	
	echo "{\"nodeIp\":\"${cluster_nodename[$i]}\",\"nodeName\":\"${cluster_nodename[$i]}\",\"partitionNum\":${cluster_nodepn[$i]},\"poolState\":\"${cluster_poolstatus[$i]}\",\"state\":\"${cluster_nodestatus[$i]}\"}"

	i=$(expr $i + 1 ) 
	
	if [ "$i" != "$cluster_nodenum" ]
	then
		echo ", \c"
	fi

	done
	echo "	],"

	
	echo "\"sspCluster\":{\"clusterid\":\"${cluster_id}\",\"clustername\":\"${cluster_name}\",\"clusterstate\":\"${cluster_status}\"},"

	echo "\"ssps\":[{\"clusterid\":\"${cluster_id}\",\"clustername\":\"${cluster_name}\",\"clusterstate\":\"${cluster_status}\",\"freespace\":${cluster_poolfree},"

	echo "\"lus\":["
	i=0
	while [ $i -lt $cluster_lunum ]
	do
	echo "{\"luname\":\"${cluster_lu_name[$i]}\",\"luudid\":\"${cluster_lu_udid[$i]}\",\"provisiontype\":\"${cluster_lu_ProvisionType[$i]}\",\"size\":${cluster_lu_size[$i]},\"unusedsize\":${cluster_lu_used[$i]}}"

	i=$(expr $i + 1 ) 
	
	if [ "$i" != "$cluster_nodenum" ]
	then
		echo ", \c"
	fi
	done
	
	echo "],\"overcommitsize\":0,"


	echo "\"pvs\":["
	i=0
	while [ $i -lt $cluster_pvnum ]
	do
	echo "{\"hdiskName\":\"${cluster_pvname[$i]}\",\"pvUniqueId\":\"${cluster_pvudid[$i]}\",\"size\":${cluster_pvsize[$i]},\"state\":\"${cluster_pvstate[$i]}\"}"
	i=$(expr $i + 1 ) 
	
	if [ "$i" != "$cluster_pvnum" ]
	then
		echo ", \c"
	fi
	done
	echo "],"

	echo "\"sspid\":\"${cluster_poolid}\",\"sspname\":\"${cluster_poolname}\",\"sspsize\":cluster_poolsize,\"ssptype\":\"${cluster_pooltype}\",\"totallus\":${cluster_totallus},\"totallusize\":${cluster_totallusize}"
	echo "}]"
	echo "}\c"

}

check_add_cluster_disk() {

	ivm_user=$1
	ivm_ip=$2
	clustername=$3
	diskname=$4
	log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli lspv -clustername ${clustername} -capable\""
	ret=$(ssh ${ivm_user}@${ivm_ip} "ioscli lspv -clustername ${clustername} -capable" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		cluster_error "Ssp get info error" "1000063"
	fi
	log_debug $LINENO "ret=${ret}"
	checkdisk=$(echo ${ret} | grep ${diskname})
	if [ "${checkdisk}" == "" ]
	then 
		cluster_error "check disk error" "1000035"
	fi
}


add_cluster_disk() {

	ivm_user=$1
	ivm_ip=$2
	clustername=$3
	spname=$4
	diskname=$5
	log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli chsp -add -clustername ${clustername} -sp ${spname} ${diskname}\""
	ret=$(ssh ${ivm_user}@${ivm_ip} "ioscli chsp -add -clustername ${clustername} -sp ${spname} ${diskname}" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		cluster_error "Ssp get info error" "1000006"
	fi
	log_debug $LINENO "ret=${ret}"
}

ssp_create_lu()  {
	ivm_user=$1
	ivm_ip=$2
	clustername=$3
	spname=$4
	lu_size=$5
	lu_name=$6
	lu_mode=$7
	lpar_id=$8

	ret=$(ssh ${ivm_user}@${ivm_ip} "ioscli mkbdsp -clustername ${clustername} -sp ${spname} ${lu_size} -bd ${lu_name} -${lu_mode}" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		cluster_error "Ssp get info error" "1000008"
	fi

	server_vscsi_id=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r prof --filter lpar_ids=${lpar_id} -F virtual_scsi_adapters" | awk -F'/' '{print $5}')

	vadapter_vios=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -all -fmt :" | grep "C${server_vscsi_id}:" | awk -F":" '{print $1}')
	
	ret=$(ssh ${ivm_user}@${ivm_ip} "ioscli mkbdsp -clustername ${clustername} -sp ${spname} -bd ${lu_name} -vadapter ${vadapter_vios}" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		cluster_error "Ssp get info error" "1000009"
	fi
}

ssp_rm_lu() {
	ivm_user=$1
	ivm_ip=$2
	clustername=$3
	spname=$4
	lu_name=$5

	ret=$(ssh ${ivm_user}@${ivm_ip} "ioscli rmbdsp -clustername ${clustername} -sp ${spname} -bd ${lu_name}" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		cluster_error "Ssp get info error" "1000030"
	fi
}

ssp_alter_lu() {
	ivm_user=$2
	ivm_ip=$1
	clustername=$3
	spname=$4
	lu_name=$5
	lu_newname=$6

	ret=$(ssh ${ivm_user}@${ivm_ip} "ioscli chbdsp -clustername ${clustername} -sp ${spname} -bd ${lu_name} -mv ${lu_newname}" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		cluster_error "Ssp get info error" "1000035"
	fi
}


adddisk_param() {
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
						clustername=$param;;
				3)
						j=4;
						spname=$param;;
				4)
						j=5;
						newdisk=$param
						disklen=0
						echo $newdisk | awk -F "," '{for(i=1;i<=NF;i++) print $i}' | while read param
						do
							newdisks[$disklen]=$param
							disklen=$(expr $disklen + 1 )
						done
						;;						
			
	        esac
	done

	if [ "$ivm_ip" == "" -o "$ivm_user" == "" -o "$clustername" == "" -o "$spname" == "" ]
	then
		cluster_error "param error" "100000"
	fi
	
	if [ $debug == 1 ]
	then
		echo $ivm_ip $ivm_user $clustername $spname ${newdisks[0]}
	fi
}


ivm_ssp_alter_add_disk() {

	adddisk_param $1
		
	i=0
	while [ $i -lt $disklen ]
	do
		check_add_cluster_disk ${ivm_user} ${ivm_ip} ${clustername} ${newdisks[$i]}
		i=$(expr $i + 1 )
	done

	i=0
	while [ $i -lt $disklen ]
	do
		add_cluster_disk  $ivm_user $ivm_ip $clustername ${spname} ${newdisks[$i]}
		i=$(expr $i + 1 )
	done
	echo "["	
	i=0
	while [ $i -lt $disklen ]
	do
		log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli lspv -clustername $clustername -sp $spname -state\" | grep ${newdisks[$i]}"
		ret=$(ssh ${ivm_user}@${ivm_ip} "ioscli lspv -clustername $clustername -sp $spname -state" | grep ${newdisks[$i]})
		if [ "$(echo $?)" != "0" ]
		then
			cluster_error "Ssp get info error" "1000103"
		fi
		log_debug $LINENO "ret=${ret}"
			cluster_pvname[$i]=$(echo ${ret} | awk '{print $1}')
			cluster_pvsize[$i]=$(echo ${ret} | awk '{print $2}')
			cluster_pvstate[$i]=$(echo ${ret} | awk '{print $3}')
			cluster_pvudid[$i]=$(echo ${ret} | awk '{print $4}')


		
		echo "{\"hdiskName\":\"${cluster_pvname[$i]}\",\"pvUniqueId\":\"${cluster_pvudid[$i]}\",\"size\":${cluster_pvsize[$i]},\"state\":\"${cluster_pvstate[$i]}\"}"
		i=$(expr $i + 1 )
	if [ "$i" != "$disklen" ]
	then
		echo ","
	fi
	done
	echo "]"
}

log_flag=$(cat ../scrpits.properties 2> /dev/null | grep "LOG=" | awk -F"=" '{print $2}')
if [ "$log_flag" == "" ]
then
	log_flag=0
fi

DateNow=$(date +%Y%m%d%H%M%S)
random=$(perl -e 'my $random = int(rand(9999)); print "$random";')
out_log="${path_log}/out_ivm_ssp_alter_add_disk_${DateNow}_${random}.log"
error_log="${path_log}/error_ivm_ssp_alter_add_disk_${DateNow}_${random}.log"

log_debug $LINENO "$0 $*"

ivm_ssp_alter_add_disk $1
#ivm_ssp_alter_add_disk '172.30.126.23|padmin|testliu|ssp1|hdisk15'

if [ "$log_flag" == "0" ]
then
	rm -f "${error_log}" 2> /dev/null
	rm -f "$out_log" 2> /dev/null
fi
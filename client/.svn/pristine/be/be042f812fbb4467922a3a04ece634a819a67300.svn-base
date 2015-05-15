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
aix_getinfo() {

	echo "{\c"

	echo "\"metapv\":{\c"
	echo "\"hdiskName\":\"${cluster_metapvname}\",\c"
	echo "\"pvUniqueId\":\"${cluster_metapvudid}\",\c"
	echo "\"size\":${cluster_metapvsize},\c"

	echo "\"state\":\"${cluster_metapvstatus}\"},\c"

	echo "\"nodes\":[\c"
	i=0
	while [ $i -lt $cluster_nodenum ]
	do
	echo "{\c"
	echo "\"nodeIp\":\"${cluster_nodeip[$i]}\",\c"
	echo "\"nodeName\":\"${cluster_nodename[$i]}\",\c"
	echo "\"partitionNum\":\"${cluster_nodepn[$i]}\",\c"
	echo "\"poolState\":\"${cluster_poolstatus[$i]}\",\c"
	echo "\"state\":\"${cluster_nodestatus[$i]}\"\c"
	echo "}\c"

	i=$(expr $i + 1 ) 
	
	if [ "$i" != "$cluster_nodenum" ]
	then
		echo ",\c"
	fi

	done
	echo "],\c"

	echo "\"sspCluster\":\c"
	echo "{\c"
	echo "\"clusterid\":\"${cluster_id}\",\c"
	echo "\"clustername\":\"${cluster_name}\",\c"
	echo "\"clusterstate\":\"${cluster_status}\"\c"
	echo "},\c"
	echo "\"ssps\":\c"
	echo "[\c"
	echo "{\c"
	echo "\"clusterid\":\"${cluster_id}\",\c"
	echo "\"clustername\":\"${cluster_name}\",\c"
	echo "\"clusterstate\":\"${cluster_status}\",\c"
	echo "\"freespace\":\"${cluster_poolfree}\",\c"
	echo "\"lus\":\c"

	echo "[\c"

	j=0
	while [ $j -lt $cluster_lunum ]
	do
	echo "{\c"
	echo "\"luname\":\"${cluster_lu_name[$j]}\",\c"
	echo "\"luudid\":\"${cluster_lu_udid[$j]}\",\c"
	echo "\"provisiontype\":\"${cluster_lu_ProvisionType[$j]}\",\c"
	echo "\"size\":\"${cluster_lu_size[$j]}\",\c"
	echo "\"unusedsize\":\"${cluster_lu_unused[$j]}\"\c"
	echo "}\c"

	j=$(expr $j + 1 ) 
	
	if [ $j != $cluster_lunum ]
	then
		echo ","
	fi
	done
	
	echo "],\c"
	echo "\"overcommitsize\":${cluster_overcommit_size},\c"

	echo "\"pvs\":\c"
	echo "[\c"
	k=0
	while [ $k -lt $cluster_pvnum ]
	do
	echo "{"
	echo "\"hdiskName\":\"${cluster_pvname[$k]}\",\c"
	echo "\"pvUniqueId\":\"${cluster_pvudid[$k]}\",\c"
	echo "\"size\":${cluster_pvsize[$k]},\c"
	echo "\"state\":\"${cluster_pvstate[$k]}\"\c"
	echo "}"
	k=$(expr $k + 1 ) 
	
	if [ "$k" != "$cluster_pvnum" ]
	then
		echo ",\c"
	fi
	done
	echo "],\c"
#####
	echo "\"sspid\":\"${cluster_poolid}\",\c"
	echo "\"sspname\":\"${cluster_poolname}\",\c"
	echo "\"sspsize\":${cluster_poolsize},\c"
	echo "\"ssptype\":\"${cluster_pooltype}\",\c"
	echo "\"totallus\":${cluster_totallus},\c"
	echo "\"totallusize\":${cluster_totallusize}\c"
	echo "}\c"
	echo "]\c"
	echo "}"
}

linux_getinfo() {

	echo -e "{"

	echo -e "\"metapv\":{"
	echo -e "\"hdiskName\":\"${cluster_metapvname}\","
	echo -e "\"pvUniqueId\":\"${cluster_metapvudid}\","
	echo -e "\"size\":${cluster_metapvsize},"

	echo -e "\"state\":\"${cluster_metapvstatus}\"},"

	echo -e "\"nodes\":["
	i=0
	while [ $i -lt $cluster_nodenum ]
	do
	echo -e "{"
	echo -e "\"nodeIp\":\"${cluster_nodeip[$i]}\","
	echo -e "\"nodeName\":\"${cluster_nodename[$i]}\","
	echo -e "\"partitionNum\":\"${cluster_nodepn[$i]}\","
	echo -e "\"poolState\":\"${cluster_poolstatus[$i]}\","
	echo -e "\"state\":\"${cluster_nodestatus[$i]}\""
	echo -e "}"

	i=$(expr $i + 1 ) 
	
	if [ "$i" != "$cluster_nodenum" ]
	then
		echo -e ","
	fi

	done
	echo -e "],"

	echo -e "\"sspCluster\":"
	echo -e "{"
	echo -e "\"clusterid\":\"${cluster_id}\","
	echo -e "\"clustername\":\"${cluster_name}\","
	echo -e "\"clusterstate\":\"${cluster_status}\""
	echo -e "},"
	echo -e "\"ssps\":"
	echo -e "["
	echo -e "{"
	echo -e "\"clusterid\":\"${cluster_id}\","
	echo -e "\"clustername\":\"${cluster_name}\","
	echo -e "\"clusterstate\":\"${cluster_status}\","
	echo -e "\"freespace\":${cluster_poolfree},"
	echo -e "\"lus\":"

	echo -e "["

	j=0
	while [ $j -lt $cluster_lunum ]
	do
	echo -e "{"
	echo -e "\"luname\":\"${cluster_lu_name[$j]}\","
	echo -e "\"luudid\":\"${cluster_lu_udid[$j]}\","
	echo -e "\"provisiontype\":\"${cluster_lu_ProvisionType[$j]}\","
	echo -e "\"size\":${cluster_lu_size[$j]},"
	echo -e "\"unusedsize\":${cluster_lu_unused[$j]}"
	echo -e "}"

	j=$(expr $j + 1 ) 
	
	if [ $j != $cluster_lunum ]
	then
		echo -e ","
	fi
	done
	
	echo -e "],"
	echo -e "\"overcommitsize\":${cluster_overcommit_size},"

	echo -e "\"pvs\":"
	echo -e "["
	k=0
	while [ $k -lt $cluster_pvnum ]
	do
	echo -e "{"
	echo -e "\"hdiskName\":\"${cluster_pvname[$k]}\","
	echo -e "\"pvUniqueId\":\"${cluster_pvudid[$k]}\","
	echo -e "\"size\":${cluster_pvsize[$k]},"
	echo -e "\"state\":\"${cluster_pvstate[$k]}\""
	echo -e "}"
	k=$(expr $k + 1 ) 
	
	if [ "$k" != "$cluster_pvnum" ]
	then
		echo -e ","
	fi
	done
	echo -e "],"
#####
	echo -e "\"sspid\":\"${cluster_poolid}\","
	echo -e "\"sspname\":\"${cluster_poolname}\","
	echo -e "\"sspsize\":${cluster_poolsize},"
	echo -e "\"ssptype\":\"${cluster_pooltype}\","
	echo -e "\"totallus\":${cluster_totallus},"
	echo -e "\"totallusize\":${cluster_totallusize}"
	echo -e "}"
	echo -e "]"
	echo -e "}"
}
get_ip() {
	ivm_user=$1
        ivm_ip=$2
        nodename=$3
	nodeip=$(ssh ${ivm_user}@${ivm_ip} "cat /etc/hosts" | grep ${nodename} | awk '{print $1}'|head -1 2>/dev/null) 
	if [ "$(echo $?)" != "0" ]
	then
		cluster_error "Ssp get info error" "1000403"
	fi
	echo $nodeip
}

ssp_get_info() {
	ivm_user=$2
	ivm_ip=$1
	clustername=$3
	spname=$4

	log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli lssp -clustername ${clustername} -field pool size free total overcommit lus type id -fmt ':'\""
	ret=$(ssh ${ivm_user}@${ivm_ip} "ioscli lssp -clustername ${clustername} -field pool size free total overcommit lus type id -fmt ':'" 2>/dev/null)
	if [ "$(echo $?)" != "0" ]
	then
		cluster_error "Ssp get info error" "1000503"
	fi
	log_debug $LINENO "ret=${ret}"
	
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

	log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli lspv | grep 'caavg_private'\""
	ret=$(ssh ${ivm_user}@${ivm_ip} "ioscli lspv | grep 'caavg_private'" 2>/dev/null)
	if [ "$(echo $?)" != "0" ]
	then
		cluster_error "Ssp get info error" "1000103"
	fi
	log_debug $LINENO "ret=${ret}"
	
	cluster_metapvname=$(echo ${ret} | awk '{print $1}')
	cluster_metapvudid=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsdev -dev ${cluster_metapvname} -attr unique_id|tail -1" 2>/dev/null)
	cluster_metapvvg=$(echo ${ret} | awk '{print $3}')
	cluster_metapvstatus=$(echo ${ret} | awk '{print $4}')
	
	log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli lspv -size | grep ${cluster_metapvname}\""
	ret=$(ssh ${ivm_user}@${ivm_ip} "ioscli lspv -size | grep ${cluster_metapvname}" 2>/dev/null)
	if [ "$(echo $?)" != "0" ]
	then
		cluster_error "Ssp get info error" "1000104"
	fi
	log_debug $LINENO "ret=${ret}"
	
	cluster_metapvsize=$(echo ${ret} | awk '{print $3}')
	log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli lspv -clustername $clustername -sp $spname -state\" | grep 'hdisk'"
	ret=$(ssh ${ivm_user}@${ivm_ip} "ioscli lspv -clustername $clustername -sp $spname -state" | grep 'hdisk' 2>/dev/null)
	if [ "$(echo $?)" != "0" ]
	then
		cluster_error "Ssp get info error" "1000105"
	fi
	log_debug $LINENO "ret=${ret}"
	
	cluster_pvnum=0
if [ "${ret}" != "" ]
then
	echo "${ret}" | while read pv
	do
		cluster_pvname[$cluster_pvnum]=$(echo ${pv} | awk '{print $1}')
		cluster_pvsize[$cluster_pvnum]=$(echo ${pv} | awk '{print $2}')
		cluster_pvstate[$cluster_pvnum]=$(echo ${pv} | awk '{print $3}')
		cluster_pvudid[$cluster_pvnum]=$(echo ${pv} | awk '{print $4}')

		cluster_pvnum=$(expr $cluster_pvnum + 1 )

	done
fi
	log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli cluster -list -fmt ':'|grep ${clustername}\""
	ret=$(ssh ${ivm_user}@${ivm_ip} "ioscli cluster -list -fmt ':'|grep ${clustername}" 2>/dev/null)
	if [ "$(echo $?)" != "0" ]
	then
		cluster_error "Ssp get info error" "1000203"
	fi
	log_debug $LINENO "ret=${ret}"
	
	cluster_name=$(echo ${ret} | awk -F ':' '{print $1}')
	cluster_id=$(echo ${ret} | awk -F ':' '{print $2}')

	log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli cluster -status -clustername ${clustername} -fmt ':'\""
	ret=$(ssh ${ivm_user}@${ivm_ip} "ioscli cluster -status -clustername ${clustername} -fmt ':'" 2>/dev/null)
	if [ "$(echo $?)" != "0" ]
	then
		cluster_error "Ssp get info error" "1000303"
	fi
	log_debug $LINENO "ret=${ret}"
	
	#hostsinfo=$(ssh ${ivm_user}@${ivm_ip} "cat /etc/hosts") 

	cluster_nodenum=0
	if [ "${ret}" != "" ]
	then
		echo "${ret}" | awk -F ' ' '{for(i=1;i<=NF;i++) print $i}' | while read css
		do
			cluster_nodename[${cluster_nodenum}]=$(echo $css | awk -F ':' '{print $3}')
		
			cluster_status[$cluster_nodenum]=$(echo $css | awk -F ':' '{print $2}')
			cluster_nodestatus[$cluster_nodenum]=$(echo $css | awk -F ':' '{print $6}')
			cluster_poolstatus[$cluster_nodenum]=$(echo $css | awk -F ':' '{print $7}')
			cluster_nodemtm[$cluster_nodenum]=$(echo $css | awk -F ':' '{print $4}')
			cluster_nodepn[$cluster_nodenum]=$(echo $css | awk -F ':' '{print $5}')
		
			cluster_nodenum=$(expr $cluster_nodenum + 1 )
		done
	fi

	ii=0	
	while [ $ii -lt $cluster_nodenum ]
	do
		cluster_nodeip[$ii]=$(get_ip ${ivm_user} ${ivm_ip} ${cluster_nodename[$ii]}) 
		ii=$(expr $ii + 1 )
	done
	
	log_debug $LINENO "CMD:ssh ${ivm_user}@${ivm_ip} \"ioscli lssp -clustername ${clustername} -sp ${spname} -bd -fmt ':'|sed -e '/^$/d'\""
	ret=$(ssh ${ivm_user}@${ivm_ip} "ioscli lssp -clustername ${clustername} -sp ${spname} -bd -fmt ':'|sed -e '/^$/d'" 2>/dev/null)
	if [ "$(echo $?)" != "0" ]
	then
		cluster_error "Ssp get info error" "1000603"
	fi
	log_debug $LINENO "ret=${ret}"
	
	cluster_lunum=0
       
	if [ "${ret}" != "" ]
        then
		echo "${ret}" | while read lu
		do
			num=$(echo $lu | awk -F ':' '{print NF}')
			if [ "$(echo $num)" != "6" ]
			then
				continue
			fi
			cluster_lu_name[$cluster_lunum]=$(echo $lu | awk -F ':' '{print $1}')
			cluster_lu_size[$cluster_lunum]=$(echo $lu | awk -F ':' '{print $2}')
			cluster_lu_ProvisionType[$cluster_lunum]=$(echo $lu | awk -F ':' '{print $3}')
			cluster_lu_used[$cluster_lunum]=$(echo $lu | awk -F ':' '{print $4}')
			cluster_lu_unused[$cluster_lunum]=$(echo $lu | awk -F ':' '{print $5}')
			cluster_lu_udid[$cluster_lunum]=$(echo $lu | awk -F ':' '{print $6}')
		
			cluster_lunum=$(expr $cluster_lunum + 1 )
		done
	fi

	case $(uname -s) in
		AIX)
	    aix_getinfo;;
	  Linux)
	    linux_getinfo;;

	esac

}

check_add_cluster_disk() {

	ivm_user=$1
	ivm_ip=$2
	clustername=$3
	diskname=$4
	
	ret=$(ssh ${ivm_user}@${ivm_ip} "ioscli lspv -clustername ${clustername} -capable" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		cluster_error "Ssp get info error" "1000033"
	fi

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
	
	ret=$(ssh ${ivm_user}@${ivm_ip} "ioscli chsp -add -clustername ${clustername} -sp ${spname} ${diskname}" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		cluster_error "Ssp get info error" "1000006"
	fi
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

	server_vscsi_id=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r prof --filter lpar_ids=${lpar_id} -F virtual_scsi_adapters" | awk -F'/' '{print $5}' 2>/dev/null)

	vadapter_vios=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -all -fmt :" | grep "C${server_vscsi_id}:" | awk -F":" '{print $1}' 2>/dev/null)
	
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
		cluster_error "Ssp get info error" "1000033"
	fi
}


get_clusterinfo_param() {
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

	        esac
	done
	if [ $debug == 1 ]
	then
		echo $ivm_ip $ivm_user $clustername $spname
	fi

	if [ "$ivm_ip" == "" -o "$ivm_user" == "" -o "$clustername" == "" ]
	then
		cluster_error "param error" "1000003"
	fi
}

ivm_ssp_get_info() {

	get_clusterinfo_param $1
	ret=$(ssp_get_info  $ivm_ip $ivm_user $clustername $spname)

	echo $ret
}
#get_ip $1 $2 $3

log_flag=$(cat ../scrpits.properties 2> /dev/null | grep "LOG=" | awk -F"=" '{print $2}')
if [ "$log_flag" == "" ]
then
	log_flag=0
fi

DateNow=$(date +%Y%m%d%H%M%S)
random=$(perl -e 'my $random = int(rand(9999)); print "$random";')
out_log="${path_log}/out_ivm_ssp_get_info_${DateNow}_${random}.log"
error_log="${path_log}/error_ivm_ssp_get_info_${DateNow}_${random}.log"

log_debug $LINENO "$0 $*"

ivm_ssp_get_info $1
#ivm_ssp_get_info '172.30.126.23|padmin|testl'

if [ "$log_flag" == "0" ]
then
	rm -f "${error_log}" 2> /dev/null
	rm -f "$out_log" 2> /dev/null
fi

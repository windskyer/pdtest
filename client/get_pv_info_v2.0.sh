#!/usr/bin/ksh

ivm_ip=$1
ivm_user=$2
pv_name=$3

. ./ivm_function.sh
check_authorized ${ivm_ip} ${ivm_user}

#to reduce cost on ssh,we just write a whole script in a single ssh

getinfo() {
	i=0 
	echo "[\c"
	while [ $i -lt $length ]
	do
		echo "{\c"
		echo "\"unique_id\":\"${unique_id[$i]}\", \c"
		echo "\"pv_id\":\"${pv_id[$i]}\", \c"
		echo "\"pv_name\":\"${pv_name[$i]}\", \c"
		echo "\"pv_status\":\"${pv_status[$i]}\", \c"
		echo "\"pv_size\":\"${pv_size[$i]}\", \c"
		echo "\"assigned_to\":\"${assigned_to[$i]}\", \c"
		echo "\"useable_type\":\"${useable_type[$i]}\"\c"
		echo "}\c"
		((i=i+1))
		if [ "$i" != "$length" ]
		then
			echo ", \c"
		fi  
	done
	echo "]"

}
if [ x"$pv_name" != x"" ]
then
	#length of the pv arry
	length=0

	#pv avail
	pv_avail=$(ssh ${ivm_user}@${ivm_ip} "ioscli lspv -avail -fmt :"|awk -F":" '{print $1}')
	#echo pv_avail=$pv_avail
	#pv free
	pv_free=$(ssh ${ivm_user}@${ivm_ip} "ioscli lspv -free -fmt :"|awk -F":" '{print $1}')
	#echo pv_free=$pv_free
	#pv used by vg
	pv_vg=$(ssh ${ivm_user}@${ivm_ip} "ioscli lspv -fmt :"|awk -F":" '{if($3 != "None"){print $1}}')
	#echo pv_vg=$pv_vg
	#whether pv in pv_vg,pv_avail, 1 is in, 0 is not in
	
	in_avail=$(echo $pv_avail|awk '{for (i=1;i<=NF;i++) {if($i==pvname) print $i}}' pvname=$pv_name)
	#echo in_avail=$in_avail
	num_free=$(echo $pv_free|awk '{for (i=1;i<=NF;i++) {if($i==pvname) print $i}}' pvname=$pv_name)
	#echo num_free=$num_free
	if [ x"$num_free" != x"" ]
	then
		#Using State (0:Unavailable, 1:Available, 2:Free)
		in_free=2
	else
		in_free=1
	fi
	
	in_vg=$(echo $pv_vg|awk '{for (i=1;i<=NF;i++) {if($i==pvname) print $i}}' pvname=$pv_name)
	#echo in_vg=$in_vg

	#only pv in pv_avail and not in pv_vg
	if [ "$in_avail" != "" -a "$in_vg" == "" ]
	then
		pv_size[$length]=$(ssh ${ivm_user}@${ivm_ip} "ioscli lspv -size $pv_name")
		#unique_id[$length]=\$(ioscli lsdev -dev $pv_name -attr unique_id|tail -1)
		unique_id[$length]=$(ssh ${ivm_user}@${ivm_ip} "ioscli chkdev -dev $pv_name -field name IDENTIFIER -fmt :"|awk -F":" '{print $2}')
		pv_id[$length]=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsdev -dev $pv_name -attr pvid"|tail -1|sed 's/none//g')
		pv_status[$length]=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsdev -dev $pv_name -field status -fmt :")
		pv_name[$length]=$pv_name
		assigned_to[$length]="0"
		useable_type[$length]=$in_free
		((length=length+1))
	else
		echo "Not found $pv_name at $ivm_ip Or the $pv_name is already used by VG or VM"
		exit 1
	fi

	#output in json format
	getinfo

else
	#length of the pv arry
	length=0

	#get pvs used by vm mapping in vhost
	pv_map=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -all -type disk -field backing"|grep -v "is not in AVAILABLE" |awk '{if ($3)print $3}')
	#echo $pv_map|awk '{for (i=1;i<=NF;i++) print $i}'|while read pv_name[$length]
	for pv in $(echo "$pv_map")
do
	pv_name[$length]=$pv
	pv_size[$length]=$(ssh ${ivm_user}@${ivm_ip} "ioscli lspv -size ${pv_name[$length]}")
	#unique_id[$length]=$(ioscli lsdev -dev ${pv_name[$length]} -attr unique_id|tail -1)
	unique_id[$length]=$(ssh ${ivm_user}@${ivm_ip} "ioscli chkdev -dev ${pv_name[$length]} -field name IDENTIFIER -fmt :"|awk -F":" '{print $2}')
	pv_id[$length]=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsdev -dev ${pv_name[$length]} -attr pvid"|tail -1|sed 's/none//g')
	pv_status[$length]=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsdev -dev ${pv_name[$length]} -field status -fmt :")
	useable_type[$length]="0"
	assigned_to[$length]="1"
	((length=length+1))
done

	#get pvs available
	pv_avail=$(ssh ${ivm_user}@${ivm_ip} "ioscli lspv -avail -fmt :"|awk -F":" '{print $1}')
	#echo pv_avail=$pv_avail
	#pv free
	pv_free=$(ssh ${ivm_user}@${ivm_ip} "ioscli lspv -free -fmt :"|awk -F":" '{print $1}')
	#echo pv_free=$pv_free
	#convert pv_map from hdisk1 hdisk2 ... to hdisk1|hdisk2|...
	#pv_map=$(echo $pv_map|sed 's/\ /|/g')
	#echo pv_map=$pv_map
	
	#filter out pv_map from pv_avail
	#echo $pv_map | awk '{for(i=1;i<=NF;i++) print $i}' | while read line
	for line in $(echo "$pv_map")
do
	#echo line=$line
	if [ "$line" != "" ]
	then
		pv_avail=$(echo $pv_avail | awk '{ for(i=1;i<=NF;i++) { if($i != pvname) { print $i } } }' pvname="$line")
		#echo pv_avail=$pv_avail
	fi
done
	
	#echo $pv_avail|awk '{for (i=1;i<=NF;i++) print $i}'|while read pv_name[$length]
	for pv in $(echo "$pv_avail")
do
	pv_name[$length]=$pv
	pv_size[$length]=$(ssh ${ivm_user}@${ivm_ip} "ioscli lspv -size ${pv_name[$length]}")
	#unique_id[$length]=$(ioscli lsdev -dev ${pv_name[$length]} -attr unique_id|tail -1)
	unique_id[$length]=$(ssh ${ivm_user}@${ivm_ip} "ioscli chkdev -dev ${pv_name[$length]} -field name IDENTIFIER -fmt :"|awk -F":" '{print $2}')
	pv_id[$length]=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsdev -dev ${pv_name[$length]} -attr pvid"|tail -1|sed 's/none//g')
	pv_status[$length]=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsdev -dev ${pv_name[$length]} -field status -fmt :")
	assigned_to[$length]="0"
	num_free=$(echo $pv_free|awk '{for (i=1;i<=NF;i++) {if($i==pvname) print $i}}' pvname=${pv_name[$length]})
	#echo num_free=$num_free
	if [ x"$num_free" != x"" ]
	then
		#Using State (0:Unavailable, 1:Available, 2:Free)
		in_free=2
	else
		in_free=1
	fi
	useable_type[$length]="$in_free"
	((length=length+1))
done

#get pv used by vg
pv_vg=$(ssh ${ivm_user}@${ivm_ip} "ioscli lspv"|grep -Ev "NAME|None"|awk '{print $1}')
#echo $pv_vg|awk '{for (i=1;i<=NF;i++) print $i}'|while read pv_name[$length]
for pv in $(echo "$pv_vg")
do
	pv_name[$length]=$pv
	pv_size[$length]=$(ssh ${ivm_user}@${ivm_ip} "ioscli lspv -size ${pv_name[$length]}")
	#unique_id[$length]=$(ioscli lsdev -dev ${pv_name[$length]} -attr unique_id|tail -1)
	unique_id[$length]=$(ssh ${ivm_user}@${ivm_ip} "ioscli chkdev -dev ${pv_name[$length]} -field name IDENTIFIER -fmt :"|awk -F":" '{print $2}')
	pv_id[$length]=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsdev -dev ${pv_name[$length]} -attr pvid"|tail -1|sed 's/none//g')
	pv_status[$length]=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsdev -dev ${pv_name[$length]} -field status -fmt :")
	assigned_to[$length]="2"
	useable_type[$length]="0"
	((length=length+1))
done

#get pv used by ssp
clusterlist=$(ssh ${ivm_user}@${ivm_ip} "ioscli cluster -list")
#echo "$clusterlist"|grep "CLUSTER_NAME"|awk '{print $2}'|while read cluster
for cluster in $(echo "$clusterlist"|grep "CLUSTER_NAME"|awk '{print $2}')
do
	#get sp name
	sp_name=$(ssh ${ivm_user}@${ivm_ip} "ioscli lssp -clustername $cluster"|grep "POOL_NAME"|awk '{print $2}')
	ssp_pv=$(ssh ${ivm_user}@${ivm_ip} "ioscli lspv -clustername $cluster -sp $sp_name")
	#echo "$ssp_pv"|grep -Ev "NAME"|awk '{print $1}'|while read pv_name[$length]
	for pv in $(echo "$ssp_pv"|grep -Ev "NAME"|awk '{print $1}')
do
	pv_name[$length]=$pv
	pv_size[$length]=$(ssh ${ivm_user}@${ivm_ip} "ioscli lspv -size ${pv_name[$length]}")
	#unique_id[$length]=$(ioscli lsdev -dev ${pv_name[$length]} -attr unique_id|tail -1)
	unique_id[$length]=$(ssh ${ivm_user}@${ivm_ip} "ioscli chkdev -dev ${pv_name[$length]} -field name IDENTIFIER -fmt :"|awk -F":" '{print $2}')
	pv_id[$length]=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsdev -dev ${pv_name[$length]} -attr pvid"|tail -1|sed 's/none//g')
	pv_status[$length]=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsdev -dev ${pv_name[$length]} -field status -fmt :")
	assigned_to[$length]="3"
	useable_type[$length]="0"
	((length=length+1))
done
done

#output in json format
getinfo
fi

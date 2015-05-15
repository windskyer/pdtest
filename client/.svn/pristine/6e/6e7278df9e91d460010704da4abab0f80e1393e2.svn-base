#!/usr/bin/ksh
#./ivm_remove_vol.sh "172.30.126.12|padmin" "lv|lv05,lv37" "pv|hdisk5,hdisk6"
#./ivm_remove_vol.sh "172.30.126.12|padmin" "lv|lv05,lv37" "pv|hdisk5,hdisk6"
#./ivm_remove_vol.sh "172.30.126.12|padmin" "lv|lv05,lv37" 
#./ivm_remove_vol.sh "172.30.126.12|padmin" "pv|hdisk5,hdisk6"

#####################################################################################
#####                           function	and par.                            #####
#####################################################################################
logpath=./
DateNow=$(date +%Y%m%d%H%M%S)
random=$(echo $RANDOM)
out_log=$logpath"out_`basename $0`_${DateNow}_${random}.log"
error_log=$logpath"error_`basename $0`_${DateNow}_${random}.log"


catchException()
{
	error_result=$(cat $1)
}

throwException()
{
	result=$1
	error_code=$2
	if [ "$result" != "" ]
	then
		echo "0|0|ERROR-${error_code}: ${result}"    			>&2
		exit 1
	fi
}

get_lvs()
{
	vols=$1
	j=0
	echo $vols |awk -F"," '{for(i=1;i<=NF;i++) print $i}' | while read lv
	do
		lvs[$j]=$lv
		echo ${lvs[$j]}		>> $out_log
		j=$(expr $j + 1)
	done
		
	lvs_num=$j
	echo lvs_num==$lvs_num	>> $out_log
}

get_pvs()
{
	vols=$1
	j=0
	echo $vols |awk -F"," '{for(i=1;i<=NF;i++) print $i}' | while read pv
	do
		pvs[$j]=$pv
		echo ${pvs[$j]}		>> $out_log
		j=$(expr $j + 1)
	done
	
	pvs_num=$j
	echo pvs_num==$pvs_num	>> $out_log
}

unmapping_lvs()
{
	j=0
	while [ $j -lt $lvs_num ]
	do
		echo "Begin to unmmaping ${lvs[$j]}"		>> $out_log
		unmapping=$(ssh ${ivm_user}@${ivm_ip} "ioscli rmvdev -vdev ${lvs[$j]} -f" 2> /dev/null)
		j=$(expr $j + 1)
	done
}

unmapping_pvs()
{
	j=0
	while [ $j -lt $pvs_num ]
	do
		echo "Begin to unmmaping ${pvs[$j]}"		>> $out_log
		unmapping=$(ssh ${ivm_user}@${ivm_ip} "ioscli rmvdev -vdev ${pvs[$j]} -f" 2> /dev/null)
		j=$(expr $j + 1)
	done
}

rm_lvs()
{
	j=0
	while [ $j -lt $lvs_num ]
	do
		echo "Begin to remove ${lvs[$j]}"		>> $out_log
		remove=$(ssh ${ivm_user}@${ivm_ip} "ioscli rmlv -f ${lvs[$j]}" 2> /dev/null)
		j=$(expr $j + 1)
	done
}

#####################################################################################
#####                   			  scripts pars.          	                 #####
#####################################################################################
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
    esac
done					


if [ "$2" != "" ]
then
	j=0
	echo $2 |awk -F"|" '{for(i=1;i<=NF;i++) print $i}' | while read param
	do
        case $j in
			0)
					j=1;
					vol_type_1=$param;;
			1)
					j=2;        
					vol_names_1=$param;;
        esac
	done
fi	

if [ "$3" != "" ]
then
	j=0
	echo $3 |awk -F"|" '{for(i=1;i<=NF;i++) print $i}' | while read param
	do
        case $j in
			0)
					j=1;
					vol_type_2=$param;;
			1)
					j=2;        
					vol_names_2=$param;;
        esac
	done
fi	

# echo $ivm_ip
# echo $ivm_user
# echo $vol_type_1
# echo $vol_names_1
# echo $vol_type_2
# echo $vol_names_2

#####################################################################################
#####                   			decoding pars.          	                 #####
#####################################################################################
case $vol_type_1 in
	lv)
		echo "vol_type_1 is lv"		>> $out_log
		get_lvs $vol_names_1
		unmapping_lvs 
		rm_lvs
		;;
	pv)
		echo "vol_type_1 is pv"		>> $out_log
		get_pvs $vol_names_1
		unmapping_pvs 
		;;
esac

case $vol_type_2 in
	lv)
		echo "vol_type_2 is lv"		>> $out_log
		get_lvs $vol_names_2
		unmapping_lvs 
		rm_lvs
		;;
	pv)
		echo "vol_type_2 is pv"		>> $out_log
		get_pvs $vol_names_2
		unmapping_pvs 
		;;
esac





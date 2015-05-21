#!/usr/bin/ksh

. ./ivm_function.sh

j=0
echo $1 |awk -F"|" '{for(i=1;i<=NF;i++) print $i}' | while read param
do
        case $j in
			0)
					j=1;
					tmp_path=$param;;
			1)
					j=2;        
					tmp_id=$param;;
			2)
					j=3;
					tmp_dir=$param;;
			3)
					j=4;
					tmp_type=$param;;
			4)
					j=5;
					tmp_desc=$param;;
        esac
done

j=0
for nfs_info in $(echo $2 |awk -F"|" '{for(i=1;i<=NF;i++) print $i}')
do
		case $j in
			0)
					j=1;
					nfs_ip=$nfs_info;;
			1)
					j=2;        
					nfs_name=$nfs_info;;
			2)
					j=3;
					nfs_passwd=$nfs_info;;
			3)
					j=4;
					nfs_path=$nfs_info;;
		esac
done

log_flag=$(cat scrpits.properties 2> /dev/null | grep "LOG=" | awk -F"=" '{print $2}')
if [ "$log_flag" == "" ]
then
	log_flag=0
fi

DateNow=$(date +%Y%m%d%H%M%S)
random=$(perl -e 'my $random = int(rand(9999)); print "$random";')
out_log="${path_log}/out_ivm_create_tmp_cfg_v2.0_${DateNow}_${random}.log"
error_log="${path_log}/error_ivm_create_tmp_cfg_v2.0_${DateNow}_${random}.log"

log_debug $LINENO "$0 $*"

#check NFSServer status and restart that had stop NFSServer proc
nfs_server_check ${nfs_ip} ${nfs_name} ${nfs_passwd}

#####################################################################################
#####                                                                           #####
#####                          		 mount nfs	                                #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "mount nfs"
log_debug $LINENO "CMD:./ivm_mount_nfs.sh "$2""
result=$(./ivm_mount_nfs.sh "$2" 2>&1)
if [ $? -ne 0 ]
then
	echo "$result" >&2
fi
log_debug $LINENO "result=${result}"

tmp_path=$(echo "$result" | sed -e 's/"//g' -e 's/\[//g' -e 's/\]//g' -e 's/{//g' -e 's/}//g' | awk -F":" '{print $2}')
log_debug $LINENO "tmp_path=${tmp_path}"
if [ "$tmp_path" == "" ]
then
	./ivm_unmount_nfs.sh "${nfs_ip}|${nfs_path}|${tmp_path}" > /dev/null 2>&1
	echo "Mount nfs server $nfs_ip failed." >&2
fi
# echo "tmp_path===$tmp_path"

log_debug $LINENO "CMD:ls -1 $tmp_path"/"$tmp_dir"
file_list=$(ls -1 $tmp_path"/"$tmp_dir 2>&1)
if [ "$(echo $?)" != "0" ]
then
	./ivm_unmount_nfs.sh "${nfs_ip}|${nfs_path}|${tmp_path}" > /dev/null 2>&1
	print_error "$tmp_path/$tmp_dir does not exist."
fi
log_debug $LINENO "file_list=${file_list}"

chmod -R 777 $tmp_path"/"$tmp_dir > /dev/null 2>&1

result=$(expect ./ssh_password.exp ${nfs_ip} ${nfs_name} ${nfs_passwd} "chmod -R 777 ${nfs_path}/${tmp_dir}|exit" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	./ivm_unmount_nfs.sh "${nfs_ip}|${nfs_path}|${tmp_path}" > /dev/null 2>&1
	print_error "$result"
fi

# echo "file_list==$file_list"

length=0
for file in $file_list
do
	if [ "$(echo ${file##*.} | awk '{if($1~/^[0-9]*[0-9]$/) print 0}')" == "0" ]
	then
		#echo "file==$file"
		file_name[$length]=$file
		length=$(expr $length + 1)
	fi
done

# echo "length==$length"

i=0
num=0
while [ $i -ge 0 ]
do
	j=0
	while [ $j -lt $length ]
	do
		file=${file_name[$j]}
		# echo "file==$file"
		if [ "${file##*.}" == "$i" ]
		then
			files=$files","$tmp_path"/"$tmp_dir"/"$file"|lv"
			num=$(expr $num + 1)
			break
		fi
		j=$(expr $j + 1)
	done
	# echo "num==$num"
	if [ "$num" == "$length" ]
	then
		break
	fi
	i=$(expr $i + 1)
done

files=$(echo $files | awk '{print substr($0,2,length($0))}')
# echo "files==$files"

error=$(echo "id=$tmp_id" > $tmp_path"/"$tmp_dir"/"$tmp_dir".cfg" 2>&1)
if [ "$(echo $?)" != "0" ]
then
	./ivm_unmount_nfs.sh "${nfs_ip}|${nfs_path}|${tmp_path}" > /dev/null 2>&1
	print_error "$error"
fi

echo "files=$files" >> $tmp_path"/"$tmp_dir"/"$tmp_dir".cfg"
echo "type=$tmp_type" >> $tmp_path"/"$tmp_dir"/"$tmp_dir".cfg"
echo "desc=$tmp_desc" >> $tmp_path"/"$tmp_dir"/"$tmp_dir".cfg"
log_debug $LINENO "files=$files"
log_debug $LINENO "type=$tmp_type"
log_debug $LINENO "desc=$tmp_desc"

#####################################################################################
#####                                                                           #####
#####                          		unmount nfs	                                #####
#####                                                                           #####
#####################################################################################
log_info $LINENO "umount nfs"
result=$(./ivm_unmount_nfs.sh "${nfs_ip}|${nfs_path}|${tmp_path}" 2>&1)
if [ $? -ne 0 ]
then
	echo "$result" >&2
fi

if [ "$log_flag" == "0" ]
then
	rm -f "${error_log}" 2> /dev/null
	rm -f "$out_log" 2> /dev/null
fi

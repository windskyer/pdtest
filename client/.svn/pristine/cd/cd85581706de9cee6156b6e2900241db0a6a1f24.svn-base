#!/usr/bin/ksh

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

file_list=$(ls -1 $tmp_path"/"$tmp_dir 2>&1)
if [ "$(echo $?)" != "0" ]
then
	echo "$tmp_path/$tmp_dir does not exist." >&2
	exit 1
fi

chmod -R 777 $tmp_path"/"$tmp_dir > /dev/null 2>&1

# echo "file_list==$file_list"

length=0
for file in $file_list
do
	if [ "$(echo ${file##*.} | awk '{if($1~/^[0-9]*[0-9]$/) print 0}')" == "0" ]
	then
		echo "file==$file"
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
	echo "$error" >&2
	exit 1
fi
echo "files=$files" >> $tmp_path"/"$tmp_dir"/"$tmp_dir".cfg"
echo "type=$tmp_type" >> $tmp_path"/"$tmp_dir"/"$tmp_dir".cfg"
echo "desc=$tmp_desc" >> $tmp_path"/"$tmp_dir"/"$tmp_dir".cfg"

# length=0
# if [ "$tmp_nm" == "" ]
# then
	# ls -l $tmp_path | awk '{if(substr($1,0,1)=="d") print $0}' | while read line
	# do
		# echo "line===="$line
		# tmp_name[$length]=$(echo $line | awk '{print $9}')
		# tmp_info=$(cat $tmp_path"/"${tmp_name[$length]}"/"${tmp_name[$length]}".cfg" 2>&1)
		# if [ "$(echo $?)" != "0" ]
		# then
			# continue
		# fi
		# tmp_id[$length]=$(echo "$tmp_info" | awk -F"=" '{if($1=="id") print $2}')
		# tmp_files[$length]=$(echo "$tmp_info" | awk -F"=" '{if($1=="files") print $2}')
		# echo ${tmp_files[$length]} | awk -F"," '{for(i=1;i<=NF;i++) print $i}' | while read file
		# do
			# ls $file > /dev/null 2>&1
			# if [ "$(echo $?)" != "0" ]
			# then
				# continue
			# fi
		# done
		# file_num[$length]=$(echo "${tmp_files[$length]}" | awk -F"," '{print NF}')
		# tmp_type[$length]=$(echo "$tmp_info" | awk -F"=" '{if($1=="type") print $2}')
		# tmp_desc[$length]=$(echo "$tmp_info" | awk -F"=" '{if($1=="desc") print $2}')
		# if [ "${tmp_id[$length]}" == "" ]||[ "${tmp_files[$length]}" == "" ]||[ "${tmp_type[$length]}" == "" ]||[ "${file_num[$length]}" == "0" ]
		# then
			# continue
		# fi
		# length=$(expr $length + 1)
	# done
# else
	# echo "tmp_nm===="$tmp_nm
	# tmp_name[$length]=${tmp_nm}
	# echo "tmp_name[$length]==${tmp_name[$length]}"
	# tmp_info=$(cat $tmp_path"/"${tmp_name[$length]}"/"${tmp_name[$length]}".cfg" 2>&1)
	# if [ "$(echo $?)" != "0" ]
	# then
		# echo "The template ${tmp_name[$length]} is not found." >&2
		# exit 1
	# fi
	# echo "$tmp_info"
	# if [ "$(echo $?)" == "0" ]
	# then
		# tmp_id[$length]=$(echo "$tmp_info" | awk -F"=" '{if($1=="id") print $2}')
		# tmp_files[$length]=$(echo "$tmp_info" | awk -F"=" '{if($1=="files") print $2}')
		# echo ${tmp_files[$length]} | awk -F"," '{for(i=1;i<=NF;i++) print $i}' | while read file
		# do
			# ls $file > /dev/null 2>&1
			# if [ "$(echo $?)" != "0" ]
			# then
				# continue
			# fi
		# done
		# file_num[$length]=$(echo "${tmp_files[$length]}" | awk -F"," '{print NF}')
		# tmp_type[$length]=$(echo "$tmp_info" | awk -F"=" '{if($1=="type") print $2}')
		# tmp_desc[$length]=$(echo "$tmp_info" | awk -F"=" '{if($1=="desc") print $2}')
		# if [ "${tmp_id[$length]}" != "" ]&&[ "${tmp_files[$length]}" != "" ]&&[ "${tmp_type[$length]}" != "" ]&&[ "${file_num[$length]}" != "0" ]
		# then
			# length=$(expr $length + 1)
		# fi
	# fi
# fi

# echo "length==$length"

# aix_getinfo() {
	# i=0
	# echo  "[\c"
	# if [ "$length" != "0" ]
	# then
		# while [ $i -lt $length ]
		# do
			# echo  "{\c"
			# echo  "\"tmp_name\":\"${tmp_name[$i]}\", \c"
			# echo  "\"tmp_id\":\"${tmp_id[$i]}\", \c"
			# echo  "\"tmp_type\":\"${tmp_type[$i]}\", \c"
			# echo  "\"tmp_desc\":\"${tmp_desc[$i]}\", \c"
			# echo  "\"tmp_file\":[\c"
			# j=0
			# echo "tmp_files[$i]===${tmp_files[$i]}"
			# echo ${tmp_files[$i]} | awk -F"," '{for(i=1;i<=NF;i++) print $i}' | while read file
			# do
				# file_number=$(expr $j + 1)
				# file_name=${file##*/}
				# file_size=$(du -k $file | awk '{print $1}')
				# echo "{\c"
				# echo "\"file_num\":\"$file_number\", \c"
				# echo "\"file_name\":\"$file_name\", \c"
				# echo "\"file_size\":\"$file_size\"\c"
				# echo "}\c"
				# j=$(expr $j + 1)
				# if [ "$j" != "${file_num[$i]}" ]
				# then
					# echo  ", \c"
				# fi
			# done
			
			# echo  "]}\c"
			# i=$(expr $i + 1)
			# if [ "$i" != "$length" ]
			# then
				# echo  ", \c"
			# fi
		# done
	# fi
	# echo  "]"
# }



# linux_getinfo() {
	# i=0
	# echo -e "[\c"
	# if [ "$length" != "0" ]
	# then
		# while [ $i -lt $length ]
		# do
			# echo -e "{\c"
			# echo -e "\"tmp_name\":\"${tmp_name[$i]}\", \c"
			# echo -e "\"tmp_id\":\"${tmp_id[$i]}\", \c"
			# echo -e "\"tmp_type\":\"${tmp_type[$i]}\", \c"
			# echo -e "\"tmp_desc\":\"${tmp_desc[$i]}\", \c"
			# echo -e "\"tmp_file\":[\c"
			# j=0
			# echo "tmp_files[$i]===${tmp_files[$i]}"
			# echo ${tmp_files[$i]} | awk -F"," '{for(i=1;i<=NF;i++) print $i}' | while read file
			# do
				# file_number=$(expr $j + 1)
				# file_name=${file##*/}
				# file_size=$(du -k $file | awk '{print $1}')
				# echo -e "{\c"
				# echo -e "\"file_num\":\"$file_number\", \c"
				# echo -e "\"file_name\":\"$file_name\", \c"
				# echo -e "\"file_size\":\"$file_size\"\c"
				# echo -e "}\c"
				# j=$(expr $j + 1)
				# if [ "$j" != "${file_num[$i]}" ]
				# then
					# echo -e ", \c"
				# fi
			# done
			
			# echo -e "]}\c"
			# i=$(expr $i + 1)
			# if [ "$i" != "$length" ]
			# then
				# echo -e ", \c"
			# fi
		# done
	# fi
	# echo -e "]"
# }

# case $(uname -s) in
	# AIX)
		# aix_getinfo;;
	# Linux)
		# linux_getinfo;;
	# *BSD)
		# bsd_getinfo;;
	# SunOS)
		# sun_getinfo;;
	# HP-UX)
		# hp_getinfo;;
	# *) echo "Unknown operating system" >&2 ;;
# esac
#!/usr/bin/ksh

ivm_ip=$1
ivm_user=$2
lpar_id=$3
new_name=$4

ssh ${ivm_user}@${ivm_ip} "chsyscfg -r lpar -i new_name=\"${new_name}\",lpar_id=${lpar_id}"

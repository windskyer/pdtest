#!/usr/bin/ksh

hmc_ip=$1
hmc_user=$2
host_id=$3
lpar_id=$4

ssh ${hmc_user}@${hmc_ip} "lssyscfg -r lpar -m \"$host_id\" -F state --filter lpar_ids=$lpar_id"

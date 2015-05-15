#!/bin/ksh
echo "==================AE Start $(date)======================="
NETPATH=/etc/sysconfig/network
HOSTPATH=/etc/
CFG_FILE=/mnt/config_*.xml

umount /dev/cdrom*
mount /dev/cdrom* /mnt

ls /mnt/config_*.xml

if [ "$(echo $?)" != "0" ]
then
  umount /dev/cdrom*
  echo "===================AE Stop $(date)========================"
  exit 0
fi

ls -1 /mnt/config_*.xml | while read line
do
        if [ "$line" != "" ]
        then
                CFG_FILE=$line
                break
        fi
done

slotno=$(cat $CFG_FILE|grep "slotno"|awk -F= '{print$2}')
ipaddr=$(cat $CFG_FILE|grep "ipaddr"|awk -F= '{print$2}')
ipgw=$(cat $CFG_FILE|grep "ipgw"|awk -F= '{print$2}')
netmask=$(cat $CFG_FILE|grep "netmask"|awk -F= '{print$2}')
hostname=$(cat $CFG_FILE|grep "hostname"|awk -F= '{print$2}')
# slotno=$(cat $CFG_FILE|grep "slotno"|awk -F= '{print$2}')
macaddr=$(cat $CFG_FILE|grep "macaddr"|awk -F= '{print$2}')

# echo "slotno : "$slotno


echo $macaddr

eth_num=$(ifconfig -a | awk '/HW/{if ($5==macaddr) print $1}' macaddr="$macaddr")
if [ "$eth_num" != "" ]
then
	netfile=$NETPATH/ifcfg-$eth_num
	hostfile=$HOSTPATH/HOSTNAME
	gwfile=$NETPATH/routes

	echo "NETMASK=$netmask" >$netfile
	echo "IPADDR=$ipaddr" >>$netfile
	echo "STARTMODE=auto" >>$netfile
	echo "USERCONTROL=no" >>$netfile
	echo "FIREWALL=no" >>$netfile

	echo "HOSTNAME=$hostname"
	echo "NETMASK=$netmask"
	echo "IPADDR=$ipaddr"
	echo "STARTMODE=auto"
	echo "USERCONTROL=no"
	echo "FIREWALL=no"
	echo "IPGATEWAY=$ipgw"
	echo "LLADDR=$macaddr" >>$netfile

	echo "default $ipgw - -" >$gwfile

	echo "$hostname" > $hostfile

	service network restart
else
	echo "eth_num is null"
fi
result=$(fdisk -l /dev/sda | grep "Disk /dev/sda" | awk '{print $3}')
result=$result"GB"
parted /dev/sda resize 4 <<EOF

$result
EOF

echo "===================AE Stop $(date)========================"

umount /dev/cdrom*
shutdown -h now
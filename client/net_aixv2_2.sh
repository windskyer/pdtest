#!/bin/bash
#NETPATH=/etc/sysconfig/network-scripts
CFG_FILE=/mnt/config_*.xml
        umount /mnt
        lsdev -C|grep cd | while read line
        do
           cd=$(echo $line | awk '{if($2=="Available") print $1}')
        done
        mount -o ro -v cdrfs /dev/$cd /mnt

        ls /mnt/config_*.xml

        if [ "$(echo $?)" != "0" ]; then
           umount /dev/$cd
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

        for I in `lsdev | grep ent | grep Ethernet | awk '{print $1}' | cut -d "t" -f2`
        do
                ifconfig en$I down
                ifconfig en$I detach
                rmdev -dl en$I
                rmdev -dl et$I
                rmdev -dl ent$I
        done
        cfgmgr

        ipaddr=$(cat $CFG_FILE|grep "ipaddress"|awk -F= '{print $2}' )
        ipgw=$(cat $CFG_FILE|grep "ipgw"|awk -F= '{print $2}')
        netmask=$(cat $CFG_FILE|grep "netmask"|awk -F= '{print $2}')
        hostname=$(cat $CFG_FILE|grep "hostname"|awk -F= '{print $2}')
        #devno=$(cat $CFG_FILE|grep "slotnumber"|awk -F= '{print$2}')
        #ipdns=$(cat $CFG_FILE|grep "dnsIPaddresses"|awk -F= '{prient$2}')
        #doman=$(cat $CFG_FILE|grep "domainname"|awk -F= '{prient$2}')
        #slotno=$(cat $CFG_FILE|grep "slotno"|awk -F= '{print$2}')
        echo "$hostname $ipaddr $netmask $ipgw"
        echo "/usr/sbin/mktcpip -h'$hostname' -a'$ipaddr' -m'$netmask' -i'en0' -g'$ipgw' -A'no' -t'N/A'"


        rm -f /etc/hosts
        echo '127.0.0.1               loopback localhost' > /etc/hosts
        echo '$hostname'
        /usr/sbin/mktcpip -h $hostname -a $ipaddr  -m $netmask  -i en0  -g $ipgw  -A no -t N/A
        #echo "/usr/sbin/mktcpip -h test116 -a 172.30.125.117 -m 255.255.255.0 -i en0 -g 172.30.125.254 -A no -t N/A"
        #/usr/sbin/mktcpip -h test116 -a 172.30.125.117 -m 255.255.255.0 -i en0 -g 172.30.125.254 -A no -t N/A
        #/usr/sbin/mktcpip -h'test116' -a'172.30.125.117' -m'255.255.255.0' -i'en0' -g'172.30.125.254' -A'no' -t'N/A'
        #touch $NETPATH/ifcfg-eth$devno
        #netfile=$NETPATH/ifcfg-eth$devno
        #echo $netfile

        #echo "DEVICE=eth$devno" >$netfile
        #echo "BOOTPROTO=none" >>$netfile
        #echo "ONBOOT=yes" >>$netfile
        #echo "TYPE=Ethernet" >>$netfile
        #echo "NETMASK=$netmask" >>$netfile
        #echo "IPADDR=$ipaddr" >>$netfile
        #echo "GATEWAY=$ipgw" >>$netfile
        
        #hostname $hostname
        #service network start
		for vg in $(lsvg)
		do
			chvg -g $vg
		done
		
        umount /mnt
        shutdown -h now
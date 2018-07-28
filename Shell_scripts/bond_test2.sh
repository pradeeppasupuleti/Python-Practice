#!/bin/sh
BC=$(ifconfig -a | grep bond | awk '{print $1}' )
AL=$(ifconfig -a | grep -A1 eth | grep -B1 inet | grep eth | awk '{print $1}')


OS_VER=$(cat /etc/[rS]*-release | tr '\n' ' ' | sed -e 's/$/\n/')
	if [ -f /etc/SuSE-release ]; then	
		OS_VER_SHORT=$(cat /etc/SuSE-release  | grep SLES | awk '{ print $2 }')
		if [ ! -z "$OS_VER_SHORT" ]; then
			 OS_VER_SHORT=$(cat /etc/SuSE-release  | grep VERSION | awk -F= '{ print "SLES-" $2 }' | sed 's/ //g' | sed -e 's/SLES-8.[0-9]/SLES-8/')
		fi
		else
		OS_VER_SHORT=$(cat /etc/redhat-release | awk -F "release" '{print $2}' | awk -F "." '{print "RHEL-"$1}' | sed 's/ //g')
	fi

echo  -e "+-------------+---------------+---------+----------------+------------+-------+-----------+---------------------+"
echo -e "Interface\tP-Interface\tStatus\t\tMac-ID\t\tSpeed\t\tDuplex\tAuto-Neg\tIPADD"
echo  -e "+-------------+---------------+---------+----------------+------------+-------+-----------+---------------------+"
	for i in $BC
	do
		#if [ "$OS_VER_SHORT" = "SLES-8*" ] || [ "$OS_VER_SHORT" = "SLES-8.1" ]; then
		if [ "$OS_VER_SHORT" = "SLES-8*" ]; then
		for j in  $(cat /proc/net/$i/info  | grep ^Slave | awk '{ print $3 }')
			do
			INET=$j
			SPEED=$(ethtool $j | grep Speed: | awk -F: '{print $2}' | sed -e 's/ //g')
			DUP=$(ethtool $j | grep Duplex: | awk -F: '{print $2}' | sed -e 's/ //g')
			AUTO=$(ethtool $j | grep Auto-negotiation: | awk -F: '{print $2}' | sed -e 's/ //g')
			LINK=$(ethtool $j | grep "Link detected:" | awk -F: '{print $2}' | sed -e 's/ //g')
			MAC=$(ifconfig eth4 | grep "HWaddr" | awk -F"HWaddr" '{print $2}' | sed -e 's/ //')
			ACB=$(grep -H "$j" /proc/net/bond*/* | grep "Slave Interface:" | awk -F "/" '{print $4}')
			ADD=$(ifconfig $ACB | grep inet 2> /dev/null |awk '{print $2}' | awk -F: '{print $2}')
			BNET=$ACB
			echo -e "$BNET\t\t\t$INET\t$LINK\t$MAC\t$SPEED\t$DUP\t$AUTO\t$ADD"
			done
		else
		BC1=$(cat /proc/net/bonding/$i | grep ^Slave | awk '{print $3}')
		for j in $BC1
			do
			INET=$j
			SPEED=$(ethtool $j | grep Speed: | awk -F: '{print $2}' | sed -e 's/ //g')
			DUP=$(ethtool $j | grep Duplex: | awk -F: '{print $2}' | sed -e 's/ //g')
			AUTO=$(ethtool $j | grep Auto-negotiation: | awk -F: '{print $2}' | sed -e 's/ //g')
			LINK=$(ethtool $j | grep "Link detected:" | awk -F: '{print $2}' | sed -e 's/ //g')
			MAC=$(grep -A3 "Slave Interface: $j" /proc/net/bonding/* |  tail -1 | awk -F "addr:" '{print $2}'| sed -e 's/ //g')
			ACB=$(grep -H "$j" /proc/net/bonding/* | awk -F : '{print $1}' | awk -F "/" '{print $NF}' | uniq)
			ADD=$(ifconfig $ACB | grep inet 2> /dev/null |awk '{print $2}' | awk -F: '{print $2}')
			BNET=$ACB

			echo -e "$BNET\t\t\t$INET\t$LINK\t$MAC\t$SPEED\t$DUP\t$AUTO\t$ADD"
			done
			fi
done

	for i in $AL
		do
			LINK=$(ethtool $i | grep "Link detected:" | awk -F: '{print $2}' | sed -e 's/ //g')
			if [ $LINK = yes ]; then 
			INET=$i
			SPEED=$(ethtool $i | grep Speed: | awk -F: '{print $2}' | sed -e 's/ //g')
			DUP=$(ethtool $i | grep Duplex: | awk -F: '{print $2}' | sed -e 's/ //g')
			AUTO=$(ethtool $i | grep Auto-negotiation: | awk -F: '{print $2}' | sed -e 's/ //g')
			LINK=$(ethtool $i | grep "Link detected:" | awk -F: '{print $2}' | sed -e 's/ //g')
			MAC=$(ifconfig $i | grep "HWaddr" | awk -F "HWaddr" '{print $2}' | sed -e 's/ //g')
			ADD=$(ifconfig $i | grep inet 2> /dev/null |awk '{print $2}' | awk -F: '{print $2}')
				
				if [ -z $ADD ]; then 
						ADD=None
				fi
			BNET=$i

			echo -e "$BNET\t\t\t$INET\t$LINK\t$MAC\t$SPEED\t$DUP\t$AUTO\t$ADD"
			fi
		done
echo  -e "+-------------+---------------+---------+----------------+------------+-------+-----------+---------------------+"
	
		
		




done


for i in $LC
do
if [ $(echo $BC_1 | grep  -w $i | wc -l) -ne 0 ]; then

INET=$i
SPEED=$(ethtool $i | grep Speed: | awk -F: '{print $2}' | sed -e 's/ //g')
DUP=$(ethtool $i | grep Duplex: | awk -F: '{print $2}' | sed -e 's/ //g')
AUTO=$(ethtool $i | grep Auto-negotiation: | awk -F: '{print $2}' | sed -e 's/ //g')
LINK=$(ethtool $i | grep "Link detected:" | awk -F: '{print $2}' | sed -e 's/ //g')
MAC=$(grep -A3 "Slave Interface: $i" /proc/net/bonding/* |  tail -1 | awk -F "addr:" '{print $2}'| sed -e 's/ //g')
ACB=$(grep "$i" /proc/net/bonding/* | awk -F : '{print $1}' | awk -F "/" '{print $NF}' | uniq)
ADD=$(ifconfig $ACB | grep inet 2> /dev/null |awk '{print $2}' | awk -F: '{print $2}')
BNET=$ACB

echo -e "$BNET\t\t\t$INET\t$LINK\t$MAC\t$SPEED\t$DUP\t$AUTO\t$ADD"
else
LINK=$(ethtool $i | grep "Link detected:" | awk -F: '{print $2}' | sed -e 's/ //g')
if [ $LINK = yes ]; then 
INET=$i
SPEED=$(ethtool $i | grep Speed: | awk -F: '{print $2}' | sed -e 's/ //g')
DUP=$(ethtool $i | grep Duplex: | awk -F: '{print $2}' | sed -e 's/ //g')
AUTO=$(ethtool $i | grep Auto-negotiation: | awk -F: '{print $2}' | sed -e 's/ //g')
LINK=$(ethtool $i | grep "Link detected:" | awk -F: '{print $2}' | sed -e 's/ //g')
MAC=$(ifconfig $i | grep "HWaddr" | awk -F "HWaddr" '{print $2}' | sed -e 's/ //g')
ADD=$(ifconfig $i | grep inet 2> /dev/null |awk '{print $2}' | awk -F: '{print $2}')
if [ -z $ADD ]; then 
ADD=None
fi
BNET=$i
#echo -e "$BNET\t$INET\t$SPEED\t$DUP\t$AUTO\t$LINK\t$MAC\t$ADD"
echo -e "$BNET\t\t\t$INET\t$LINK\t$MAC\t$SPEED\t$DUP\t$AUTO\t$ADD"
fi 
fi
done
echo  -e "+-------------+---------------+---------+----------------+------------+-------+-----------+---------------------+"

#!/bin/sh
LC=$(ifconfig -a | egrep "eth" |awk '{print $1}' )
BC=$(ifconfig -a | grep bond | awk '{print $1}' )

for i in $BC
do
BC=$(cat /proc/net/bonding/$i | grep ^Slave | awk '{print $3}' | tr '\n' ',';printf "\n")
BOND="$BOND,$i,$BC"
done

#echo $BOND

BC_1=$(echo $BOND | sed -e 's/,,/\n/g;s/^,//g;s/,$//g;s/,/ /g')

#BC_2=$(echo $BC_1 | tr ' ' '\n')
#echo $BC_2
echo  -e "+-------------+---------------+---------+----------------+------------+-------+-----------+---------------------+"
echo -e "Interface\tP-Interface\tStatus\t\tMac-ID\t\tSpeed\t\tDuplex\tAuto-Neg\tIPADD"
echo  -e "+-------------+---------------+---------+----------------+------------+-------+-----------+---------------------+"
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

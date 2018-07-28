#!/usr/bin/ksh
#
# Health check script - Solaris
#
# Author: Pradeep K Pasupuleti
#
# Created on: 
#
ECHO="/bin/echo"

if [ -f "/usr/ucb/whoami" ]; then	
	WHOAMI="/usr/ucb/whoami"
else	
	$ECHO "Error: whoami command not found"
	exit
fi	

if [ $($WHOAMI) != "root" ]; then
	$ECHO "Please execute the script with the root user"
	exit 1
fi	

if [ -f "/bin/cat" ]; then	
	CAT="/bin/cat"
else
	$ECHO "Error: cat command not found"
	exit
fi

if [ -f "/bin/date" ]; then	
	DATE1="/bin/date"
else	
	$ECHO "Error: date command not found"
	exit
fi

if [ -f "/usr/bin/nawk" ]; then	
	NAWK="/usr/bin/nawk"
else	
	$ECHO "Error: nawk command not found"
	exit
fi

if [ -f "/usr/bin/grep" ]; then	
	GREP="/usr/bin/grep"
else	
	$ECHO "Error: grep command not found"
	exit
fi

if [ -f "/usr/bin/awk" ]; then
	AWK="/usr/bin/awk"
else	
	$ECHO "Error: awk command not found"
	exit
fi

if [ -f "/usr/bin/nawk" ]; then	
	NAWK="/usr/bin/nawk"
else	
	$ECHO "Error: nawk command not found"
	exit
fi

if [ -f "/usr/bin/sed" ]; then
	SED="/usr/bin/sed"
elif [ -f "/bin/sed" ]; then
	SED="/bin/sed"
else	
	$ECHO "Error: sed command not found"
	exit
fi

if [ -f "/usr/bin/egrep" ]; then	
	EGREP="/usr/bin/egrep"
else	
	$ECHO "Error: egrep command not found"
	exit
fi


if [ -f "/usr/local/soe/bin/bdf" ]; then
	BDF="/usr/local/soe/bin/bdf"
else
	$ECHO "Error: bdf command not found"
fi
$ECHO -e "\t+-------------+---------------+--------+-------------------+-----------------+-----------------+-----------+---------------------+"
	$ECHO -e "\t|  Interface  |  P-Interface  | Status |  Mac-ID           |  Speed          | Duplex          |  Auto-Neg |     IP Address      |"
	$ECHO -e "\t+-------------+---------------+--------+-------------------+-----------------+-----------------+-----------+---------------------+"
	for i in $BC
		do
		BC=$(cat /proc/net/bonding/$i | $GREP ^Slave | $AWK '{print $3}')
		for j in $BC
					do
						INET=$j
						SPEED=$(ethtool $j | $GREP Speed: | $AWK -F: '{print $2}' | $SED -e 's/ //g')
						DUP=$(ethtool $j | $GREP Duplex: | $AWK -F: '{print $2}' | $SED -e 's/ //g')
						AUTO=$(ethtool $j | $GREP Auto-negotiation: | $AWK -F: '{print $2}' | $SED -e 's/ //g')
						LINK=$(ethtool $j | $GREP "Link detected:" | $AWK -F: '{print $2}' | $SED -e 's/ //g')
						#MAC=$($GREP -A3 "Slave Interface: $j" /proc/net/bonding/* |  tail -1 | $AWK -F "addr:" '{print $2}'| $SED -e 's/ //g')
						MAC=$($CAT /proc/net/bonding/* | $SED  -n '/Slave Interface: '"${j}"'/,/Permanent/p' | tail -1 | $AWK -F "addr:" '{print $2}' | $SED -e 's/ //g')
						ACB=$($GREP -H "$j" /proc/net/bonding/* | $AWK -F : '{print $1}' | $AWK -F "/" '{print $NF}' | uniq)
						ADD=$(ifconfig $ACB | $GREP inet 2> /dev/null |$AWK '{print $2}' | $AWK -F: '{print $2}')
						BNET=$ACB

				#$ECHO -e "$BNET\t\t\t$INET\t$LINK\t$MAC\t$SPEED\t$DUP\t$AUTO\t$ADD"
					printf "\t""| %-11s | %-13s | %-6s | %-14s | %-15s | %-15s | %-9s | %-19s |\n" "$BNET" "$INET" "$LINK" "$MAC" "$SPEED" "$DUP" "$AUTO" "$ADD"
				done
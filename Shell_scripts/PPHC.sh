#!/bin/sh
#
# Health check script - SLES and RHEL
#
# Author: Pradeep Pasupuleti
#
# Created on: 
#
echo -n "Enter CRQNUMBER : " 
read CRQNUMBER

ECHO="/bin/echo"

if [ -f "/bin/cat" ]; then	
	CAT="/bin/cat"
else
	$ECHO "Error: cat command not found"
	exit
fi

if  [ -f "/bin/mount" ]; then
	MOUNT="/bin/mount"
else
	$ECHO "Error: mount command not found"
fi

if  [ -f "/bin/awk" ]; then
	AWK="/bin/awk"
else
	$ECHO "Error: awk command not found"
fi

if [ -f "/bin/hostname" ]; then
	HOSTNAME="/bin/hostname"
else
	$ECHO "Error: hostname command not found"
	exit
fi


if [ -f "/usr/sbin/ethtool" ]; then
	ETHTOOL="/usr/sbin/ethtool"
else 
	$ECHO "Error: ethtool command not found"
fi

if [ -f "/bin/mkdir" ]; then
	MKDIR="/bin/mkdir"
else
	$ECHO "Error: mkdir command not found"
fi

if [ -f "/sbin/ifconfig" ]; then
	IFCFG="/sbin/ifconfig"
else
	$ECHO "Error: ifconfig command not found"
fi

if [ -f "/bin/date" ]; then
	DATE="/bin/date"
else
	$ECHO "Error: date command not found"
fi

if [ -f "/bin/grep" ]; then	
	GREP="/bin/grep"
else
	$ECHO "Error: grep command not found"
	exit
fi

if [ -f "/bin/egrep" ]; then	
	EGREP="/bin/egrep"
else
	$ECHO "Error: Egrep command not found"
	exit
fi

if [ -f "/usr/bin/tr" ]; then	
	TR="/usr/bin/tr"
else
	$ECHO "Error: tr command not found"
	exit
fi

if [ -f "/usr/bin/tr" ]; then	
	TR="/usr/bin/tr"
else
	$ECHO "Error: tr command not found"
	exit
fi

if [ -f "/bin/sed" ]; then	
	SED="/bin/sed"
else
	$ECHO "Error: sed command not found"
	exit
fi


if [ -f "/usr/bin/sdiff" ]; then	
	SDIFF="/usr/bin/sdiff"
else
	$ECHO "Error: sdiff command not found"
	exit
fi

if  [ -f "/usr/bin/diff" ]; then
	DIFF="/usr/bin/diff"
else
	$ECHO "Error: diff command not found"
fi

if [ -f "/sbin/route" ]; then
	ROUTE="/sbin/route"
else
	$ECHO "Error: route command not found"
	exit
fi

if [ -f "/bin/netstat" ]; then
	NETSTAT="/bin/netstat"
else
	$ECHO "Error: netstat command not found"
fi

if [ -f "/sbin/chkconfig" ]; then
	CHKCON="/sbin/chkconfig"
else
	$ECHO "Error: chkconfig command not found"
fi

RED='\033[1;37;41m'
NC='\033[0m'
GREEN='\033[1;37;42m'
YELLOW='\033[1;37;43m'

bold=$(tput bold)
normal=$(tput sgr0)

PRE_MOUNT="$CRQNUMBER"_"pre_mount".csv
POST_MOUNT="$CRQNUMBER"_"post_mount".csv

PRE_LINK="$CRQNUMBER"_"pre_link".csv
POST_LINK="$CRQNUMBER"_"post_link".csv

PRE_LSPEED="$CRQNUMBER"_"pre_lspeed".csv
POST_LSPEED="$CRQNUMBER"_"post_lspeed".csv

PRE_BC="$CRQNUMBER"_"pre_bc".csv
POST_BC="$CRQNUMBER"_"post_bc".csv

PRE_RPM="$CRQNUMBER"_"pre_rpml".csv
POST_RPM="$CRQNUMBER"_"post_rpml".csv

PRE_FSTAB="$CRQNUMBER"_"pre_fstab".csv
POST_FSTAB="$CRQNUMBER"_"post_fstab".csv

PRE_FU="$CRQNUMBER"_"pre_fu".csv
POST_FU="$CRQNUMBER"_"post_fu".csv

PRE_IS="$CRQNUMBER"_"pre_is".csv
POST_IS="$CRQNUMBER"_"post_is".csv

PRE_MAC="$CRQNUMBER"_"pre_mac".csv
POST_MAC="$CRQNUMBER"_"post_mac".csv

PRE_ROUTE="$CRQNUMBER"_"pre_route".csv
POST_ROUTE="$CRQNUMBER"_"post_route".csv

PRE_NET="$CRQNUMBER"_"pre_net".csv
POST_NET="$CRQNUMBER"_"post_net".csv

PRE_UP="$CRQNUMBER"_"pre_up".csv
POST_UP="$CRQNUMBER"_"post_up".csv

PRE_CHKCON="$CRQNUMBER"_"pre_chkconfig".csv
POST_CHKCON="$CRQNUMBER"_"post_chkconfig".csv

PRE_CHKOFF="$CRQNUMBER"_"pre_chkconfig_off".csv
POST_CHKOFF="$CRQNUMBER"_"post_chkconfig_off".csv

PRE_SER="$CRQNUMBER"_"pre_services".csv
POST_SER="$CRQNUMBER"_"post_services".csv

PRE_SER_OFF="$CRQNUMBER"_"pre_services_off".csv
POST_SER_OFF="$CRQNUMBER"_"post_services_off".csv


HOSTNAME1=$($HOSTNAME -s)

DATE=$(date +%d-%m-%y)

#cdir="/var/tmp"
sdir=""$CRQNUMBER"_"$HOSTNAME1""

# create directory with CRQNUMBER
#$MKDIR $sdir

#change directory to create files
#cd $sdir


PRE_CHECK () {

	if [ -d "$sdir" ]; then
	echo "Directory already exists really want to replace"
	exit 1
	else 
	$MKDIR $sdir
	cd $sdir
		
	$ECHO "Device;MountPoint;Permissions" >> $PRE_MOUNT	
	$MOUNT | $AWK '{print $1";"$3";"$6}' | $EGREP -v "tmpfs|/\proc|sysfs|devpts|none|sunrp" >> $PRE_MOUNT

	# Checking for the FSTAB entries
	$ECHO "Device;MountPoint;FilesystemType;Options;Dump;Fsckorder" >> $PRE_FSTAB
	$CAT /etc/fstab | $GREP -v ^# | $SED '/^$/d' | $AWK '{print $1";"$2";"$3";"$4";"$5";"$6}' >> $PRE_FSTAB

	# Cheking for disk usage 
	$ECHO "Filesystem;Usage" >> $PRE_FU
	df -Ph |$EGREP -v "^Filesystem|tmpfs|/\proc|sysfs|devpts|none|sunrp" | $SED 's/%//g' | $AWK '{ if($5 >= 90) print$0}' | $AWK '{print $1";"$5}' >> $PRE_FU
	
	# Checking for the INODE Usage
	$ECHO "Inode;Usage" >> $PRE_IS
	df -ih |$EGREP -v "^Filesystem|tmpfs|/\proc|sysfs|devpts|none|sunrp" | $SED 's/%//g' | $AWK '{ if($5 >= 90) print$0}' | $AWK '{print $1";"$5}' >> $PRE_IS
	
	# Checking Link Status
	LC=$($IFCFG -a | $GREP  eth | wc -l)
	BC=$($IFCFG -a | $GREP bond | awk '{print $1}')
	BOC=$($IFCFG -a | $GREP bond | wc -l)

	$ECHO "Interface;LinkDetected" >> $PRE_LINK
	for i in `seq 0 $(expr "$LC" - 1)`; do $ECHO -n  "eth $i;"; $ETHTOOL eth$i 2> /dev/null | $GREP -i "Link detected" | $AWK -F ":" '{print $2}' || $ECHO ""  ;done >> $PRE_LINK
	if [ $BOC -ne 0 ] ; then
	for i in $BC; do $ECHO -n "$i;"; $CAT "/proc/net/bonding/$i" | grep "MII Status" | head -1 | awk '{print $3}'; done >> $PRE_LINK
	fi

	if [ $BOC -ne 0 ] ; then
	$ECHO "BondName;Interfaces" >> $PRE_BC
	for i in $BC; do $ECHO -n "$i;";$CAT /proc/net/bonding/$i | grep ^Slave | awk '{print $3}' | tr '\n' ';';printf "\n";done >> $PRE_BC
	fi
	
	
	# Checking for Link speed
	$ECHO "Interface;Supports auto-negotiation;Advertised auto-negotiation;Speed;Duplex" >> $PRE_LSPEED
	for i in `seq 0 $(expr "$LC" - 1)`; do $ECHO -n "eth$i"; $ETHTOOL  eth$i  | $EGREP "Speed|Duplex|auto-negotiation" | $GREP -v Link | $TR '\n' ' ' | $SED -e 's/ $/\n/' | $TR '\t' ':'  | $AWK -F: '{ print $1";"$3";"$5";"$7";"$9}' | $SED -e 's/ *//g'; done >> $PRE_LSPEED
	
	# Checking for MAC address
	$ECHO "Interface;MAC-Add" >> $PRE_MAC
	$IFCFG | $GREP -i "HWaddr" | $AWK '{print $1";"$5}' >> 	$PRE_MAC
	
	if [ -f $PRE_BC ]; then
	BMAC=$($SED -n '2,$p' $PRE_BC | $AWK -F ";" '{print $2"\n" $3}' | $SED '/^\s*$/d')
	for i in $BMAC;do $ECHO -n "$i;";$GREP -h -A3 "Slave Interface: $i" /proc/net/bonding/* |  tail -1 | $AWK -F "addr:" '{print $2}'| $SED -e 's/ //g';done >> $PRE_MAC
	fi

	#for i in `cat /proc/net/bonding/bond0 | grep ^Slave | awk '{print $3}'`; do echo "$i"| tr '\n' ';';cat /proc/net/bonding/bond0 | grep -A3 "Slave Interface: $i" | tail -1 | awk -F "addr:" '{print $2}'| sed -e 's/ //g';done

	# Checking for routing table
	$ECHO "Destination;Gateway;Genmask;Flags;Metric;Ref;Use;Iface" >> $PRE_ROUTE
	$ROUTE -n | $EGREP -v "Kernel|Destination" | $AWK '{print $1";"$2";"$3";"$4";"$5";"$6";"$7";"$8}' >> $PRE_ROUTE

	# Checking for netstat table
	$ECHO "Destination;Gateway;Genmask;Flags;MSS;Window;irtt;Iface" >> $PRE_NET
	$NETSTAT -nr | $EGREP -v "Kernel|Destination" | $AWK '{print $1";"$2";"$3";"$4";"$5";"$6";"$7";"$8}' >> $PRE_NET

	# Checking uptime and kernel
	$ECHO "Uptime;KernelVersion" >> $PRE_UP
	RET=$(uptime | $AWK -F "," '{print $1}' | $AWK -F "up" '{print $2}' | $SED 's/\ //g' | tr '/\n' ';' ; uname -r)
	$ECHO $RET >> $PRE_UP
	
	# Checking chkconfig list
	run=$(runlevel | awk '{print $2}')
	a=$(expr "$run" + 2)
	$CHKCON --list | $AWK -v col=$a '{print $1";" $col}' | $GREP ":on" >> $PRE_CHKCON
	$CHKCON --list | $AWK -v col=$a '{print $1";" $col}' | $GREP ":off" >> $PRE_CHKOFF

	# Checking for running services
	CHKC=$($CAT $PRE_CHKCON | $AWK -F ";" '{print $1}')
	CHKOF=$($CAT $PRE_CHKOFF | $AWK -F ";" '{print $1}')
	#for i in $CHKC; do /etc/init.d/$i status | $GREP running | $AWK '{print $1}';done >> $PRE_SER
	#/etc/init.d/$i status 2> /dev/null | $GREP running | $EGREP -v "not running|unsed" | $AWK '{print $1}';done >> $PRE_SER_OFF
	for i in $CHKOF; do 
	CHS=`/etc/init.d/$i status 2> /dev/null | $EGREP -v "not running|unused|unknown|dead" | grep -i "running"| wc -l`
	if [ $CHS -ne 0 ]; then
	echo "$i" >> $PRE_SER_OFF
	fi
	done
	
		
fi	
}

POST_CHECK () {
		
	cd $sdir
	rm -rf *post*	
	$ECHO "Device;MountPoint;Permissions" >> $POST_MOUNT
	$MOUNT | $AWK '{print $1";"$3";"$6}' | $EGREP -v "tmpfs|/\proc|sysfs|devpts|none|sunrp"  >> $POST_MOUNT

	# Checking for the FSTAB entries
	$ECHO "Device;MountPoint;FilesystemType;Options;Dump;Fsckorder" >> $POST_FSTAB
	$CAT /etc/fstab | $GREP -v ^# | $SED '/^$/d' | $AWK '{print $1";"$2";"$3";"$4";"$5";"$6}' >> $POST_FSTAB
		
	# Cheking for disk usage 
	$ECHO "Filesystem;Usage" >> $POST_FU
	df -Ph |$EGREP -v "^Filesystem|tmpfs|/\proc|sysfs|devpts|none|sunrp" | $SED 's/%//g' | $AWK '{ if($5 >= 90) print$0}' | $AWK '{print $1";"$5}' >> $POST_FU

	# Checking for the INODE Usage
	$ECHO "Inode;Usage" >> $POST_IS
	df -ih |$EGREP -v "^Filesystem|tmpfs|/\proc|sysfs|devpts|none|sunrp" | $SED 's/%//g' | $AWK '{ if($5 >= 90) print$0}' | $AWK '{print $1";"$5}' >> $POST_IS

	# Checking Link Status
	LC=$($IFCFG -a | $GREP  eth | wc -l)
	BC=$($IFCFG -a | $GREP bond | awk '{print $1}')
	BOC=$($IFCFG -a | $GREP bond | wc -l)
	
	$ECHO "Interface;LinkDetected" >> $POST_LINK
	for i in `seq 0 $(expr "$LC" - 1)`; do $ECHO -n  "eth $i;"; $ETHTOOL eth$i 2> /dev/null | $GREP -i "Link detected" | $AWK -F ":" '{print $2}' || $ECHO ""  ;done >> $POST_LINK
	if [ $BOC -ne 0 ] ; then
	for i in $BC; do $ECHO -n "$i;"; $CAT /proc/net/bonding/$i | grep "MII Status" | head -1 | awk '{print $3}'; done >> $POST_LINK
	fi
	
	if [ $BOC -ne 0 ] ; then
	$ECHO "BondName;Interfaces" >> $POST_BC
	for i in $BC; do $ECHO -n "$i;";$CAT /proc/net/bonding/$i | grep ^Slave | awk '{print $3}'  | tr '\n' ';';printf "\n";done >> $POST_BC
	fi

	# Checking for Link speed
	$ECHO "Interface;Supports auto-negotiation;Advertised auto-negotiation;Speed;Duplex" >> $POST_LSPEED
	for i in `seq 0 $(expr "$LC" - 1)`; do $ECHO -n "eth$i"; $ETHTOOL  eth$i  | $EGREP "Speed|Duplex|auto-negotiation" | $GREP -v Link | $TR '\n' ' ' | $SED -e 's/ $/\n/' | $TR '\t' ':'  | $AWK -F: '{ print $1";"$3";"$5";"$7";"$9}' | $SED -e 's/ *//g'; done >> $POST_LSPEED

	# Checking for MAC address
	$ECHO "Interface;MAC-Add" >> $POST_MAC
	$IFCFG | $GREP -i "HWaddr" | $AWK '{print $1";"$5}' >> 	$POST_MAC
	
	if [ -f $POST_BC ]; then
	BMAC=$($SED -n '2,$p' $PRE_BC | $AWK -F ";" '{print $2"\n" $3}' | $SED '/^\s*$/d')
	for i in $BMAC;do $ECHO -n "$i;";$GREP -h -A3 "Slave Interface: $i" /proc/net/bonding/* |  tail -1 | $AWK -F "addr:" '{print $2}'| $SED -e 's/ //g';done >> $POST_MAC
	fi

	# Checking for routing table
	$ECHO "Destination;Gateway;Genmask;Flags;Metric;Ref;Use;Iface" >> $POST_ROUTE
	$ROUTE -n | $EGREP -v "Kernel|Destination" | $AWK '{print $1";"$2";"$3";"$4";"$5";"$6";"$7";"$8}' >> $POST_ROUTE

	# Checking for netstat table
	$ECHO "Destination;Gateway;Genmask;Flags;MSS;Window;irtt;Iface" >> $POST_NET
	$NETSTAT -nr | $EGREP -v "Kernel|Destination" | $AWK '{print $1";"$2";"$3";"$4";"$5";"$6";"$7";"$8}' >> $POST_NET

	# Checking uptime and kernel
	$ECHO "Uptime;KernelVersion" >> $POST_UP
	RET=$(uptime | $AWK -F "," '{print $1}' | $AWK -F "up" '{print $2}' | $SED 's/\ //g' | tr '/\n' ';' ; uname -r)
	$ECHO $RET >> $POST_UP

	# Checking chkconfig list
	run=$(runlevel | awk '{print $2}')
	a=$(expr "$run" + 2)
	$CHKCON --list | $AWK -v col=$a '{print $1";" $col}' | $GREP ":on" >> $POST_CHKCON
	$CHKCON --list | $AWK -v col=$a '{print $1";" $col}' | $GREP ":off" >> $POST_CHKOFF

	# Checking for running services
	CHKC=$($CAT $PRE_CHKCON | $AWK -F ";" '{print $1}')
	CHKOF=$($CAT $PRE_CHKOFF | $AWK -F ";" '{print $1}')
	#for i in $CHKC; do /etc/init.d/$i status | $GREP running | $AWK '{print $1}';done >> $POST_SER
	#for i in $CHKOF; do /etc/init.d/$i status | $GREP running |  $GREP -v "not running" | $AWK '{print $1}';done >> $POST_SER_OFF
	for i in $CHKOF; do 
	CHS=`/etc/init.d/$i status 2> /dev/null | $EGREP -v "not running|unused|unknown|dead" | grep -i "running" | wc -l`
	if [ $CHS -ne 0 ]; then
	echo "$i" >> $POST_SER_OFF
	fi
	done
	
}


opt=$1

case $opt in 

pre)

		PRE_CHECK 
		
		DU=$($CAT $PRE_FU | wc -l)
		
		if [ $DU -ge 2 ]; then 
		for i in `$SED -n '2,$p' $PRE_FU | $AWK -F ";" '{print $1}'`; do 
		echo -e "FS usage >> 90% for ${bold}$i${normal}\t${YELLOW}[ALERT]${NC}"
		done
		fi

		IU=$($CAT $PRE_IS | wc -l)
		
		if [ $IU -ge 2 ]; then 
		for i in `$SED -n '2,$p' $PRE_IS | $AWK -F ";" '{print $1}'`; do 
		echo -e "Inode usage >> 90% for ${bold}$i${normal}\t${YELLOW}[ALERT]${NC}"
		done
		fi
		
		if [ -f  $PRE_SER_OFF ]; then
		for i in `$CAT $PRE_SER_OFF`;
		do
		printf "Chkconfig off for \"%s$i\" service \t${RED}[FAIL]${NC}\n"
		done
		fi
		echo -e "${bold}PRE checks data collected....${normal} \t\t\t${GREEN}[COMPLETED]${NC}"
		
		;;
post)	
		rm -rf *post*
		POST_CHECK 
		P_MOUNT=$($CAT $PRE_MOUNT | wc -l)
		PO_MOUNT=$($CAT $POST_MOUNT | wc -l)

		if [ $P_MOUNT -ne $PO_MOUNT ]; then

		#echo "####### Mount Point Detials #############"	
		#echo "Total mount points count on PRE : $P_MOUNT"
		#echo "Total mount points count on POST : $PO_MOUNT"

		for i in `sed -n '2,$p' $PRE_MOUNT`; 
		do
		grep $i $POST_MOUNT >> /dev/null

		if [ $? -ne 0 ]; then
		MS=$(echo $i | $AWK -F ";" '{print $1}')
		echo -e "Mount point check  ${bold}"$MS"${normal} \t\t\t${RED}[FAIL]${NC}"
		fi		
		done

		#echo "####################################"		
		else
		#echo "####### Mount Points count #########"
		echo -e "Total mount points count matched \t\t${GREEN}[PASS]${NC}"
		#echo "####################################"		
		fi
		
		P_FSTAB=$($CAT $PRE_FSTAB | wc -l)
		PO_FSTAB=$($CAT $POST_FSTAB | wc -l)
		
		if [ $P_FSTAB -ne $PO_FSTAB ]; then

		#echo "####### FSTAB count Detials #############"	
		#echo "Total FSTAB points count on PRE : $P_FSTAB"
		#echo "Total FSTAB points count on POST : $PO_FSTAB"

		for i in `sed -n '2,$p' $PRE_FSTAB`; 
		do
		grep $i $POST_FSTAB >> /dev/null

		if [ $? -ne 0 ]; then
		FS=$(echo $i | $AWK -F ";" '{print$2}')
		echo -e "FSTAB entry check is failed for ${bold}$FS${normal}\t\t${RED}[FAIL]${NC}"
		#done
		fi	
		done

		#echo "####################################"		
		else
		#echo "####### FSTAB entry count #########"
		echo -e "Total FSTAB entry count matched \t\t${GREEN}[PASS]${NC}"
		#echo "####################################"		
		fi

		DU=$($CAT $POST_FU | wc -l)
		
		if [ $DU -ge 2 ]; then 
		for i in `$SED -n '2,$p' $POST_FU | $AWK -F ";" '{print $1}'`; do 
		echo -e "FS usage >> 90% for ${bold}$i${normal}\t${YELLOW}[ALERT]${NC}"
		done
		#echo "#####################################"
		fi

		IU=$($CAT $POST_IS | wc -l)
		
		if [ $IU -ge 2 ]; then 
		for i in `$SED -n '2,$p' $POST_IS | $AWK -F ";" '{print $1}'`; do 
		echo -e "Inode usage >> 90% for ${bold}$i${normal}\t${YELLOW}[ALERT]${NC}"
		done
		fi
		
		
		LD=$($DIFF $PRE_LINK $POST_LINK | wc -l)
		#echo "##############  Link Status ###########"
		if [ $LD -ne 0 ]; then
		IFS=$'\n'
		#echo "Found difference in Link Status"
		for i in `$SED -n '2,$p' $PRE_LINK`;
		do 
		grep $i $POST_LINK >> /dev/null
		if [ $? -ne 0 ]; then
		echo -e "Link Differed for ${bold}$i${normal}\t\t\t${RED}[FAIL]${NC}"
		fi		
		done
		else
		echo -e "Total ${LC} interface(s) up and running fine\t${GREEN}[PASS]${NC}"
		fi
	
		MD=$($DIFF $PRE_MAC $POST_MAC | wc -l)
		#echo "########### MAC Status ###############"
		if [ $MD -ne 0 ]; then
		#echo " Found MAC ID difference"
		for i in `sed -n '2,$p' $PRE_MAC`;
		do 
		grep $i $POST_MAC >> /dev/null
		if [ $? -ne 0 ]; then
		echo -e "MAC difference for ${bold}$i${normal}\t${RED}[FAIL]${NC}"
		fi
		done
		else 
		printf "All MAC ID's are matched \t\t\t${GREEN}[PASS]${NC} \n"
		fi

		LSD=$($DIFF $PRE_LSPEED $POST_LSPEED | wc -l)
		#echo "########### LSPEED Status ############"
		if [ $LSD -ne 0 ]; then
		#echo " Found Link Speed difference"
		for i in `sed -n '2,$p' $PRE_LSPEED`;
		do 
		grep $i $POST_LSPEED >> /dev/null
		if [ $? -ne 0 ]; then
		echo -e "Link speed differed ${bold}$i${normal}\t${RED}[FAIL]${NC}"
		fi
		done
		else 
		printf "Total Interface Link-Speed are matched\t\t${GREEN}[PASS]${NC} \n"
		fi

		RD=$($DIFF $PRE_ROUTE $POST_ROUTE | wc -l)
		#echo "########### Routing Status ############"
		if [ $RD -ne 0 ]; then
		#echo "Found routing difference"
		for i in `sed -n '2,$p' $PRE_ROUTE`;
		do
		grep $i $POST_ROUTE >> /dev/null
		if [ $? -ne 0 ]; then
		echo -e "Route differed for ${bold}$i${normal}\t${RED}[FAIL]${NC}"
		fi
		done
		else 
		printf "Total routes are matched \t\t\t${GREEN}[PASS]${NC} \n"
		fi

		ND=$($DIFF $PRE_NET $POST_NET | wc -l)
		#echo "########### Routing Status ############"
		if [ $ND -ne 0 ]; then
		#echo "Found netstat difference"
		for i in `sed -n '2,$p' $PRE_NET`;
		do
		grep $i $POST_NET >> /dev/null
		if [ $? -ne 0 ]; then
		echo -e "netstat differed for ${bold}$i${normal}\t${RED}[FAIL]${NC}"
		fi
		done
		else 
		printf "Total netstat entries are matched\t\t${GREEN}[PASS]${NC} \n"
		fi


		CHD=$($DIFF $PRE_CHKCON $POST_CHKCON | wc -l)
		#echo "########### Chkconfig Status ############"
		if [ $CHD -ne 0 ]; then
		#echo "Found chkconfig difference"
		for i in `sed -n '2,$p' $PRE_CHKCON`;
		do
		grep $i $POST_CHKCON >> /dev/null
		if [ $? -ne 0 ]; then
		echo -e "chkconfig differed for ${bold}$i${normal}\t\t${RED}[CROSSCHECK]${NC}"
		fi
		done
		else 
		printf "Total chkconfig list are matched\t\t${GREEN}[PASS]${NC} \n"
		fi


		SRD=$($DIFF $PRE_SER $POST_SER | wc -l)
		#echo "### Running Services with chkconfig on ###"
		if [ $SRD -ne 0 ]; then
		#echo "Found difference in running services"
		for i in `sed -n '2,$p' $PRE_SER`;
		do
		grep $i $POST_SER >> /dev/null
		if [ $? -ne 0 ]; then
		echo -e "Services running differed for ${bold}$i${normal}\t\t${RED}[FAIL]${NC}"
		fi
		done
		else 
		printf "Total running services list are matched\t\t${GREEN}[PASS]${NC} \n"
		fi


		if [ -f  $PRE_SER_OFF ]; then
		#echo "## Below services were running in pre check plz cross check #####"
		for i in `$CAT $PRE_SER_OFF`;
		do
		printf "Chkconfig off for \"%s$i\" service \t${RED}[FAIL]${NC}\n"
		done
		#echo "###########################"
		fi
	
		;;
*)		
		$ECHO "Usage: $0 {pre|post}"
		;;
esac


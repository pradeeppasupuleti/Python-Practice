#!/bin/bash
#
# Health check script - SLES and RHEL
#
# Author: Aneel Ramireddy
#
# Created on: 
#

ECHO="/bin/echo"

if [ -f "/bin/cat" ]; then	
	CAT="/bin/cat"
else
	$ECHO "Error: cat command not found"
	exit
fi

if [ -f "/bin/ps" ]; then	
	PS="/bin/ps"
else
	$ECHO "Error: ps command not found"
	exit
fi

if [ -f "/usr/bin/tr" ]; then	
	TR="/usr/bin/tr"
else
	$ECHO "Error: tr command not found"
	exit
fi

if [ -f "/usr/sbin/dmidecode" ]; then	
	DMIDECODE="/usr/sbin/dmidecode"
elif [  -f "/var/sysadmin/dmidecode" ]; then
	DMIDECODE="/var/sysadmin/dmidecode"
else
	$ECHO "Error: dmicode command not found"
	exit
fi

if [ -f "/bin/hostname" ]; then	
	HOSTNAME="/bin/hostname"
else
	$ECHO "Error: hostname command not found"
	exit
fi

if [ -f "/bin/date" ]; then	
	DATE1="/bin/date"
else	
	$ECHO "Error: date command not found"
	exit
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
	$ECHO "Error: egrep command not found"
	exit
fi

if [ -f "/usr/bin/awk" ]; then
	AWK="/usr/bin/awk"
else	
	$ECHO "Error: awk command not found"
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
if [ -f "/usr/bin/head" ]; then
	HEAD="/usr/bin/head"
else	
	$ECHO "Error: head command not found"
	exit
fi

if [ -f "/sbin/vgs" ]; then
	VGS="/sbin/vgs"
elif [ -f "/usr/sbin/vgs" ]; then
	VGS="/usr/sbin/vgs"
else	
	$ECHO "Error: vgs command not found"
	exit
fi

if [ -f "/sbin/lvs" ]; then
	LVS="/sbin/lvs"
elif [ -f "/usr/sbin/lvs" ]; then
	LVS="/usr/sbin/lvs"
else	
	$ECHO "Error: lvs command not found"
	exit
fi

if [ -f "/sbin/lvdisplay" ]; then
	LVDISPLAY="/sbin/lvdisplay"
elif [ -f "/usr/sbin/lvdisplay" ]; then
	LVDISPLAY="/usr/sbin/lvdisplay"
else	
	$ECHO "Error: lvdisplay command not found"
	exit
fi




DATE=$($DATE1 "+%m/%d/%Y %H:%M")
HOSTNAME1=$($HOSTNAME -s)
OUTPUTFILE="$HOSTNAME1-HC.csv"

HW_DETIALS () {
	Vendor=$($DMIDECODE | $GREP "BIOS Information" -C 3 | $GREP Vendor | $AWK -F: '{ print $2 }')
	Product=$($DMIDECODE | $GREP "System Information" -C 3 | $GREP "Product Name" | $AWK -F: '{ print $2 }')
	Serial=$($DMIDECODE | $GREP "System Information" -C 4 | $GREP "Serial Number" | $AWK -F: '{ print $2 }')
	BIOS_VER=$($DMIDECODE | $GREP "BIOS Information" -C 2 | $GREP "Version" | $AWK -F: '{ print $2 }')
	PROC_TYPE=$($CAT /proc/cpuinfo | $GREP 'model name' | uniq | $AWK -F ":" '{print $2}')
	NO_PROCS=$($CAT /proc/cpuinfo | $GREP -i processor | wc -l)
	NO_CORES=$($CAT /proc/cpuinfo | $GREP "cpu cores" | $AWK -F ":" '{total += $2}END {print total}')
}

OS_DETIALS () {
	OS_VER=$($CAT /etc/[rS]*-release | $TR '\n' ' ' | $SED -e 's/$/\n/')
	if [ -f /etc/SuSE-release ]; then	
		OS_VER_SHORT=$($CAT /etc/SuSE-release  | $GREP SLES | $AWK '{ print $2 }')
		if [ ! -z "$OS_VER_SHORT" ]; then
			 OS_VER_SHORT=$($CAT /etc/SuSE-release  | $GREP VERSION | $AWK -F= '{ print "SLES-" $2 }' | $SED 's/ //g')
		fi
		else
		OS_VER_SHORT=$($CAT /etc/redhat-release | $AWK -F "release" '{print $2}' | $AWK -F "." '{print "RHEL-"$1}' | $SED 's/ //g')
	fi

	KERNEL_VER=$(uname -r)
}

MEMORY_DETIALS () {
	PH_MEM_TOT=$(free -m | $GREP Mem | $AWK '{print $2}')
	SWAP_MEM_TOT=$(free -m |  $GREP -i swap | $AWK '{print $2}')
	PH_MEM_USED=$(free -m | $GREP Mem | $AWK '{print $3}')
	SWAP_MEM_USED=$(free -m |  $GREP -i swap | $AWK '{print $3}')
	IDLE_CPU=$(sar -u 1 1 | $GREP Average | $AWK '{print $7}')
	CPU_USAGE=$($ECHO "100 - $IDLE_CPU" | bc)
	CPU_LOAD=$(uptime | $AWK -F "load average:" '{print $2}' | $SED -e 's/ //g')
}
	
PROCESS_CHECK () {
	DEFUNCT_LIST=$($PS aux | $AWK '"[Zz]" ~ $8 { printf("(%s; %s; %s; PID = %d)", $1, $11, $9, $2); }' | $SED -e 's/$/\n/')
	if [ "$DEFUNCT_LIST" = "" ]; then	
		DEFUNCT_LIST="No defunct processes"
	fi
}

USM_CHECK () {
	#/opt/perf/bin/perfstat  > /dev/null 2>&1
	if [ -f "/opt/perf/bin/perfstat" ]; then
		OUTPUT=$(/opt/perf/bin/perfstat)
		ERR_CNT=$($ECHO "$OUTPUT" | $EGREP -i "Aborting|not active" -c)
		if [ $ERR_CNT -ne 0 ]; then	
			USM_STATUS="Few agents are running in USM"
		else	
			USM_STATUS="Running fine"
		fi
	else
		USM_STATUS="USM agent not found"
	fi
}

BACKUP_CHECK () {
	/usr/openv/netbackup/bin/bpclimagelist > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		RECENT_BK=$(/usr/openv/netbackup/bin/bpclimagelist | $HEAD -3 | tail -1 | $AWK '{ print $1, $2, $7 $8 }')
		BACKUP="Working and recent backup is on $RECENT_BK"
	else	
		BACKUP="No backup"
	fi
}

FS_CHECK () {
	FS_FULL=""
	CUR_IFS=$IFS
	IFS='
	'
	for i in `df -hP | $EGREP -v '^Filesystem|^tmpfs'`
	do
		FS=$($ECHO $i | $AWK '{ print $6 }')
		USED=$($ECHO $i | $AWK '{ print $5 }' | $SED -e 's/%//')
		if [ $USED -gt 85 ]; then
			FS_FULL="$FS_FULL; $FS ${USED}%"
		fi
	done
	
	FS_FULL=$($ECHO $FS_FULL | $SED -e 's/^; //')
	
	if [ "$FS_FULL" = "" ]; then
		FS_FULL="Filesystems are fine"
	fi
	
	for j in `df -iP  | $EGREP -v '^Filesystem|^tmpfs' |  $AWK '{ print $6, $5}'`
	do
		#echo $j
		IUSED=$($ECHO $j | $AWK '{ print $2 }' | $SED -e 's/%//')
		if [ "$IUSED" = "-" ]; then
                continue;
        fi
		if [ $IUSED -gt 85 ]; then
			FS_INODEFULL="$FS_INODEFULL; $j"
		fi
	done
	
	if [ "$FS_INODEFULL" = "" ]; then
		FS_INODEFULL="All Filesystems are fine"
	fi
	IFS=$CUR_IFS
}

DISK_CHECK () {
	#NO_DISKS=$(lsblk -io KNAME,TYPE | $GREP disk | $AWK '{ print $1 }' | wc -l)
	NO_DISKS=$(fdisk -l 2> /dev/null | $EGREP "Disk /dev/sd|Disk /dev/cciss" | wc -l)
	if [ `$ECHO $Vendor | $GREP 'Dell' -c` -eq 1 ]; then
		omreport storage controller > /dev/null 2>&1
		if [ $? -ne 0 ]; then
			CTRL="No controller found"
			RAID=$CTRL
			PDISK_STATUS=$CTRL
			VDISK_STATUS=$CTRL
			BATTERY_STATUS=$CTRL
		else	
			CTRL=$(omreport storage controller | $GREP ^ID |  $AWK -F: '{ print $2 }' | $SED 's/ //g')
			# RAID Level
			RAID=$(omreport storage vdisk controller=0 | $GREP ^Layout | $AWK -F: '{ print $2 }' | $SED -e 's/ *//g')
			
			# Physical disk check
			omreport storage pdisk controller=$CTRL > /dev/null 2>&1
			if [ $? -ne 0 ]; then
				CUR_IFS=$IFS
				IFS=$'\n'
				#for i in `omreport storage adisk controller=0  | $AWK '/^ID/{a=$0;getline; print a,$0 }' | $AWK -F: '{ print $2 $3 $4 }' | $AWK '{ print $1, $3 }'`
				for i in `omreport storage adisk controller=0 | $AWK '/^ID/{a=$0;getline;print a,$0}'  | $AWK '{ print  $3,$6 }'`
				do
					if [ $($ECHO $i | $GREP -i "Ok" -c) -eq 0 ]; then
					PDISK_STATUS="$PDISK_STATUS, `$ECHO $i | $AWK '{ print $1 }'`"
					fi
				done
				if [ -z "$PDISK_STATUS" ]; then
					PDISK_STATUS="All disks are fine"
				else
					PDISK_STATUS="Following disk(s) failed: `$ECHO $PDISK_STATUS | $SED -e 's/^,//'`"				
				fi
				IFS=$CUR_IFS
			else
				IFS=$'\n'
				for i in `omreport storage pdisk controller=0  | $AWK '/^ID/{a=$0;getline;print a,$0}'  | $AWK '{ print  $3,$6 }'`
				do
					if [ $($ECHO $i | $GREP -i "Ok" -c) -eq 0 ]; then
					PDISK_STATUS="$PDISK_STATUS, `$ECHO $i | $AWK '{ print $1 }'`"
					fi
				done
				if [ -z "$PDISK_STATUS" ]; then
					PDISK_STATUS="All disks are fine"
				else
					PDISK_STATUS="Following disk(s) failed: `$ECHO $PDISK_STATUS | $SED -e 's/^,//'`"				
				fi
			fi
						
			# Logical drive
			CUR_IFS=$IFS
			IFS=$'\n'
			for i in `omreport storage vdisk controller=0  | $AWK '/^ID/{a=$0;getline;print a,$0}'  | $AWK '{ print  $3,$6 }'`
			do
				if [ $($ECHO $i | $GREP -i "Ok" -c) -eq 0 ]; then
					VDISK_STATUS="$VDISK_STATUS, `$ECHO $i | $AWK '{ print $1 }'`"
				fi
			done
			IFS=$CUR_IFS
			if [ -z "$VDISK_STATUS" ]; then
				VDISK_STATUS="All logical drive(s) fine"
			else
				VDISK_STATUS="Following logical drive(s) failed: `$ECHO $VDISK_STATUS | $SED -e 's/^,//'`"				
			fi
			
			# RAID Battery check
			BATTERY_STATUS=$(omreport storage battery | $GREP ^Status | $AWK -F: '{ print $2 }' | $SED -e 's/ *//g')
		fi
			
	elif [ `$ECHO $Vendor | $GREP 'IBM' -c` -eq 1  ]; then
		if [ -f /usr/RaidMan/arcconf ]; then
			ARCCONF="/usr/RaidMan/arcconf"
		else
			RAID="Tool not found"
			PDISK_STATUS="Tool not found"
			VDISK_STATUS="Tool not found"
			BATTERY_STATUS="Tool not found"
			return
		fi
		
		#RAID level check
		RAID=$($ARCCONF GETCONFIG 1 | $GREP "RAID level" | $AWK -F: '{ print $2 }' | $SED 's/ //g' | tr '\n' ',' | $SED 's/,$/\n/')
		
		# Physical drive check
		CUR_IFS=$IFS
		IFS=$'\n'
		for i in `$ARCCONF GETCONFIG 1 PD | $EGREP 'State|Reported Channel,Device' |  $GREP 'State' -A1 | $AWK -F: '{ print $2 }'  | $AWK '{a=$0; getline; print $0, a }'`
		do
			if [ $($ECHO $i | $EGREP  'Online|Standby' -c) -eq 0 ]; then
				PDISK_STATUS="$PDISK_STATUS, `$ECHO $i | $AWK '{ print $1 }'`"
			fi
		done
		IFS=$CUR_IFS
		if [ -z "$PDISK_STATUS" ]; then
			PDISK_STATUS="All disks are fine"
		else
			PDISK_STATUS="Following disk(s) failed: `$ECHO $PDISK_STATUS | $SED -e 's/^,//'`"				
		fi
		
		# Logical drive check
		CUR_IFS=$IFS
		IFS=$'\n'
		for i in `$ARCCONF GETCONFIG 1 LD | $EGREP 'Logical drive number|Status of logical drive' | $AWK '{ print $NF }' | $AWK '{a=$0; getline; print a, $0 }'`
		do
			if [ $($ECHO $i | $GREP -i "Okay" -c) -eq 0 ]; then
				VDISK_STATUS="$VDISK_STATUS, `$ECHO $i | $AWK '{ print $1 }'`"
			fi
		done
		IFS=$CUR_IFS
		if [ -z "$VDISK_STATUS" ]; then
			VDISK_STATUS="All logical drive(s) fine"
		else
			VDISK_STATUS="Following logical drive(s) failed: `$ECHO $VDISK_STATUS | $SED -e 's/^,//'`"				
		fi
		
		# Battery check
		BATTERY_STATUS=$($ARCCONF GETCONFIG 1 | $GREP -A2 "Controller Battery Information"  | $GREP "Status" | $AWK -F: '{ print $2 }')
	elif [ `$ECHO $Vendor | $GREP 'HP' -c` -eq 1  ]; then
		if [ -f "/usr/sbin/hpacucli" ]; then
			HPACUCLI="/usr/sbin/hpacucli"
		else
			RAID="Tool not found"
			PDISK_STATUS="Tool not found"
			VDISK_STATUS="Tool not found"
			BATTERY_STATUS="Tool not found"
			return
		fi
		
		CTRL=$($HPACUCLI ctrl all show |  $GREP "^Smart Array" | $AWK '{ print $6 }' | $GREP -v '^$')
		
		#RAID level check
		RAID=$($HPACUCLI  ctrl slot=$CTRL logicaldrive all show | $GREP ", RAID" | $AWK -F, '{ print $2 }' | $AWK '{ print $2 }' | tr '\n' ',' | $SED 's/,$/\n/' )
		
		DRIVE_TYPE=$($HPACUCLI ctrl slot=$CTRL show config | $GREP array | $HEAD -1  | $AWK '{ print $3 }' | $SED 's/(//' | $SED 's/,//')
		
		if [ "$DRIVE_TYPE" = "Parallel" ]; then	
			DRIVE_STATUS_FIELD="11"
		else
			DRIVE_STATUS_FIELD="10"
		fi
		
		# Physical drive check
		CUR_IFS=$IFS
		IFS=$'\n'
		for i in `$HPACUCLI ctrl slot=$CTRL physicaldrive all show | $GREP physicaldrive | $AWK -v field=$DRIVE_STATUS_FIELD '{ print $2, $field }' | $SED 's/)//g'`
			do
				if [ $($ECHO $i | $EGREP  'OK' -c) -eq 0 ]; then
					PDISK_STATUS="$PDISK_STATUS, `$ECHO $i | $AWK '{ print $1 }'`"
				fi
			done
		IFS=$CUR_IFS
		if [ -z "$PDISK_STATUS" ]; then
			PDISK_STATUS="All disks are fine"
		else
			PDISK_STATUS="Following disk(s) failed: `$ECHO $PDISK_STATUS | $SED -e 's/^,//'`"				
		fi
		
		# Logical drive check
		CUR_IFS=$IFS
		IFS=$'\n'
		for i in `$HPACUCLI ctrl slot=$CTRL logicaldrive all show | $GREP logicaldrive | $AWK '{ print $2, $7 }' | $SED 's/)//g'`
			do
				if [ $($ECHO $i | $GREP -i "OK" -c) -eq 0 ]; then
					VDISK_STATUS="$VDISK_STATUS, `$ECHO $i | $AWK '{ print $1 }'`"
				fi
			done
		IFS=$CUR_IFS
		if [ -z "$VDISK_STATUS" ]; then
			VDISK_STATUS="All logical drive(s) fine"
		else
			VDISK_STATUS="Following logical drive(s) failed: `$ECHO $VDISK_STATUS | $SED -e 's/^,//'`"				
		fi
		
		# Battery check
		BATTERY_STATUS=$($HPACUCLI ctrl slot=$CTRL show | $GREP "Battery/Capacitor Status:" | $AWK -F: '{ print $2 }' | $SED 's/ //g')
		
			fi
	
					
                	
}

LV_CHECK () {

		VG=$($VGS | $GREP -v "VG" | $AWK '{print $1}' | wc -l)
		LV=$($LVS | $GREP -v "VG" | wc -l)
				
		for i in `$LVS | $GREP -v LSize| $AWK '{print "/dev/"$2"/"$1}'`
			do
				if [ $($LVDISPLAY $i | $GREP "LV Status" | $AWK -F "LV Status" '{print $1}' | $GREP "NOT available" -c) -ne 0 ]; then
					LV_STATUS="$LV_STATUS,`$ECHO $i | $AWK '{ print $1 }'`"
				fi
            done
                
		IFS=$CUR_IFS
             if [ -z "$LV_STATUS" ]; then
                LV_STATUS="All logical drive(s) fine"
            else
                LV_STATUS="Following logical drive(s) failed: $ECHO LV_STATUS"
             fi
				
				}
				
IP_DETAILS () {
#BC=$(ifconfig -a | $GREP bond | $AWK '{print $1}' )
BC=$(ifconfig -a | $AWK '{ print $1 }' | $GREP bond | $GREP -v ':[0-9]*$')
AL=$(ifconfig -a | $GREP -A1 eth | $GREP -B1 inet | $GREP eth | $AWK '{print $1}')


OS_VER=$(cat /etc/[rS]*-release | $TR '\n' ' ' | $SED -e 's/$/\n/')
	if [ -f /etc/SuSE-release ]; then	
		OS_VER_SHORT=$(cat /etc/SuSE-release  | $GREP SLES | $AWK '{ print $2 }')
		if [ ! -z "$OS_VER_SHORT" ]; then
			 OS_VER_SHORT=$(cat /etc/SuSE-release  | $GREP VERSION | $AWK -F= '{ print "SLES-" $2 }' | $SED 's/ //g' | $SED -e 's/SLES-8.[0-9]/SLES-8/')
		fi
		else
		OS_VER_SHORT=$(cat /etc/redhat-release | $AWK -F "release" '{print $2}' | $AWK -F "." '{print "RHEL-"$1}' | $SED 's/ //g')
	fi

	$ECHO -e "\t+-------------+---------------+--------+-------------------+-----------------+-----------------+-----------+---------------------+"
	$ECHO -e "\t|  Interface  |  P-Interface  | Status |  Mac-ID           |  Speed          | Duplex          |  Auto-Neg |     IP Address      |"
	$ECHO -e "\t+-------------+---------------+--------+-------------------+-----------------+-----------------+-----------+---------------------+"
	for i in $BC
		do
			if [ "$OS_VER_SHORT" = "SLES-8" ]; then
				for j in  $(cat /proc/net/$i/info  | $GREP ^Slave | $AWK '{ print $3 }')
					do
						INET=$j
						SPEED=$(ethtool $j | $GREP Speed: | $AWK -F: '{print $2}' | $SED -e 's/ //g')
						DUP=$(ethtool $j | $GREP Duplex: | $AWK -F: '{print $2}' | $SED -e 's/ //g')
						AUTO=$(ethtool $j | $GREP Auto-negotiation: | $AWK -F: '{print $2}' | $SED -e 's/ //g')
						LINK=$(ethtool $j | $GREP "Link detected:" | $AWK -F: '{print $2}' | $SED -e 's/ //g')
						MAC=$(ifconfig $j | $GREP "HWaddr" | $AWK -F"HWaddr" '{print $2}' | $SED -e 's/ //')
						ACB=$($GREP -H "$j" /proc/net/bond*/* | $GREP "Slave Interface:" | $AWK -F "/" '{print $4}')
						ADD=$(ifconfig $ACB | $GREP inet 2> /dev/null |$AWK '{print $2}' | $AWK -F: '{print $2}')
						BNET=$ACB
						printf "\t""| %-11s | %-13s | %-6s | %-14s | %-15s | %-15s | %-9s | %-19s |\n" "$BNET" "$INET" "$LINK" "$MAC" "$SPEED" "$DUP" "$AUTO" "$ADD"
					done
			else
			BC1=$(cat /proc/net/bonding/$i | $GREP ^Slave | $AWK '{print $3}')
				for j in $BC1
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
			fi
		done

	for i in $AL
		do
			LINK=$(ethtool $i | $GREP "Link detected:" | $AWK -F: '{print $2}' | $SED -e 's/ //g')
			if [ $LINK = yes ]; then 
				INET=$i
				SPEED=$(ethtool $i | $GREP Speed: | $AWK -F: '{print $2}' | $SED -e 's/ //g')
				DUP=$(ethtool $i | $GREP Duplex: | $AWK -F: '{print $2}' | $SED -e 's/ //g')
				AUTO=$(ethtool $i | $GREP Auto-negotiation: | $AWK -F: '{print $2}' | $SED -e 's/ //g')
				LINK=$(ethtool $i | $GREP "Link detected:" | $AWK -F: '{print $2}' | $SED -e 's/ //g')
				MAC=$(ifconfig $i | $GREP "HWaddr" | $AWK -F "HWaddr" '{print $2}' | $SED -e 's/ //g')
				ADD=$(ifconfig $i | $GREP inet 2> /dev/null |$AWK '{print $2}' | $AWK -F: '{print $2}')
				
				if [ -z $ADD ]; then 
						ADD=None
				fi
					BNET=$i

			#$ECHO -e "$BNET\t\t\t$INET\t$LINK\t$MAC\t$SPEED\t$DUP\t$AUTO\t$ADD"
			printf "\t""| %-11s | %-13s | %-6s | %-14s | %-15s | %-15s | %-9s | %-19s |\n" "$BNET" "$INET" "$LINK" "$MAC" "$SPEED" "$DUP" "$AUTO" "$ADD"
			fi
		done
	$ECHO -e "\t+-------------+---------------+--------+-------------------+-----------------+-----------------+-----------+---------------------+"
	


}
				
				
				
NW_CHECK () {
	INTERFACES=$(ifconfig -a | $GREP eth | $AWK '{ print $1 }')
	BONDS=$(ifconfig -a | $GREP bond | $AWK '{ print $1 }' | $GREP -v ':[0-9]*$')
	
	
	for i in $BONDS
	do	
		if [ "$OS_VER_SHORT" = "SLES-8" ]; then
			for j in  $($CAT /proc/net/$i/info  | $GREP ^Slave | $AWK '{ print $3 }')
			do
				if [ "$(ethtool  $j | $GREP Link | $AWK '{ print $3 }')" = "no" ]; then
					NO_LINK="$NO_LINK; $j"
				fi
				if [ "$(ethtool $j | $GREP "Duplex:" | $AWK -F: '{ print $2 }' | $SED 's/ //g')" != "Full" ];then 
					DUPLEX="$DUPLEX; $j"
				fi
				INTERFACES=$($ECHO $INTERFACES | $SED -e "s/$j//")
			done
		#elif [ "$OS_VER_SHORT" = "SLES-9" ]; then
		else
			for j in  $($CAT /proc/net/bonding/$i  | $GREP ^Slave | $AWK '{ print $3 }')
			do
				if [ "$(ethtool  $j | $GREP Link | $AWK '{ print $3 }')" = "no" ]; then
					NO_LINK="$NO_LINK; $j"
					
				fi
				if [ "$(ethtool $j | $GREP "Duplex:" | $AWK -F: '{ print $2 }' | $SED 's/ //g')" != "Full" ];then 
					DUPLEX="$DUPLEX; $j"
					
				fi
				INTERFACES=$($ECHO $INTERFACES | $SED -e "s/$j//")
			done
		fi
		
	done
	
	INTERFACES=$($ECHO $INTERFACES | $SED -e 's/  */ /g')
	if [ ! -z "$INTERFACES" ]; then
		for k in $INTERFACES	
		do
			if [ $(ifconfig $k | $GREP "inet addr" | $AWK '{ print $2 }' | $AWK -F: '{ print $2 }' | wc -l) -eq 1 ]; then
				if [ "$(ethtool  $k | $GREP Link | $AWK '{ print $3 }')" = "no" ]; then
					NO_LINK="$NO_LINK; $k"	
				fi
				if [ "$(ethtool $k | $GREP "Duplex:" | $AWK -F: '{ print $2 }' | $SED 's/ //g')" != "Full" ];then 
					DUPLEX="$DUPLEX; $k"					
				fi
			fi
		done
	fi

	if [ -z "$NO_LINK" ]; then
		NW_STATUS="All links are fine"
	else
		NW_STATUS="No link found for `$ECHO $NO_LINK | $SED s'/^, //' | $SED s'/;//'`"
	fi
	
	if [ -z "$DUPLEX" ]; then
		NW_STATUS="$NW_STATUS with Full duplex"
	else
		NW_STATUS="$NW_STATUS and (`$ECHO $DUPLEX | $SED s'/;//'`) are not configured with Full duplex"
	fi
	
	}
	
VERITAS_CHECK () {

		RPM_C=$(rpm -qa | $GREP -i vrtsvcs | wc -l )
if [ $RPM_C -ne 0 ]; then
                NODES=$(/opt/VRTSvcs/bin/hasys -list | $TR '\n' '  ' | $SED 's/ $/\n/')
        NODE_C=$(/opt/VRTSvcs/bin/hasys -list | wc -l)
		$ECHO -e "\t No of nodes in cluster		: $NODE_C"
        $ECHO -e "\t+-----------------+-------------+--------+"
        $ECHO -e "\t|     System      |    State    | Frozen |"
        $ECHO -e "\t+-----------------+-------------+--------+"

        for i in $($ECHO $NODES)
                do
					C_HST=$(/opt/VRTSvcs/bin/hastatus -sum | $GREP "\-\- System" -A`expr "$NODE_C" + 1` | $SED '/^$/d' | $GREP "$i" | $AWK '{print $2}')
					C_STAT=$(/opt/VRTSvcs/bin/hastatus -sum | $GREP "\-\- System" -A`expr "$NODE_C" + 1` | $SED '/^$/d' | $GREP "$i" | $AWK '{print $3}')
					C_FROZ=$(/opt/VRTSvcs/bin/hastatus -sum | $GREP "\-\- System" -A`expr "$NODE_C" + 1` | $SED '/^$/d' | $GREP "$i" | $AWK '{print $4}')
					printf "\t""| %-15s | %-11s | %-6s |\n" "$C_HST" "$C_STAT" "$C_FROZ"
                done
        $ECHO -e "\t+-----------------+-------------+--------+"
        CLUS_S=$(/opt/VRTSvcs/bin/hastatus -sum | $GREP "ClusterService" | $AWK '{print $6}' | $GREP "ONLINE" -c)
                if [ $CLUS_S -eq 0 ]; then
                        CLUS_SER=$(/opt/VRTSvcs/bin/hastatus -sum | $GREP "ClusterService" | $GREP -v "ONLINE" | $AWK '{print $3}' | $TR '\n' ' ')
                        CLUS_SER="Cluster service is not running $CLUS_SER"
                else
                        CLUS_SER="Cluster Service runnig fine."
                fi

        CVM=$(/opt/VRTSvcs/bin/hastatus -sum | $GREP cvm | $GREP "ONLINE" | wc -l)
                if [ $CVM -ne $NODE_C ]; then
                        CVM_STAT=$(/opt/VRTSvcs/bin/hastatus -sum | $GREP cvm | $GREP -v "ONLINE" | $AWK '{print $3}')
                        CVM_STAT="Cvm is not online for $CVM_STAT"
                else
                        CVM_STAT="All cvm service are running fine"
                fi


                PSG=$(/opt/VRTSvcs/bin/hastatus -sum | $GREP psg | $AWK '{print $2}'| uniq)
                for i in $PSG;
					do
                        #if [ "$(/opt/VRTSvcs/bin/hastatus -sum | $GREP "\-psg" |$GREP "db-ucsmsvt-psg" | $GREP "ONLINE" -c)" -ne $NODE_C ]; then
                        #if [ "$(/opt/VRTSvcs/bin/hastatus -sum | $GREP "\-psg" |$GREP "$i" | $GREP "ONLINE" -c)" -ne 1 ]; then
                        if [ "$(/opt/VRTSvcs/bin/hastatus -sum | $GREP "\-psg" |$GREP "$i" | $GREP "ONLINE" -c)" -ne $NODE_C ]; then
                                #PSG_STAT="$PSG_STAT;$i"
                                PSG_STAT="$PSG_STAT;$i"
                        fi

					done
                if [ -z "$PSG_STAT" ]; then

                        PSG_STATUS="All psg group are running fine."
                else

                        PSG_STATUS="Psg group is offline for (`$ECHO $PSG_STAT | $SED -e 's/;/ /g'`)"
                fi
                
				
				FSG=$(/opt/VRTSvcs/bin/hastatus -sum | $GREP fsg | $AWK '{print $2}'| uniq)
                for i in $FSG;
					do
                        if [ "$(/opt/VRTSvcs/bin/hastatus -sum | $GREP "\-fsg" |$GREP "$i" | $GREP "ONLINE" -c)" -ne 1  ]; then
                                FSG_STAT="$FSG_STAT;$i"
                        fi

					done
                if [ -z "$FSG_STAT" ]; then

                        FSG_STATUS="All fsg group are running fine."
                else

                        FSG_STATUS="Fsg group is offline for (`$ECHO $FSG_STAT | $SED -e 's/;/ /g'`)"
                fi

        $ECHO -e "\n"
        $ECHO -e "\t Cluster Status             : $CLUS_SER"
        $ECHO -e "\t Cvm Status         : $CVM_STAT"
        $ECHO -e "\t Psg Status         : $PSG_STATUS"
        $ECHO -e "\t Fsg Status                 : $FSG_STATUS"

		
				if [ $(egrep -i "WARNING|ERROR" /var/VRTSvcs/log/engine_A.log | wc -l) -gt 0 ]; then
					VCSL_STATUS="Errors found. Please refer ${HOSTNAME1}-vcs-errors.log"
					$EGREP -i "WARNING|ERROR" /var/VRTSvcs/log/engine_A.log > ${HOSTNAME1}-vcs-errors.log
				else
					VCSL_STATUS="No errors found"
				fi
		
		$ECHO -e "\t Other Erros		: $VCSL_STATUS"		
        else
        $ECHO -e "\t Cluster Status		: Host is not in cluster"
fi
				
			 }
			 
VXVM_CHECK () {
RPM_C=$(rpm -qa | $GREP -i vxvm | wc -l )
	if [ $RPM_C -ne 0 ]; then
		DISK_G=$(vxdg  list | $AWK '{print $1}' | $GREP -v "NAME")
		DISK_GC=$(vxdg  list | $AWK '{print $1}' | $GREP -v "NAME" | wc -l)

for i in $DISK_G
        do
                if [ $(vxprint -g $i | $EGREP "^v" | $AWK '{print $4}' | $GREP -v -c "ENABLED") -ne 0 ]; then

                        V_STATUS="$V_STATUS,$i"
                fi
        done
if [ -z "$V_STATUS" ]; then
        V_STATUS="All Voluumes under DiskGroup(s) fine."
else
        V_STATUS="Volumes under Diskgroup(s) failed:`echo $V_STATUS | sed 's/,/ /'`"
fi

for i in $DISK_G
        do
                if [ $(vxprint -g $i | $EGREP "^sd" | $AWK '{print $4}' | $GREP -v -c "ENABLED") -ne 0 ]; then

                        SD_STATUS="$SD_STATUS,$i"
                fi
        done
if [ -z "$SD_STATUS" ]; then
        SD_STATUS="All Sub Disks under DiskGroup(s) fine."
else
        SD_STATUS="Subdisk under Diskgroup(s) failed:`$ECHO $SD_STATUS | sed 's/,/ /'`"
fi

for i in $DISK_G
        do
                for j in $(vxprint -g $i | $GREP "^dm" | $AWK '{print $2}')
                        do
                                if [ $(vxdisk list | $GREP "$j" | $AWK '{print $5}' | $GREP online -c ) -eq 0 ]; then
                                        PD_STATUS="$PD_STATUS,$j"
                                fi
                        done
        done

        if [ -z "$PD_STATUS" ]; then

                PD_STATUS="All Physical disk(s) are online."
        else
                PD_STATUS="Physical disk offline for : `$ECHO $PD_STATUS | sed 's/,/ /'`"
        fi

		
		
$ECHO -e "\tDisk groups count   : $DISK_GC"
$ECHO -e "\tVolumes Status              : $V_STATUS"
$ECHO -e "\tSubDisk(s) Status   : $SD_STATUS"
$ECHO -e "\tP Disk Status               : $PD_STATUS"

else
$ECHO -e "\t Vertias Volume Status      : Host not configure with Vertias Volume."
fi

	

}
	


DMESG_CHECK () {
	if [ $(dmesg | $EGREP -i 'I/O error|ECC error' | wc -l ) -gt 0 ]; then	
		DMESG_STATUS="Errors found. Please refer ${HOSTNAME1}-dmesg-errors.log"
		dmesg | $EGREP -i 'I/O error|ECC error' > ${HOSTNAME1}-dmesg-errors.log
	else
		DMESG_STATUS="No errors found"
	fi
}

MESG_CHECK () {
	if [ $($EGREP -i 'error|err' /var/log/messages | $GREP -v "Authenti$CATion failure" | $GREP -v "Invalid credentials" | $GREP -v "Constraint violation" | $GREP -v "error: ssh_msg_send: write" | $GREP -v "PAM: User not known" | wc -l ) -gt 0 ]; then	
		MESG_STATUS="Errors found. Please refer ${HOSTNAME1}-messages-errors.log"
		$EGREP -i 'error|err' /var/log/messages | $GREP -v "Authenti$CATion failure" | $GREP -v "Invalid credentials" | $GREP -v "Constraint violation" | $GREP -v "error: ssh_msg_send: write" | $GREP -v "PAM: User not known" > ${HOSTNAME1}-messages-errors.log
	else
		MESG_STATUS="No errors found"
	fi
}

## Main
$ECHO "***************************Server's health check has started ($DATE)*********************************"

# Collecting uptime
UPTIME=`/usr/bin/uptime`
#$ECHO $UPTIME | $GREP -c 'day'
if [ `$ECHO $UPTIME | $GREP -c 'day'` -eq 1 ]; then
	UPTIME_DAYS=`$ECHO $UPTIME | $AWK '{ print $3 }'`
else
	UPTIME_DAYS="0"
fi

$ECHO "HW details:"
$ECHO "-----------"
HW_DETIALS
$ECHO -e "\t Hostname     		:  $HOSTNAME1"
$ECHO -e "\t Vendor       		: $Vendor"
$ECHO -e "\t Product      		: $Product"
$ECHO -e "\t Serial No    		: $Serial"
$ECHO -e "\t Bios Version 		: $BIOS_VER"
$ECHO -e "\t Processor Type		: $PROC_TYPE"
$ECHO -e "\t No of Processor	:  $NO_PROCS"
$ECHO -e "\t Total cores		:  $NO_CORES"
$ECHO -e "\n"


$ECHO "Memory and CPU Utilization:"
$ECHO "---------------------------"
MEMORY_DETIALS
$ECHO -e "\t Total  Memory		: $PH_MEM_TOT M"
$ECHO -e "\t Used Memory		: $PH_MEM_USED M"
$ECHO -e "\t SWAP Memory		: $SWAP_MEM_TOT M"
$ECHO -e "\t Used Swaap Memory	: $SWAP_MEM_USED M"
$ECHO -e "\t CPU Utilization  %	: $CPU_USAGE"
$ECHO -e "\t Load average 1,5,15	: $CPU_LOAD"
$ECHO -e "\n"

$ECHO "OS details:"
$ECHO "-----------"
OS_DETIALS
$ECHO -e "\t OS Version     	: $OS_VER"
$ECHO -e "\t Uptime         	: $UPTIME_DAYS day(s)"
$ECHO -e "\t Kernel Version 	: $KERNEL_VER"
$ECHO -e "\n"

$ECHO "Processes details:"
$ECHO "------------------"
PROCESS_CHECK
$ECHO -e "\t Defunct List   	: $DEFUNCT_LIST"
$ECHO -e "\n"

$ECHO "USM:"
$ECHO "----"
USM_CHECK
$ECHO -e "\t Agent Status   	: $USM_STATUS"
$ECHO -e "\n"

$ECHO "Backup:"
$ECHO "-------"
BACKUP_CHECK
$ECHO -e "\t Status   		: $BACKUP"
$ECHO -e "\n"

$ECHO "Filesystems:"
$ECHO "------------"
FS_CHECK
$ECHO -e "\t Space status 		: $FS_FULL"
$ECHO -e "\t Inode status 		: $FS_INODEFULL"
$ECHO -e "\n"

$ECHO "Disks:"
$ECHO "------"
DISK_CHECK
$ECHO -e "\t No of Disks       	: $NO_DISKS"
$ECHO -e "\t Raid level(s)     	: $RAID"
$ECHO -e "\t Physical drive(s) 	: $PDISK_STATUS"
$ECHO -e "\t Logical drive(s)  	: $VDISK_STATUS"
$ECHO -e "\t Battery           	: $BATTERY_STATUS"
$ECHO -e "\n"

$ECHO "LVM Detials:"
$ECHO "------------"
LV_CHECK
$ECHO -e "\t No Of VG(s)		: $VG"
$ECHO -e "\t No Of LVM(s)		: $LV"
$ECHO -e "\t Lvm Status 		: $LV_STATUS"
$ECHO -e "\n"

$ECHO "Network:"
$ECHO "--------"
NW_CHECK
$ECHO -e "\t Status			: $NW_STATUS"
$ECHO -e "\n"

$ECHO "Vertias Cluster Check"
$ECHO "---------------------"
VERITAS_CHECK
$ECHO -e "\n"

$ECHO "Veritas Volume Manger"
$ECHO "---------------------"
VXVM_CHECK
$ECHO -e "\n"

$ECHO "Interface Details:"
$ECHO "------------------"
IP_DETAILS
$ECHO -e "\n"

$ECHO "Other Errors:"
$ECHO "-------------"
DMESG_CHECK
MESG_CHECK
$ECHO -e "\t 		$MESG_STATUS"
$ECHO -e "\t 		$DMESG_STATUS"
$ECHO ""
DATE=$($DATE1 "+%m/%d/%Y %H:%M")
$ECHO "**************************Server's health check has completed ($DATE)********************************"


#$ECHO "$DATE | $HOSTNAME1 | $Vendor | $Product | $Serial | $BIOS_VER | $OS_VER | $UPTIME_DAYS | $KERNEL_VER | $DEFUNCT_LIST | $USM_STATUS | $BACKUP | $FS_FULL | $FS_INODEFULL | $NO_DISKS | $RAID | $PDISK_STATUS | $VDISK_STATUS | $BATTERY_STATUS | $NW_STATUS | $MESG_STATUS | $DMESG_STATUS " | $SED 's/  */ /g' > $OUTPUTFILE
$ECHO "$HOSTNAME1 | $OS_VER | $UPTIME_DAYS | $DEFUNCT_LIST | $USM_STATUS | $BACKUP_CHECK | $FS_FULL | $FS_INODEFULL | $NO_DISKS | $RAID | "

Server Name	Support Group	OS Versioon	Uptime	Defunct process	Sudo (Working/Not Working)	USM Status	Backup Status	File System Usage 	FS inode Usage	Disks on OS	RAID Level ( 0/1/5 )	Disk Failure	Logical Disk Status	RAID Battery Status	Network Issues	Any error in /var/log/messages	Any error in dmesg
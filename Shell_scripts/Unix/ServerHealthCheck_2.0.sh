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

if [ -f "/usr/sbin/ndd" ]; then
	NDD="/usr/sbin/ndd"
else
	$ECHO "Error: ndd command not found"
fi

if [ -f "/usr/sbin/dladm" ]; then
	DLADM="/usr/sbin/dladm"
else
	$ECHO "Error: dladm command not found"
fi	

if [ -f "/usr/bin/kstat" ]; then
	KSTAT="/usr/bin/kstat"
else
	$ECHO "Error: Kstat command not found"
fi

if [ -f "/usr/bin/netstat" ]; then
	NETSTAT="/usr/bin/netstat"
else
	$ECHO "Error: netstat command not found"
fi

if [ -f "/sbin/ifconfig" ]; then
	IFCFG="/sbin/ifconfig"
elif [ -f "/usr/sbin/ifconfig" ]; then
	IFCFG="/usr/sbin/ifconfig"
else
	$ECHO "Error: ifconfig command not found"
fi


DATE=$($DATE1 "+%m/%d/%Y %H:%M")
HOSTNAME1=$(uname -n)
OS_VER=$($CAT /etc/release | grep -i "Solaris" | $AWK '{print $1" "$2}')


OS_DETAILS ()
{
	OS_VER=$($CAT /etc/release | $GREP -i "Solaris" | $AWK '{print $1" "$2}')
	KER_ID=$(uname -X | $GREP "KernelID" | $AWK '{print $3}')
	UPTIME=$(uptime | $AWK '{print $3}')
	LOAD_AVG=$(uptime | $NAWK -F "load average:" '{print $2}' | $SED -e 's/ //')
	VENDOR=$(prtdiag  | $GREP -i "System Configuration")
}

HW_DETAILS ()
{
	PROC_VER=$(psrinfo -pv | $AWK '{print $2}' | uniq)
	N_PROC=$(psrinfo -p)
	V_PROC=$(psrinfo -v | wc -l)
	P_MEM=$(prtconf | $GREP Memory | cut -d ":" -f2 | $AWK '{print $1}')
	if [ -f "/opt/SUNWsneep/bin/showplatform" ]; then
	SERIAL=$(/opt/SUNWsneep/bin/showplatform)
	else 
	SERIAL=$(/usr/sbin/eeprom |grep -i ChassisSerialNumber | awk '{print $3}')
	fi
	
	}

FS_CHECK ()
{
for i in $(df -k | grep -v "^$"| $GREP -v "^Filesystem" | $AWK '{print $1}')
	do
		FS=$(df -k | grep -v "^$" | $GREP $i | $AWK '{print $6}')
		USED=$(df -k | grep -v "^$" | $GREP $i | $AWK '{ print $5 }' | sed -e 's/%//')
		if [ "$USED" -gt 85 ]; then
			FS_FULL="$FS_FULL; $FS ${USED}%"
		fi
	done

		if [ -z "FS_FULL" ]; then
			FS_FULL="All File system(s) fine."
		else
			FS_FULL="`$ECHO $FS_FULL| $SED -e 's/^;//'`"				
		fi
		
for j in $($BDF -i | $GREP -v "^Filesystem" | $AWK '{print $1}')
	do
		IUSED=$($BDF -i | $GREP $i | $AWK '{ print $8 }' | $SED -e 's/%//')
		if [ "$IUSED" -gt 85 ]; then
				FS_INODEFULL="$FS_INODEFULL; $j"
		fi
	done
			if [ "$FS_INODEFULL" = "" ]; then
				FS_INODEFULL="All Filesystems are fine."
			fi
			
			
DISKERR=$(iostat -En  | grep -i hard | awk '$7 > 30 || $10 > 30 {print $0}' |wc -l | awk '{print $1}')
        if [ $DISKERR -eq 0 ]
        then
            DISK_STATUS="No Disk errors found"
        else
			DISK_STATUS="Found "$DISKERR" disk errors. Please check the "/tmp/"$HOSTNAME1"_eror.log" for errors."
			$ECHO "+++++++++++++ Hard Disk Erros +++++++++++++++" >> "/tmp/"$HOSTNAME1"_eror.log"
			iostat -En  |grep -i hard | awk '$7 > 30 || $10 > 30 {print $0}' >> "/tmp/"$HOSTNAME1"_eror.log"
        fi
}

PROCESS_CHECK () {
	DEFUNCT_LIST=$(ps -elf | grep -i defunct | wc -l | sed -e 's/[ \t]*//')
	if [ "$DEFUNCT_LIST" = "0" ]; then	
		DEFUNCT_LIST="No defunct processes."
	else 
	DEFUNCT_LIST="Found $DEFUNCT_LIST defunct processes."
	fi
}

BACKUP_CHECK () {
	BACKUP_VER=$(cat /usr/openv/netbackup/bin/version)
	/usr/openv/netbackup/bin/bpclimagelist > /dev/null 2>&1
	
	if [ $? -eq 0 ]; then
		RECENT_BK=$(/usr/openv/netbackup/bin/bpclimagelist | head -3 | tail -1 | $AWK '{ print $1, $2, $7 $8 }')
		BACKUP="Working and recent backup is on $RECENT_BK."
	else	
		BACKUP="No backup"
	fi
}

USM_CHECK () {
	#/opt/perf/bin/perfstat  > /dev/null 2>&1
	if [ -f "/opt/perf/bin/perfstat" ]; then
		OUTPUT=$(/opt/perf/bin/perfstat)
		ERR_CNT=$($ECHO "$OUTPUT" | $EGREP -i -c "Aborting|not active|Aborted")
		if [ $ERR_CNT -ne 0 ]; then	
			USM_STATUS="Few agents are not running in USM."
		else	
			USM_STATUS="Running fine."
		fi
	else
		USM_STATUS="USM agent not found."
	fi
}
NET_CHECK () {
#auto neg=ndd -get /dev/bge1 adv_autoneg_cap
#link_status=ndd -get /dev/bge0 link_status
#number of interface = netstat -in
#link_speed=ndd -get /dev/bge0 link_speed

#NET=$(netstat -in | grep -v "Name" | awk '{print $1}' | grep -v "^$")

	$ECHO  "\t+-------------+--------+-------------------+-----------------+-----------------+-----------+---------------------+"
	$ECHO  "\t|  Interface  | Status |  Mac-ID           |  Speed          | Duplex          |  Auto-Neg |     IP Address      |"
	$ECHO  "\t+-------------+--------+-------------------+-----------------+-----------------+-----------+---------------------+"

	BGNET=$($NETSTAT -in | $GREP bge | $AWK '{print $1}')
	if [ ! -z $BGNET ]; then
	
	for i in $BGNET
		do
			INET=$i
			if [ $($NDD -get /dev/$i link_status) -ge 0 ]; then
			LINK="UP"
			else
			LINK="DOWN"
			fi
			
			MAC=$($IFCFG $i | $GREP ether | $AWK '{print $2}')
			ADD=$($IFCFG $i | $GREP inet | $AWK '{print $2}')
			
			if [ $($NDD -get /dev/$i adv_autoneg_cap) -ge 1 ]; then
			AUTO="ON"
			else
			AUTO="OFF"
			fi
			
			SPEED=$($NDD -get /dev/$i link_speed)

			if [ $($NDD -get /dev/$i link_duplex) -ge 1 ]; then
			DUP="FULL"
			else
			DUP="HALF"
			fi
		printf "\t""| %-11s | %-6s |  %-15s  | %-15s | %-15s | %-9s | %-19s |\n" "$INET" "$LINK" "$MAC" "$SPEED" "$DUP" "$AUTO" "$ADD"
		done
	fi
	
	CENET=$($NETSTAT -in | $GREP ce | $AWK '{print $1}' | $NAWK -F"ce" '{print $2}')
	if [ ! -z $CENET ]; then
	
		for i in $CENET
			do
				INET="ce$i"
				if [ $($KSTAT -m ce -i $i -s link_up | $GREP "link_up" | $AWK '{print $2}') -eq 1 ]; then
				LINK="UP"
				else
				LINK="DOWN"
				fi
				
				MAC=$($IFCFG ce$i | $GREP ether | $AWK '{print $2}')
				ADD=$($IFCFG ce$i | $GREP inet | $AWK '{print $2}')
				
				if [ $($KSTAT -m ce -i $i -s cap_autoneg | $GREP "cap_autoneg" | $AWK '{print $2}') -ge 1 ]; then
				AUTO="ON"
				else
				AUTO="OFF"
				fi
				
				SPEED=$($KSTAT -m ce -i 0 -s link_speed | $GREP "link_speed" | $AWK '{print $2}')

				if [ $($KSTAT -m ce -i 0 -s link_duplex | $GREP "link_duplex" | $AWK '{print $2}') -ge 1 ]; then
				DUP="FULL"
				else
				DUP="HALF"
				fi
				printf "\t""| %-11s | %-6s |  %-15s  | %-15s | %-15s | %-9s | %-19s |\n" "$INET" "$LINK" "$MAC" "$SPEED" "$DUP" "$AUTO" "$ADD"
		
		done
		
	fi
	
	NXGENET=$($NETSTAT -in | $GREP nxge | $AWK '{print $1}')
	if  [ ! -z $NXGENET ]; then
		for i in $NXGENET
			do
				INET="$i"
				if [ $( $DLADM show-dev $i 2> /dev/null | awk '{print $3;}') -eq 1 ]; then
				LINK="UP"
				else
				LINK="DOWN"
				fi
				MAC=$($IFCFG $i | $GREP ether | $AWK '{print $2}')
				ADD=$($IFCFG $i | $GREP inet | $AWK '{print $2}')
				
				if [ $($NDD -get /dev/$i adv_autoneg_cap) -ge 1 ]; then
				AUTO="ON"
				else
				AUTO="OFF"
				fi
				SPEED=$($DLADM show-dev $i 2> /dev/null | awk '{print $5;}')
				DUP=$(show-dev $i 2> /dev/null | awk '{print $NF;}' | tr "[a-z]" "[A-Z]")
				printf "\t""| %-11s | %-6s |  %-15s  | %-15s | %-15s | %-9s | %-19s |\n" "$INET" "$LINK" "$MAC" "$SPEED" "$DUP" "$AUTO" "$ADD"
			done
	fi
	
	$ECHO  "\t+-------------+--------+-------------------+-----------------+-----------------+-----------+---------------------+"
}


CHECK_META () {
        
		METASYN=$(metastat | grep -i "%" | wc -l | sed -e 's/^[ \t]*//')
		if [ $METASYN -eq 0 ]; then
			META_SYN_STAT="No meta device's are syncing in Background."
        else
			META_SYN_STAT="Found $METASYN device's are syncing in Background."
		fi
		
		METADEV=$(metastat | grep -i maintenance | wc -l | sed -e 's/^[ \t]*//')
		if [ $METADEV -eq 0 ]; then
			META_DEV_STAT="No meta device's are in Maintenance mode."
        else
			META_DEV_STAT="Found $METASYN meta device's are in Maintenance mode."
		fi
		        
}

VXVM_CHECK () {

VXVM_VER=`/usr/sbin/modinfo  |grep -i vxvm | grep -v portal |awk '{print $8}'| sed -e 's/://g' | uniq`
RPM_C=`/usr/sbin/modinfo  |grep -i vxvm | grep -v portal |awk '{print $8}' | cut -d "_" -f2 | cut -c 5- | wc -l`
	if [ $RPM_C -ne 0 ]; then
		DISK_G=`vxdg  list | awk '{print $1}' | grep -v "NAME"`
		DISK_GC=`vxdg  list | awk '{print $1}' | grep -v "NAME" | wc -l`

for i in $DISK_G
        do
                if [ `vxprint -g $i | grep "^v" | awk '{print $4}' | grep "^v" | grep -v "ENABLED" | wc -l` -ne 0 ]; then

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
                if [ `vxprint -g $i | grep "^sd" | awk '{print $4}' | grep -v  "ENABLED"| wc -l` -ne 0 ]; then

                        SD_STATUS="$SD_STATUS,$i"
                fi
        done
if [ -z "$SD_STATUS" ]; then
        SD_STATUS="All Sub Disks under DiskGroup(s) fine."
else
        SD_STATUS="Subdisk under Diskgroup(s) failed:`echo $SD_STATUS | sed 's/,/ /'`"
fi

for i in $DISK_G
        do
                for j in `vxprint -g $i | grep "^dm" | awk '{print $2}'`
                        do
                                if [ `vxdisk list | grep "$j" | awk '{print $5}' | grep online | wc -l` -eq 0 ]; then
                                        PD_STATUS="$PD_STATUS,$j"
                                fi
                        done
        done

        if [ -z "$PD_STATUS" ]; then

                PD_STATUS="All Physical disk(s) are online."
        else
                PD_STATUS="Physical disk offline for : `echo $PD_STATUS | sed 's/,/ /'`"
        fi

	
	#SAN_ST=`vxdmpadm listenclosure all | grep -i disconnected | awk '{print $1}' | tr '\n' ';' ; printf "\n"`
	SAN_ST=`vxdmpadm listenclosure all | grep -i disconnected | awk '{print $1}' | wc -l`
	SNA_STC=`vxdmpadm listenclosure all | grep -i disconnected | awk '{print $1}' | tr '\n' ';' ; printf "\n"`
		
		if [ $SAN_ST -eq 0 ]; then
			SAN_STATUS="All SAN storages are attached."
		else
			SAN_STATUS="`echo $SNA_STC SAN` encloser were disconnected."
		fi
		
		
echo "\tVeritas FileSystem  : $VXVM_VER"		
echo "\tDisk groups count   : $DISK_GC"
echo "\tVolumes Status      : $V_STATUS"
echo "\tSubDisk(s) Status   : $SD_STATUS"
echo "\tP Disk Status       : $PD_STATUS"
echo "\tSAN DISK Status     : $SAN_STATUS"
else
echo "\t Veritas Volume Status      : Host not configure with Vertias Volume Manager."
fi

}



## Main
$ECHO "***************************Server's health check has started ($DATE) on $HOSTNAME1 *********************************"

$ECHO "OS details:"
$ECHO "-----------"
OS_DETAILS
$ECHO "\t Hostname		: $HOSTNAME1"
$ECHO "\t OS Version		: $OS_VER"
$ECHO "\t Kernel ID      	: $KER_ID"
$ECHO "\t Vendor			: $VENDOR"
$ECHO "\t Uptime in day(s)	: $UPTIME day(s)"
$ECHO "\t Load Average		: $LOAD_AVG"
$ECHO "\n"

$ECHO "HW details:"
$ECHO "-----------"
HW_DETAILS
$ECHO "\t Processor Version	: $PROC_VER"
$ECHO "\t Serial Number		: $SERIAL"
$ECHO "\t No of Physical Procs	: $N_PROC"
$ECHO "\t No of Virtual Procs	: $N_PROC"
$ECHO "\t Physical Memory	: $P_MEM (MB)"
$ECHO "\n"

$ECHO "FileSystem Utilization:"
$ECHO "-----------------------"
FS_CHECK
$ECHO "\t Space status 		: $FS_FULL"
$ECHO "\t Inode status 		: $FS_INODEFULL"
$ECHO "\t Disk Errors status	: $DISK_STATUS"
$ECHO "\n"

$ECHO "Processes details:"
$ECHO "------------------"
PROCESS_CHECK
$ECHO "\t Defunct List   	: $DEFUNCT_LIST"
$ECHO "\n"

$ECHO "Backup:"
$ECHO "-------"
BACKUP_CHECK
$ECHO "\t Version   		: $BACKUP_VER"
$ECHO "\t Status   		: $BACKUP"
$ECHO "\n"

$ECHO "Meta Devices Check:"
$ECHO "-------------------"
CHECK_META
$ECHO "\t Sync status		: $META_SYN_STAT"
$ECHO "\t Maintenance status	: $META_DEV_STAT"
$ECHO "\n"

$ECHO "USM:"
$ECHO "----"
USM_CHECK
$ECHO "\t Agent Status   	: $USM_STATUS"
$ECHO "\n"

$ECHO "Veritas Volume Manger and SAN DISK"
$ECHO "----------------------------------"
VXVM_CHECK
$ECHO "\n"

$ECHO "Network Details:"
$ECHO "----------------"
NET_CHECK
$ECHO "\n"

$ECHO "***************************Server's health check has completed ($DATE) on $HOSTNAME1 *********************************"


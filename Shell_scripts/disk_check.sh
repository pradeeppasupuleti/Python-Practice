#!/bin/sh
#
# Disk and Raid Battery Validation - SLES and RHEL (HP,IBM & DELL)
#
# Author: Pradeep K Pasupuleti
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


DISK_CHECK () {
Vendor=$($DMIDECODE | $GREP "BIOS Information" -C 3 | $GREP Vendor | $AWK -F: '{ print $2 }')

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
				for i in `omreport storage adisk controller=0  | $AWK '/^ID/{a=$0;getline; print a,$0 }' | $AWK -F: '{ print $2 $3 $4 }' | $AWK '{ print $1, $3 }'`
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
				for i in `omreport storage pdisk controller=0  | $AWK '/^ID/{a=$0;getline; print a,$0 }' | $AWK -F: '{ print $2 $3 $4 }' | $AWK '{ print $1, $3 }'`
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
			for i in `omreport storage vdisk controller=0  | $AWK '/^ID/{a=$0;getline; print a,$0 }' | $AWK -F: '{ print $2 $3 $4 }' | $AWK '{ print $1, $3 }'`
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
		if [ -z $BATTERY_STATUS ]; then 
		
			BATTERY_STATUS="No Battery found."
		else
			BATTERY_STATUS="$BATTERY_STATUS"
		fi
fi                	
}

DISK_CHECK

echo -e "\t Raid Level		: $RAID"
echo -e "\t Physical disk Status	: $PDISK_STATUS"
echo -e "\t Logical drive Status	: $VDISK_STATUS"
echo -e "\t Battery chek		: $BATTERY_STATUS"





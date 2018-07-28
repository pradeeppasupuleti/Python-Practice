#!/usr/bin/ksh

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

DATE=$($DATE1 "+%m/%d/%Y %H:%M")
HOSTNAME1=$(uname -n)
OS_VER=$($CAT /etc/release | grep -i "Solaris" | $AWK '{print $1" "$2}')


OS_DETAILS ()
{
	OS_VER=$($CAT /etc/release | $GREP -i "Solaris" | $AWK '{print $1" "$2}')
	KER_ID=$(uname -X | $GREP "KernelID" | $AWK '{print $3}')
	UPTIME=$(uptime | $AWK '{print $3}')
}

HW_DETAILS ()
{
	PROC_VER=$(psrinfo -pv | $AWK '{print $2}' | uniq)
	N_PROC=$(psrinfo -p)
	V_PROC=$(psrinfo -v | wc -l)
	P_MEM=$(prtconf | $GREP Memory | cut -d ":" -f2 | $AWK '{print $1}')
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
			FS_FULL="All File system(s) fine"
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
				FS_INODEFULL="All Filesystems are fine"
			fi
			
			
DISKERR=$(iostat -En  |grep -i hard | awk '$7 > 30 || $10 > 30 {print $0}' |wc -l | awk '{print $1}')
        if [ $DISKERR -eq 0 ]
        then
            DISK_STATUS="No Disk errors found"
        else
			DISK_STATUS="Found "$DISKERR" disk errors. Please check the "/tmp/"$HOSTNAME1"_eror.log" for errors."
			$ECHO "+++++++++++++ Hard Disk Erros +++++++++++++++" >> "/tmp/"$HOSTNAME1"_eror.log"
			iostat -En  |grep -i hard | awk '$7 > 30 || $10 > 30 {print $0}' >> "/tmp/"$HOSTNAME1"_eror.log"
        fi
}


## Main
$ECHO "***************************Server's health check has started ($DATE) on $HOSTNAME1 *********************************"

$ECHO "OS details:"
$ECHO "-----------"
OS_DETAILS
$ECHO "\t OS Version		: $OS_VER"
$ECHO "\t Kernel ID      	: $KER_ID"
$ECHO "\t Uptime in day(s)	: $UPTIME day(s)"

$ECHO "HW details:"
$ECHO "-----------"
HW_DETAILS
$ECHO "\t Processor Version	: $PROC_VER"
$ECHO "\t No of Physical Procs	: $N_PROC"
$ECHO "\t No of Virtual Procs	: $N_PROC"
$ECHO "\t Physical Memory	: $P_MEM (MB)"

$ECHO "FileSystem Utilization:"
$ECHO "-----------------------"
FS_CHECK
$ECHO "\t Space status 		: $FS_FULL"
$ECHO "\t Inode status 		: $FS_INODEFULL"
$ECHO "\t Disk Errors status	: $DISK_STATUS"
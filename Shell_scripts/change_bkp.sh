#!/bin/sh
#
# Configuration files backup for Chnages
#
# Author: Pradeep K Pasupuleti
#
# Created on: 
#
echo "Enter CRQNUMBER : "
read CRQNUMBER

#echo "DID Number: "
#read DID

ECHO="/bin/echo"

if [ -f "/bin/cat" ]; then
        CAT="/bin/cat"
else
        $ECHO "Error: cat command not found"
        exit
fi

if [ -f "/bin/hostname" ]; then
        HOSTNAME="/bin/hostname"
else
        $ECHO "Error: hostname command not found"
        exit
fi

if [ -f "/bin/rpm" ]; then
        RPM="/bin/rpm"
else
        $ECHO "Error: rpm command not found"
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

if [ -f "/usr/bin/uptime" ]; then
        UPTIME="/usr/bin/uptime"
else
        $ECHO "Error: uptime command not found"
fi

if [ -f "/bin/df" ]; then
        DF="/bin/df"
else
        $ECHO "Error: df command not found"
fi

if [ -f "/sbin/ifconfig" ]; then
        IFCFG="/sbin/ifconfig"
else
        $ECHO "Error: ifconfig command not found"
fi

if [ -f "/sbin/route" ]; then
        ROUTE="/sbin/route"
else
        $ECHO "Error: route command not found"
fi

if [ -f "/bin/date" ]; then
        DATE="/bin/date"
else
        $ECHO "Error: date command not found"
fi

if  [ -f "/bin/uname" ]; then
        UNAME="/bin/uname"
else
        $ECHO "Error: uname command not found"
fi

if  [ -f "/bin/mount" ]; then
        MOUNT="/bin/mount"
else
        $ECHO "Error: mount command not found"
fi

if  [ -f "/bin/netstat" ]; then
        NETSTAT="/bin/netstat"
else
        $ECHO "Error: netstat command not found"
fi


if  [ -f "/sbin/fdisk" ]; then
        FDISK="/sbin/fdisk"
else
        $ECHO "Error: fdisk command not found"
fi


if  [ -f "/usr/bin/free" ]; then
        FREE="/usr/bin/free"
else
        $ECHO "Error: free command not found"
fi

if  [ -f "/sbin/sysctl" ]; then
        SYSCTL="/sbin/sysctl"
else
        $ECHO "Error: sysctl command not found"
fi


if  [ -f "/usr/sbin/dmidecode" ]; then
        DMID="/usr/sbin/dmidecode"
else
        $ECHO "Error: dmidecode command not found"
fi


if [ -f "/usr/RaidMan/arcconf" ]; then
        ARCC="/usr/RaidMan/arcconf"
elif
   [ -f "/usr/sbin/hpacucli" ]; then
        HPACU="/usr/sbin/hpacucli"
else
        $ECHO "Error: arcconf or HPACU command not found"
fi

if  [ -f "/usr/bin/sudo" ]; then
        SUDO="/usr/bin/sudo"
else
        $ECHO "Error: sudo command not found"
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

if  [ -f "/usr/bin/whoami" ]; then
        WHO="/usr/bin/whoami"
else
        $ECHO "Error: whoami command not found"
fi

HOSTNAME1=$($HOSTNAME -s)

DATE=$(date +%d-%m-%y)
DID=$WHO

#cdir="/var/tmp"
sdir=""$CRQNUMBER"_"$HOSTNAME1""

# create directory with CRQNUMBER
$MKDIR $sdir

echo "change directory to create files"

cd "$sdir"

echo "`pwd`"

$SUDO $RPM -qa > "$CRQNUMBER"_"$HOSTNAME1"_"$DATE"_"rpm"

$SUDO $UPTIME > "$CRQNUMBER"_"$HOSTNAME1"_"uptime"

$SUDO  $UNAME -a > "$CRQNUMBER"_"$HOSTNAME1"_"uname"

$SUDO $DF -PHT >> "$CRQNUMBER"_"$HOSTNAME1"_"DFKH"

$SUDO $DF -PHT | wc -l >> "$CRQNUMBER"_"$HOSTNAME1"_"DFKH"

$SUDO $IFCFG >> "$CRQNUMBER"_"$HOSTNAME1"_"ifcfg"

$SUDO $IFCFG -a >> "$CRQNUMBER"_"$HOSTNAME1"_"ifcfg"

$SUDO $CAT /proc/net/bonding/* >> "$CRQNUMBER"_"$HOSTNAME1"_"bond"

$SUDO $ROUTE >> "$CRQNUMBER"_"$HOSTNAME1"_"Routes"

$SUDO $MOUNT >> "$CRQNUMBER"_"$HOSTNAME1"_"MOUNT"

$SUDO $NETSTAT -tpln >> "$CRQNUMBER"_"$HOSTNAME1"_"NETSTAT"

$SUDO $NETSTAT -r >> "$CRQNUMBER"_"$HOSTNAME1"_"NETSTAT"

$SUDO $FREE -m >> "$CRQNUMBER"_"$HOSTNAME1"_"FREE"

$SUDO $CAT /proc/swaps >> "$CRQNUMBER"_"$HOSTNAME1"_"SWAP"

for i in `seq 0 13`; do echo -n "eth${i}: " ; $SUDO $ETHTOOL eth$i | $GREP detected;done > "$CRQNUMBER"_"$HOSTNAME1"_"LINKSTATUS"

for i in `seq 0 13`;do echo -n "eth$i   :";$SUDO $ETHTOOL -i eth$i | $GREP bus;done > "$CRQNUMBER"_"$HOSTNAME1"_"BUSINFO"

if [ -f /etc/SuSE-release ]; then	
IFC=$(ls -ltrh /etc/sysconfig/network | $GREP -v "^d" | $GREP "ifcfg" | $AWK '{print $9}' | $GREP -v "ifcfg.template")
for i in $IFC
do
echo "+++++++++++++++ config file for $i +++++++++++++++" >> "$CRQNUMBER"_"$HOSTNAME1"_"IFCFG"
cat /etc/sysconfig/network/$i >> "$CRQNUMBER"_"$HOSTNAME1"_"IFCFG"
echo "++++++++++++++++++++++++++++++++++++++++++++++++++" >> "$CRQNUMBER"_"$HOSTNAME1"_"IFCFG"
done
elif [ -f /etc/redhat-release ]; then
IFC=$(ls -ltrh /etc/sysconfig/network-scripts | $GREP -v "^d" | $GREP "ifcfg" | $AWK '{print $9}' | $GREP -v "ifcfg.template") 
for i in $IFC
do
echo "+++++++++++++++ config file for $i +++++++++++++++" >> "$CRQNUMBER"_"$HOSTNAME1"_"IFCFG"
cat /etc/sysconfig/network-scripts/$i >> "$CRQNUMBER"_"$HOSTNAME1"_"IFCFG"
echo "++++++++++++++++++++++++++++++++++++++++++++++++++" >> "$CRQNUMBER"_"$HOSTNAME1"_"IFCFG"
done
else 
$ECHO "OS is nor LINUX nor SUSE"
fi

$SUDO rug get-prefs|grep rollback >> "$CRQNUMBER"_"$HOSTNAME1"_"RUGROLLBK"

$SUDO $CAT /etc/sysctl.conf >> "$CRQNUMBER"_"$HOSTNAME1"_"sysctl.conf"_"$DATE"

$SUDO $CAT /etc/fstab >> "$CRQNUMBER"_"$HOSTNAME1"_"fstab"_"DATE"

$SUDO $CAT /etc/sudoers >> "$CRQNUMBER"_"$HOSTNAME1"_"sudoers"_"DATE"

$SUDO $SYSCTL -a >> "$CRQNUMBER"_"$HOSTNAME1"_"$DATE"_"sysctl"

$SUDO $CAT /etc/passwd >> "$CRQNUMBER"_"$HOSTNAME1"_"$DATE"_"passwd"

$SUDO $CAT /etc/shadow >> "$CRQNUMBER"_"$HOSTNAME1"_"$DATE"_"shadow"

if [ -f "/etc/SuSE-release" ]; then
        grep -i patch /etc/SuSE-release > "$CRQNUMBER"_"$HOSTNAME1"_"PATCH"
        $CAT  /etc/SuSE-release >> "$CRQNUMBER"_"$HOSTNAME1"_"PATCH"
else
        $ECHO "OS is not SUSE" >> "$CRQNUMBER"_"$HOSTNAME1"_"PATCH"
fi

$SUDO $CAT /etc/fstab >> "$CRQNUMBER"_"$HOSTNAME1"_"$DATE"_"FSTAB"

$SUDO $DMID | grep -i vendor >> "$CRQNUMBER"_"$HOSTNAME1"_"$DATE"_"vendor"

$SUDO $ARCC GETCONFIG 1 >> "$CRQNUMBER"_"$HOSTNAME1"_"$DATE"_"RAIDDETAILS"

$SUDO $HPACU ctrl all show config >> "$CRQNUMBER"_"$HOSTNAME1"_"$DATE"_"RAIDDETAILS"

cd

scp -r $sdir lxapp0424.in.telstra.com.au:~

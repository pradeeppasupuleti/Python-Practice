#!/bin/bash
#Scirpt developed by Lingeswaran website:www.unixarena.com "vxprint calculation script version 0.12"
foo ()
{
echo
echo -n "Enter a number 1=SUBDISK,2=PLEX,3=VOLUME,4=DISK > "
read character
if [ "$character" = "1" ]; then
    echo -n "Enter the Subdisk Name:"
read subdisk
/usr/sbin/vxprint -sb |grep ENABLED |awk ' { print $2 } ' |grep -w "$subdisk" > /dev/null
if [ `echo $?` -eq 0 ]
then
echo "The Subdisk $subdisk size is=$(for i in `/usr/sbin/vxprint -g $DGS -Qqs $subdisk |awk ' { print $5 }' `; do echo "scale=2;$i/2/1024/1024" |bc;done) GB"
else
echo "---------------------------------------------------------------"
echo "Sub-disk $subdisk is not part of $DGS or incorrect sub-diskname"
echo "---------------------------------------------------------------"
fi
else
if [ "$character" = "2" ]; then
        echo -n "Enter the Plex Name:"
read plex
/usr/sbin/vxprint -p |grep ACTIVE |awk ' { print $2 } ' |grep -w "$plex" > /dev/null
if [ `echo $?` -eq 0 ]
then
echo "The plex $plex size is=$(for i in `/usr/sbin/vxprint -g $DGS -Qqp $plex |awk ' { print $5 }' `; do echo "scale=2;$i/2/1024/1024"  |bc;done) GB"
else
echo "-----------------------------------------------------"
echo "Plex $plex is not part of $DGS or incorrect Plex name"
echo "-----------------------------------------------------"
fi
else
if [ "$character" = "3" ]; then
 echo -n "Enter the Volume Name:"
read volume
/usr/sbin/vxprint -v |grep ENABLED |awk ' { print $2 } ' |grep -w "$volume"  > /dev/null
if [ `echo $?` -eq 0 ]
then
echo "The volume $volume size is=$(for i in `/usr/sbin/vxprint -g $DGS -Qqv $volume |awk ' { print $5 }' `; do echo "scale=2;$i/2/1024/1024" |bc;done) GB"
else
echo "-----------------------------------------------------------"
echo "Volume $volume is not part of $DGS or incorrect Volume name"
echo "-----------------------------------------------------------"
fi
else
if [ "$character" = "4" ]; then
echo -n "Enter the Veritas Disk Name:"
read DISK
/usr/sbin/vxdisk list |grep $DGS|grep $DISK > /dev/null
if [ `echo $?` -eq 0 ]
then
GADSK=`/usr/sbin/vxdisk list |grep "$DGS" |awk ' { print $1 } '|grep "$DISK" `
GDSK=`/usr/sbin/vxdisk list $GADSK |grep public |awk ' { print $4 } '|cut -f2 -d'=' `
echo "The size of the disk $DISK="$(echo "scale=2;$GDSK/2/1024/1024"|bc)" GB"
else
echo "-----------------------------------------------------------"
echo "The entered disk is not part of $DGS or incorrect disk name"
echo "-----------------------------------------------------------"
fi
else
echo "--------------------------------------------------------------------------------------"
echo "Please enter the correct option;Thank you for using UnixArena's Vxprint_size.sh script"
echo "--------------------------------------------------------------------------------------"
fi
        fi
    fi
 fi
foo
}

#Actual script begins
echo -n "Enter the diskgroup name: "
read DGS
/usr/sbin/vxdg list |grep -v ID |awk ' { print $1 } ' |grep -w $DGS > /dev/null
if [ `echo $?` -eq 0 ]
then
DGSPACE=`/usr/sbin/vxprint -g $DGS -dF "%publen" | awk 'BEGIN {s = 0} {s += $1} END {print s}' `
echo "Diskgroup $DGS size is = "$(echo "scale=2;$DGSPACE/2/1024/1024"|bc)" GB"
DGFREE=`/usr/sbin/vxdg -g $DGS free | awk ' { print $5 }' |grep -v LENGTH |awk 'BEGIN {s = 0} {s += $1} END {print s}' `
echo "Free space/Unallocated space in diskgroup $DGS is = "$(echo "scale=2;$DGFREE/2/1024"|bc)" MB"
echo "------------------------------------------------"
echo "To know the size of volume/plex/subdisks;continue"
echo "------------------------------------------------"
foo
else
echo "----------------------------------------------------------------------------------------------"
echo "Diskgroup $DGS is not imported in `uname -n` ;Thank you for using UnixArena's Vxprint_size.sh script "
echo "----------------------------------------------------------------------------------------------"
fi


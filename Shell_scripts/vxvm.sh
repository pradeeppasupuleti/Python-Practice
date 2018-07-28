#!/bin/sh
DISK_G=$(vxdg  list | awk '{print $1}' | grep -v "NAME")
DISK_GC=$(vxdg  list | awk '{print $1}' | grep -v "NAME" | wc -l)

for i in $DISK_G
	do 
		if [ $(vxprint -g $i | egrep "^v" | awk '{print $4}' | grep -v -c "ENABLED") -ne 0 ]; then
			
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
		if [ $(vxprint -g $i | egrep "^sd" | awk '{print $4}' | grep -v -c "ENABLED") -ne 0 ]; then
			
			SD_STATUS="$SD_STATUS,$i"
		fi
	done
if [ -z "$SD_STATUS" ]; then
	SD_STATUS="All Sub Disks under DiskGroup(s) fine."
else
	SD_STATUS="Subdisk under Diskgroup(s) failed:`echo $SD_STATUS | sed 's/,/ /'`"
fi


echo -e "\tDisk groups count	: $DISK_GC"
echo -e "\tVolumes Status		: $V_STATUS"
echo -e "\tSubDisk(s) Status	: $SD_STATUS"
#!/usr/bin/bash
for i in `df -k | grep -v "^$" | grep -v "^Filesystem" | awk '{print $1}'`
	do
		FS=`df -k | grep -v "^$" | grep $i | awk '{print $6}'`
		USED=`df -k | grep -v "^$" | grep $i | awk '{ print $5 }' | sed -e 's/%//'`
		if [ "$USED" -gt 85 ]; then
			FS_FULL="$FS_FULL; $FS ${USED}%"
		fi
	done

		if [ -z "FS_FULL" ]; then
			FS_FULL="All File system(s) fine"
		else
			FS_FULL="`echo $FS_FULL| sed -e 's/^;//'`"				
		fi
echo "\t Space status	: $FS_FULL"
		
for j in `/usr/local/soe/bin/bdf -i | grep -v "^Filesystem" | awk '{print $1}'`
	do
		IUSED=`/usr/local/soe/bin/bdf -i | grep $i | awk '{ print $8 }' | sed -e 's/%//'`
		if [ "$IUSED" -gt 85 ]; then
				FS_INODEFULL="$FS_INODEFULL; $j"
		fi
	done
			if [ "$FS_INODEFULL" = "" ]; then
				FS_INODEFULL="All Filesystems are fine"
			fi
	
echo  "\t Inode status	: $FS_INODEFULL"
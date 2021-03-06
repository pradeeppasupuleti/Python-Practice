

#!/bin/bash
# Version:1.0
# Author : Prashant Pilankar
# Script for LVM Administration in Linux
# Read the BigAdmin article that describes the usage of this script:
# http://www.sun.com/bigadmin/content/submitted/lvm_admin.jsp
# Declare variable choice and assign value 9
choice=9
# Print to stdout
 echo "1. Display existing LV's PV's VG's info"
 echo "2. Display the devices available to create PV's"
 echo "3. Create Physical Volume"
 echo "4. Create Volume Group"
 echo "5. Create Logical Volume"
 echo "6. Create filesystem "
 echo "7. Extend existing filesystem "
 echo "8. mount  filesystem "
 echo -n "Please choose a word [1,2,3,4,5,6,7 or 8]? "
# Loop while the variable choice is equal 9
# bash while loop
while [ $choice -eq 9 ]; do

# read user input
read choice
# bash nested if/else
if [ $choice -eq 1 ] ; then

        /home/pilankar/LVM_scripts/lvm_display.sh

else

        if [ $choice -eq 2 ] ; then
    echo "=====Existing physical Vols=====" ; pvs ; echo "============" ; fdisk -l | grep -i lvm
        else

                if [ $choice -eq 3 ] ; then
                        /home/pilankar/LVM_scripts/pvc.sh
                else
                if [ $choice -eq 4 ] ; then
                        /home/pilankar/LVM_scripts/vgc.sh
                else
                if [ $choice -eq 5 ] ; then
                        /home/pilankar/LVM_scripts/lvc.sh
                else
                if [ $choice -eq 6 ] ; then
                        /home/pilankar/LVM_scripts/fsc.sh
                else
                if [ $choice -eq 7 ] ; then
                        /home/pilankar/LVM_scripts/lv_fs_resize.sh
                else
                if [ $choice -eq 8 ] ; then
                        /home/pilankar/LVM_scripts/mount.sh
                else
                        echo "Please make a choice between 1-8 !"
                        echo "1. Display existing LV's PV's VG's info"
                        echo "2. Display the devices available to create PV's"
                        echo "3. Create Physical Volume"
                        echo "4. Create Volume Group"
                        echo "5. Create Logical Volume"
                        echo "6. Create filesystem "
                        echo "7. Extend existing filesystem "
                        echo "8. mount  filesystem "
                        echo -n "Please choose a word [1,2,3,4,5,6,7 or 8]? "
                        choice=9
                fi
        fi
fi
fi
fi
fi
fi
fi
done

Following are the subscripts that are called from the main lvmadm script.

Code for pvc.sh subscript:

#!/bin/sh
# Script to create a physical volume in LVM
# Author : Prashant Pilankar
# Read the BigAdmin article that describes the usage of this script:
# http://www.sun.com/bigadmin/content/submitted/lvm_admin.jsp
echo "enter the devices to create the physical volume"
read a b c d
pvcreate /dev/$a /dev/$b /dev/$c /dev/$d
echo "following confirms the pv is created"
pvs

Code for lvm_display.sh subscript:

#!/usr/bin/sh
# Script to display the current pv's lv's and vg's
# Read the BigAdmin article that describes the usage of this script:
# http://www.sun.com/bigadmin/content/submitted/lvm_admin.jsp

pvs ; echo "=======================" ; lvs ; echo "============================="  ; vgs ; echo "============================="

pvdisplay ; echo "=======================" ; lvdisplay ; echo "============================="  ; vgdisplay ; echo "============================="

Code for vgc.sh subscript:

#!/bin/sh
# Script to create the  volume group in LVM
# Author : Prashant Pilankar
# Read the BigAdmin article that describes the usage of this script:
# http://www.sun.com/bigadmin/content/submitted/lvm_admin.jsp
echo "enter the volume group name followed by the devices to create the  volume group "
read a b c d e
vgcreate $a /dev/$b /dev/$c /dev/$d /dev/$e
echo "following confirms the volume group is created"
vgs

Code for lvc.sh subscript:

#!/bin/sh
# Script to create the  logical volume in LVM
# Author : Prashant Pilankar
# Read the BigAdmin article that describes the usage of this script:
# http://www.sun.com/bigadmin/content/submitted/lvm_admin.jsp
echo "enter the size followed by the LV and VG name to create the  logical volume "
read a b c
lvcreate -L $a -n $b /dev/$c
echo "following confirms the logical volume is created"
lvs

Code for fsc.sh subscript:

#!/bin/bash
# Script to create the  filesystem in LVM
# Author : Prashant Pilankar
# Read the BigAdmin article that describes the usage of this script:
# http://www.sun.com/bigadmin/content/submitted/lvm_admin.jsp
echo "enter the filesystem type following by the vg name and lv name "
read a b c
if [ $a = ext3 ]; then
 mkfs -t ext3 /dev/$b/$c ; ls -lt /dev/$b/$c
else
 mkfs -t ext2 /dev/$b/$c ; /dev/$b/$c
fi

Code for lv_fs_resize.sh subscript:

#!/bin/sh
# Script to resize the  filesystem in LVM
# Author : Prashant Pilankar
# Read the BigAdmin article that describes the usage of this script:
# http://www.sun.com/bigadmin/content/submitted/lvm_admin.jsp
echo "Please ensure the associated filesystem is unmounted before resize "
echo "enter the new size for lv followed by the vg and lv name and new size for filesystem for the resize operation "
echo "please be informed that during the resize operation filesystem consistency will be checked"
read a b c d
lvresize -L $a /dev/$b/$c ; e2fsck -f /dev/$b/$c ; resize2fs /dev/$b/$c $d
echo "following confirms the logical volume is resized"
lvs

Code for mount.sh subscript:

#!/bin/sh
# Script to mount the  filesystem in LVM
# Author : Prashant Pilankar
# Read the BigAdmin article that describes the usage of this script:
# http://www.sun.com/bigadmin/content/submitted/lvm_admin.jsp
echo "enter the vg and lv name and mount point for mounting the FS "
echo "please ensure mount point directory exists prior to mounting the FS "
read a b c
mount /dev/$a/$b  /app/$c
echo "following confirms the filesystem is mounted"
mount | grep $c


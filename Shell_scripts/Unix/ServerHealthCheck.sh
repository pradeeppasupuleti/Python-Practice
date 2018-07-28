#!/usr/bin/ksh

###############################################################################################
#
# Script Name: quickservchk.sh
#
# Author: Gaurav Sangamnerkar
#
# Platform: Solaris
# Version: 1.0
# Information: This script will run a series of tests on server & will report issues.
#              Following would be checked by this server
#                       1.Solaris Volume Manager generic checks
#                               2.Solaris generic checks
#                               3.Veritas Volume Manager generic checks
#                               4.Veritas cluster generic checks
#
# Modified by : Aneel Ramireddy on 28-Apr-2015
# Version: 2.0
#                               Modifications:
#                               - Added the .csv functionality
#                               - Added the additional check for health check report
#
#
#
#
#
# Usage: Run sript like #./quickservchk.sh
#        When requested, please give appropriate information
#
###############################################################################################
#--------------------------Define All Variables--------------------------------
# Setting Hard error & Transport error threshold to 50

HARDERRTSHOLD=50
TRANERRTSHOLD=50

#--------------------------Define All Functions--------------------------------

display_banner ()
{
        tput clear
        echo "Script Started at: `date`">$LOGFILE
        echo " ******************************************************************************"  | $TEE -a $LOGFILE
        echo "*                                                                              *" | $TEE -a $LOGFILE
        echo "*                          Server health check script                          *" | $TEE -a $LOGFILE
        echo "*                                                                              *" | $TEE -a $LOGFILE
        echo " ******************************************************************************"  | $TEE -a $LOGFILE
        echo "" | $TEE -a $LOGFILE
        echo "This script runs series of tests on server & gives an idea about server health." | $TEE -a $LOGFILE
        echo "" | $TEE -a $LOGFILE
        echo "This script uses lots of commands to check stats, please be patient while output returns"  | $TEE -a $LOGFILE
        echo "" | $TEE -a $LOGFILE
        echo "Workspace for this script is $WORKSPACE" | $TEE -a $LOGFILE
        echo "" | $TEE -a $LOGFILE
        echo "--------------------------------------------------------------------------------------------------------------" | $TEE -a $LOGFILE
        echo "" | $TEE -a $LOGFILE
##Commenting below line to override root check, to meet Blade Logic job requirements
        #if [[ "$CHOICE" == "y" ]]
        #then
        #echo ""
        #else
        #echo "\nThis script must be ran as root, do you wish to continue ?(y/n) \c" | $TEE -a $LOGFILE
        #read CHOICE
        #fi
        #echo $CHOICE >> $LOGFILE
        #if [ $CHOICE <> "" ] ; then break ; fi
        #if [ "$CHOICE" != "y" ]
        #then
        #echo "" | $TEE -a $LOGFILE
        #echo "Script Exiting..... "  | $TEE -a $LOGFILE
        #echo "" | $TEE -a $LOGFILE
        #exit 1
        #fi
        #echo "" | $TEE -a $LOGFILE
        #echo "" | $TEE -a $LOGFILE
}

check_root_priv ()
{
        WHORU=`id -a | awk '{print $1}'`
        if [ "$WHORU" != "uid=0(root)" ];
        then
        echo "\n\033[41mYou are not logged in as root, please login as root user or sudo to root..\033[0m\c" | $TEE -a $LOGFILE
        echo "" | $TEE -a $LOGFILE
        echo "\nScript Exiting..... "  | $TEE -a $LOGFILE
        echo "" | $TEE -a $LOGFILE
        exit 1
        fi
}
check_os ()
{
        echo "======================================================" | $TEE -a $LOGFILE
        echo ""
        echo "\n[*]Checking if OS is Sun Solaris..." | $TEE -a $LOGFILE
        if [ "`uname -s`" !=  "SunOS" ]
        then
                echo "This script is designed to work only on Solaris. This is not Solaris OS. Hence exiting" | $TEE -a $LOGFILE
                exit 1
        fi
        echo "\n-->This is Sun Solaris System." | $TEE -a $LOGFILE
        if [[ -f $CSV_FILE ]]
        then
        echo -e "\n===================,* * * * * * * * * * * * * * * * * *,====================" > $CSV_FILE
        echo -e "This is Sun Solaris System.,Hostname:`hostname`" >> $CSV_FILE
        fi
        echo "" | $TEE -a $LOGFILE
        echo "\n[*]Checking uptime of server ..." | $TEE -a $LOGFILE
        UPTIME=`/usr/bin/uptime  |awk '{print $3" "$4}' |cut -d "," -f1`
        UPT=`/usr/bin/uptime  |awk '{print $3}'`
        if [ $UPT -ge 100 ]
        then
        echo "\n\033[41m--> uptime of server is $UPTIME \033[0m" | $TEE -a $LOGFILE
        if [[ -f $CSV_FILE ]]
        then
        echo "uptime,$UPTIME" >> $CSV_FILE
        echo "\n">> $CSV_FILE
        fi

        else
        echo "\n\033[42m--> uptime of server is $UPTIME \033[0m" | $TEE -a $LOGFILE
        if [[ -f $CSV_FILE ]]
        then
        echo -e "uptime,$UPTIME" >> $CSV_FILE
        echo -e "\n">> $CSV_FILE
        fi

        fi
        echo "" | $TEE -a $LOGFILE
}

check_OS_version ()
{
        echo "======================================================" | $TEE -a $LOGFILE
        echo ""
        echo "[*]Checking software versions ..." | $TEE -a $LOGFILE
                OS_VER=`/usr/bin/uname -r`
                if [ $OS_VER = "5.8" ]
                then
        echo "\n--> OS version = solaris 8" | $TEE -a $LOGFILE
                        echo ""
                if [[ -f $CSV_FILE ]]
                then
                echo "OS version:,Solaris 8" >> $CSV_FILE
                echo "\n"
                fi
                elif [ $OS_VER = "5.9" ]
                then
        echo "\n--> OS version = solaris 9" | $TEE -a $LOGFILE
                        echo ""
                if [[ -f $CSV_FILE ]]
                then
                echo "OS version:,Solaris 9" >> $CSV_FILE
                echo "\n"
                fi
                elif [ $OS_VER = "5.10" ]
                then
        echo "\n--> OS version = solaris 10" | $TEE -a $LOGFILE
                        echo ""
                if [[ -f $CSV_FILE ]]
                then
                echo "OS version:,Solaris 10" >> $CSV_FILE
                echo "\n"
                fi
                else
        echo "\n--> You are running an unsupported solaris version, exiting..." | $TEE -a $LOGFILE
                if [[ -f $CSV_FILE ]]
                then
                echo "\n--> You are running an unsupported solaris version: exiting..." >> $CSV_FILE
                fi
                exit 1
                fi
}

check_vx_version ()
{
        echo "======================================================" | $TEE -a $LOGFILE
        echo ""
        echo "\n[*] Checking veritas sofware versions ..." | $TEE -a $LOGFILE
        VxVM_VER=`/usr/sbin/modinfo  |grep -i vxio |awk '{print $8}'`
        if [ "$VxVM_VER" = "" ]
        then
        echo "\n--> Veritas Volume Manager is not installed" | $TEE -a $LOGFILE
        if [[ -f $CSV_FILE ]]
        then
        echo "Veritas Volume Manager, Not Installed" >> $CSV_FILE
        fi
        else
        echo "\n--> Veritas Volume Manager version is $VxVM_VER "| $TEE -a $LOGFILE
        if [[ -f $CSV_FILE ]]
        then
        echo "Veritas Volume Manager, $VxVM_VER" >> $CSV_FILE
        fi
        fi
        VxFS_VER=`/usr/sbin/modinfo  |grep -i vxfs | grep -v portal |awk '{print $8}' | cut -d "_" -f2 | cut -c 5-`
        if [ "$VxFS_VER" = "" ]
        then
        echo "\n--> Veritas Filesystem is not installed" | $TEE -a $LOGFILE
        if [[ -f $CSV_FILE ]]
        then
        echo "Veritas Filesystem, Not Installed" >> $CSV_FILE
        fi
        else
        echo "\n--> Veritas Filesystem version is $VxFS_VER "| $TEE -a $LOGFILE
        if [[ -f $CSV_FILE ]]
        then
        echo "Veritas Filesystem, $VxFS_VER" >> $CSV_FILE
        fi
        fi
        VCS_VER=`/usr/sbin/modinfo  |grep -i gab |awk '{print $9}' |cut -d ")" -f1`
        if [ "$VCS_VER" = "" ]
        then
        echo "\n--> Veritas Cluster is not installed" | $TEE -a $LOGFILE
        if [[ -f $CSV_FILE ]]
        then
        echo "Veritas Cluster, not installed" >> $CSV_FILE
        fi
        else
        echo "\n--> Veritas Cluster version is $VCS_VER "| $TEE -a $LOGFILE
        if [[ -f $CSV_FILE ]]
        then
        echo "Veritas Cluster, $VCS_VER" >> $CSV_FILE
        fi
        fi
        NBU_VER=`cat /usr/openv/netbackup/bin/version`
        if [ "$NBU_VER" = "" ]
        then
        echo "\n--> Netbackup client is not installed" | $TEE -a $LOGFILE
        if [[ -f $CSV_FILE ]]
        then
        echo "Netbackup client, not installed" >> $CSV_FILE
        fi
        else
        echo "\n--> Veritas Netbackup version is $NBU_VER "| $TEE -a $LOGFILE
        if [[ -f $CSV_FILE ]]
        then
        echo "Netbackup client, $NBU_VER" >> $CSV_FILE
        fi
        fi
        echo ""
}

check_load_avg ()
{
        echo "======================================================" | $TEE -a $LOGFILE
        echo ""
        echo "\n[*] Checking load average .... " | $TEE -a $LOGFILE
        LOADAVG=`/usr/bin/uptime | cut -d ":" -f4`
        LOAD_AVG=`/usr/bin/uptime | cut -d ":" -f4 | cut -d "," -f1`
        if [ $LOAD_AVG -ge 50 ]
        then
        echo "\n\033[41m--> Load average of server is $LOAD_AVG \033[0m" | $TEE -a $LOGFILE
        if [[ -f $CSV_FILE ]]
        then
        echo "Load average, $LOAD_AVG" >> $CSV_FILE
        fi
        else
        echo "\n\033[42m--> Load average of server is $LOAD_AVG \033[0m" | $TEE -a $LOGFILE
        if [[ -f $CSV_FILE ]]
        then
        echo "Load average, $LOAD_AVG" >> $CSV_FILE
        fi
        fi
        echo "" | $TEE -a $LOGFILE
}

check_dg_disabled ()
{
        echo "======================================================" | $TEE -a $LOGFILE
        echo ""
        echo "\n[*]Checking if any diskgroup is in disabled state... " | $TEE -a $LOGFILE
        DGDISABLED=`vxdg list |grep -i disabled |wc -l`
        DG_DIS_NAME=`vxdg list | grep -i disabled |grep -v NAME |awk '{print $1}'`
        if [ $DGDISABLED -ge 1 ]
        then
        echo "\n\033[41m--> Following diskgroups found in disabled state \033[0m" | $TEE -a $LOGFILE
        echo "\n$DG_DIS_NAME" | $TEE -a $LOGFILE
        if [[ -f $CSV_FILE ]]
        then
        echo "Disabled diskgroups, $LOAD_AVG" >> $CSV_FILE
        fi
        else
        echo "\n--> No diskgroup found in disabled state "| $TEE -a $LOGFILE
        if [[ -f $CSV_FILE ]]
        then
        echo "Disabled diskgroups, 0" >> $CSV_FILE
        fi
        fi
        echo "" | $TEE -a $LOGFILE
}

check_vol_disabled ()
{
        echo "======================================================" | $TEE -a $LOGFILE
        echo ""
        echo "\n[*]Checking if any volume is in disabled state... " | $TEE -a $LOGFILE
        VOLDISABLED=`vxprint -v |grep -i disabled |wc -l`
        VOL_DIS_NAME=`vxprint -v | grep -v group |grep -v NAME |awk '{print $2}'`
        if [ $VOLDISABLED -ge 1 ]
        then
        echo "\n\033[41m--> Following volumes found in disabled state \033[0m" | $TEE -a $LOGFILE
        echo "\n$VOL_DIS_NAME" | $TEE -a $LOGFILE
        else
        echo "\n--> No volume found in disabled state "| $TEE -a $LOGFILE
        fi
        echo "" | $TEE -a $LOGFILE
}

check_fs_full ()
{
        echo "======================================================" | $TEE -a $LOGFILE
        echo ""
        echo "\n[*]Checking if any filesystem is above 85% utilized.... " | $TEE -a $LOGFILE
        FS_TSHOLD=85
        if [[ -f $CSV_FILE ]]
        then
        echo  "FS_NAME,USED%" >> $CSV_FILE
        fi

        INIT_VAR=0
        df -k | egrep -v '/cdrom' |grep -v platform | awk '{print $5"\t"$6}'| egrep -v -i "capacity|mounted" | tr -d '%' | while read USED FS_NAME
        do
        if [ $USED -ge $FS_TSHOLD ]
        then
        echo "" | $TEE -a $LOGFILE
        echo "\n\033[41m$FS_NAME..................... $USED"%" \033[0m" | $TEE -a $LOGFILE

         if [[ -f $CSV_FILE ]]
        then
        echo  "$FS_NAME,$USED"%"\n" >> $CSV_FILE
        fi

        INIT_VAR=1
        fi
        done
        if [ ${INIT_VAR} -eq 0 ]
        then
        echo "\n-->No Filesystem is above 85% utilized ... " | $TEE -a $LOGFILE
         if [[ -f $CSV_FILE ]]
        then
        echo  "No Filesystem is above 85%" >> $CSV_FILE
        echo  "\n" >> $CSV_FILE
        fi


        fi
}

check_fs_full_csv()
{
        FS_TSHOLD=85
        df -k | egrep -v '/cdrom' |grep -v platform | awk '{print $5"\t"$6}'| egrep -v -i "capacity|mounted" | tr -d '%' | while read USED FS_NAME
        do
        if [ $USED -ge $FS_TSHOLD ]
        then
        echo "$FS_NAME - $USED : \c"
        fi
        done
        echo "\n"
}

check_hard_trans_err ()
{
        echo "======================================================" | $TEE -a $LOGFILE
        echo ""
        echo "\n[*]Checking disks for hard & transport errors above threshold value.... " | $TEE -a $LOGFILE
        echo "\n   Setting Hard error & Transport error threshold to 50 " | $TEE -a $LOGFILE
        echo ""
        DISKERR=`iostat -En  |grep -i hard | awk '$7 > 50 || $10 > 50 {print $0}' |wc -l`
        if [ $DISKERR -eq 0 ]
        then
        echo "\n-->No Disk has Hard or Transport error greater than threshold value .... " | $TEE -a $LOGFILE
        if [[ -f $CSV_FILE ]]
        then
        echo "Hard or Transport error, 0" >> $CSV_FILE
        fi
        else
        echo "\n\033[41m--> Following disks have hard or transport errors greater than threshold value ... \033[0m" | $TEE -a $LOGFILE
        iostat -En  |grep -i hard | awk '$7 >= 50 || $10 > 50 {print $0}' 2>&1
        if [[ -f $CSV_FILE ]]
        then
        echo "Hard or Transport errors," >> $CSV_FILE
         echo "`iostat -En  |grep -i hard | awk '$7 >= 50 || $10 > 50 {print $1","$2","$3","$4","$5","$6","$7","$8","$9","$10}'` \n" >> $CSV_FILE
        fi
        fi
}

check_hard_trans_err_csv ()
{
        DISKERR=`iostat -En  |grep -i hard | awk '$7 > 30 || $10 > 30 {print $0}' |wc -l`
        if [ $DISKERR -eq 0 ]
        then
                echo "No Disk has Hard or Transport error greater than threshold value .... "
        else
        iostat -En  |grep -i hard | awk '$7 >= 30 || $10 > 30 {print $0}' 2>&1 | tr  "\n\r" ":"
        fi
        }
check_meta_dev ()
{
        echo "======================================================" | $TEE -a $LOGFILE
        echo ""
        echo "\n[*]Checking if any metadevice is reported in maintenance state .... " | $TEE -a $LOGFILE
        METAERR=`metastat | grep -i maintenance | wc -l`
        if [ $METAERR -eq 0 ]
        then
        echo "\n-->No metadevice is reported in maintenance state from metastat output ..." | $TEE -a $LOGFILE
        if [[ -f $CSV_FILE ]]
        then
        echo "Metadevice in maintenance,0 " >> $CSV_FILE
        fi
        else
        echo "\n\033[41m--> One or more metadevices are found in maintenance state, invoke metastat for details ... \033[0m" | $TEE -a $LOGFILE
        if [[ -f $CSV_FILE ]]
        then
        echo " Metadevice in maintenance, One or more found - invoke metastat for details" >> $CSV_FILE
        fi
        fi
        echo "" | $TEE -a $LOGFILE
}

check_meta_sync ()
{
        echo "======================================================" | $TEE -a $LOGFILE
        echo ""
        echo "\n[*]Checking if any metadevice is syncing in background ... " | $TEE -a $LOGFILE
        METASYN=`metastat | grep -i "%" | wc -l`
        if [ $METASYN -eq 0 ]
        then
        echo "\n-->No metadevice is syncing in background ... " | $TEE -a $LOGFILE
        if [[ -f $CSV_FILE ]]
        then
        echo "Meta Sync, No metadevice is syncing in background" >> $CSV_FILE
        fi
        else
        echo "\n\033[41m--> One more more metadevices are found in syncing state, invoke metastat for details ... \033[0m" | $TEE -a $LOGFILE
        if [[ -f $CSV_FILE ]]
        then
        echo "Meta Sync, one or metadevice is syncing in background - invoke metastat for details" >> $CSV_FILE
        echo "\n"
        fi
        fi
        echo "" | $TEE -a $LOGFILE
}


check_discon_san ()
{
        echo "======================================================" | $TEE -a $LOGFILE
        echo ""
        echo "\n[*]Checking for any disconnected SAN storage from Veritas volume Manager..." | $TEE -a $LOGFILE
        DISSANCNT=`vxdmpadm listenclosure all | grep -i disconnected |wc -l`
        DISSAN=`vxdmpadm listenclosure all | grep -i disconnected |awk '{print $0}'`
        if [ $DISSANCNT -eq 0 ]
        then
        echo "\n-->No SAN is found to be in disconnected state from Veritas Volume Manager..... "| $TEE -a $LOGFILE
        echo ""
        if [[ -f $CSV_FILE ]]
        then
        echo "SAN in disconnected state, none" >> $CSV_FILE
        echo "\n"
        fi
        else
        echo "\n\033[41m--> Following SAN enclosure is found in Disconnected state from Veritas Volume Manager.. \033[0m"| $TEE -a $LOGFILE
        echo "$DISSAN"
        if [[ -f $CSV_FILE ]]
        then
        echo "SAN in disconnected state,">> $CSV_FILE
        echo "`vxdmpadm listenclosure all | grep -i disconnected |awk '{print $1","$2","$3","$4","$5}'|grep -v "="`\n" >> $CSV_FILE
        echo "\n"
        fi
        fi
}
check_disabled_ctlr ()
{
        echo "======================================================" | $TEE -a $LOGFILE
        echo ""
        echo "\n[*]Checking for any disabled controllers from veritas volume manager..." |$TEE -a $LOGFILE
        DISCLRCNT=`vxdmpadm listctlr all |grep -i disabled | wc -l`
        DISCLR=`vxdmpadm listctlr all |grep -i disabled |grep -v grep |awk '{print $0}'`
        if [ $DISCLRCNT -eq 0 ]
        then
        echo "\n-->No controller is found in disabled state from Veritas Volume Manager..... "| $TEE -a $LOGFILE
        echo ""
        if [[ -f $CSV_FILE ]]
        then
        echo "No controller is found in disabled state from Veritas Volume Manager," >> $CSV_FILE
        echo "\n"
        fi
        else
        echo "\n\033[41m--> Following controller is found in disabled state from Veritas Volume Manager..\033[0m"| $TEE -a $LOGFILE
        echo "$DISCLR"
        if [[ -f $CSV_FILE ]]
        then
        echo "Veritas Volume Manager in disabled state," >> $CSV_FILE
        echo "` vxdmpadm listctlr all |grep -i disabled |grep -v grep |awk '{print $1","$2","$3","$4}'|grep -v "="`\n" >> $CSV_FILE
        echo "\n" >> $CSV_FILE
        fi
        fi
}
check_runn_vxtask ()
{
        echo "======================================================" | $TEE -a $LOGFILE
        echo ""
        echo "\n[*]Checking if any veritas sync tasks are running in the background ..." |$TEE -a $LOGFILE
        VXTASCNT=`vxtask list |grep -v grep|grep -v TASK |wc -l`
        VXTASK=`vxtask list`
        if [ $VXTASCNT -eq 0 ]
        then
        echo "\n-->No Veritas sync tasks found to be running in background ... "|$TEE -a $LOGFILE
        echo ""
        if [[ -f $CSV_FILE ]]
        then
        echo "No Veritas sync tasks found to be running in background,">>$CSV_FILE
        echo "\n" >> CSV_FILE
        fi
        else
        echo "\n\033[41m--> Following veritas sync tasks are running in background .....\033[0m"| $TEE -a $LOGFILE
        vxtask list
        if [[ -f $CSV_LIST ]]
        then
        echo "Following veritas sync tasks are running in background ,">>$CSV_FILE
        echo "`vxtask list|awk '{print $1","$2","$3","$4","$5}'`\n" >> $CSV_FILE
        echo "\n" >>$CSV_FILE
        fi
        fi
}

check_vxdisk_failed ()
{
        echo "======================================================" | $TEE -a $LOGFILE
        echo ""
        echo "\n[*]Checking if any disk is being reported as failed/failing in veritas volume manager ... " |$TEE -a $LOGFILE
        VXDSKFAICNT=`vxdisk list | grep -v grep |egrep 'failed|failing' |wc -l`
        VXDSKFAIL=`vxdisk -e list | grep -v grep |egrep 'failed|failing'|awk '{print $0}'`
        if [ $VXDSKFAICNT -eq 0 ]
        then
        echo "\n-->None of disk is found in failed/failing state from veritas volume manager ..." |$TEE -a $LOGFILE
        echo ""
        if [[ -f $CSV_FILE ]]
        then
        echo "None of disk is found in failed/failing state from veritas volume manager," >> $CSV_FILE
        echo "/n" >> $CSV_FILE
        fi
        else
        echo "\n\033[41m--> Following disks are reported in failed /failing state in Veritas Volume Manager ... \033[0m"|$TEE -a $LOGFILE
        echo "$VXDSKFAIL"
        if [[ -f $CSV_FILE ]]
        then
        echo "`vxdisk -e list | grep -v grep |egrep 'failed|failing'|awk '{print $1","$2","$3","$4","$5","$6}'`\n" >> $CSV_FILE
        echo "\n" >> $CSV_FILE
        fi
        fi
}
display_sar_data ()
{
        echo "======================================================" | $TEE -a $LOGFILE
        echo ""
        echo "\n[*]Showing sar data for 3 instances to check current CPU utilization ... " |$TEE -a $LOGFILE
        echo ""
        sar 3 3
        echo ""
        if [[ -f $CSV_FILE ]]
        then
        echo "`sar 3 3|tail +4|awk '{print $1","$2","$3","$4","$5}'`\n" >> $CSV_FILE
        echo "\n" >> $CSV_FILE
        fi
}
display_vmstat_data ()
{
        echo "======================================================" | $TEE -a $LOGFILE
        echo ""
        echo "\n[*]Showing vmstat data for 3 instances to check read/write/block queues...." |$TEE -a $LOGFILE
        echo ""
        vmstat 3 3
        echo ""
        if [[ -f $CSV_FILE ]]
        then
        echo "`vmstat |head -1|awk '{print $1","$2","$3","$4","$5","$6}'`">> $CSV_FILE
        echo "`vmstat 3 3|tail +2|tr " " ","`\n" >> $CSV_FILE
        echo "\n">>$CSV_FILE
        fi
}
check_defu_process ()
{
        echo "======================================================" | $TEE -a $LOGFILE
        echo ""
        echo "\n[*]Checking if any defunct processes are existing on the server ... "|$TEE -a $LOGFILE
        echo ""
        DEFCNT=`ps -elf | grep -i defunct | wc -l`
        if [ $DEFCNT -eq 0 ]
        then
        echo "\n-->No defunct processes are found on the server ... " |$TEE -a $LOGFILE
        if [[ -f $CSV_FILE ]]
        then
        echo "Defunct processes, 0" >> $CSV_FILE
        echo "\n" >> $CSV_FILE
        fi
        else
        echo "\n\033[41m--> $DEFCNT Defunct processes found on the server, please check (ps -ef |grep -i defunct output) ... \033[0m" |$TEE -a $LOGFILE
        echo ""
        if [[ -f $CSV_FILE ]]
        then
        echo "Defunct processes,Please check (ps -ef |grep -i defunct) " >> $CSV_FILE
        echo "\n" >> $CSV_FILE
        fi
        fi
}

check_defu_process_csv ()
{
        DEFCNT=`ps -elf | grep -i defunct | wc -l`
        if [ $DEFCNT -eq 0 ]
        then
        echo "No defunct processes are found on the server ... "
        else
        echo "$DEFCNT Defunct processes found on the server"
        fi
}
display_top_cpu_proc ()
{
        echo "======================================================" | $TEE -a $LOGFILE
        echo ""
        echo "\n[*]Showing top CPU consuming processes as per prstat output ... " |$TEE -a $LOGFILE
        echo ""
        prstat -a -s cpu | head -10
        echo ""
        if [[ -f $CSV_FILE ]]
        then
        echo "prstat output" >> $CSV_FILE
        echo "` prstat -a -s rss | head -10 | awk '{print $1","$2","$3","$4","$5","$6","$7","$8","$9","$10}'` \n" >> $CSV_FILE
        echo "\n" >> $CSV_FILE
        fi
}
display_top_mem_proc ()
{
        echo "======================================================" | $TEE -a $LOGFILE
        echo ""
        echo "\n[*]Showing top memory consuming processes as per prstat output ... " |$TEE -a $LOGFILE
        echo ""
        prstat -a -s rss | head -10
        echo ""
}
check_nw_inter ()
{
        echo "======================================================" | $TEE -a $LOGFILE
        echo ""
        echo "\n[*]Checking if any network interface is reported in failed state ... " | $TEE -a $LOGFILE
        echo ""
        NWFAILCNT=`ifconfig -a |grep -i failed |wc -l`
        NWFAILINT=`ifconfig -a |grep -i failed |awk '{print $1}' |cut -d: -f1 |uniq`
        if [ $NWFAILCNT -eq 0 ]
        then
        echo "\n-->None of network interface is found in failed state from ifconfig output..." |$TEE -a $LOGFILE
        echo ""
        if [[ -f $CSV_FILE ]]
        then
        echo "Nework interface failed, 0" >> $CSV_FILE
        echo "\n" >> $CSV_FILE
        fi

        else
        echo "\n\033[41m--> Following network interface are reported in failed state from ifconfig output... \033[0m"|$TEE -a $LOGFILE
        echo "$NWFAILINT"
        if [[ -f $CSV_FILE ]]
        then
        echo "Nework interface failed," >> $CSV_FILE
        echo "`ifconfig -a |grep -i failed |awk '{print $1}' |cut -d: -f1 |uniq`\n" >> $CSV_FILE
        echo "\n" >> $CSV_FILE
        fi
        fi
}

output_csv ()
{
        # IP address check
        IPADD=`cat /etc/hosts | grep -i loghost | grep $(hostname) | awk '{ print $1 }'`

        # HW Model check
        HW_MODEL=`prtdiag -v | head -1 | awk '{ print $6, $7, $8 }'`

        # Veritas checks
        if [ "$VxVM_VER" = "" ]; then
                VxVM_VER="N/A"
        fi
        if [ "$VCS_VER" = "" ]; then
                VCS_VER="N/A"
        fi
        if [ "$NBU_VER" = "" ]; then
                NBU_VER="N/A"
        fi

        # OBP  Version check
        OBP_VER=`prtdiag -v | grep -i obp |  sed 's/,/ /'`

        # META devices check
        META_MAIN=$(check_meta_dev | tail -2 | head -1)

        #Filesystem check
        FS_FULL=$(check_fs_full_csv)

        # Sun cluster check
        if [ -f "/etc/cluster/release" ]; then
                SUNCLUS_VER=`cat /etc/cluster/release | head -1`
        else
                SUNCLUS_VER="N/A"
        fi

        # HW errors check
        HDD_ERR=$(check_hard_trans_err_csv)

        # Defunction process check
        DFUNC_ERR=$(check_defu_process_csv)

        # Load avg check
        LOADAVG1=`/usr/bin/uptime | cut -d ":" -f4 | cut -d "," -f1`

        # /var/crash separate partition check
        OP_VAL=`df -h | grep -i /var/crash 2>/dev/null | wc -l`
        if [ $OP_VAL -eq 0 ];then
                CRASH="Not configured as separate"
        else
                        CRASH="Configured"
        fi

        # NW fault check
        if [ $NWFAILCNT -eq 0 ]
        then
                NWFAILINT="No failures"
        fi

        # SVCS check
        OS_VER1=`uname -r | cut -d. -f2`
        if [ $OS_VER1 -lt 10 ]; then
                SVCS="N/A"
        else
                SVCS=`svcs -x | grep ^svc | tr "\n\r" ":"`
        fi

        # VXVM failures check
        VXVM_FAIL=" "
        if [ $DGDISABLED -ge 1 ]; then
                DG_DIS_NAME=`echo $DG_DIS_NAME | tr "\n\r" " "`
                VXVM_FAIL="DGs disabled: $DG_DIS_NAME"
        fi

        if [ $VXDSKFAICNT -ne 0 ]; then
                VXDSKFAIL=`echo $VXDSKFAIL | tr "\n\r" " "`
                VXVM_FAIL="$VXVM_FAIL Disk failed: $VXDSKFAIL"
        fi

        if [ $VOLDISABLED -ge 1 ]; then
                VOL_DIS_NAME=`echo $VOL_DIS_NAME |  tr "\n\r" " "`
                VXVM_FAIL="$VXVM_FAIL Volumes disabled: $VOL_DIS_NAME"
        fi

        if [ "$VXVM_FAIL" = " " ]; then
                VXVM_FAIL="No failures"
        fi

        # USM agent check
        if [ -f "/opt/OV/bin/ovc" ]; then
                if [ `/opt/OV/bin/ovc -status > /dev/null; echo $?` -eq 0 ]; then
                        USM_AGENT="Running"
                fi
        else
                if [ -f "/opt/perf/bin/perfstat" ]; then
                        OUTPUT=$(/opt/perf/bin/perfstat)
                        ERR_CNT=$(echo "$OUTPUT" | egrep -c -i "Aborting|not active")
                        if [ $ERR_CNT -ne 0 ]; then
                                USM_AGENT="Few agents are running in USM"
                        else
                                USM_AGENT="Running"
                        fi
                else
                        USM_AGENT="N/A"
                fi
        fi

        if [ -f "/opt/perf/bin/perfstat" ]; then
                MW_VERSION=$(/opt/perf/bin/perfstat -v | grep " HP OpenView MeasureWare Agent" | awk '{ print $NF }')
        else
                MW_VERSION="N/A"
        fi

        if [ -f "/opt/OV/bin/OpC/opcagt" ]; then
                USM_VERSION=$(/opt/OV/bin/OpC/opcagt -version 2> /dev/null)
        else
                USM_VERSION="N/A"
        fi

        # NSR check
        if [ `ps -ef | grep -i "/usr/sbin/nsr/nsrexecd" | wc -l` -gt 1 ]; then
                NSR_DAEMON="Running"
        else
                NSR_DAEMON="N/A"
        fi

        echo "`hostname` , , Yes , `uname -s -r`, $IPADD, $HW_MODEL, `uname  -v` , $VxVM_VER, $SUNCLUS_VER, $VCS_VER, $NBU_VER,  $VXVM_FAIL , $UPTIME, $OBP_VER, $META_MAIN, \"$FS_FULL\", $HDD_ERR, $DFUNC_ERR, $LOADAVG1, $SVCS, $NWFAILINT, $CRASH, $USM_VERSION, $MW_VERSION, $USM_AGENT, $NSR_DAEMON" > /var/tmp/`hostname`-HC-output.csv
}
while getopts "cy" opts
do
case "$opts" in
c)


                CSV_FILE=/var/tmp/`hostname`.csv
                echo > $CSV_FILE
;;
y)
        CHOICE=y
;;
esac
done



WORKSPACE=/tmp/temp`echo $$`/quickservchk.sh.log
LOGFILE=$WORKSPACE/log
TEE=/usr/bin/tee
PATH=$PATH:/usr/bin:/usr/sbin:/opt/VRTS/bin:/opt/VRTSvcs/bin
export WORKSPACE LOGFILE TEE PATH
mkdir -p $WORKSPACE
#--------------------------Function Definations End-------------------------------

#--------------------------Starts Execution Here----------------------------------
display_banner
check_root_priv
check_os
check_OS_version
check_vx_version
check_meta_dev
check_meta_sync
check_dg_disabled
check_vol_disabled
check_discon_san
check_disabled_ctlr
check_vxdisk_failed
check_runn_vxtask
check_fs_full
check_hard_trans_err
check_defu_process
check_load_avg
display_sar_data
display_vmstat_data
display_top_cpu_proc
display_top_mem_proc
check_nw_inter
output_csv

echo ""
echo "======================================================"
echo "Workspace for this script is $WORKSPACE" | $TEE -a $LOGFILE
echo "" | $TEE -a $LOGFILE
echo "Script ended ... "
echo "======================================================"

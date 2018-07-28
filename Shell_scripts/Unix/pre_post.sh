#!/usr/bin/ksh

###################################################

# Written By:

# Purpose:

# Release Date:

# Version Status:

#

###################################################



DT=`date +%d%h%y-%H%M%S`

HN=`uname -n`

OS=`uname`

REL=`uname -r`

WH=`who am i |cut -f1 -d" "`

AWK=/usr/xpg4/bin/awk

LB=`who -b | $AWK '{print $4,$5,$6,$7,$8}'`

UT=`uptime | tr u . | cut -f2 -d. | $AWK  '{ORS=" "; for(i=2;i<=NF-1;i++) print $i}' | tr "," " "`

BDir=/var/tmp/$HN/compare

OMntC="OK"



#Filesystem size validation exclude list ( Applicable ex: swap, lofs, mntfs, )

FilesystemExcl="/etc/svc/volatile /lib/libc.so.1 /tmp /var/run"



if [ "$OS" != "SunOS" ]; then echo "Incompatiable OS,exitting.."; exit; fi

if [ ! -d $BDir ]; then mkdir -p  $BDir; fi

#rm /var/tmp/$HN/compare/* 2>/dev/null





## Syntax Validattion / command usage



preflag=off

postflag=off

defaultsflag=off

verboseflag=off



f_usage () {

echo >&2 "usage: $0  -pre|-post  [-d|--defaults] [-v|--verbose]"

exit

}



while [ $# -gt 0 ] && [ $# -le 3 ]

do

    case "$1" in

        -pre)  preflag=on;;

        -post) postflag=on;;

        -d|--defaults) defaultsflag=on;;

        -v|--verbose) verboseflag=on;;

        -*) f_usage;;

        *) f_usage;;

    esac

    shift

done



if  ([ "$preflag" = "on" ] && [ "$postflag" = "on" ]) || ([ "$preflag" = "off" ] && [ "$postflag" = "off" ]); then

f_usage

elif [ "$preflag" = "on" ]; then

WN="Pre"

elif [ "$postflag" = "on" ]; then

WN="Post"

fi



echo $WN

#Logfiles - Global files

LOG=$BDir/$WN-$DT-$HN-log

LOG1=$BDir/.$WN-$DT-$HN-tmplog1Del

LOG2=$BDir/.$WN-$DT-$HN-tmplog2Del

LOGD=$BDir/.$WN-$DT-$HN-DetailedLog

PRETMP=$BDir/.Pre-$DT-$HN-tmpDel

POSTTMP=$BDir/.Post-$DT-$HN-tmpDel

DATAF=$BDir/$WN-$DT-$HN-ConfigData





# Header

f_MasterHeader () {

clear

echo "                PRE/POST CONFIGURATION COMPARE v.1 " | $AWK  '{printf "%40s\n",$0}' |tee $LOG

echo "--------------------------------------------------------------------------" | tee -a $LOG

echo "DATE;HOSTNAME;OS;RELEASE;USER;UPTIME;LASTBOOT" | $AWK -F";" '{printf "%-14s|%-15s|%-5s|%-7s|%-5s|%-10s|%12s\n",$1,$2,$3,$4,$5,$6,$7}' | tee -a $LOG

echo "--------------------------------------------------------------------------" | tee -a $LOG

echo "$DT;$HN;$OS;$REL;$WH;$UT;$LB"  |$AWK -F";" '{printf "%-14s|%-15s|%-5s|%-7s|%-5s|%-10s|%12s\n",$1,$2,$3,$4,$5,$6,$7}' | tee -a $LOG

echo "--------------------------------------------------------------------------" | tee -a $LOG

}





#compare two strings

f_CompStr () {

if [ $# -eq 3 ]; then

        if [ -n $1 ]; then  WhtComp=$1; fi

        if [ -n $2 ]; then  Preval=$2; fi

        if [ -n $3 ]; then  Poval=$3; fi



                        if [ "$Preval" = "$Poval" ]; then

                        echo "$WhtComp;$Preval;$Poval;OK"

                        else

                        echo "$WhtComp;$Preval;$Poval;ERROR"

                       # PoMntErr="Y"

                        exit 200

                        fi

else

echo "pass the parameters"

exit 100

fi

}



#Create Tmp files

#       awk -v has alternate options but may face issues in sol8

f_ExtractCreateTempFile () {

if [ $# == 3 ];then

ExtCmd="$1"

SourceFile=$2

TmpFilename=$3

else

echo "invalid no.of perameters passed to function"

fi

while read line

do

        if [ "$line" = "<$ExtCmd>" ]; then ST=Y; continue; elif [ "$line" = "</$ExtCmd>" ]; then ST=N; fi

        if [ "$ST" = "Y" ]; then

        echo $line >>$TmpFilename

        fi



 done < $SourceFile

}





############ START - Collection ##################





## DF data collection function for pre/post data ##



f_dfcollect () {

#Logfiles - DF Temp

DataDelim=$1

DFlog=$BDir/.$WN-$DT-$HN-DF

DFErr=$BDir/.$WN-$DT-$HN-DFErr

DFErrMnt=$BDir/.$WN-$DT-$HN-DFErrMnt

Mnttab=$BDir/.$WN-$DT-$HN-Mnttab

DfMnttab=$BDir/$WN-$DT-$HN-DFdata





df -k 2>$DFErr | $AWK '{print $1";"$2";"$3";"$4";"$5";"$6}' > $DFlog

#awk '{print $1";"$2";"$3";"$4";"$5}' /etc/mnttab >$Mnttab

mount -v | $AWK '{print $1";"$3";"$5";"$6";"$8"-"$9"-"$10"-"$11"-"$12}' >$Mnttab



# Parsing df -k data

DFLine1=Y

while read DFLine ;do

ma=N

if [ $DFLine1 = Y ]; then

        echo $DFLine";FSType;MountOptions;Mounttime;Permissions;Ownership;StaleMount" >$DfMnttab

        DFLine1=N ; ma=Y

fi

        while read Mntline ;do

                if [ `echo $DFLine | $AWK -F";" '{print $6 }'` = `echo $Mntline |  $AWK -F";" '{print $2}'` ]; then

                mnt=`echo $DFLine | $AWK -F";" '{print $6 }'`

                MntPerOwnr=`ls -ld $mnt | $AWK '{print $1";"$3":"$4}'`

                if [ -z $MntPerOwnr ]; then MntPerOwnr=";"; fi

                echo $DFLine";"`echo $Mntline | $AWK -F";" '{print $3";"$4";"$5}'`";"$MntPerOwnr";NO" >> $DfMnttab

                ma=Y ; break

                fi

        done < $Mnttab

if [ $ma = N ]; then echo $DFLine >> $DfMnttab; fi

done < $DFlog







# Parsing df -k std error log for STALE mounts

if [ -s $DFErr ]; then

#df: cannot statvfs /aa: No such file or directory

cut -d/ -f2 $DFErr | cut -d: -f1 | $AWK '{print "/"$1}' > $DFErrMnt

while read DfMntLine ;do

ma=N

                while read Mntline ;do

                if [ $DfMntLine = `echo $Mntline |  $AWK -F";" '{print $2}'` ]; then

                MntPerOwnr=`ls -ld $DfMntLine  2>/dev/null | $AWK '{print $1";"$3":"$4}'`

                if [ -z $MntPerOwnr ]; then MntPerOwnr=";"; fi

                echo `echo $Mntline | $AWK -F";" '{print $1";;;;;"$2";"$3";"$4";"$5}'`";"$MntPerOwnr";STALEYES"  >> $DfMnttab

                ma=Y ; break

                fi

                done < $Mnttab



if [ "$ma" = "N" ]; then echo $DfMntLine >> $DfMnttab;fi

done < $DFErrMnt

rm $DFErrMnt

fi





# 2.align with function

if [ "$WN" = "Pre" ]; then

PreMntC=`grep -v StaleMount $DfMnttab | grep -v STALEYES | wc -l`

PreMntS=`grep -w STALEYES $DfMnttab | wc -l`

if [ $PreMntS -ne 0 ]; then PreMntC="$PreMntC+$PreMntS(Stale)"; fi

PreMntC=`echo $PreMntC | tr " " ""`

echo "\nPreDF Mounts       : $PreMntC\n"  | tee -a $LOG

fi



#Del#DFCurdata=$DfMnttab

echo "<$DataDelim>" >>$DATAF

cat $DfMnttab >>$DATAF

echo "</$DataDelim>" >>$DATAF



rm "$DFlog" "$DFErr" "$Mnttab"

}                #end of f_dfcollect



f_ifconfigCollect () {

#Logfiles - Ifconfig Temp

Ifcollect=$BDir/$WN-$DT-$HN-Ifcfgdata

DataDelim=$1



        # a. collects ifconfig -a output with logical ips into single line,

                #prints output along with groupname/mac details for logical nics also by matching nic index



ifconfig -a | $AWK '/flags/{if (NR=1);print x;x=$0;next}  {x=x""$0} END {print x;}'  | tr "\t" ";" | tr " " ";"|  $AWK -F";" 'BEGIN {print "NIC;FLAGS;MTU;IP;NETMASK;BROADCAST;MAC;IPMPGROUP;NICINDEX" } /^$/ {next}  {for(i = 1; i <= NF; i++) { if (i==1) xnic=$i; else if (i==2) xflags=$i; else if ($i=="mtu") xmtu=$(i+1); else if ($i=="index") xindex=$(i+1); else if ($i=="inet") xinet=$(i+1); else if ($i=="netmask")  xnetmask=$(i+1); else if ($i=="broadcast")  xbroadcast=$(i+1); else if ($i=="groupname") xgroupname=$(i+1); else if ($i=="ether") xether=$(i+1) ;}

if ( NR > 1 ) {

                if (NR==2) {oindex=xindex;ogroupname=xgroupname;oether=xether;}

                if (oindex==xindex) { if (xgroupname=="") xgroupname=ogroupname;

                if (xether=="") xether=oether;;}

                if (oindex!=xindex) {oindex=xindex;ogroupname=xgroupname;oether=xether;}

;} print xnic";"xflags";"xmtu";"xinet";"xnetmask";"xbroadcast";"xether";"xgroupname";"xindex;xnic="";xflags="";xmtu="";xinet="";xnetmask="";xbroadcast="";xgroupname="";xether="";xindex="";}' >$Ifcollect



echo "<$DataDelim>" >>$DATAF

cat $Ifcollect >>$DATAF

echo "</$DataDelim>" >>$DATAF

rm $Ifcollect

}





############ END - Collection ##################









## Select Pre/Post Config data ##

f_SelectPreConfigData () {

Err=

PreDataFile=



ls -lt $BDir/Pre*ConfigData >/dev/null 2>&1

if [ $? = 0 ]; then

TOldConfig=`ls -lt $BDir/Pre*ConfigData | $AWK -F/ 'NR==1 {print $NF}'`

else

echo "Pre Config data NOT found in $BDir..exitting.." | tee -a $LOG

exit 100

fi



printf "\nComparing Current Config data with Pre Config data ..,\n   (L)ist Pre Config files [$TOldConfig]: " | tee -a $LOG

read PD

case $PD in

        "")

                PreDataFile=$BDir/$TOldConfig

        ;;

        L)

        cd $BDir

        ls -lt Pre*ConfigData | head -10 | $AWK -F/ '{print $NF}' | head -10 | $AWK 'BEGIN {print "\nS.No\t\tFilename\t\t\tCreationDate"} {print NR"\t",$9,"\t"$6"-"$7"-"$8}' | tee -a $LOG

        printf "\nSelect the Pre Config Data file: " 2>&1 | tee -a $LOG

        read LFl

        if [ -f $BDir/$LFl ]; then

                PreDataFile=$BDir/$LFl

        else

                echo "Error: $LF1 No such file." | tee -a $LOG

        fi

        ;;

        *)

        echo "Invalid Option..." | tee -a $LOG

        break

        ;;

esac



}               #end of f_SelectPreConfigData





## START - COMAPRE  #######



## Compare Pre/Post DF data ##



#PreMountCount

f_PreMountcount () {

PreMntC=`grep -v StaleMount $PRETMP | grep -v STALEYES | wc -l`

PreMntS=`grep -w STALEYES $PRETMP | wc -l`

if [ $PreMntS -ne 0 ]; then PreMntC="$PreMntC+$PreMntS(Stale)"; fi

PreMntC=`echo $PreMntC | tr " " ""`

}



#PostMountCount

f_PoMountcount () {

PostMntC=`grep -v StaleMount $POSTTMP | grep -v STALEYES | wc -l`

PostMntS=`grep -w STALEYES $POSTTMP | wc -l`

if [ $PostMntS -ne 0 ]; then PostMntC="$PostMntC+$PostMntS(Stale)"; fi

PostMntC=`echo $PostMntC | tr " " ""`

}



#df -k compare



f_dfcompare () {

DataDelim="$1"



f_ExtractCreateTempFile "$DataDelim" $PreDataFile $PRETMP

f_ExtractCreateTempFile "$DataDelim" $PostDataFile $POSTTMP



#Extra mounts/Missing attributes : comapring  PostDf with PreDf

PoExtMnt=""

PoExtMntErr=";OK"

PoExtMntC=0

while IFS=\; read PoFilesystem  Pokbytes  Poused  Poavail  Pocapacity  PoMounted  PoFSType  PoMountOptions  PoMounttime  PoPermissions  PoOwnership  PoStaleMount

do

PoMntExi="N"

PoMntErr="N"

PoStl=""



if [ "$PoStaleMount" = "STALEYES" ] ;then PoStl="(Stale)"; fi



#echo "$PoFilesystem;$Pokbytes;$Poused;$Poavail;$Pocapacity;$PoMounted;$PoFSType;$PoMountOptions;$PoMounttime;$PoPermissions;$PoOwnership;$PoStaleMount"

        while IFS=\; read PrFilesystem  Prkbytes  Prused  Pravail  Prcapacity  PrMounted  PrFSType  PrMountOptions  PrMounttime  PrPermissions  PrOwnership  PrStaleMount

        do

        PrStl=""

        MountOptionsMis=

        MountOptionsExt=



        if [ "$PrStaleMount" = "STALEYES" ] ;then PrStl="(Stale)"; fi



                if [ "$PoMounted" != "Mounted" ] && [ "$PoMounted" = "$PrMounted" ]; then

                PoMntExi="Y"

                #echo "\t $PrFilesystem;$Prkbytes;$Prused;$Pravail;$Prcapacity;$PrMounted;$PrFSType;$PrMountOptions;$PrMounttime;$PrPermissions;$PrOwnership;$PrStaleMount"





                        FilesystemRes=$(f_CompStr "Filesystem" "$PrFilesystem" "$PoFilesystem")

                        if [ $? = 200 ]; then PoMntErr="Y";fi



                        kbytesRes=$(f_CompStr "FSSize(kb)" "$Prkbytes" "$Pokbytes")

                        if [ $? = 200 ]; then PoMntErr="Y";fi



                        for J in `echo "$FilesystemExcl" | tr " " "\n"`; do

                        if [ "$J" = "$PoMounted" ]; then

                                kbytesRes="FSSize(kb);Skipped;Skipped;OK"

                                PoMntErr="N"

                        fi

                        done



                        PermissionsRes=$(f_CompStr "Permissions" "$PrPermissions" "$PoPermissions")

                        if [ $? = 200 ]; then PoMntErr="Y";fi



                        FSTypeRes=$(f_CompStr "FSType" "$PrFSType" "$PoFSType")

                        if [ $? = 200 ]; then PoMntErr="Y";fi



                        OwnershipRes=$(f_CompStr "Ownership" "$PrOwnership" "$PoOwnership")

                        if [ $? = 200 ]; then PoMntErr="Y";fi





                        PoMountOpt=`echo  $PoMountOptions | $AWK -F= '{print $1 }'`

                        PrMountOpt=`echo  $PrMountOptions | $AWK -F= '{print $1 }'`



                        if [ "$PoMountOpt" = "$PrMountOpt" ]; then

                        MountOptionsRes="MountOptions;$PrMountOpt;$PoMountOpt;OK"

                        else



                                mntcmd=`diff <(echo "$PoMountOpt" | tr / "\n" | sort) <(echo "$PrMountOpt" | tr / "\n" | sort)  | grep '>'`

                                if [ $? -eq 0 ]; then

                                        for i in `echo "$mntcmd" | tr / "\n" | cut -f2 -d " "`

                                        do

                                                if [ -z $MountOptionsMis ];then

                                                MountOptionsMis="MountOptions Miss;;$i;ERROR"

                                                else

                                                MountOptionsMis="$MountOptionsMis\n;;$i;ERROR"

                                                fi

                                        done

                                fi



                                mntcmd=`diff <(echo "$PoMountOpt" | tr / "\n" | sort) <(echo "$PrMountOpt" | tr / "\n" | sort)  | grep '<'`

                                if [ $? -eq 0 ]; then



                                        for i in `echo "$mntcmd" | tr / "\n" | cut -f2 -d " "`

                                        do

                                                if [ -z $MountOptionsExt ];then

                                                MountOptionsExt="  MountOptions Extra;;$i;ERROR"

                                                else

                                                MountOptionsExt="$MountOptionsExt\n;;$i;ERROR"

                                                fi

                                        done

                                fi





                        MountOptionsRes="$MountOptionsMis\n$MountOptionsExt"

                        PoMntErr="Y"

                        fi





        if [ "$PoMntErr" = "Y" ]; then

        echo "#$PoMounted;$PrStl;$PoStl;;ERROR" >> $LOG2

        PoMntErr="N"

        else

        echo "#$PoMounted;$PrStl;$PoStl;OK" >> $LOG2

        fi



        echo "  $FilesystemRes\n  $kbytesRes\n  $FSTypeRes\n  $MountOptionsRes\n  $PermissionsRes\n  $OwnershipRes\n" >>$LOG2



                fi

        done < $PRETMP





        if [ "$PoMounted" != "Mounted" ] && [ "$PoMntExi" = "N" ]; then

                if [ "$PoExtMnt" = "" ]; then

                PoExtMnt="$PoMounted$PoStl;ERROR"

                PoExtMntErr=""

                else

                PoExtMnt="$PoMounted$PoStl;ERROR\n;;$PoExtMnt"

                PoExtMntErr=""

                fi

                #echo "$PoFilesystem;$Pokbytes;$Poused;$Poavail;$Pocapacity;$PoMounted;$PoFSType;$PoMountOptions;$MountOptionsMis;$PoMounttime;$PoPermissions;$PoOwnership;$PoStaleMount"

        PoExtMntC=`expr $PoExtMntC + 1`

        OMntC="ERROR"

        fi

done < $POSTTMP

##Missing Mounts comparing with PreDF with PostDF

PrExtMnt=

PrExtMntErr=";OK"

PrExtMntC=0

while IFS=\; read PrFilesystem  Prkbytes  Prused  Pravail  Prcapacity  PrMounted  PrFSType  PrMountOptions  PrMounttime  PrPermissions  PrOwnership  PrStaleMount

do

PrMntExi="N"

PreStl=""

if [ "$PrStaleMount" = "STALEYES" ]; then PreStl="(Stale)";fi



#echo "\t $PrFilesystem;$Prkbytes;$Prused;$Pravail;$Prcapacity;$PrMounted;$PrFSType;$PrMountOptions;$PrMounttime;$PrPermissions;$PrOwnership;$PrStaleMount"



        while IFS=\; read PoFilesystem  Pokbytes  Poused  Poavail  Pocapacity  PoMounted  PoFSType  PoMountOptions  PoMounttime  PoPermissions  PoOwnership  PoStaleMount

        do

                if [ "$PrMounted" != "Mounted" ] && [ "$PrMounted" = "$PoMounted" ]; then

                PrMntExi="Y"

         #echo "$PoFilesystem;$Pokbytes;$Poused;$Poavail;$Pocapacity;$PoMounted;$PoFSType;$PoMountOptions;$PoMounttime;$PoPermissions;$PoOwnership;$PoStaleMount"

                fi

        done < $POSTTMP



        if [ "$PrMounted" != "Mounted" ] && [ "$PrMntExi" = "N" ]; then

                if [ "$PrExtMnt" = "N" ]; then

                PrExtMnt="$PrMounted$PreStl;ERROR"

                PrExtMntErr=""

                else

                PrExtMnt="$PrMounted$PreStl;ERROR\n;;$PrExtMnt"

                PrExtMntErr=""

                fi

                #echo "$PrFilesystem;$Prkbytes;$Prused;$Pravail;$Prcapacity;$PrMounted;$PrFSType;$PrMountOptions;$PrMounttime;$PrPermissions;$PrOwnership;$PrStaleMount"

        PrExtMntC=`expr $PrExtMntC + 1`

        OMntC="ERROR"

        fi

done < $PRETMP



echo "Total DF Mounts;$PreMntC;$PostMntC;$OMntC" >> $LOG1

echo "Missing Mounts   $PrExtMntC;;$PrExtMnt$PrExtMntErr" >> $LOG1

echo "Extra Mounts     $PoExtMntC;;$PoExtMnt$PoExtMntErr" >> $LOG1



if [ "`grep ERROR "$LOG1" "$LOG2"`" ]; then

echo "[*] $DataDelim;;;;ERROR" >>$LOGD

fi

cat "$LOG1" "$LOG2" >>$LOGD; rm "$LOG1" "$LOG2"

rm "$PRETMP" "$POSTTMP"



}               #end of f_dfcompare







f_ifconfigCompare () {



#NIC;FLAGS;MTU;IP;NETMASK;BROADCAST;MAC;IPMPGROUP;NICINDEX

#e1000g3:1:;flags=19040843<UP,BROADCAST,RUNNING,MULTICAST,DEPRECATED,IPv4,NOFAILOVER,FAILED>;1500;192.168.85.22;ffffff00;192.168.85.255;8:0:27:c2:a7:52;testgroup1;4





DataDelim="$1"

f_ExtractCreateTempFile "$DataDelim" "$PreDataFile" "$PRETMP"

f_ExtractCreateTempFile "$DataDelim" "$PostDataFile" "$POSTTMP"





if [ ! -s "$PRETMP" ]; then

echo "Error: No Pre Config data found compare.skipping.. $DataDelim"

exit 300

elif [ ! -s "$POSTTMP" ]; then

echo "Error: No Post Config data found compare.skipping.. $DataDelim"

exit 300

else

a=`cat $PRETMP | wc -l`

PreNICC=`expr $a - 1`

b=`cat $POSTTMP | wc -l`

PostNICC=`expr $b - 1`

fi



PoExtNIC=""

PoExtNICErr=";OK"

PoExtNICC=0



while IFS=\; read PoNIC PoFLAGS PoMTU PoIP PoNETMASK PoBROADCAST PoMAC PoIPMPGROUP PoNICINDEX

do



 PoNICExi="N"

 PoNICErr="N"

FlagOptionsMis=

FlagOptionsExt=



        while IFS=\; read PrNIC PrFLAGS PrMTU PrIP PrNETMASK PrBROADCAST PrMAC PrIPMPGROUP PrNICINDEX

        do

               if [ "$PoNIC" != "NIC" ] && [ "$PoNIC" = "$PrNIC" ]; then

               PoNICExi="Y"





                        #FLAGSRes=$(f_CompStr "flags" "$PrFLAGS" "$PoFLAGS")

                        #if [ $? = 200 ]; then PoNICErr="Y";fi



                        PoNICOpt=`echo  $PoFLAGS | $AWK -F= '{print $2 }'`

                        PrNICOpt=`echo  $PrFLAGS | $AWK -F= '{print $2 }'`



                        if [ "$PoNICOpt" = "$PrNICOpt" ]; then

                        FLAGSRes="flags;$PrNICOpt;$PoNICOpt;OK"

                        else



                                flagcmd=`diff <(echo "$PoNICOpt" | tr , "\n" | tr \< "\n" | tr \> "\n" | sort) <(echo "$PrNICOpt" | tr , "\n" | tr \< "\n" | tr \> " " | sort)  | grep '>'`

                                if [ $? -eq 0 ]; then

                                        for i in `echo "$flagcmd" | tr / "\n" | cut -f2 -d " "`

                                        do

                                                if [ -z $FlagOptionsMis ];then

                                                FlagOptionsMis="flags Miss;;$i;ERROR"

                                                else

                                                FlagOptionsMis="$FlagOptionsMis\n;;$i;ERROR"

                                                fi

                                        done

                                fi



                                flagcmd=`diff <(echo "$PoNICOpt" | tr , "\n" | tr \< "\n" | tr \> "\n" | sort) <(echo "$PrNICOpt" | tr , "\n" | tr \< "\n" | tr \> " " | sort)  | grep '<'`

                                if [ $? -eq 0 ]; then



                                        for i in `echo "$flagcmd" | tr / "\n" | cut -f2 -d " "`

                                        do

                                                if [ -z $FlagOptionsExt ];then

                                                FlagOptionsExt="flags Extra;;$i;ERROR"

                                                else

                                                FlagOptionsExt="$FlagOptionsExt\n;;$i;ERROR"

                                                fi

                                        done

                                fi





                        FLAGSRes="$FlagOptionsMis\n  $FlagOptionsExt"

                        PoNICErr="Y"

                        fi





                        MTURes=$(f_CompStr "mtu" "$PrMTU" "$PoMTU")

                        if [ $? = 200 ]; then PoNICErr="Y";fi



                        IPRes=$(f_CompStr "ip" "$PrIP" "$PoIP")

                        if [ $? = 200 ]; then PoNICErr="Y";fi



                        NETMASKRes=$(f_CompStr "netmask" "$PrNETMASK" "$PoNETMASK")

                        if [ $? = 200 ]; then PoNICErr="Y";fi



                        BROADCASTRes=$(f_CompStr "broadcast" "$PrBROADCAST" "$PoBROADCAST")

                        if [ $? = 200 ]; then PoNICErr="Y";fi



                        MACRes=$(f_CompStr "ether" "$PrMAC" "$PoMAC")

                        if [ $? = 200 ]; then PoNICErr="Y";fi



                        IPMPGROUPRes=$(f_CompStr "ipmpgroup" "$PrIPMPGROUP" "$PoIPMPGROUP")

                        if [ $? = 200 ]; then PoNICErr="Y";fi





                        if [ "$PoNICErr" = "Y" ]; then

                                echo "#$PoNIC;;;;ERROR" >> $LOG2

                                PoNICErr="N"

                        else

                                echo "#$PoNIC;;;;OK" >> $LOG2

                        fi



                echo "  $FLAGSRes\n  $MTURes\n  $IPRes\n  $NETMASKRes\n  $BROADCASTRes\n  $MACRes\n  $IPMPGROUPRes\n" >>$LOG2



                fi

        done < $PRETMP



        if [ "$PoNIC" != "NIC" ] && [ "$PoNICExi" = "N" ]; then

                if [ "$PoExtNIC" = "" ]; then

                PoExtNIC="$PoNIC;ERROR"

                PoExtNICErr=""

                else

                PoExtNIC="$PoNIC;ERROR\n;;$PoExtNIC"

                PoExtNICErr=""

                fi



        PoExtNICC=`expr $PoExtNICC + 1`

        ONICC="ERROR"

        fi



done < $POSTTMP





##Missing NICs comparing with Pre with Post

PrExtNIC=

PrExtNICErr=";OK"

PrExtNICC=0

while IFS=\; read PrNIC PrFLAGS PrMTU PrIP PrNETMASK PrBROADCAST PrMAC PrIPMPGROUP PrNICINDEX

do

PrNICExi="N"





        while IFS=\; read PoNIC PoFLAGS PoMTU PoIP PoNETMASK PoBROADCAST PoMAC PoIPMPGROUP PoNICINDEX

        do

                if [ "$PrNIC" != "NIC" ] && [ "$PoNIC" = "$PrNIC" ]; then

                PrNICExi="Y"

                fi

        done < $POSTTMP



        if [ "$PrNIC" != "NIC" ] && [ "$PrNICExi" = "N" ]; then

                if [ "$PrExtNIC" = "N" ]; then

                PrExtNIC="$PrNIC;ERROR"

                PrExtNICErr=""

                else

                PrExtNIC="$PrNIC;ERROR\n;;$PrExtNIC"

                PrExtNICErr=""

                fi



        PrExtNICC=`expr $PrExtNICC + 1`

        ONICC=";ERROR"

        fi

done < $PRETMP



if [ $PreNICC != $PostNICC ]; then ONICC="ERROR"; fi



echo "Total NICs;$PreNICC;$PostNICC;$ONICC" >> $LOG1

echo "Missing NICs      $PrExtNICC;;$PrExtNIC$PrExtNICErr" >> $LOG1

echo "Extra NICs        $PoExtNICC;;$PoExtNIC$PoExtNICErr" >> $LOG1



if [ "`grep ERROR "$LOG1" "$LOG2"`" ]; then

echo "[*] $DataDelim ----;--------------------;--------------------;----------;ERROR" >>$LOGD

fi

cat "$LOG1" "$LOG2" >>$LOGD; rm "$LOG1" "$LOG2"

rm "$PRETMP" "$POSTTMP"



}







#####  END - COMAPRE  #######



f_AllDataCollect () {



if [ -z $WN ]; then

echo "Invalid Data collection option, Pre/Post"

exit

fi



f_dfcollect "df -k"

f_ifconfigCollect "ifconfig -a"



if [ -e $DATF ] && [ -s $DATF ]; then PostDataFile=$DATAF; else PostDataFile=""; fi

}





f_AllDataCompare () {



until [[ -n $PreDataFile ]] && [[ -n $PostDataFile ]]; do

        f_SelectPreConfigData

done



echo "\n Pre Config Data file   :   `basename $PreDataFile`" | tee -a $LOG

echo "Post Config Data file   :  `basename $PostDataFile`" | tee -a $LOG

echo "Processing...." | tee -a $LOG





f_dfcompare "df -k"

f_ifconfigCompare "ifconfig -a"







if [ "`grep ERROR $LOGD`" ] || [ "$verboseflag" = "on" ]; then

echo "--------------------------------------------------------------------------" | tee -a $LOG

echo "Comparing Data;PRE Config Data;POST Config Data;STATUS" | $AWK -F";" '{printf "%-20s|%-20s|%-20s|%-10s|\n",$1,$2,$3,$4}' | tee -a $LOG

echo "--------------------------------------------------------------------------" | tee -a $LOG

else

echo "\n\nNo Errors found."

fi



if [ "$verboseflag" = "on" ]; then

cat $LOGD | $AWK -F";" '{printf "%-20s|%-20s|%-20s|%-10s|\n",$1,$2,$3,$4}' | tee -a $LOG

else

cat $LOGD | grep ERROR | $AWK -F";" '{printf "%-20s|%-20s|%-20s|%-10s|\n",$1,$2,$3,$4}' | tee -a $LOG

fi









}

## Main ##

case $WN in

        Pre)

        f_MasterHeader

        f_AllDataCollect

        ;;

        Post)

        f_MasterHeader

        f_AllDataCollect

        f_SelectPreConfigData

        f_AllDataCompare

        echo "\n"

        ;;

        *)

        echo "Invalid input flag pre/post..exiting.." | tee -a $LOG

        exit

        ;;

esac


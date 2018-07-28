#!/bin/sh
#
# Confidential and Proprietary for Oracle Corporation
#
# This computer program contains valuable, confidential, and
# proprietary information.  Disclosure, use, or reproduction
# without the written authorization of Oracle is prohibited.
# This unpublished work by Oracle is protected by the laws
# of the United States and other countries.  If publication
# of this computer program should occur, the following notice
# shall apply:
#
# Copyright (c) 2011, 2014, Oracle and/or its affiliates. All rights reserved.
#
#
#export MW_HOME=/u01/app/Oracle/Middleware/Oracle_Home
#export JAVA_HOME=/u01/app/jdk
usage() {
        echo "Usage:"
        echo " pre_upgrade_pod.sh "
        echo "  -n <pod name>"
        echo " -e current em_home (optional) "

}

while getopts n:p:e: flag; do
  case $flag in
        n)
                echo "-n used: $OPTARG";
                POD_NAME=$OPTARG
          ;;
       p)

                PASSWORD=$OPTARG
          ;;
        e)

                EM_HOME=$OPTARG
          ;;
  esac
done

if [ -n "$PASSWORD" ]
then
    echo "Proceeding with the password provided"
else
  stty -echo
  printf "Enter paasusr Password:"
  read password
  stty echo
  printf "\n"
  export PASSWORD=$password

fi
if [ -n "$EM_HOME" ]
then
 echo "proceeding with EM_HOME provided"
else
 echo "setting EM_HOME to default /u01/ops/em"
  EM_HOME="/u01/ops/em"
fi
EXITCODE=0
SCRIPT_PATH=`dirname $0`
#To make sure that right user is running this script
USER=`whoami`
echo "user is $USER"
if [ "$USER" != "sdiadmin" ]
then
echo "This script can't be executed as "$USER
exit 1
fi
PROPERTY_FILE_NAME="pre_upgrade_checks.properties"

  SCRIPT_PATH=`dirname $0`
 . $SCRIPT_PATH/$PROPERTY_FILE_NAME
  echo "Successfully Read the properties file"


#$SCRIPT_PATH/update_pod_databag.sh -n $POD_NAME
#RESULT=$?
#if [ $RESULT -ne 0 ]; then
#        EXITCODE=1
#fi

echo "cookbook version is $COOKBOOK_VER"
 DBAG_DIR=/u01/data/objectrepoclient/decrypted/$POD_NAME/data_bags
    for DBAG_JSON_FILE in "$DBAG_DIR"/*as.json; do
        if [ -f $DBAG_JSON_FILE ]
        then
            AS_HOST=$(cat $DBAG_JSON_FILE | python -c 'import sys, json; obj=json.load(sys.stdin); print obj["bdpsvc.wls.adminserver.hostname"]' | awk '{print tolower($0)}')
            MS1_HOST=$(cat $DBAG_JSON_FILE | python -c 'import sys, json; obj=json.load(sys.stdin); print obj["bdpsvc.wls.managedserver1.hostname"]' | awk '{print tolower($0)}')
            MS2_HOST=$(cat $DBAG_JSON_FILE | python -c 'import sys, json; obj=json.load(sys.stdin); print obj["bdpsvc.wls.managedserver2.hostname"]' | awk '{print tolower($0)}')
            MN_HOST=$(cat $DBAG_JSON_FILE | python -c 'import sys, json; obj=json.load(sys.stdin); print obj["bdpsvc.hadoop.masternode.hostname"]' | awk '{print tolower($0)}')

           WN1_HOST=$(echo $MN_HOST | sed -e 's/mn1/wn1/g')
                WN2_HOST=$(echo $MN_HOST | sed -e 's/mn1/wn2/g')
                WN3_HOST=$(echo $MN_HOST | sed -e 's/mn1/wn3/g')

        fi
  done
  MCO_AS_HOSTS+="-I $AS_HOST "
  MCO_MS1_HOSTS+="-I $MS1_HOST "
  MCO_MS2_HOSTS+="-I $MS2_HOST "
  MCO_AS_MS1_HOSTS="$MCO_AS_HOSTS $MCO_MS1_HOSTS"
  ALL_HOSTS="$MCO_AS_HOSTS $MCO_MS1_HOSTS $MCO_MS2_HOSTS "

  MCO_MN_HOSTS+="-I $MN_HOST "
  MCO_WN1_HOSTS+="-I $WN1_HOST "
  MCO_WN2_HOSTS+="-I $WN2_HOST "
  MCO_WN3_HOSTS+="-I $WN3_HOST "
  ALL_HADOOP_HOSTS="$MCO_MN_HOSTS $MCO_WN1_HOSTS $MCO_WN2_HOSTS $MCO_WN3_HOSTS "

  ALL_POD_HOSTS="$ALL_HOSTS $ALL_HADOOP_HOSTS"

    WLS_HOSTS="$AS_HOST,$MS1_HOST,$MS2_HOST "
  ALL_HOSTS="$AS_HOST,$MS1_HOST,$MS2_HOST,$MN_HOST"
  echo "Checking login to remote host"
  FIRST_HOST=${WLS_HOSTS[0]}
  fab -f fab_manage_tarball.py -p "$PASSWORD" check_login -H $FIRST_HOST

(
start=`date +"%s"`

 echo "start $POD_NAME pre-upgrade: `date`"

 echo "Running devops-precache and devops-paas cookbooks"
 mco rpc -v --dt 15 -t 355 -jW service=odecs runchefclient  runlist --arg items="cookbook-odecs-pod::devops_precache_caller@$COOKBOOK_VER" $ALL_POD_HOSTS
 mco rpc -v --dt 15 -t 355 -jW service=odecs runchefclient  runlist --arg items="cookbook-odecs-pod::devops_paas_caller@$COOKBOOK_VER" $ALL_POD_HOSTS

 echo "deleting backup scripts, if any"
 fab -f fab_manage_tarball.py -p "$PASSWORD" backup_cleanup -H $WLS_HOSTS -P -z 3
 res=$?
 if [ $res -ne 0 ]; then
       EXITCODE=1
 fi

backup_pids=''
fab -f fab_manage_tarball.py -p "$PASSWORD" backup:"$POD_NAME" -H $WLS_HOSTS -P -z 3 &
backup_pid=$!

fab -f fab_manage_tarball.py -p "$PASSWORD" hadoop_backup -H $MN_HOST &
hadoop_backup_pid=$!

fab -f fab_manage_tarball.py -p "$PASSWORD" prepare_bdp_source -H $WLS_HOSTS -P -z 3 &
bdp_source_pid=$!

fab -f fab_manage_tarball.py -p "$PASSWORD" prepare_hadoop_source -H $MN_HOST &
hadoop_source_pid=$!

backup_pids="$backup_pids $backup_pid $hadoop_backup_pid $bdp_source_pid $hadoop_source_pid"

for pid in $backup_pids
do
    wait $pid
    RESULT=$?
    if [ $RESULT -ne 0 ]; then
        EXITCODE=1
    fi
done

echo "setup key"
fab -f fab_manage_tarball.py -p "$PASSWORD" push_key -H $ALL_HOSTS -P -z 4
res=$?
if [ $res -ne 0 ]; then
   EXITCODE=1
fi

rsync_pids=''
fab -f fab_manage_tarball.py -p "$PASSWORD" rsync_vm:"/u01/app/shiphomes/tarsource/bdp-install-files/","wls" -H $WLS_HOSTS -P -z 3 &
bdp_rsync_pid=$!

fab -f fab_manage_tarball.py -p "$PASSWORD" rsync_vm:"/u01/app/shiphomes/tarsource/bdp-hadoop-files/","hadoop" -H $MN_HOST &
hadoop_rsync_pid=$!

rsync_pids="$rsync_pids $bdp_rsync_pid $hadoop_rsync_pid"
for pid in $rsync_pids
do
    wait $pid
    RESULT=$?
    if [ $RESULT -ne 0 ]; then
        EXITCODE=1
    fi
done

permissions_pids=''
fab -f fab_manage_tarball.py -p "$PASSWORD" wls_permissions -H $WLS_HOSTS -P -z 3 &
wls_permissions_pid=$!

fab -f fab_manage_tarball.py -p "$PASSWORD" hadoop_permissions -H $MN_HOST &
hadoop_permissions_pid=$!

permissions_pids="$permissions_pids $wls_permissions_pid $hadoop_permissions_pid"
for pid in $permissions_pids
do
    wait $pid
    RESULT=$?
    if [ $RESULT -ne 0 ]; then
        EXITCODE=1
    fi
done

echo "Updating the databag"
$SCRIPT_PATH/update_pod_databag.sh -n $POD_NAME -r true -e $EM_HOME
RESULT=$?
if [ $RESULT -ne 0 ]; then
        EXITCODE=1
fi

finish=`date +"%s"`
echo "finish $POD_NAME pre-upgrade: `date`"
let ttlTime=($finish-$start)/60

if [ $EXITCODE -eq 0 ]
then
        echo "Pre-Upgrade of $POD_NAME SUCCESSFUL. Total running time: $ttlTime mins"
else
        echo "Pre-Upgrade of $POD_NAME FAILED. Total running time: $ttlTime mins"
fi
)2>&1 | logger -st "pre_upgrade_pod_"$POD_NAME
exit $EXITCODE

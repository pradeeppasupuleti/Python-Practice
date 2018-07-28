#!/usr/bin/python
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
# Copyright (c) 2011, 2016, Oracle and/or its affiliates. All rights reserved.
#
#
'''
fab_manage_tarball.py script. Requires python-fabric to run.
Run as:
fab -f fab_manage_tarball.py <task>:'<parameter>' <arguments>.
See individual commands for details.
'''

import os, os.path
from fabric.api import env, parallel
from fabric.operations import sudo, run, put, local
from fabric.api import settings
from fabric.api import run, hide
from fabric.contrib.project import rsync_project
import socket
from fabric.contrib.files import append, contains

REMOTE_DIR = "/u01/data/binaries"
BDP_USER = "paasusr"
DEFAULT_TARBALL_URL = ""
DEFAULT_CDH_URL = ""
APP_HOME="/u01/app"
DATA_HOME="/u01/data"
env.user = BDP_USER
env.password='uMuCGAvzCHKuv3Ma'
POD_NAME = ""
PUB_KEY='/home/sdiadmin/.ssh/id_rsa.pub'
AUTH_KEY='/home/paasusr/.ssh/authorized_keys'
def check_login():
  '''Run as:
  fab -f fab_manage_tarball.py check_login -H <host> -p "PASSWORD"
  '''
  try:
   sudo( "pwd", shell=False )
  except EOFError:
    print("fab_manage_tarball check_login: Incorrect Password")
  except Exception as e:
    print(e)



def upload_from_mvm_to_podvm(tarball_file_url=DEFAULT_TARBALL_URL):
  '''Run as:
  fab -f fab_manage_tarball.py upload_from_mvm_to_podvm:'<path>' \
      -H <host1>,<host2>,<host3> -p "PASSWORD" -P -z 3
  '''
  sudo( "rm -rf %s" % REMOTE_DIR, shell=False )
  sudo( "mkdir -p %s" % REMOTE_DIR, shell=False )
  sudo( "chown -R %s:%s %s" % (BDP_USER, BDP_USER, REMOTE_DIR), shell=False )
  put( "%s" % tarball_file_url, "%s" % REMOTE_DIR )
  #put( "%s.md5" % tarball_file_url, "%s" % REMOTE_DIR )

def read_key_file(key_file):
  key_file = os.path.expanduser(key_file)
  if not key_file.endswith('pub'):
    raise RuntimeWarning('Trying to push non-public part of key pair')
  with open(key_file) as f:
    return f.read()

def push_key(key_file='~/.ssh/id_rsa.pub'):
  key_text = read_key_file(key_file)
  ssh_path='/home/paasusr/.ssh'
  sudo( "mkdir -p %s" % ssh_path, shell=False )
  sudo( "chown -R %s:%s %s" % (BDP_USER, BDP_USER, ssh_path), shell=False )
  if not contains('/home/paasusr/.ssh/authorized_keys', key_text):
    with hide('output'):
      append('/home/paasusr/.ssh/authorized_keys', key_text)

def prepare_bdp_source():
  sudo( "rm -rf %s" % REMOTE_DIR, shell=False )
  sudo( "mkdir -p %s" % REMOTE_DIR, shell=False )
  sudo( "cp -R -p %s/java %s/" % (APP_HOME, REMOTE_DIR), shell=False )
  sudo( "cp -R -p %s/Oracle %s/" % (APP_HOME, REMOTE_DIR), shell=False )
  sudo( "cp -R -p %s/oraInst %s/" % (APP_HOME, REMOTE_DIR), shell=False )
  sudo( "chown -R %s:%s %s" % (BDP_USER, BDP_USER, REMOTE_DIR), shell=False )

def prepare_hadoop_source():
  sudo( "rm -rf %s" % REMOTE_DIR)
  sudo( "mkdir -p %s" % REMOTE_DIR)
  sudo( "chown -R %s:%s %s" % (BDP_USER, BDP_USER, REMOTE_DIR), shell=False )
  sudo( "hadoop fs -get -f /odecs/paasusr/jars/* %s/" % REMOTE_DIR)
  sudo( "hadoop fs -get -f /odecs/paasusr/knowledge/* %s/" % REMOTE_DIR)
  sudo( "hadoop fs -get -f /data/* %s/" % REMOTE_DIR)
  sudo( "chown -R %s:%s %s" % (BDP_USER, BDP_USER, REMOTE_DIR), shell=False )


def rsync_vm(src_loc, target_host):
  sudo( "chown -R %s:%s %s" % (BDP_USER, BDP_USER, REMOTE_DIR ), shell=False )
  if target_host=='wls':
    cmd='rsync -az -e "ssh -i /home/sdiadmin/.ssh/id_rsa" %s  paasusr@%s:%s' %(src_loc, env.host, REMOTE_DIR )
  else:
    cmd='rsync -acvz -e "ssh -i /home/sdiadmin/.ssh/id_rsa" %s  paasusr@%s:%s' %(src_loc, env.host, REMOTE_DIR )
  os.system(cmd)


def unzip():
  '''
  fab -f fab_manage_tarball.py unzip -H <host>
  '''
  sudo( "tar -C %s -xzf %s/bdp-*.tar.gz" % (REMOTE_DIR,REMOTE_DIR), shell=False )
  sudo( "rm -rf %s/bdp-*.tar.gz" % REMOTE_DIR, shell=False )
  sudo( "chown -R paasusr:paasusr %s" % REMOTE_DIR, shell=False )
  sudo( "chmod -R 750 %s" % REMOTE_DIR, shell=False )

def backup(pod_name=POD_NAME):
  '''Run as:
  fab -f fab_manage_tarball.py unzip -H <host>
  '''
  sudo( "rm -rf %s/app.orig" % APP_HOME, shell=False )
  sudo( "rsync -a %s/* %s/app.orig/ --exclude %s/app.orig" % (APP_HOME, APP_HOME, APP_HOME), shell=False )
  sudo( "rm -rf %s/app.orig/backup" % APP_HOME, shell=False )
  sudo( "cp -R %s/cookbooks/cookbook-odecs-binaries %s/app.orig" % (DATA_HOME, APP_HOME), shell=False )
  sudo( "chown %s:%s -R %s/app.orig" % (BDP_USER, BDP_USER, APP_HOME), shell=False )
  sudo( "rm -rf %s/user_projects/domains/%s.orig" % (DATA_HOME, pod_name), shell=False )
  sudo( "mkdir -p %s/user_projects/domains/%s.orig" % (DATA_HOME, pod_name), shell=False )
  sudo( "cp -R %s/user_projects/domains/%s/* %s/user_projects/domains/%s.orig" % (DATA_HOME, pod_name, DATA_HOME, pod_name), shell=False )
  sudo( "chown %s:%s -R %s/user_projects/domains/%s.orig" % (BDP_USER, BDP_USER, DATA_HOME, pod_name), shell=False )
  sudo( "chmod -R 750 %s/user_projects/domains/%s.orig" % (DATA_HOME, pod_name), shell=False )


def hadoop_backup():
  sudo( "rm -rf %s/hadoop_backup" % DATA_HOME)
  sudo( "mkdir -p %s/hadoop_backup/jars.orig" % DATA_HOME)
  sudo( "mkdir %s/hadoop_backup/demodata.orig" % DATA_HOME)
  sudo( "mkdir %s/hadoop_backup/knowledge.orig" % DATA_HOME)
  sudo( "hadoop fs -get /odecs/paasusr/jars/* %s/hadoop_backup/jars.orig/" % DATA_HOME)
  sudo( "hadoop fs -get /odecs/paasusr/knowledge/* %s/hadoop_backup/knowledge.orig/" % DATA_HOME)
  sudo( "hadoop fs -get /data/* %s/hadoop_backup/demodata.orig/" % DATA_HOME)
  sudo( "chown -R hdfs:hdfs %s/hadoop_backup" % DATA_HOME, shell=False )
  sudo( "chmod -R 777 %s/hadoop_backup" % DATA_HOME, shell=False )


def opc_init():
  '''Run as:
  fab -f fab_manage_tarball.py opc_init  -H <host>
  '''
  with settings(warn_only=True,keepalive=30,connection_attempts=10,timeout=10,show="debug"):
        result =  sudo( "python /opt/opc-compute/opc-init.py 2>&1 | logger -t UPGRADE_LOG" )
        if result.return_code == 0:
               print "opc_init result : ",result.return_code
        else:
                print "opc_init result : ",result.return_code

def opc_init_status():
  '''Run as:
  fab -f fab_manage_tarball.py opc_init_status  -H <host>
  '''
  with settings(warn_only=True,keepalive=30,connection_attempts=10,timeout=10):
     result = run( "ps aux | grep '[p]ython /opt/opc-compute/opc-init.py'")
     if result.return_code == 0:
                print "opc_init result : ",result.return_code
     else:
                print "opc_init result : ",result.return_code


def as_kill_python_http():
  '''Run as:
  fab -f fab_manage_tarball.py as_kill_python_http  -H <host>
  '''
  with settings(warn_only=True,keepalive=30,connection_attempts=10,timeout=10):
          result = sudo( "kill $(ps aux | grep 'python /dev/shm/tmp/odecs_http_serv.py' | awk '{print $2}')" )
          if result.return_code == 0:
                print "opc_init result : ",result.return_code
          else:
                print "opc_init result : ",result.return_code


def wls_permissions():
  '''Run as:
  fab -f fab_manage_tarball.py unzip -H <host>
  '''
  sudo( "chown -R paasusr:paasusr %s" % REMOTE_DIR, shell=False )
  sudo( "chmod -R 750 %s" % REMOTE_DIR, shell=False )

def hadoop_permissions():
  '''Run as:
  fab -f fab_manage_tarball.py unzip -H <host>
  '''
  sudo( "chown -R hdfs:hdfs %s" % REMOTE_DIR, shell=False )
  sudo( "chmod -R 777 %s" % REMOTE_DIR, shell=False )

def cdh_upload(cdh_file_url=DEFAULT_CDH_URL):
  '''Run as:
  fab -f fab_manage_tarball.py cdh_upload -H <host>
  '''

  sudo( "rm -rf %s" % REMOTE_DIR, shell=False )
  sudo( "mkdir -p %s" % REMOTE_DIR, shell=False )
  sudo( "chmod -R 777 %s" % REMOTE_DIR, shell=False )
  put( "%s" % cdh_file_url, "%s" % REMOTE_DIR )
  sudo( "chown -R hdfs:hdfs %s" % REMOTE_DIR, shell=False )
  sudo( "chmod -R 777 %s" % REMOTE_DIR, shell=False )

def backup_cleanup():
  '''Run as:
  fab -f fab_manage_tarball.py cdh_upload -H <host>
  '''
  sudo( "rm -rf %s/backup/scripts/backup-daily" % DATA_HOME, shell=False )
  sudo( "rm -rf %s/backup/scripts/restore" % DATA_HOME, shell=False )
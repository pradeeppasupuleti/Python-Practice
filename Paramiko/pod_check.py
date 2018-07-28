#!/usr/bin/python
import paramiko
import sys, re, logging, argparse

parser = argparse.ArgumentParser(add_help=True)
parser.add_argument("--login")
parser.add_argument("--hosts")
parser.add_argument("--source_data")
args = parser.parse_args()

LOGIN_FILE = args.login
HOSTS_FILE = args.hosts
LOG_FILE_PATH = args.source_data

if LOGIN_FILE == None or HOSTS_FILE == None or LOG_FILE_PATH == None:
    parser.print_usage()
    sys.exit(2)

fd = open(LOG_FILE_PATH, 'w')

logging.basicConfig(filename="pod_check_activity.log", level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')

login_file=open(LOGIN_FILE,'r')
hosts_file=open(HOSTS_FILE, 'r')

#Collecting credentials form the file
for line in login_file.readlines():
        up=line.strip().split(':')
        user=up[0]
        passwd=up[1]
        a_server=up[2]
        
# Reading hosts from the file
hlist = [line for line in hosts_file.readlines()]

ssh_dir = '/root/.ssh/'
ssh_setup_dir= '/root/.ssh_setup/'
bda_path = '/opt/oracle/bda/cloud/'

source_conf = []
source_md5 =[]
source_nfs = []
ref_rsa_pub = ""
ref_rsa = ""
sdr_stat = ""

#Colleting source data from given node to compare with individual nodes
def get_sourcedata(server1, username, password):
    global source_conf
    global source_md5
    global source_nfs
    if LOGIN_FILE:
        try:
            logging.info('---------------------------------------------------------------------------------------------------------')
            logging.info('Connecting to the host ' + str(server1) + ' to get the information')
            logging.info('---------------------------------------------------------------------------------------------------------')
            try:
                ssh = paramiko.SSHClient()
                ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
                ssh.connect(hostname=server1, port=22, username=user, password=passwd)
                try:
                    logging.info('Collecting ssh_config file content on ' + str(server1))
                    stdin, stdout, stderr=ssh.exec_command("cat "+ str(ssh_dir)+ "/config")
                    con_output=stdout.readlines()
                    source_conf.append(con_output)
                    logging.info('Collecting md5sum value for id_rsa  files on  ' + str(server1))
                    stdin, stdout, stderr=ssh.exec_command("md5sum "+ str(ssh_setup_dir)+ "id_rsa.pub " + str(ssh_setup_dir)+ "id_rsa" )
                    md5_output=stdout.readlines()
                    source_md5.append(md5_output)
                    stdin, stdout, stderr=ssh.exec_command('for i in `ifconfig | grep inet | grep -v "127.0.0.1" | cut -d: -f2 | cut -d" " -f1 | cut -d"." -f1-3`; do mount | grep $i ; done')
                    nfs_output=stdout.readlines()
                    source_nfs.append(nfs_output)
                    ssh.close()
                except Exception as amsg:
                    logging.error("Exception occured while execute commands ->" + str(amsg))
            except Exception as emsg:
                logging.error("Exception -> " + str(emsg))
        except Exception as k:
                    logging.critical("exception occurred - {0}".format(k))
                    sys.exit()
        else:
            logging.info("Execution format -> # python v4.py --login=login.txt --hosts=hosts.txt --log_file=<value>")
            logging.info("Exiting the script input file format is not correct...")
            sys.exit()
        
#Define varibles for id_rsa.pub and id_rsa for source data    
def prepare_reference_data():
    global ref_rsa_pub, ref_rsa
    for line in source_md5[0]:
        line = line.strip()
        if line.endswith("id_rsa.pub"):
            ref_rsa_pub = line.split()[0]
        elif line.endswith("id_rsa"):
            ref_rsa = line.split()[0]
        else:
            logging.error("Unexpected ouptut found - " + str(line))

#Collecting data from individual node
def get_nodedata(server, username, password):
    global sdr_stat
    try:
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(hostname=server, port=22, username=user, password=passwd)
        try:
            stdin, stdout, stderr=ssh.exec_command("cat "+ str(ssh_dir)+ "/config")
            con_output=stdout.readlines()
            conf_list.append(con_output)
            stdin, stdout, stderr=ssh.exec_command("md5sum "+ str(ssh_setup_dir)+ "id_rsa.pub " + str(ssh_setup_dir)+ "id_rsa" )
            md5_output=stdout.readlines()
            md5_list.append(md5_output)
            sftp = ssh.open_sftp()
            try:
                sftp.stat(str(bda_path) + "SKIP_DATA_RETENTION")
                sdr_stat = True
#                 print(sdr_stat)
            except Exception as s_msg:
                logging.error("Exception occured for SKIP_DATA_RETENTION " + str(s_msg))
                sdr_stat = False
            stdin, stdout, stderr=ssh.exec_command('for i in `ifconfig | grep inet | grep -v "127.0.0.1" | cut -d: -f2 | cut -d" " -f1 | cut -d"." -f1-3`; do mount | grep $i ; done')
            nfs_output=stdout.readlines()
            nfs_list.append(nfs_output)
            
            ssh.close()
        except Exception as amsg:
            logging.error("Exception occured while execting commands ->" + str(amsg))
    except Exception as emsg:
        logging.error("Exception -> " + str(emsg))

#ssh config files content check 
def compare_ssh_config(server):
    for conf in source_conf:
        check_key = True
        if conf not in conf_list:
            check_key = True
        if not check_key:
            logging.critical(str(conf) + "is missing in " + str(server))
        else:
            logging.info("ssh config file contains all the lines")

#md5sum check for id_rsa.pub and id_rsa files            
def compare_rsa_md5(server):
    node_rsa_pub = ""
    node_rsa = ""
    for line in md5_list[0]:
        line = line.strip()
        if line.endswith("id_rsa.pub"):
            node_rsa_pub = line.split()[0]
        elif line.endswith("id_rsa"):
            node_rsa = line.split()[0]
        else:
            print("Unexpected ouptut found - " + str(line))
    if ref_rsa_pub != node_rsa_pub:
        logging.critical("id_rsa.pub file is mismatched.")
    else:
        logging.info("id_rsa.pub file matched.")
        
    if ref_rsa != node_rsa:
        logging.critical("id_rsa file is mismatched.")
    else:
        logging.info("id_rsa file matched.")

#Skip data retention check         
def sdr_check(server):
    if sdr_stat:
        logging.info("SKIP_DATA_RETENTION file exists.")
    else:
        logging.error("SKIP_DATA_RETENTION file was missing.")

def nfs_mount_check(server):
#     print(source_nfs)
    for file in source_nfs[0]:
        check_nfs = True
        if file not in nfs_list[0]:
            check_nfs = False
        if not check_nfs:
            logging.critical(str(file) + "is missing on " + str(server))
        else:
            logging.info("All nfs mount points are exists.")
            
    
# executing main script
if __name__ == '__main__':
    get_sourcedata(a_server, user, passwd)
    prepare_reference_data()
    fd.write("+++++++ Source ssh config file ++++++++")
    fd.write(source_conf)
    fd.write("+++++++ Source md5sum  ++++++++")
    fd.write(source_md5)
    fd.write("+++++++ Source nfs mount points  ++++++++")
    fd.write(source_nfs)
    for server in hlist:
        server = server.strip()
        conf_list = []
        md5_list = []
        nfs_list = []
        logging.info('---------------------------------------------------------------------------------------------------------')
        logging.info('Connecting to the host' + str(server) + ' and comparing data with ' + str(a_server))
        logging.info('----------------------------------------------------------------------------------------------------------')
        get_nodedata(server, user, passwd)
        compare_ssh_config(server)
        compare_rsa_md5(server)
        sdr_check(server)
        nfs_mount_check(server)
        logging.info('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++')

print("Please check the pod_check_activity.log for status........")
        


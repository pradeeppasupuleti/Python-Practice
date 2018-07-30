#!/usr/bin/python
import paramiko
import sys, re, logging, argparse, json

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

logging.basicConfig(filename="pod_check_activity.log", level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')

login_file=open(LOGIN_FILE,'r')
hosts_file=open(HOSTS_FILE, 'r')

fd = open(LOG_FILE_PATH, 'w')
#Collecting credentials form the file
for line in login_file.readlines():
        up=line.strip().split(':')
        user=up[0]
        passwd=up[1]
        a_server=up[2]
        
# Reading hosts from the file
hlist = [line for line in hosts_file.readlines()]

#Defined varibles
ssh_dir = '/root/.ssh/'
ssh_setup_dir= '/root/.ssh_setup/'
bda_path = '/opt/kjfkafkafkdfa/bda/'
bdcs_path = '/home/bdcsadm/.ssh/'
nic_cmd = 'for i in `ifconfig | grep inet | grep -v "127.0.0.1" | cut -d: -f2 | cut -d" " -f1 | cut -d"." -f1-3`; do mount | grep $i ; done'

source_conf = []
source_md5 =[]
source_nfs = []
node_authkey_list = []
node_count = 0
source_json = ""
ref_rsa_pub = ""
ref_rsa = ""
source_md5_auth = ""
sdr_stat = ""
free_node = ""
node_pub = ""


#Colleting source data from given node to compare with individual nodes
def get_sourcedata(server1, username, password):
    global source_conf
    global source_md5
    global source_md5_auth
    global source_nfs
    global source_json
    if LOGIN_FILE:
        try:
            logging.info('---------------------------------------------------------------------------------------------------------')
            logging.info('Connecting to the host ' + str(server1) + ' to get the information')
            logging.info('---------------------------------------------------------------------------------------------------------')
            try:
                ssh = paramiko.SSHClient()
                ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
                ssh.connect(hostname=server1, port=22, username=user, password=passwd)
            except Exception as emsg:
                logging.error("Exception -> " + str(emsg) + "on " + str(server1))
            try:
                logging.info('Collecting ssh_config file content on ' + str(server1))
                stdin, stdout, stderr=ssh.exec_command("cat "+ str(ssh_dir)+ "/config")
                con_output=stdout.readlines()
                source_conf.append(con_output)
                logging.info('Collecting md5sum value for id_rsa  files on  ' + str(server1))
                stdin, stdout, stderr=ssh.exec_command("md5sum "+ str(ssh_setup_dir)+ "id_rsa.pub " + str(ssh_setup_dir)+ "id_rsa" )
                md5_output=stdout.readlines()
                source_md5.append(md5_output)
                stdin, stdout, stderr=ssh.exec_command('md5sum '+ str(bdcs_path)+ 'authorized_keys | cut -d" " -f1')
                md5_auth_output=stdout.read()
                source_md5_auth = md5_auth_output.strip()
                print(source_md5_auth)
                print(type(source_md5_auth))
                logging.info('Collecting nfs mountpoints on ' + str(server1))
                stdin, stdout, stderr=ssh.exec_command(str(nic_cmd))
                nfs_output=stdout.readlines()
                source_nfs.append(nfs_output)
                logging.info('Collecting network json data from ' + str(server1))
                stdin, stdout, stderr=ssh.exec_command("cat " + str(bda_path) + "network.json")
                source_json = stdout.read()
#                 source_json = json.loads(source_json)
                ssh.close()
                return source_conf, source_md5, source_nfs, source_json, source_md5_auth
            except Exception as amsg:
                logging.error("Exception occured while execute commands ->" + str(amsg) + "on " + str(server1))

        except Exception as k:
                    logging.critical("exception occurred - {0}".format(k))
                    sys.exit()
    else:
        logging.info("Execution format -> # python r3.py --login=login_file --hosts=hostfile --source_data=source_file")
        logging.info("Exiting the script input file format is not correct...")
        sys.exit()
 
#Collecting the netwrok.json file from the 1st node of the rack 
def get_json(server, username, password):
    global source_json
    print("Collecting new json data form " + str(server))
    try:
        logging.info('---------------------------------------------------------------------------------------------------------')
        logging.info('Connecting to the host ' + str(server) + 'to get newtwork json file.')
        logging.info('---------------------------------------------------------------------------------------------------------')
        try:
            ssh = paramiko.SSHClient()
            ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
            ssh.connect(hostname=server, port=22, username=user, password=passwd)
        except Exception as emsg:
            logging.error("Exception -> " + str(emsg) + "on " + str(server))
        try:
            logging.info('Collecting network json data from ' + str(server))
            stdin, stdout, stderr=ssh.exec_command("cat " + str(bda_path) + "network.json")
            source_json = stdout.read()
            ssh.close()
            return source_json
        except Exception as amsg:
            logging.error("Exception occured while execute commands ->" + str(amsg) + "on " + str(server))
    
    except Exception as k:
        logging.critical("exception occurred - {0}".format(k))
        sys.exit()
        
#Define variables for id_rsa.pub and id_rsa for source data    
def prepare_reference_data():
    global ref_rsa_pub, ref_rsa
    for line in source_md5[0]:
        line = line.strip()
        if line.endswith("id_rsa.pub"):
            ref_rsa_pub = line.split()[0]
        elif line.endswith("id_rsa"):
            ref_rsa = line.split()[0]
        else:
            logging.error("Unexpected ouptut found - " + str(line) + "on " + str(server))
            

#Collecting data from individual node
def get_nodedata(server, username, password):
    global sdr_stat
    global free_node
    global node_pub
    global node_authkey
    global node_authkey_list
    global node_md5_auth
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
            stdin, stdout, stderr=ssh.exec_command('md5sum '+ str(bdcs_path)+ 'authorized_keys | cut -d" " -f1')
            md5_auth_output=stdout.read()
            node_md5_auth = md5_auth_output.strip()
            print(node_md5_auth)
            print(type(node_md5_auth))
            sftp = ssh.open_sftp()
            try:
                sftp.stat(str(bda_path) + "/cloud/SKIP_DATA_RETENTION")
                sdr_stat = True
#                 print(sdr_stat)
            except Exception as s_msg:
                logging.error("Exception occured for SKIP_DATA_RETENTION " + str(s_msg) + "on " + str(server))
                sdr_stat = False
            stdin, stdout, stderr=ssh.exec_command(str(nic_cmd))
            nfs_output=stdout.readlines()
            nfs_list.append(nfs_output)
            stdin, stdout, stderr=ssh.exec_command("cat " + str(bda_path) + "network.json")
            node_json = stdout.read()
            stdin, stdout, stderr=ssh.exec_command("cat " + str(ssh_setup_dir) + "/id_rsa.pub")
            node_pub = stdout.read()
            stdin, stdout, stderr=ssh.exec_command("cat " + str(ssh_dir) + "/authorized_keys")
            node_authkey = stdout.read()
            node_authkey_list.append(node_authkey)
#             print(node_authkey_list)
#             print(type(node_authkey_list))
#             print(len(node_authkey_list))
            stdin, stdout, stderr=ssh.exec_command('cat ' + str(bda_path) + '/cloud/bdacloudcli_STATE')
            free_node=stdout.read()
            ssh.close()
            return conf_list, md5_list, sdr_stat, nfs_list, node_json, free_node, node_authkey, node_pub, node_authkey_list, node_md5_auth
        
        except Exception as amsg:
            logging.error("Exception occured while execting commands ->" + str(amsg) + "on " + str(server))
    except Exception as emsg:
        logging.error("Exception -> " + str(emsg) + "on " + str(server))

#ssh config files content check 
def compare_ssh_config(server, source_conf, conf_list):
    for conf in source_conf:
        check_key = True
        if conf not in conf_list:
            check_key = True
        if not check_key:
            logging.critical(str(conf) + "is missing in " + str(server))
        else:
            logging.info("ssh config file contains all the lines on node " + str(server) )

#md5sum check for id_rsa.pub and id_rsa files            
def compare_rsa_md5(server, source_md5, md5_list):
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

def check_md5_auth(server, node_md5_auth, source_md5_auth):
    if node_md5_auth == source_md5_auth:
        logging.info("md5sum is matched for authorzied key of bdcsadm for" + str(server)) 
    else:
        logging.error("md5sum is not matched for authorzied key of bdcsadm for" + str(server))
        

#Skip data retention check         
def sdr_check(server, sdr_stat):
    if sdr_stat:
        logging.info("SKIP_DATA_RETENTION file exists on" + str(server))
    else:
        logging.error("SKIP_DATA_RETENTION file was missing on " + str(server))

#Comparing source nfs mount points with inidividual node mount points 
def nfs_mount_check(server, source_nfs, nfs_list):
    for file in source_nfs[0]:
        check_nfs = True
        if file not in nfs_list[0]:
            check_nfs = False
        if not check_nfs:
            logging.critical(str(file) + "is missing on " + str(server))
        else:
            logging.info("All nfs mount points are exist on " + str(server))

#Comparing the source json file with the individual node of the rack            
def json_compare(server, source_json, node_json):
    if source_json and node_json:
        source_json = json.loads(source_json)
        node_json = json.loads(node_json)
#         json_key = False
        if sorted(source_json.items()) == sorted(node_json.items()):
            logging.info("network json file is matched with the source file on " + str(server))
        else:
            logging.error("network json file is mismathced on " + str(server))
            
#Checking id_rsa.pub file in autrozied keys based on bdacli_STATE outpu
def node_deprovision( server, free_node, node_authkey_list):
    if str(free_node) in ["deploy_segment SUCCEEDED", "deprovision_cluster_vms SUCCEEDED"]:
        logging.info("bdacli_state for " + str(server) + " is " + str(free_node))
        if str(node_pub) in node_authkey_list[0]:
            logging.info("id_rsa.pub key was exist in authorized keys for the node " + str(server)  + ".")
        else:
            logging.error("id_rsa.pub key not exist  in authorized keys for " + str(server))
    else:
        logging.info("bdacli_STATE is not deploy_segment SUCCEEDED/deprovision_cluster_vms SUCCEEDED for " + str(server) + ".")

# executing main script
if __name__ == '__main__':
    source_conf, source_md5, source_nfs, source_json, source_md5_auth = get_sourcedata(a_server, user, passwd)
    prepare_reference_data()
    fd.write("+++++++ Source ssh config file ++++++++" "\n")
    fd.write("".join(source_conf[0]))
    fd.write("+++++++ Source md5sum  ++++++++" + "\n")
    fd.write("".join(source_md5[0]))
    fd.write("+++++++ Source nfs mount points  ++++++++" "\n")
    fd.write("".join(source_nfs[0]))
    fd.close()
    
    for server in hlist:
        server = server.strip()
        conf_list = []
        md5_list = []
        md5_list_auth = []
        nfs_list = []
        node_authkey_list = []
#         node_md5_auth = ""
        node_count += 1
        
        if node_count == 19:
            node_count = 0
            source_josn = get_json(server, user, passwd)
            
        node_json = ""
        logging.info('---------------------------------------------------------------------------------------------------------')
        logging.info('Connecting to the host ' + str(server) + ' and comparing data with ' + str(a_server))
        logging.info('----------------------------------------------------------------------------------------------------------')
        conf_list, md5_list, sdr_stat, nfs_list, node_json, free_node, node_pub, node_authkey, node_authkey_list, node_md5_auth = get_nodedata(server, user, passwd)
        compare_ssh_config(server, source_conf, conf_list)
        compare_rsa_md5(server, source_md5, md5_list)
        sdr_check(server, sdr_stat)
        nfs_mount_check(server, source_nfs, nfs_list)
        json_compare(server, source_json, node_json)
        node_deprovision( server, free_node, node_authkey_list)
        check_md5_auth(server, node_md5_auth, source_md5_auth)
        logging.info('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++')

print("Please check the pod_check_activity.log for status........")

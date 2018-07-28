#!/usr/bin/python
import paramiko
import sys, logging

logging.basicConfig(filename="user_list.log", level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')

login_file=open('login.txt','r')
hosts_file=open('hosts.txt', 'r')

#Collecting credentials form the file
for line in login_file.readlines():
        up=line.strip().split(':')
        user=up[0]
        passwd=up[1]
        u_password=up[2]

hlist = [line for line in hosts_file.readlines()]

def create_user(server,user,passwd):
    try:
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(hostname=server, port=22, username=user, password=passwd)
    except Exception as emsg:
        logging.error("Exception -> " + str(emsg) + "on " + str(server))
    try:
        logging.info("----------------------------------------------------------------")
        logging.info('listing user in  ' + str(server))
        logging.info("----------------------------------------------------------------")
        stdin, stdout, stderr=ssh.exec_command("show /SP/users")
        usr_p_output=stdout.read()
        logging.info(str(usr_p_output))
        logging.info("----------------------------------------------------------------")
        #stdin, stdout, stderr=ssh.exec_command("create /SP/users/ilom-em-admin password="+ str(u_password) + " role=cro")
        if ilom-em-admin not in str(usr_p_output):
        stdin, stdout, stderr=ssh.exec_command("create /SP/users/ilom-em-admin password="+ str(u_password))
        c_output=stdout.read()
        logging.info(str(c_output))
        logging.info("----------------------------------------------------------------")
        stdin, stdout, stderr=ssh.exec_command("set /SP/users/ilom-em-admin role=cro")
        r_output=stdout.readline()
        logging.info(str(r_output))
        logging.info("----------------------------------------------------------------")
        stdin, stdout, stderr=ssh.exec_command("show /SP/users/ilom-em-admin")
        usr_a_output=stdout.read()
        logging.info(str(usr_a_output))
        logging.info("====================================================================================")
        ssh.close()
    except Exception as amsg:
        logging.error("Exception -> " + str(amsg) + "on " + str(server))


if __name__ == '__main__':
    for server in hlist:
        server = server.strip()
        create_user(server,user,passwd)

#!/usr/bin/python
import paramiko
import sys, logging

login_file=open('login.txt','r')
hosts_file=open('hosts.txt.bkp', 'r')

#Collecting credentials form the file
for line in login_file.readlines():
        up=line.strip().split(':')
        user=up[0]
        passwd=up[1]

hlist = [line for line in hosts_file.readlines()]

def update_time(server,user,passwd):
    try:
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(hostname=server, port=22, username=user, password=passwd)
    except Exception as emsg:
        logging.error("Exception -> " + str(emsg) + "on " + str(server))
    try:
        logging.info("----------------------------------------------------------------")
        logging.info('updating timestamp on   ' + str(server))
        logging.info("----------------------------------------------------------------")
        stdin, stdout, stderr=ssh.exec_command("touch /mnt/bundles/ol5/BDABaseImageOVM-ol5-4.9.5-171204.zip")
        stdin, stdout, stderr=ssh.exec_command("ls -ltrh /mnt/bundles/ol5/BDABaseImageOVM-ol5-4.9.5-171204.zip")
        usr_p_output=stdout.read()
        print(usr_p_output)
    except Exception as amsg:
        logging.error("Exception -> " + str(amsg) + "on " + str(server))


if __name__ == '__main__':
    for server in hlist:
        server = server.strip()
        create_user(server,user,passwd)

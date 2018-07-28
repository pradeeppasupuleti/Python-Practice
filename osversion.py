#!/usr/bin/python
import subprocess

def get_os_version():
    p_cmd="""cat /etc/redhat-release"""
    p=subprocess.Popen(p_cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    p_os=p.stdout.read()
    os_version= p_os.split("(") [1] [:-2]
    return os_version

def get_uptime():
    p_cmd="""uptime"""
    p=subprocess.Popen(p_cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    p_uptime=p.stdout.read()
    uptime= p_uptime.split() [0]
    return uptime

os_version = get_os_version()
uptime = get_uptime()

print("Os version is " + "'" + str(os_version)+ "'")
print("Sytem uptime is " + str(uptime))

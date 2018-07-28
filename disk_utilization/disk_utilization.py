#!/usr/bin/python
import smtplib
import subprocess
from subprocess import Popen
# Here are the email package modules we'll need
from email.mime.image import MIMEImage
from email.mime.multipart import MIMEMultipart
from email.MIMEText import MIMEText


from_addr = 'mr.pradeep666@gmail.com'
to_addr = 'pradeeprhce23@gmail.com'


def disk_ut():
    #Disk utilization command
    df = """df -h"""
    df_cmd= subprocess.Popen(df, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    df_cmd=df_cmd.stdout.readlines()
    msg_format = ''
    for use in df_cmd:
        msg_format += use
    return msg_format

msg_format = disk_ut()

# me == the sender's email address
# you == the recipient's email address

try:
    s = smtplib.SMTP()
    s.connect()
    msg = MIMEMultipart()
    msg['Subject'] = 'Test mail from Machine'
    msg['From'] = from_addr
    msg['To'] = to_addr
    disk = MIMEText(msg_format)
    msg.attach(disk)
    s.sendmail(from_addr, to_addr, msg.as_string())
    s.quit()
except Exception as s_msg:
    print(s_msg)

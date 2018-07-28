#!/usr/bin/python
import smtplib
import subprocess, socket
from subprocess import Popen
# Here are the email package modules we'll need
from email.mime.image import MIMEImage
from email.mime.multipart import MIMEMultipart
from email.MIMEText import MIMEText

#Mail variables
from_addr = 'mr.pradeep666@gmail.com'
to_addr = ['pradeeprhce23@gmail.com','pradeep.pasupuleti@oracle.com']

def disk_ut():
    #Disk utilization command
    df = """df -h"""
    df_cmd= subprocess.Popen(df, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    df_cmd=df_cmd.stdout.readlines()
    msg = ''
    for usage in df_cmd:
                usage = usage.strip().split()
                if len(usage) <= 6 and int(usage[4].split('%')[0]) >= 10:
                        msg += '<tr><td>' + usage[0] + '</td><td>' + usage[1] + '</td><td>' + usage[2] + '</td><td>' + usage[3] + '</td><td>'
                        msg += usage[4] + '</td><td>' + usage[5] + '</td></tr>'
    return msg

def final():
    content = disk_ut()
    msg_header= '<tr><th>Filesystem</th><th>Size</th><th>Used</th><th>Avail</th><th>Use%</th><th>Mounted on</th></tr>'
    table_start = '<table border=1 cellpadding=1 cellspacing=1>'
    table_end = '</table>'

    host_name = socket.gethostname()
    msg_format = '<th> Disk utilization Report of the host ' + host_name + '}</th>'
    msg_format += table_start
    msg_format += msg_header
    msg_format += content
    msg_format += table_end

    s = smtplib.SMTP()
    s.connect()
    msg = MIMEMultipart()
    msg['Subject'] = 'Disk utilization report'
    msg['From'] = from_addr
    msg['To'] = ", ".join(to_addr)
    part2 = MIMEText(msg_format, 'html')
    msg.attach(part2)
    s.sendmail(from_addr, to_addr, msg.as_string())
    s.quit()

if __name__ == '__main__':
    final()

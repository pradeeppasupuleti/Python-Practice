#!/usr/bin/python
import smtplib
from email.mime.text import MIMEText
from email.mime.application import MIMEApplication
from email.mime.multipart import MIMEMultipart
from smtplib import SMTP
import smtplib
import sys



msg = MIMEMultipart()
msg['Subject'] = 'Your Airtel Mobile Bill for 8790626662 for 24/2/2018 is ready to view'
msg['From'] = 'ebill@airtel.com'

from_addr = 'ebill@airtel.com'
to_addr = 'mr.pradeep666@gmail.com'

msg.preamble = 'Multipart massage.\n'

part = MIMEText(open('bill.html',"r").read(),'html')
msg.attach(part)

part = MIMEApplication(open('MobileBill_1261997661.pdf',"rb").read())
part.add_header('Content-Disposition', 'attachment', filename='MobileBill_1261997661.pdf')
msg.attach(part)


s = smtplib.SMTP()
s.connect()
s.sendmail(from_addr, to_addr, msg.as_string())
s.quit()

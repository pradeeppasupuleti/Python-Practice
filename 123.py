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

fobj = open('bill.html')
	templete
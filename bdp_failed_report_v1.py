import smtplib
import MimeWriter
import mimetools
from email.MIMEMultipart import MIMEMultipart
from email.MIMEText import MIMEText

import logging
import os
import subprocess
import re
from datetime import datetime, timedelta

def failed_info(from_date, to_date):
        p_cmd = """/u01/app/oracle/product/fmw/Oracle_SDI2/sdictl/sdictl.sh listrq -filter -last_update '"""+ from_date+'|'+to_date+ """ ' -service_type '%DataEnrichment%' """
        p = subprocess.Popen(p_cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        p = p.stdout.readlines()

        cim_pattern = r'CIM\w+#\w+'
        cim_regex = re.compile(cim_pattern, flags=re.IGNORECASE)

        state_pattern = r'COMPLETED'
        state_regex = re.compile(state_pattern, flags=re.IGNORECASE)

        task_pattern = r'SUCCESS|CreateSftpAccountAsyncTask'
        task_regex = re.compile(task_pattern, flags=re.IGNORECASE)

        connect_pattern = r'ConnectingtotheSDIControlServiceendpoint'
        connect_regex = re.compile(connect_pattern, flags=re.IGNORECASE)

        trace_pattern = r'TaskName'
        trace_regex = re.compile(trace_pattern, flags=re.IGNORECASE)

        service_pattern = r'DataEnrichment'
        service_regex = re.compile(service_pattern, flags=re.IGNORECASE)
        msg = ''

        for i in p:
                i = re.sub('-----*','',i)
                cim_match = cim_regex.search(i)
                state_match = state_regex.search(i)
                service_match = service_regex.search(i)
                if cim_match and not re.search(r"COMPLETED", i):
                        logger.info('checking '+ cim_match.group())
                        msg += '<tr><td colspan=5 align="center" valign="middle">' + cim_match.group() + '</td></tr>'
                        sp_cmd = """/u01/app/oracle/product/fmw/Oracle_SDI2/sdictl/sdictl.sh gt -id """ + cim_match.group()
                        sp = subprocess.Popen(sp_cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
                        sp = sp.stdout.readlines()
                        for si in sp:
                                si = re.sub('-----*','',si)
                                si_1 = re.sub(' ','',''.join(si.splitlines()))
                                connect_match = connect_regex.search(si_1)
                                trace_match = trace_regex.search(si_1)
                                task_match = task_regex.search(si_1)
                                if not connect_match and not trace_match:
                                        formatter = re.sub('TraceLogof' + str(cim_match.group()),'',si_1)
                                        #if re.search(r"DataEnrichment",formatter) and not re.search(r"SKIP_AUTO",formatter):
                                        if re.search(r"PAUSED", formatter) or  re.search(r"FAILED",formatter) or re.search(r"INCOMPLETE",formatter):
                                                msg_list = formatter.split('|')
                                                msg += '<tr><td>' + msg_list[0] + '</td><td>' + msg_list[1] + '</td><td>' + msg_list[2] + '</td><td>'
                                                msg += msg_list[3] + '</td><td>' + msg_list[4] + '</td></tr>'
        return msg

def main():

    number_of_days_to_use = 7
    back_date = datetime.now() - timedelta(days=number_of_days_to_use)
    from_date = back_date.strftime ("%m/%d/%y")
    to_date_format = datetime.now() + timedelta(days=1)
    to_date = to_date_format.strftime ("%m/%d/%y")

    logger.info('running bdp failed report for' + from_date + ' and ' + to_date)
    from_addr = 'bdsrvs_ww_grp@oracle.com'
    #to_addr = ['naveen.dosapati@oracle.com','naveen.dosapati@oracle.com']
    to_addr = ['naveen.dosapati@oracle.com','ritesh.majumdar@oracle.com']

    content  = failed_info(from_date, to_date)

    msg_header= '<tr><th>Task Name</th><th>Status</th><th>Trace Error (short)</th><th> Trace Time</th><th> Duplicate status count</th></tr>'
    table_start = '<table border=1 cellpadding=1 cellspacing=1>'
    table_end = '</table>'

    msg_format = table_start
    msg_format += msg_header
    msg_format += content
    msg_format += table_end

    dc_cmd = """/u01/app/oracle/product/fmw/Oracle_SDI2/sdictl/sdictl.sh config -get datacenter.shortname | awk 'NR > 3 { print }'"""
    dc_res = subprocess.Popen(dc_cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    dc_name = dc_res.stdout.readlines()[0]
    dc_name = dc_name.strip('\n')

    logger.info('DC [ ' + dc_name + ' ] : running bdp failed report for' + from_date + ' and ' + to_date)
    if not content:
        logger.info('No BDP pod failed info found')
    else:
        s = smtplib.SMTP()
        msg = MIMEMultipart('alternative')
        msg['Subject'] = 'DC [ ' + dc_name + ' ] BDP POD STATUS AUTORUN FOR '+ from_date + ' - ' + to_date
        msg['From'] = from_addr
        msg['To'] = ", ".join(to_addr)
        part2 = MIMEText(msg_format, 'html')
        msg.attach(part2)
        s.connect()
        s.sendmail(from_addr, to_addr, msg.as_string())
        s.quit()

if __name__ == '__main__':

    logger = logging.getLogger('bdp pod tracker')
    logger.setLevel(logging.INFO)

    fh = logging.FileHandler('bdp_pod_failed.log')
    fh.setLevel(logging.INFO)

    formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    fh.setFormatter(formatter)
    logger.addHandler(fh)
    logger.info('BDP Tracker begins ...')
    main()
    logger.info('BDP Tracker ends ...')

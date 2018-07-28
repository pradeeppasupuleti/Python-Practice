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
        p_cmd = """/u01/app/oracle/product/fmw/Oracle_SDI2/sdictl/sdictl.sh listrq -filter -last_update '"""+ from_date+'|'+to_date+ """'"""
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
                if cim_match and re.search(r"DataEnrichment",i) and not state_match:
                #if cim_match and not state_match:
                        logger.info('checking '+ cim_match.group())
                        msg += '<h3>--------' + cim_match.group()+'</h3>\n'
                        msg += '<h4>Task Name| Status| Trace Error (short)| Trace Time| Duplicate status count'+'</h4>\n'
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
                                        if re.search(r"DataEnrichment",formatter) and not re.search(r"SKIP_AUTO",formatter):
                                                msg += formatter+'\n'
        return msg

def main():
        number_of_days_to_use = 15
        back_date = datetime.now() - timedelta(days=number_of_days_to_use)
        from_date = back_date.strftime ("%m/%d/%y")
        to_date = datetime.now().strftime ("%m/%d/%y")

        from_addr = 'naveen.dosapati@oracle.com'
        to_addr = 'naveen.dosapati@oracle.com' #TODO
        #to_addr = 'naveen.dosapati@oracle.com,ritesh.majumdar@oracle.com,naveen.kumar.vaddepally@oracle.com'
        content  = failed_info(from_date, to_date)
        if not content:
                content = 'No BDP pod failed info found'
        s = smtplib.SMTP()
        msg = MIMEMultipart('alternative')
        msg['Subject'] = 'BDP POD STATUS AUTORUN FOR '+ from_date + ' - ' + to_date
        msg['From'] = from_addr
        msg['To'] = to_addr
        part2 = MIMEText(content, 'html')
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

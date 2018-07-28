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

def get_active_sdi():
    p_cmd = """grep '^alias sdictl=' /home/appinfra/.bash_profile"""
    p = subprocess.Popen(p_cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    p_path = p.stdout.read().rstrip()
    active_sdi = p_path.split('=')[1][1:-1]
    return active_sdi

def get_cim_ids(from_date, to_date, sdi):
    p_cmd = sdi + """ listrq -filter -last_update '"""+ from_date+'|'+to_date+ """ ' -service_type '%DataEnrichment%' """
    p = subprocess.Popen(p_cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    p = p.stdout.readlines()

    cim_pattern = r'CIM\w+#\w+'
    cim_regex = re.compile(cim_pattern, flags=re.IGNORECASE)
    cim_ids = []
    for i in p:
        cim_match = cim_regex.search(i)
        if cim_match and not re.search(r"COMPLETED", i):
            cim_ids.append(cim_match.group())

    return cim_ids


def get_failed_info(cim_id, sdi):

    cancel_cmd = sdi + """ gt -id CANCEL_""" + cim_id
    cancel_query = subprocess.Popen(cancel_cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    cancel_data = cancel_query.stdout.read()

    if re.search(r"FAILED to get trace log of", cancel_data):
        cim_id = cim_id
    else:
        cim_id = "CANCEL_" + cim_id

    sp_cmd = sdi + """ gt -id """ + cim_id
    sp = subprocess.Popen(sp_cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    sp = sp.stdout.readlines()

    connect_pattern = r'ConnectingtotheSDIControlServiceendpoint'
    connect_regex = re.compile(connect_pattern, flags=re.IGNORECASE)

    trace_pattern = r'TaskName'
    trace_regex = re.compile(trace_pattern, flags=re.IGNORECASE)
    msg_list = []

    for si in sp:
        si = re.sub('-----*','',si)
        si_1 = re.sub(' ','',''.join(si.splitlines()))
        connect_match = connect_regex.search(si_1)
        trace_match = trace_regex.search(si_1)
        if not connect_match and not trace_match:
            formatter = re.sub('TraceLogof' + cim_id,'',si_1)
            failed_list = formatter.split('|')
            if msg_list:
                for x,y in enumerate(msg_list):
                    if cim_id in y and failed_list[0] in y:
                        del msg_list[x]

            if re.search(r"PAUSED", formatter) or  re.search(r"FAILED",formatter) or re.search(r"INCOMPLETE",formatter):
                failed_list.append(cim_id)
                msg_list.append(failed_list)
    return msg_list


def main(sdi):
    number_of_days_to_use = 15
    back_date = datetime.now() - timedelta(days=number_of_days_to_use)
    from_date = back_date.strftime ("%m/%d/%y")
    to_date_format = datetime.now() + timedelta(days=1)
    to_date = to_date_format.strftime ("%m/%d/%y")
    cim_ids = get_cim_ids(from_date, to_date, sdi)
    msg_list = []
    for cim_id in list(set(cim_ids)):
        msg_data = get_failed_info(cim_id, sdi)
        if msg_data:
            msg_list.append(msg_data)

    logger.info('running bdp failed report for' + from_date + ' and ' + to_date)
    from_addr = 'bdsrvs_ww_grp@oracle.com'
    #to_addr = ['naveen.dosapati@oracle.com','']
    to_addr = ['bdsrvs_ww_grp@oracle.com','']

    table_data = ''
    for i in msg_list:
        if i:
            table_data += '<tr><th>' + i[0][6] + '</th></tr>'
            for j in i:
                table_data += '<tr><td>'+ j[0]+'</td><td>'+ j[1]+'</td><td>'+ j[2]+'</td><td>'+ j[3]+'</td><td>'+ j[4]+'</td></tr>'

    msg_header= '<tr><th>Task Name</th><th>Status</th><th>Trace Error (short)</th><th> Trace Time</th><th> Duplicate status count</th></tr>'
    table_start = '<table border=1 cellpadding=1 cellspacing=1>'
    table_end = '</table>'

    msg_format = table_start
    msg_format += msg_header
    msg_format += table_data
    msg_format += table_end

    dc_cmd = sdi + """ config -get datacenter.shortname | awk 'NR > 3 { print }'"""
    dc_res = subprocess.Popen(dc_cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    dc_name = dc_res.stdout.readlines()[0]
    dc_name = dc_name.strip('\n')

    if not msg_list:
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
    active_sdi = get_active_sdi()
    main(active_sdi)
    logger.info('BDP Tracker ends ...')
    logger.info('-------------------------------')

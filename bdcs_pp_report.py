import smtplib
from email.MIMEMultipart import MIMEMultipart
from email.MIMEText import MIMEText
from email.MIMEBase import MIMEBase
from email import Encoders
import suds
from suds.client import Client
from os.path import expanduser
import simplejson as json
from operator import itemgetter
from subprocess import PIPE, Popen
import os
import re
import csv
import time
import socket
import pprint
import urllib2
import itertools

def get_active_sdi():
    home_dir = expanduser("~")
    p_cmd = """grep '^alias sdictl=' """ + home_dir + """/.bash_profile"""
    p = Popen(p_cmd, shell=True, stdout=PIPE, stderr=PIPE)
    p_path = p.stdout.read().rstrip()
    active_sdi = p_path.split('=')[1][1:-1]
    return active_sdi

def get_bdcs_clusters(uri=''):
    #url="https://infrainternal.em2.cloud.oracle.com:7777/SDI-WS/SDIControlService?wsdl"
    url="https://infrainternal.pp1.oraclecloud.com:7777/SDI-WS/SDIControlService?wsdl"
    client = Client(url)
    bdcs_clusters=client.service.listGenericResource("BigDataAppliance","bdcs_cluster")
    return bdcs_clusters

def get_nodes(url):
    c_t=[]
    client = Client(url)
    all_nodes=client.service.listGenericResource("BigDataAppliance","bdcs_node")
    return all_nodes

def calc_mask(nm):
  nwbits = 0
  octets = nm.split(".")
  for elt in octets:
        a = int(elt)
        if (a == 255):
          nwbits = nwbits + 8
        else:
          l = []
          while True:
            m = a % 2
            l.append(m)
            a = a/2
            if ( a <= 1 ):
                l.append(a)
                break
          for i in l:
            nwbits = nwbits + i
  return nwbits

def run_command(command):
    process = Popen(
        args=command,
        stdout=PIPE,
        stderr=PIPE,
        shell=True
    )
    output, error = process.communicate()
    rc = process.returncode
    return (output.strip() , error.strip(), rc)

def get_fqdn(ipaddr):
  cmd_output = run_command("host %s" %(ipaddr))
  if (cmd_output[2] == 0):
        fqdn = cmd_output[0].split()
        fqdn = fqdn[-1][:-1]
        return fqdn
  else:
        return ipaddr

def check_dc_code(sdi):
     global ac
     ac=None
     p = Popen( sdi + """ config -get datacenter.shortname | awk 'NR > 3 { print }'""",shell=True, stdout=PIPE, stderr=PIPE)
     val = p.stdout.readlines()[0]
     if "pp" in val:
             ac = "Franklinpark"
     elif "us" in val:
             ac = "America"
     elif "em" in val:
             ac = "Franklinpark"
     if ac == None:
        print ("%s dc code is not allowed to execute here"% val)
        raise SystemExit
     else:
        return ac.capitalize()


def query_tas(domain, url=''):
    #url='https://tascentralinternal.us1.cloud.oracle.com:8888/tas-central/common/tas/api/v1/subscriptions?identityDomainName='+domain
    url='https://stg-tascentralinternal.us1.cloud.oracle.com:8888/tas-central/common/tas/api/v1/subscriptions?identityDomainName='+domain
    usr='OCLOUD9_OPCINFRA_ADMINUI_APPID'
    pwd='t@swelcome1'
    enc_usr="Basic " + (usr + ":" + pwd).encode("base64").rstrip()
    req = urllib2.Request(url)
    req.add_header("X-Oracle-UserId","ritesh.majumdar@oracle.com")
    req.add_header('Authorization', enc_usr)
    json_data=json.load(urllib2.urlopen(req))
    return json_data

def get_identity_domains(sdi):
    identity_domains = []
    p_cmd = sdi + """ listrq -filter -service_type '%BigDataAppliance%' -State '%COMPLETED%' """
    p = Popen(p_cmd, shell=True, stdout=PIPE, stderr=PIPE)
    p = p.stdout.readlines()

    for si in p:
        si = re.sub('-----*','',si)
        si_1 = re.sub(' ','',''.join(si.splitlines()))
        failed_list = si_1.split('|')
        if len(failed_list) > 1:
            service_list = failed_list[3][1:-1].split(',')
            if failed_list[3]=='[BigDataApplianceServiceEntitlement]' or \
               failed_list[3]=='[BigDataAppliance]' or \
               ','.join(sorted(service_list)) == 'BDDCS,BigDataApplianceServiceEntitlement,Storage':
                identity_domains.append(failed_list[6])
    return list(set(identity_domains))

def get_subnet_mask(bdcs_clusters, domain):
    for val in bdcs_clusters:
        if hasattr(val, 'occupiedByPod'):
            if val.occupiedByPod.split('.')[0] == domain:
                subnet=re.findall(r"(<subnet>([0-9\.]+)</subnet>)",val.body)[0][1]
                mask=re.findall(r"(<mask>([0-9\.]+)</mask>)",val.body)[0][1]
                m3 = calc_mask(mask)
                m4 = subnet + "/" + str(m3)
                return m4
    return None

def get_customer_details(created_identity_domains, customers):
    bdcs_clusters = get_bdcs_clusters(url)
    for domain in created_identity_domains:
        json_data = query_tas(domain, url='')
        m4 = None
        #cluster_name, cluster_status = query_sm(cu='', cp='', url='', idomain=domain)
        cluster_name, cluster_status = None, None
        if domain not in customers:
            for item in json_data['items']:
                if item['service']['type']== 'BigDataAppliance':
                    customer = item['account']['name']
                    startDate = item['startDate']
                    dataCenter = item['dataCenter']['id']
                    identityDomain = item['identityDomain']['name']
                    createdBy = item['createdBy']
                    serviceDisplayName = item['serviceDisplayName']
                    if item['status'] == 'ACTIVE':
                        try:
                            subscriptionId = item['states']['items'][0]['subscriptionId']
                        except IndexError:
                            subscriptionId = None
                        try:
                            gsiCsiNumber = item['gsiCsiNumber']
                        except KeyError:
                            gsiCsiNumber = None

                        for i in item['customAttributeValues']:
                            if i['name'] == "REUSE_EXISTING_GSI_POD" and i['value'] == "Y":
                                extension = True
                            else:
                                extension = False
                        subnet_mask = get_subnet_mask(bdcs_clusters, domain)
                        customers['active_customers'][domain+'_'+startDate] = {'cluster_name': cluster_name, 'cluster_status':cluster_status ,
                                                                               'customer':customer,'identityDomain':identityDomain,'startDate':startDate,
                                                                               'extension':extension,'dataCenter':dataCenter,'subnet_mask':subnet_mask,
                                                                               'serviceDisplayName':serviceDisplayName,'serviceAdminUserName':createdBy,
                                                                               'subscriptionId':subscriptionId,'gsiCsiNumber':gsiCsiNumber}
                    else:
                        terminationDate = item['terminationDate']
                        termination_status = item['status']
                        customers['deleted_customers'][domain+'_'+startDate] = {'customer':customer,'terminationDate':terminationDate,'startDate':startDate,
                                                                                'identityDomain':identityDomain,'serviceDisplayName':serviceDisplayName,
                                                                                'serviceAdminUserName':createdBy,'dataCenter':dataCenter,
                                                                                'termination_status':termination_status}
    return customers


def query_sm(cu='', cp='', url='', idomain=''):
    try:
        #cu="OCLOUD9_BDCS_APPID"
        #cp="b0c5_App1d"
        #url="https://paassvcmngrinternal-em2-sm01.oraclecloud.com:8888/paas/bdcs/api/v1.0/services"
        cu="OCLOUD9_BDCS_APPID"
        cp="bdc$_App1d"
        url="https://paassvcmngrinternal-sm01.uspp1.oraclecloud.com:8888/paas/bdcs/api/v1.0/services"
        enc_usr = "Basic " + (cu + ":" + cp).encode("base64").rstrip()
        req = urllib2.Request(url)
        req.add_header("X-USER-IDENTITY-DOMAIN-NAME",idomain)
        req.add_header('Authorization', enc_usr)
        sm_data = json.load(urllib2.urlopen(req))
        return sm_data
    except Exception:
        sm_data = None
        return sm_data


def format_active_customers(customers, customer_nodes):
    final_data={}
    for i, jj in customers['active_customers'].items():
        final_data[i] = jj
        final_data[i]['servicename'] = None
        final_data[i]['compute_size'] = 0
        for k, ll in customer_nodes.items():
            occupied = k.split('.')
            indomain = i.split('_')
            if k == indomain[0]+'.'+jj['serviceDisplayName'] or indomain[0] == occupied[0]:
                chk_r = [ chk for chk in final_data.values() if 'dom0' in chk and 'dom0' in ll and chk['dom0']==ll['dom0']]
                if chk_r:
                    continue
                else:
                    final_data[i].update(ll)
                    final_data[i]['servicename'] = occupied[1]
    for i, jj in final_data.items():
        indomain = i.split('_')
        sm_res = query_sm(cu='', cp='', url='', idomain=indomain[0])
        if sm_res:
            for val in sm_res['items']:
                if val['name'] == jj['servicename']:
                    if "cluster" in val:
                        final_data[i]['cluster_name'] = val['cluster']['name']
                        final_data[i]['cluster_status'] = val['cluster']['status']
                        final_data[i]['compute_size'] = val['computeSize']
        else:
            final_data[i]['cluster_name'] = None
            final_data[i]['cluster_status'] = None
    return final_data


def customer_nodes(all_nodes):
    customer_nodes = {}
    for i in all_nodes:
        if hasattr(i, 'occupiedByPod'):
            if i.occupiedByPod not in customer_nodes:
                customer_nodes[i.occupiedByPod] = {'dom0': [ get_fqdn(i.name) ],
                                                   'serviceType': [i.serviceType],
                                                   'parentResource':[i.parentResource]}
            else:
                customer_nodes[i.occupiedByPod]['dom0'].append(get_fqdn(i.name))
                customer_nodes[i.occupiedByPod]['serviceType'].append(i.serviceType)
                customer_nodes[i.occupiedByPod]['parentResource'].append(i.parentResource)
    return customer_nodes

def resource_statistics(node_list):
    c_t = []
    nl = sorted(node_list, key=itemgetter('parentResource'))
    for key, value in itertools.groupby(nl, key=itemgetter('parentResource')):
        customers_list = []
        free_nodes = []
        alloted_nodes = []
        for i in value:
            if hasattr(i, 'occupiedByPod'):
                if not customers_list:
                    customers_list = [i.occupiedByPod]
                else:
                    customers_list.append(i.occupiedByPod)
                if not alloted_nodes:
                    alloted_nodes = [i.id]
                else:
                    alloted_nodes.append(i.id)
            elif not hasattr(i, 'occupiedByPod'):
                if not free_nodes:
                    free_nodes = [get_fqdn(i.id)]
                else:
                    free_nodes.append(get_fqdn(i.id))
        c_t.append({'customers_list':customers_list, 'alloted_nodes':alloted_nodes, 'free_nodes':free_nodes, 'zone':key })
    return c_t

def resource_table(dc_code, resource_dict):
    table_data = '<h3>'+ dc_code + ' Resource Statistics:</h3>'
    table_data += '<table border=1 cellpadding=1 cellspacing=1 style="border-collapse: collapse;">'
    table_data += '<tr bgcolor="#b5a434"><th>Security Zone</th><th>Allocated Nodes</th><th>Customer Count</th><th>Available Nodes</th><th>Free Nodes List</th></tr>'
    #resultFile = open("/home/appinfra/.bdcs_daily_update/bdcs_daily_update.csv",'w')
    resultFile = open("/home/apsinfra/bigdata/Report_test_Jun_06/bdcs_daily_update.csv",'w')
    out = csv.writer(resultFile, delimiter=',',quoting=csv.QUOTE_ALL)
    out.writerow(['Franklinpark Resource Statistics',''])
    out.writerow(['Security Zone','Allocated Nodes', 'Customer Count', 'Available Nodes', 'Free Nodes List'])
    for data in resource_dict:
        table_data += '<tr bgcolor="#f2eed2"><td>'
        table_data += data['zone']
        table_data += '</td><td>'
        table_data += str(len(data['alloted_nodes']))
        table_data += '</td><td>'
        table_data += str(len(set(data['customers_list'])))
        table_data += '</td><td>'
        table_data += str(len(data['free_nodes']))
        table_data += '</td><td>'
        #table_data += '<br />\n'.join(data['free_nodes'])
        ips = [ ','.join(data['free_nodes'][3 * i: 3 * i + 3]) for i in range(0, len(data['free_nodes']) / 3) ]
        table_data += '<br />\n'.join(ips)
        table_data += '</td></tr>'
        csv_row = []
        csv_row.append(str(data['zone'].encode('utf-8')))
        csv_row.append(str(len(data['alloted_nodes'])))
        csv_row.append(str(len(set(data['customers_list']))))
        csv_row.append(str(len(data['free_nodes'])))
        fn = '\n'.join(data['free_nodes'])
        csv_row.append(str(fn))
        out.writerow(csv_row)
    table_data += '</table>'
    out.writerow('')
    out.writerow('')
    resultFile.close()
    return table_data

def active_customers_table(dc_code, active_customers_data):
    table_data = '<br/><h3>Detailed Report:</h3>'
    table_data += '<br/><h4>' + dc_code + ' customers and segment allocation :( '+ str(len(active_customers_data)) +' )</h4>'
    table_data += '<table border=1 cellpadding=1 cellspacing=1 style="border-collapse: collapse;">'
    table_data += '<tr bgcolor="#b5a434"><th>Customer</th><th>Identity Domain</th><th>Service Name</th><th>Dom0 List</th><th>Service size</th>'
    table_data += '<th>Subnet</th><th>Cluster Name</th><th>Cluster Status</th><th>Createdby</th><th>Datacenter</th>'
    table_data += '<th>Subscription ID</th><th>Zone </th><th>Compute Nodes</th><th>Created On</th><th>CSI Number </th></tr>'
    #resultFile = open("/home/appinfra/.bdcs_daily_update/bdcs_daily_update.csv",'a+')
    resultFile = open("/home/apsinfra/bigdata/Report_test_Jun_06/bdcs_daily_update.csv",'a+')
    out = csv.writer(resultFile, delimiter=',',quoting=csv.QUOTE_ALL)
    out.writerow(['Franklinpark customers and segment allocation', ''])
    out.writerow(['Customer','Identity Domain', 'Service Name', 'Dom0 List', 'Service size', 'Subnet', 'Cluster Name', 'Cluster Status', 'Createdby', 'Datacenter', 'Subscription ID', 'Zone', 'Compute Nodes', 'Created On', 'CSI Number'])
    for i, data in active_customers_data.items():
        if 'oracle.com' in data['serviceAdminUserName'].lower():
            table_data += '<tr bgcolor="#aec8f2"><td>'
        else:
            table_data += '<tr bgcolor="#f2eed2"><td>'
        table_data += data['customer']
        table_data += '</td><td>'
        table_data += data['identityDomain']
        table_data += '</td><td>'
        table_data += str(data.get('servicename','None'))
        table_data += '</td><td style="width: 100%; white-space: nowrap;">'
        dom0 = data.get('dom0',['None'])
        dom0.sort()
        if 'None' not in dom0:
            dom0_len = str(len(dom0))
        else:
            dom0_len = None
        table_data += '<br>\n'.join(dom0)
        table_data += '</td><td>'
        table_data += str(dom0_len)
        table_data += '</td><td>'
        table_data += str(data['subnet_mask'])
        table_data += '</td><td>'
        table_data += str(data['cluster_name'])
        table_data += '</td><td>'
        table_data += str(data['cluster_status'])
        table_data += '</td><td>'
        table_data += data['serviceAdminUserName']
        table_data += '</td><td>'
        table_data += data['dataCenter']
        table_data += '</td><td>'
        table_data += str(data['subscriptionId'])
        table_data += '</td><td>'
        parentResource = data.get('parentResource',['None'])
        table_data += str(parentResource[0])
        table_data += '</td><td>'
        table_data += str(data['compute_size'])
        table_data += '</td><td>'
        table_data += data['startDate']
        table_data += '</td><td>'
        table_data += str(data['gsiCsiNumber'])
        table_data += '</td></tr>'
        csv_row = []
        csv_row.append(str(data['customer'].encode('utf-8')))
        csv_row.append(str(data['identityDomain'].encode('utf-8')))
        csv_row.append(str(data.get('servicename','None')))
        csv_row.append(str('\n'.join(dom0)))
        csv_row.append(str(dom0_len))
        csv_row.append(str(data['subnet_mask']))
        csv_row.append(str(data['cluster_name']))
        csv_row.append(str(data['cluster_status']))
        csv_row.append(str(data['serviceAdminUserName']))
        csv_row.append(str(data['dataCenter']))
        csv_row.append(str(data['subscriptionId']))
        csv_row.append(str(parentResource[0]))
        csv_row.append(str(data['compute_size']))
        csv_row.append(str(data['startDate']))
        csv_row.append(str(data['gsiCsiNumber']))
        out.writerow(csv_row)
    table_data += '</table>'
    out.writerow('')
    out.writerow('')
    resultFile.close()
    return table_data


def deleted_customers_table(deleted_customers_data):
    deleted_customers = [ i for i, data in deleted_customers_data.items() if 'CANCEL' not in str(data['termination_status']) and 'oracle.com' not in data['serviceAdminUserName'].lower()]
    table_data = '<h3>Customers in terminated state  :( '+ str(len(deleted_customers)) + ' )</h3>'
    table_data += '<table border=1 cellpadding=1 cellspacing=1 style="border-collapse: collapse;">'
    table_data += '<tr bgcolor="#b5a434"><th>Customer</th><th>Customer status</th><th>Identity Domain</th><th>Service Name</th><th>Createby</th><th>Datacenter</th>'
    table_data += '<th>Start Date</th><th>Termination Date </th></tr>'
    #resultFile = open("/home/appinfra/.bdcs_daily_update/bdcs_daily_update.csv",'a+')
    resultFile = open("/home/apsinfra/bigdata/Report_test_Jun_06/bdcs_daily_update.csv",'a+')
    out = csv.writer(resultFile, delimiter=',',quoting=csv.QUOTE_ALL)
    out.writerow(['Customers in terminated state', ''])
    out.writerow(['Customer','Customer status', 'Identity Domain', 'Service Name', 'Createdby', 'Datacenter', 'Start Date', 'Termination Date'])
    for i, data in deleted_customers_data.items():
        if 'CANCEL' not in str(data['termination_status']) and \
            'oracle.com' not in data['serviceAdminUserName'].lower():
            table_data += '<tr bgcolor="#f2eed2"><td>'
            table_data += data['customer']
            table_data += '</td><td>'
            table_data += data['termination_status']
            table_data += '</td><td>'
            table_data += data['identityDomain']
            table_data += '</td><td>'
            table_data += data['serviceDisplayName']
            table_data += '</td><td>'
            table_data += data['serviceAdminUserName']
            table_data += '</td><td>'
            table_data += data['dataCenter']
            table_data += '</td><td>'
            table_data += data['startDate']
            table_data += '</td><td>'
            table_data += data['terminationDate']
            table_data += '</td></tr>'
            csv_row = []
            csv_row.append(str(data['customer'].encode('utf-8')))
            csv_row.append(str(data['termination_status'].encode('utf-8')))
            csv_row.append(str(data['identityDomain'].encode('utf-8')))
            csv_row.append(str(data['serviceDisplayName'].encode('utf-8')))
            csv_row.append(str(data['serviceAdminUserName'].encode('utf-8')))
            csv_row.append(str(data['dataCenter'].encode('utf-8')))
            csv_row.append(str(data['startDate'].encode('utf-8')))
            csv_row.append(str(data['terminationDate'].encode('utf-8')))
            out.writerow(csv_row)
    table_data += '</table>'
    resultFile.close()
    return table_data

def main(sdi, resource_dict, active_customers, deleted_customers):
    msg_format = ''
    #dc_code = check_dc_code(sdi)
    #dc_code='Franklinpark'
    dc_code='Franklinpark'
    resource = resource_table(dc_code, resource_dict)
    msg_format += resource
    active_customers = active_customers_table(dc_code, active_customers)
    msg_format += active_customers
    deleted_customers = deleted_customers_table(deleted_customers)
    msg_format += deleted_customers
    from_addr = 'bdsrvs_ww_grp@oracle.com'
    to_addr = ['bdsrvs_ww_grp@oracle.com', '']
    #to_addr = ['raghu.mani@oracle.com', 'jean-pierre.dijcks@oracle.com', 'jacco.draaijer@oracle.com', 'petr.blaha@oracle.com', 'raj.raina@oracle.com', 'bdsrvs_ww_grp@oracle.com', 'sumana.vijayagopal@oracle.com', 'cloud_capacityplanners_ww_grp@oracle.com', 'brandon.gresham@oracle.com']
    #to_addr = ['ritmajum_org_ww@oracle.com', '']
    #from_addr = 'naveen.kumar.vaddepally@oracle.com'
    #to_addr = ['naveen.kumar.vaddepally@oracle.com', '']
    s = smtplib.SMTP()
    msg = MIMEMultipart()
    msg['Content-Type'] = "text/html; charset=us-ascii"
    msg['Subject'] = 'BDCS '+ dc_code + ' customers report'
    msg['From'] = from_addr
    msg['To'] = ", ".join(to_addr)
    part2 = MIMEText(msg_format.encode('utf-8'), 'html', 'utf-8')
    msg.attach(part2)
    #file_content = open("/home/appinfra/.bdcs_daily_update/bdcs_daily_update.csv", "rb").read()
    file_content = open("/home/apsinfra/bigdata/Report_test_Jun_06/bdcs_daily_update.csv", "rb").read()
    part = MIMEBase("application", "octet-stream")
    part.set_payload(file_content)
    Encoders.encode_base64(part)
    fname= 'bdcs_daily_update_'+time.strftime("%d_%m_%Y")+'.csv'
    part.add_header('Content-Disposition', 'attachment', filename=os.path.basename(fname))
    msg.attach(part)
    s.connect()
    s.sendmail(from_addr, to_addr, msg.as_string())
    s.quit()


if __name__ == '__main__':
   #url="https://infrainternal.em2.cloud.oracle.com:7777/SDI-WS/SDIControlService?wsdl"
   url="https://infrainternal.pp1.oraclecloud.com:7777/SDI-WS/SDIControlService?wsdl"
   customers = {}
   customers['active_customers']={}
   customers['deleted_customers']={}
   node_list = get_nodes(url)
   customer_nodes = customer_nodes(node_list)
   active_sdi = get_active_sdi()
   c_t = resource_statistics(node_list)
   identity_domains = get_identity_domains(active_sdi)
   customer_details = get_customer_details(identity_domains, customers)
   formatted_active_customers = format_active_customers(customer_details, customer_nodes)
   main(active_sdi, c_t, formatted_active_customers, customer_details['deleted_customers'])

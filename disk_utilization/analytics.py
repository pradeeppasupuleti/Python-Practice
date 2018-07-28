from lxml import etree
from lxml.html import document_fromstring
import sys, subprocess, smtplib,urllib2,re,zipfile,os,json
import commands
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email import Encoders
import time
from email.Utils import formatdate
from optparse import OptionParser

#################################################
# this function is used to retrieve the html file 
# containing table will all the jobIds 
#################################################
def getAllJobs(service_name,csr_user,csr_pass,psm_restinternal_url):
    logMessage("Step1 : Executing getAllJobs function") 
    service_name = service_name.upper()
    if not psm_restinternal_url.endswith("/"):
        psm_restinternal_url = psm_restinternal_url + "/"
    else:
        pass
    try:
        cmd = '''curl --basic --user ''' + csr_user +  ":" + csr_pass + ''' --header 'Accept: text/html' --header 'X-ID-TENANT-NAME: CSR' ''' + psm_restinternal_url +'''CSR?operation=sm-create-service-operation&status=Failed&serviceType=''' + service_name + ''' -o b.html''' 
        status = os.system(cmd)
        if status == 0 :
            logMessage("JobIds file generated successfully")
        else:
            raise Exception('')
    except Exception , error :
        error_message = "Error :" + str(error) + ":" + "Unable to download the file using curl..Please check the cURL command in getAllJobs function"
        logMessage(error_message) 
        script_failed_notification(service_name,error_message)
        logMessage("terminating the program now...")
        sys.exit(1)
    else:
        logMessage("CURL triggered succesfully")
        logMessage("File downloaded with all jobIDs")

#################################################
# this function is used to read the downloaded html file 
# and add new css format and general seperate html files
# for each jobId  
#################################################
def parseHTML(csr_user, csr_pass, service_name, psm_restinternal_url):
    logMessage("Step2 : Executing parseHTML function")
    global all_jobids
    all_jobids = []
    try:
        htmljobs = "b.html"
	fobj = open(htmljobs)
	s = fobj.read()
	fobj.close()
        part1 = '''
        <html xmlns:p="http://xmlns.oracle.com/cloud/paas/1.0">
        <head>
        <META http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <title>Jobs</title>
        '''
        css_style_new='''
        <style type="text/css">
	.failed {
	font-family: "Trebuchet MS", Arial, Helvetica, sans-serif;
	border-collapse: collapse;
	width: 100%;
	}

	.failed td, .failed th {
	border: 1px solid #ddd;
	padding: 8px;
	}

	.failed tr:nth-child(even){background-color: #f2f2f2;}

	.failed tr:hover {background-color: #ddd;}

	.failed th {
	padding-top: 12px;
	padding-bottom: 12px;
	text-align: left;
	background-color: #ff6347;
	color: white;
	}
	</style>

        '''
	if len(s) == 0 :
            logMessage("failed to read the file containing Jobs as it is empty")
            logMessage( "exiting from parseHTML function")
            sys.exit(1)
           

        htmlhead = part1 + css_style_new + "</head>"

	table = etree.HTML(s).find("body/table")
        s= document_fromstring(s)
        rows = iter(table)
        count = 0
        htmlbody = ""
        headers = [col.text for col in next(rows)]
        headers.remove('Sub Status')
        headers.remove('Parent Id')
        headers.extend(["Customer Name"])
       
        newheader =  list(map( lambda x : "<th>" + x + "</th>" , headers))
        newheaderstring = "".join(newheader)
        newheaderstring = """<tr class="new">""" + newheaderstring + "</tr>"
        for row in rows:
            jobid = [col.text for col in row[0]]
            service_call = s.xpath("//a")[count].get("href")
            count = count + 1
            getcall =  service_call.split("job/")[1]
            if not psm_restinternal_url.endswith("/"):
                psm_restinternal_url = psm_restinternal_url + "/"
            else :
                pass
	    curl_call = "curl --basic --user " + csr_user + ":" + csr_pass + " --header 'Accept: text/html' --header 'Accept: text/html' --header 'X-ID-TENANT-NAME: CSR' " +  psm_restinternal_url +  getcall + " -o " + jobid[0] + ".html"
            ##### storing all job ids in the list in order to use the same in getAttachment function
            all_jobids.append(jobid[0])
            logMessage("Inside parseHTML : curl command :" + curl_call)
            logMessage("Executing curl command from parseHTML function")
	    try:
                os.system(curl_call)
            except OSError, error:
                logMessage(error)    
                error_message = error + ":" + "Unable to execute the cURL command from parseHTML function"
                script_failed_notification(service_name,error_message)
                continue
            #status, output = commands.getstatusoutput(curl_call)
            link = jobid[0] 

            values = [col.text for col in row[1:]]   
            customerdata = values[-4]
            values = [link] + values
            #jsondata = getJSON(customerdata)
            '''
	    if len(jsondata) == 5:
                customer_name = "NA"
            else:
                customer_name = jsondata["items"][0]['customAttributeValues'][25]["value"]
            '''
            try:
                tree = etree.parse(jobid[0]+".html", parser)
                datalist = tree.xpath('//table/tr/td')
                customer_name = mylist[4].xpath('text()')[0]
            except IndexError , error :
                customer_name = "NA"
            except Exception , error:
                customer_name = "NA"   
            values.append(customer_name)
            values.pop(3)
            values.pop(-2)
            values = [str() for item in values]
            record =  list(map( lambda x : "<td>" + x + "</td>" , values))
            record = "".join(record)
            record = """<tr class="failed">""" + record + "</tr>"   
            htmlbody+=record

        htmlbody = '''<body>''' + " Total no. of failed jobs  :" + count + '''<table class="failed">''' + newheaderstring + htmlbody + "</table></body>"
        #print(htmlbody)
        global template
        template = htmlhead + htmlbody + "</html>"

    except Exception , error :
	logMessage("Error found in parseHTML function ", error)
        error_message = "Error found in parseHTML function " + "\n" +error + "\n" + str(sys.exc_info()[0])
	logMessage(error_message)
        script_failed_notification(service_name,error_message)

##################################################
# getJSON function will retrieve the json output
# to get the customer_name
##################################################	
def getJSON(customerdomain):
    try:
        url='https://tascentralinternal.us1.cloud.oracle.com:8888/tas-central/common/tas/api/v1/subscriptions?identityDomainName='+customerdomain
        usr='OCLOUD9_OPCINFRA_ADMINUI_APPID'
        pwd='t@swelcome1'
        enc_usr="Basic " + (usr + ":" + pwd).encode("base64").rstrip()
        req = urllib2.Request(url)
        req.add_header("X-Oracle-UserId","ritesh.majumdar@oracle.com")
        req.add_header('Authorization', enc_usr)
        json_data=json.load(urllib2.urlopen(req))
        return json_data
    except Exception , error:
        logMessage("Exception in getJSON method :" +  error)
        logMessage("Exception in getJSON method :", sys.exc_info()[0])        
        return "error"

##########################################################
# getAttachment function will zip all the html JobID files
##########################################################
def getAttachment(service_name):
    logMessage("Step3:  preparing the zip file")
    service_name = service_name.lower()
    try:
	global newfile    
        newfile = "psm_job_logs_" + service_name + "_" + time.strftime("%d_%m_%Y") + '.zip'
        jobs_zip = zipfile.ZipFile(newfile, 'w')
        for folder, subfolders, files in os.walk(os.getcwd()):
            for file in files:
                if re.search("^[0-9]+",file): 
                    if file in all_jobids:
                        jobs_zip.write(os.path.join(folder, file), os.path.relpath(os.path.join(folder,file), os.getcwd()), compress_type = zipfile.ZIP_DEFLATED)
        jobs_zip.close()

    except Exception , error :
        error_message = "Exception found in getAttachment method :" + error  + ":" + str(sys.exc_info()[0])
        logMessage(error_message)
        script_failed_notification(service_name,error_message)

#################################
# sending mail
################################
def send_email_with_attachment(to_emails,from_email,service_name):
    logMessage("Step4:  sending email to", to_emails , " with the zip file")
    service_name = service_name.lower()
    to_emails = to_emails.split(",")
    #cc_emails = " " 
    
    subject = service_name.capitalize() + " CS psm FAILED job report of US region"
    body_text = "This email contains an attachment!"
    newfile = "psm_job_logs_" + service_name + "_" + time.strftime("%d_%m_%Y") + '.zip'
    base_path = os.path.dirname(os.path.abspath(__file__))
    header = 'Content-Disposition', 'attachment; filename="%s"' % newfile
    # extract server and from_addr from config
    host = "127.0.0.1"
    # create the message
    msg = MIMEMultipart()
    msg["From"] = from_email
    from_address = from_email
    msg["Subject"] = subject
    part2 = MIMEText(template, 'html')
    if template:
        msg.attach( part2 )
    
    msg["To"] = ', '.join(to_emails)
    attachment = MIMEBase('application', "octet-stream")
    try:
        with open(newfile, "rb") as fh:
            data = fh.read()
        attachment.set_payload( data )
        Encoders.encode_base64(attachment)
        attachment.add_header(*header)
        msg.attach(attachment)
    except IOError:
        error_message = "Error opening attachment file %s .. Error in send_email_with_attachment function" % newfile 
        logMessage(error_message)
        script_failed_notification(service_name ,error_message)
        sys.exit(1)
    
    emails = to_emails
    
    server = smtplib.SMTP(host)
    server.sendmail(from_address, emails, msg.as_string())
    server.quit()
    
##########################################################
# the below function will delete all the html files that
# are been created while executing the script
##########################################################
def delete_unwanted_files(service_name):
    logMessage("Step5: cleaning all the unwanted files")
    for folder, subfolders, files in os.walk(os.getcwd()):
        for file in files:
            if file.endswith(".htm") or file.endswith(".html"):
                try:
                    os.unlink(file)
                except Exception , error:
                    error_message = error + "\n" + "Unable to delete the file named " + file
                    logMessage(error_message)
                    script_failed_notification(service_name ,error_message)
                    pass

def move_zip_to_storage_cloud(service_name,storage_url,storage_user,storage_pass ):
    logMessage("Step6: moving the zip file to the Oracle cloud service")
    #curl_command = """curl -X PUT -u  "ritesh.majumdar@oracle.com:grDn36m0@" -T """ + newfile + """ -i https://uscom-east-1.storage.oraclecloud.com/v1/""" + storage_name + "/" +container_name + "/"
    curl_command = """curl -X PUT -u """  + storage_user + ":" + storage_pass + """ -T """ + newfile + """ -i """ + storage_url
    if not curl_command.endswith("/"):
       curl_command = curl_command + "/"
    else:
       pass
    logMessage("executing move_zip_to_storage_cloud function and executing "+  curl_command)
    try:
       storage_status = os.system(curl_command)
       #print "status code :", storage_status
       if storage_status == 0:
            logMessage(newfile + "has been stored in " + container_name +  " successfully")
       else:
            logMessage("failed to store the file in " +  container_name)
            logMessage("Exiting from the program")
    except Exception , error:
       error_message = "Exception found in move_zip_to_storage_cloud function" + ":" + error
       logMessage(error_message)
       script_failed_notification(service_name ,error_message)
    else :
       os.unlink(newfile)
   

def logMessage(message):
    current_timestamp = time.strftime("%d.%b %Y %H:%M:%S") 
    filename = "psm_" + service_name +  "_" + time.strftime("%Y%m%d.log") 
    fobj = open(filename,"a") 
    fobj.write(current_timestamp + "    " + message + "\n")

def script_failed_notification(service_name,error_message):
    service_name = service_name.lower()
    to_emails = to_email.split(",")
    script_name = sys.argv[0]
    #subject = service_type.capitalize() + " CS psm FAILED job report of US region"
    subject = script_name + " failed" + " for " + service_name.capitalize() + " CS psm FAILED job report of US region"
    host = "127.0.0.1"
    msg = MIMEText(error_message)
    # create the message
    msg['Subject'] = subject
    msg['To'] = ', '.join(to_emails)
    msg['From'] = from_email
    #from_address = from_email
    emails = to_emails
    server = smtplib.SMTP(host)
    server.sendmail('giridhar.sripathi@oracle.com', emails, msg.as_string())
    server.quit()


if __name__ == "__main__" :
    parser = OptionParser()
    parser.add_option("--service_name", dest="service_name",help="define the type of service")
    parser.add_option("--from_email", dest="from_email",help="need to specify from email address..")
    parser.add_option("--to_email", dest="to_email",help="to whom we need to send.. specify emails seperated with , ")
    parser.add_option("--psm_restinternal_url",dest="psm_restinternal_url",help="provide the REST URL to make a rest call")
    parser.add_option("--dc", dest = "dc", help = "data center information")
    parser.add_option("--csr_user",dest="csr_user",help="CSR username")
    parser.add_option("--csr_pass",dest="csr_pass",help="CSR password")
    parser.add_option("--with_storage",dest="with_storage",help="Storage to be enabled or disabled")
    parser.add_option("--storage_url",dest="storage_url",help="provide storage URL here")
    parser.add_option("--storage_user",dest="storage_user",help="provide storage service user name")
    parser.add_option("--storage_pass",dest="storage_pass",help="provide storage service password")

    (options,args) = parser.parse_args()
    service_name = options.service_name
    global to_email
    global from_email
    to_email = options.to_email
    from_email = options.from_email
    psm_restinternal_url = options.psm_restinternal_url
    dc = options.dc
    csr_user = options.csr_user
    csr_pass = str(options.csr_pass)
    with_storage = options.with_storage
    storage_url = options.storage_url
    storage_user = options.storage_user
    storage_pass = options.storage_pass
 
    # validating all the required fields are been defined or not 
    if service_name == None or to_email == None or from_email == None or psm_restinternal_url == None or csr_user == None or csr_pass == None :
        print "-----------------------------------------------------------------------------------------------"
        print "Error : One of the mandatory argument or more number of arguments are missing.. to_email , from_email , psm_restinternal_url , csr_user , csr_pass are the mandatory arguments"
        print "------------------------------------------------------------------------------------------------"
        sys.exit(1)

    logMessage("Execution started")
    getAllJobs(service_name,csr_user,csr_pass,psm_restinternal_url)
    #parseHTML(csr_user,csr_pass,service_name,psm_restinternal_url)
    #getAttachment(service_name)
    #send_email_with_attachment(to_email,from_email,service_name)
    #delete_unwanted_files(service_name)

    if with_storage in ["y","YES","Y","yes"] :
        move_zip_to_storage_cloud(service_name ,storage_url, storage_user , storage_pass)
        logMessage("Connecting to ", storage_url , " with", storage_user , " and" , storage_pass)
    else:
        logMessage("storage is not enabled .. hence not storing the archive to the storage service")
    ### closing the file
    fobj.close()
    logMessage("End of the program")

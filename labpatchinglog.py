#!/usr/bin/env python

'''
Copyright (c) 2010, 2016, Oracle and/or its affiliates.
All rights reserved.

Initial execution starts from this script. This module used to create log file based on the output for all component.
It also parses the output of commands run through ssh, different parsing function for all component..


MODIFIED    (MM/DD/YY)
vvieks      10/08/16
rmaliset      16/03/17

'''


import traceback, os, sys
from pprint import pprint
#from optparse import OptionParser

from createlog import addtolog, run_psm_rcsm, ssh_exception_entries, run_storage_info, process_idcs
import dbHandler, sendemail
import logging, logging.handlers
from idm_post_execution import process_idm_nodes

import idoru_artifacts
import shutil


# parser = OptionParser(usage="usage: %prog [configuration file] [option] ",version="%prog 1.0")
# (options, args) = parser.parse_args()


debug = False

emails_to = []
emails_cc = []
emails_bcc = []

def execute_checks():
    '''
    Iterate through all the DC's mentioned in env_list and update the prepared version string in the Oracle DB.
    '''
    
    env_list=['migdc1','edgdc1','migdc2','migdc3','ea3_c9lab','ea3_c9stage', 'sydney dc']
    conf_list = [each.lower()+'.conf' for each in env_list]
    try:
        for cnf in conf_list:
            env = cnf.split('.')[0].upper()
            #if env != 'SYDNEY DC':continue                 ## DC filter to restrict execution to only a particular DC. 
            
            if env.lower().startswith("sydney"):
                env = "SYDNEY DC"
            else:
                env = env[:3].capitalize()+' '+env[3:]      ## To maintain a proper notation for DC representation like MIGDC1, MIGDC2 ..
            
            '''
            ## run for All components
            #run_idm_info(cnf.upper())        #commented as we added entries in LAB_OVM_DETAILS table.
            '''
            run_storage_info(cnf.upper())
            run_psm_rcsm(cnf.upper())
            process_idcs(cnf.upper())
            
            component_dict = dbHandler.get_all_component(env)
            for component in component_dict:
                addtolog(component,cnf.upper())
        dbHandler.update_last_update_time()
    except Exception, emsg:
        logger.critical("Exception occurred in labpatchinglog > " + str(emsg))
        logger.debug("Traceback - " + str(traceback.print_exc()))

def notify_emails():
    '''
    Report via email for the entries gathered in ssh_exception_entries and dbHandler.email_nodes.
    '''
    
    try:
        if debug:
            emails_to = ["rammurthy.malisetti@oracle.com"]
            emails_cc = ["slcn03vmf0257@us.oracle.com"]
            emails_cc_exclude_ganesh = ["slcn03vmf0257@us.oracle.com"]
        else:
            emails_to = ["rammurthy.malisetti@oracle.com", "vivek.b.sharma@oracle.com"]
            emails_cc = ["sivakumar.samidas@oracle.com", "Ganesh Puram <ganesh.puram@oracle.com>"]
            emails_cc_exclude_ganesh = ["sivakumar.samidas@oracle.com"]
            

        if ssh_exception_entries or dbHandler.exc_nodes:
            sendemail.send_exception_update(to_list02=emails_to, cc_list02=emails_cc_exclude_ganesh, bcc_list02=[], subject02="Patching Script Exceptions", info02=dbHandler.exc_nodes + ssh_exception_entries)
            pprint("dbHandler.exc_nodes -")
            pprint(dbHandler.exc_nodes)
            print
            pprint("ssh_exception_entries - ")
            pprint(ssh_exception_entries)
            pprint("##########################")
        
        if dbHandler.email_nodes:
            sendemail.send_email_update(to_list01=emails_to, cc_list01=emails_cc, bcc_list01=emails_bcc, subject01="Error - Patching Dashboard", info01=dbHandler.email_nodes)
            #sendemail.send_email_update(to_list=["rammurthy.malisetti@oracle.com", "vivek.b.sharma@oracle.com"], cc_list=[], bcc_list=[], subject="Error - Patching Dashboard", info=dbHandler.email_nodes)
            pprint("dbHandler.email_nodes -")
            pprint(dbHandler.email_nodes)
        
        logger.debug("########### SUMMARY ###########")
        logger.debug("email_nodes - {0}".format(len(dbHandler.email_nodes)))
        logger.debug("ssh_exception_entries - {0}".format(len(ssh_exception_entries)))
        logger.debug("exc_nodes - {0}".format(len(dbHandler.exc_nodes)))
        logger.debug("###############################")
    except Exception, emsg:
        logger.critical("Exception occurred during sending email - " + str(emsg))
        logger.debug("Traceback - " + str(traceback.print_exc()))


def execute_individual(dc_input = "", node = ""):
    '''
    It executes for the mentioned DC and component provided as part of command line arguments and update the prepared version string in the Oracle DB.
    '''
    logger.debug("Execution started for {0} -> {1}".format(dc_input, node))
    
#     env_list={'MIGDC1': 'Mig DC1',
#               'EDGDC1': 'Edg DC1',
#               'MIGDC2' : 'Mig DC2',
#               'MIGDC3' : 'Mig DC3',
#               'SYDNEY DC' : 'SYDNEY DC'
#     }

    cnf = dc_input.lower()+'.conf'
    env = cnf.split('.')[0].upper()
    if env.lower().startswith("sydney"):
        env = "SYDNEY DC"
    else:
        env = env[:3].capitalize()+' '+env[3:]
    
    try:
        #logger.debug(cnf.upper())
        if node in ["Storage"]:
            run_storage_info(cnf.upper())
        elif node in ["PSM", "RCSM"]:
            run_psm_rcsm(cnf.upper())
        elif node in ["IDCS"]:
            process_idcs(cnf.upper())
        else:
            component_list = dbHandler.get_all_component(env)
            for component in component_list:
                addtolog(component, cnf.upper(), component_filter=node.split()[0].lower())
        dbHandler.update_last_update_time()
    except Exception, emsg:
        logger.critical("Exception occurred in labpatchinglog > " + str(emsg))
        logger.debug("Traceback - " + str(traceback.print_exc()))

if __name__ == "__main__":
    '''
    Bot execution starts here!!
    '''
    try:
        if not os.path.exists(os.path.join(os.path.dirname(__file__), "Logs")):
            os.makedirs(os.path.join(os.path.dirname(__file__), "Logs"))
            print "Log directory created - {0}".format(os.path.join(os.path.dirname(__file__), "Logs"))
    except:
        pass
    
    if len(sys.argv) == 3:
        logFile = os.path.join("Logs", 'one_dc_one_node.log')
        if os.path.exists(logFile + ".1"):shutil.move(logFile + ".1", logFile + ".2")
        if os.path.exists(logFile):shutil.move(logFile, logFile + ".1")
        
        loghandler = logging.handlers.RotatingFileHandler(logFile, maxBytes=5242880, backupCount=3)
        formatter = logging.Formatter('%(asctime)-15s : %(levelname)s : %(name)s : %(funcName)s : %(message)s')
        loghandler.setFormatter(formatter)
        
        logger = logging.getLogger()
        logger.setLevel("DEBUG")    # Possible log levels 'CRITICAL', 'ERROR', 'WARNING', 'INFO', 'DEBUG', 'NOTSET'
    
        logger.addHandler(loghandler)
        logger.info("")
        logger.info("########### Module Execution Started ({0} -> {1}) ###########".format(sys.argv[1], sys.argv[2]))
        execute_individual(dc_input=sys.argv[1], node=sys.argv[2])
        notify_emails()
        
        if sys.argv[2] in ['OIDHOST', 'IDMHOST', 'IDMOHSHOST']:
            process_idm_nodes()
        
        logger.info("########### Module Execution Completed ###########")    
    else:
        logFile = os.path.join("Logs", 'patching_dashboard_agent.log')
        loghandler = logging.handlers.RotatingFileHandler(logFile, maxBytes=5242880, backupCount=3)
        #formatter = logging.Formatter('%(asctime)-15s : %(levelname)s : %(name)s : %(funcName)s : %(message)s')
        formatter = logging.Formatter('%(asctime)-15s : %(levelname)s : %(name)s : %(funcName)s : %(message)s')
        loghandler.setFormatter(formatter)
        
        logger = logging.getLogger()
        logger.setLevel("DEBUG")    # Possible log levels 'CRITICAL', 'ERROR', 'WARNING', 'INFO', 'DEBUG', 'NOTSET'
    
        logger.addHandler(loghandler)
        
        logger.info("")
        logger.info("########### Module Execution Started ###########")
        logger.debug("Environment variables - {0}".format(os.environ))
        
        local_artifacts = idoru_artifacts.prepare_idoru_artifacts()
        dbHandler.facts = local_artifacts
    
        execute_checks()
        notify_emails()
        process_idm_nodes()
        
        logger.info("########### Module Execution Completed ###########")
    

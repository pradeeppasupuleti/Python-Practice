#!/usr/bin/env python

import traceback, os, sys
from pprint import pprint
import logging, logging.handlers
import shutil


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
	pass
    else:
        logFile = os.path.join("Logs", 'messages.log')
        loghandler = logging.handlers.RotatingFileHandler(logFile, maxBytes=5242880, backupCount=3)
        formatter = logging.Formatter('%(asctime)-15s : %(levelname)s : %(name)s : %(funcName)s : %(message)s')
        loghandler.setFormatter(formatter)
        
        logger = logging.getLogger()
        logger.setLevel("DEBUG")    # Possible log levels 'CRITICAL', 'ERROR', 'WARNING', 'INFO', 'DEBUG', 'NOTSET'
    
        logger.addHandler(loghandler)
        
        logger.info("")
        logger.info("Execution Started")
        logger.debug("Environment variables - {0}".format(os.environ))
	""" execute our main logic here!!!"""
        logger.info("Execution Completed")

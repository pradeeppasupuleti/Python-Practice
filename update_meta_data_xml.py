import logging
import os
import subprocess
from shutil import copyfile
import filecmp
import commands

def register_meta_data_xml(src_file, dst_file, p_path):
    cmp_flag = filecmp.cmp(src_file, dst_file)
    if cmp_flag == False:
        copyfile(src_file, dst_file)
        register_cmd = p_path + "/sdictl/sdictl.sh register_generic_servicetype -file " + dst_file + " -force"
        os.system(register_cmd)
        logger.info('copied'+ src_file + ' to '+ dst_file)
        logger.info('updated metadata xml file in SDI')
    else:
        logger.info('already have proper  metadata xml file in SDI')

def main():
    p_cmd = """more /home/appinfra/.bash_profile | grep 'alias sdictl=' | cut -d'/' -f-7 | cut -d'=' -f 2 | cut -c 2-"""
    p = subprocess.Popen(p_cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    p_path = p.stdout.read().rstrip()
    src_file = '/home/appinfra/.data_enrichment_service_metadata.xml'
    dst_file = p_path + '/serviceTypeRegistration/data_enrichment_service_metadata.xml'
    register_meta_data_xml(src_file, dst_file, p_path)


if __name__ == '__main__':

    logger = logging.getLogger('bdp metadata xml file')
    logger.setLevel(logging.INFO)

    fh = logging.FileHandler('bdp_metadata_xml.log')
    fh.setLevel(logging.INFO)

    formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    fh.setFormatter(formatter)
    logger.addHandler(fh)
    logger.info('bdp metadata xml file begins ...')
    main()
    logger.info('bdp metadata xml file ends ...')
    logger.info('-------------------------------')

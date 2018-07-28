#!/usr/bin/python

import traceback
import pexpect


def ssh_command(host, user, password, command, return_code = False, use_ssh_key = False, ssh_key_file = "", ssh_passphrase = ""):
    '''
    Execute SSH command on the remote host and return with command return output.
    This subroutine can handle below cases when invoking an ssh command:
        -> SSH could not login.
        -> SSH host have the public key.
        -> SSH host does not have the public key.
    '''
    
    try:
        ssh_prompt = 'Are you sure you want to continue connecting'
        if '/usr/bin/sudo' in command:
            if use_ssh_key:
                ssh_command = 'ssh -t -i %s -l  %s  %s  %s' % (ssh_key_file, user, host, command)
            else:
                ssh_command = 'ssh -t -l %s  %s  %s ' % (user, host, command)
        else:
            if use_ssh_key:
                ssh_command = 'ssh -i %s -l %s  %s  %s' % (ssh_key_file, user, host, command)   ##Cmd Exec Status: $?\''
            else:
                ssh_command = 'ssh -l %s  %s  %s' % (user, host, command)   ##Cmd Exec Status: $?\''

        error_msg = ""
        print "cmd - " + str(ssh_command)
        ssh_process = pexpect.spawn(ssh_command)
        ssh_process.timeout=400
        
        ret = ssh_process.expect([pexpect.TIMEOUT, ssh_prompt, 'assword: ', pexpect.EOF, 'passphrase for key'])
        
        # Case: Timeout
        if ret == 0:
            print 'SSH could not login: {0}'.format(host)
            error_msg += 'SSH could not login: %s'%host
            print "Before - {0}".format(ssh_process.before)
            print "After - {0}".format(ssh_process.after)
            
            if return_code:return error_msg, ssh_process.exitstatus
            else:return error_msg
        
        # Case: SSH may have the public key
        if ret == 3:
            ssh_process.sendline ('yes')
            ret1 = ssh_process.expect([pexpect.TIMEOUT, 'password: '])
            print 'RSA Key added'
        
        # Case: SSH does not have the public key
        if ret == 1:
            ssh_process.sendline ('yes')
            ret1 = ssh_process.expect([pexpect.TIMEOUT, 'password: '])
            # Timeout
            if ret1 == 0:
                print 'SSH could not login: %s'%host
                error_msg += 'SSH could not login: %s'%host
                print "Before - {0}".format(ssh_process.before)
                print "After - {0}".format(ssh_process.after)
                                
                if return_code:return error_msg, ssh_process.exitstatus
                else:return error_msg
        
        # Case: When asking for ssh passphrase.
        if ret == 4:
            ssh_process.sendline(ssh_passphrase)
        
        if ret == 4:
            '''
            Skip entering the password because no need to send password in case if it is working with passphrase 
            '''
            pass
        else:
            ssh_process.sendline(password)
        
        ret = ssh_process.expect([pexpect.TIMEOUT, pexpect.EOF])
        if ret == 0:
            print 'SSH could not login: {0}'.format(host)
            error_msg += 'SSH could not login: %s'%host
            if return_code:return error_msg, ssh_process.exitstatus
            else:return error_msg
        else:
            print "Output - \n{0}".format(ssh_process.before.strip()) 
            if return_code:return ssh_process.before.strip(), ssh_process.exitstatus
            else:return ssh_process.before.strip()
            
    except Exception, emsg:
        print "ssh Exc > host - {0}, command - {1}, emsg - {2}".format(host, command, str(emsg))
        return "", 0
    
output = ssh_command(host="127.0.0.1", user="ram", password="ram", command="ls /tmp/")
print output



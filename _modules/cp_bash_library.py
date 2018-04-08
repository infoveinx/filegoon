# -*- coding: utf-8 -*-

# Import python libs
from __future__ import absolute_import
import logging
import subprocess
import os

# Import salt libs
import salt.utils.files
from salt.exceptions import CommandExecutionError, SaltInvocationError

LOG = logging.getLogger(__name__)

# Define the module's virtual name
__virtualname__ = 'sshjail'

def __virtual__():
    '''
    Confirm this module is on a Linux based system
    '''
    if __grains__['kernel'] == 'Linux':
        return __virtualname__
    return (False, 'The sshjail module could not be loaded: unsupported kernel')

def sys_files(jailhome='/tmp', saltenv='base', rsync=False):
    '''
    A function to copy bash and optionally rsync libraries to sshjail path

    CLI Example:

        salt '*' sshjail.sys_files 
    '''
    # Get list of bash libraries
    proc = subprocess.check_output(["ldd", "/bin/bash"])
    lib_names = []
        
    for line in proc.splitlines():
        if 'vdso' not in line: 
            line = line.split()
            lib_names.append(line[0])

    if rsync:
        if salt.utils.which('rsync'):
            # Get list of rsync libraries
            proc = subprocess.check_output(["ldd", "/usr/bin/rsync"])
            for line in proc.splitlines():
                if 'vdso' not in line and 'lib64' not in line and 'libc' not in line:
                    line = line.split()
                    lib_names.append(line[0])
        else:
            LOG.error('rsync not insalled')

    # iterate through list and build paths for copying files    
    for line in lib_names:
        if 'lib64' in line:
            dest_dir = 'lib64'
            tmp_file = os.path.basename(line)
            src_file = '/' + dest_dir + '/' + tmp_file
            dest_file = os.path.join(
                jailhome,
                dest_dir,
                tmp_file 
            )
        else:
            dest_dir = 'lib'
            src_file = '/lib/x86_64-linux-gnu/' + line
            dest_file = os.path.join(
                jailhome,
                dest_dir,
                line
            )
        try:
            if os.path.exists(os.path.dirname(dest_file)):
                result = True
                sfn = __salt__['cp.cache_file'](src_file, saltenv)
                LOG.info('Copying {0} to {1}'.format(src_file, dest_file))
                salt.utils.files.copyfile(sfn, dest_file)
            else:
                LOG.error('Path does not exist: {0}'.format(
                    os.path.dirname(dest_file))
                )
                result = False
                break
            mask = os.umask(0)
            os.umask(mask)
            # Apply umask and remove exec bit
            mode = (0o0777 ^ mask) & 0o0666
            # Set permissions on files
            if 'lib64' in dest_file:
                os.chmod(dest_file, 0755)
            else:
                os.chmod(dest_file, mode)
        except (IOError, OSError) as e:
            raise CommandExecutionError('Problem copying {0}'.format(e))

    return result


def exec_files(jailhome='/tmp', filelist=None, saltenv='base', rsync=False):
    '''
    A function to copy executable files to sshjail path

    CLI Example:

        salt '*' sshjail.exec_files filelist=["/path/file1", "/path/file2"]
    '''
    if filelist:
        filelist.append('/bin/bash')
        if rsync:
            filelist.append('/usr/bin/rsync')
        for file in filelist:
            dest_dir = 'bin'
            tmp_file = os.path.basename(file)
            dest_file = os.path.join(
                jailhome,
                dest_dir,
                tmp_file
            )
            try:
                if os.path.exists(os.path.dirname(dest_file)):
                    result = True
                    sfn = __salt__['cp.cache_file'](file, saltenv)
                    LOG.info('Copying {0} to {1}'.format(file, dest_file))
                    salt.utils.files.copyfile(sfn, dest_file)
                else:
                    LOG.error('Path does not exist: {0}'.format(
                        os.path.dirname(dest_file))
                    )
                    result = False
                    break
                os.chmod(dest_file, 0755)

            except (IOError, OSError) as e:
                raise CommandExecutionError('Problem copying {0}'.format(e))
    else:
        return False

    return result

def etc_files(jailhome='/tmp', filelist=[], saltenv='base'):
    '''
    A function to copy etc files to sshjail path

    CLI Example:

        salt '*' sshjail.etc_files filelist=["/etc/file1", "/etc/file2"]
    '''
    filelist.append('/etc/passwd')
    filelist.append('/etc/group')
    for file in filelist:
        dest_dir = 'etc'
        tmp_file = os.path.basename(file)
        dest_file = os.path.join(
            jailhome,
            dest_dir,
            tmp_file
        )
        try:
            if os.path.exists(os.path.dirname(dest_file)):
                result = True
                sfn = __salt__['cp.cache_file'](file, saltenv)
                LOG.info('Copying {0} to {1}'.format(file, dest_file))
                salt.utils.files.copyfile(sfn, dest_file)
            else:
                LOG.error('Path does not exist: {0}'.format(
                    os.path.dirname(dest_file))
                )
                result = False
                break
            os.chmod(dest_file, 0644)

        except (IOError, OSError) as e:
            raise CommandExecutionError('Problem copying {0}'.format(e))

    return result
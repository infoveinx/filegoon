# filegoon
---

## Requirements
* [Saltstack](https://saltstack.com/)
* [Lsyncd](https://github.com/axkibe/lsyncd)
* OpenSSH
* Rsync
* Optionally: Samba
---

## Description
Lsyncd-based file sync for shell accounts and optionally Samba shares.  Drag and drop files into the outbound folder to have it send files to a remote location.  Both locations must exchange public ssh keys if for instance you want to send files both ways.  The same applies to shell only where you copy files at prompt as opposed to using Samba.

Salt states are in the filegoon directory from this repo.  There is also a custom module that handles copying files around on the minion such as rsync.  This module can be used to create a fully functioning ssh jail.  The module was essentially created so that filegoon remotes are in jails to increase security.  

This setup uses a custom compiled lsyncd binary because it required features of lsyncd not present in distros.  Required features included ssh key overrides.  See the repo for details at [https://github.com/axkibe/lsyncd](https://github.com/axkibe/lsyncd)

By default the states will use the home path of the filegoon user as the default Samba share.  You can ovverride this in pillar with the user that you wish to use for Samba file share access.   

**Caveats**
* /etc/ssh/sshd_config is edited to make the jailed parts work
* Samba and smb.conf is assumed to be installed and working.  An append will be added to the end of the config for the filegoon path.  The config is backed up on first salt run and only on first run prior to append.
* Requires Debian for now but probably also works with Ubuntu.
---

## Future Plans
* Docker containers in lieu of jails

{% import slspath+'/map.jinja' as jail with context %}

configure_sshd_sftp:
  file.comment:
    - name: /etc/ssh/sshd_config
    - regex: '^Subsystem sftp /usr/lib/openssh/sftp-server'

configure_sshd_jail_group:
  file.append:
    - name: /etc/ssh/sshd_config
    - text: |
        Subsystem sftp internal-sftp

        # Apply chroot jail to group {{ jail.group }} 
        Match Group {{ jail.group }} 
          ChrootDirectory %h
          AuthorizedKeysFile %h/.ssh/authorized_keys
          X11Forwarding no
          AllowTcpForwarding no

ssh:
  service.running:
    - watch:
      - file: configure_sshd_sftp
      - file: configure_sshd_jail_group


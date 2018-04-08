{% import slspath+'/map.jinja' as jail with context %}

backup_config:
  cmd.run:
    - name: cp /etc/samba/smb.conf /etc/samba/smb.conf.orig
    - unless: test -f /etc/samba/smb.conf.orig

{% for user, configs in jail.users %}
create_samba_share:
  file.append:
    - name: /etc/samba/smb.conf
    - source: salt://{{ slspath }}/templates/smb.conf.j2
    - template: jinja
    - context:
        jail_home: {{ configs['config']['home'] }}/files
        {% if jail.samba_user is defined %}
        samba_user: {{ jail.samba_user }}
        {% else %}
        samba_user: {{ user }}
        {% endif %}
        {% if jail.samba_group is defined %}
        samba_group: {{ jail.samba_group }}
        {% else %}
        samba_group: {{ jail.group }}
        {% endif %}
        {% if jail.samba_path is defined %}
        samba_path: {{ jail.samba_path }}
        {% else %}
        samba_path: filesync-{{ user }}
        {% endif %}
  service.running:
    - name: smbd
    - enable: True
    - watch:
      - file: /etc/samba/smb.conf 
{% endfor %}    

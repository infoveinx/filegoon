{% import slspath+'/map.jinja' as jail with context %}
{% set filesync_dirs = ['inbound', 'outbound'] %}

# add users
{% for user, args in jail.users %}
{{ user }}:
  group.present:
    - gid: {{ args['config']['uid'] }}
  user.present:
    - uid: {{ args['config']['uid'] }}
    - gid: {{ args['config']['uid'] }}
    - shell: /bin/bash
    - home: {{ args['config']['home'] }}
    - groups:
      - {{ jail.group }} 

# change perms to root:root for user home 
{{ args['config']['home'] }}:
  file.directory:
    - makedirs: True
    - user: root
    - group: root
    - dir_mode: 0755

{% if args['config']['ssh-keys'] %}
{{ user }}_key:
  ssh_auth.present:
    - user: {{ user }}
    - names:
      {% for key in args['config']['ssh-keys'] %}
      - {{ key }}
      {% endfor %}
{% endif %}

# ensure .ssh directory
{{ args['config']['home'] }}/.ssh:
  file.directory:
    - user: {{ user }}
    - group: {{ user }}
    - dir_mode: 0700

# add private key 
generate_ssh_key:
  cmd.run:
    - name: ssh-keygen -t rsa -b 4096 -q -N '' -f {{ args['config']['home'] }}/.ssh/id_rsa
    - runas: {{ user }}
    - unless: test -f {{ args['config']['home'] }}/.ssh/id_rsa

# create lsync structure if values in pillar
{% if args['lsyncd'] is defined %}
# populate known hosts
{{ args['lsyncd']['remote_host'] }}:
  ssh_known_hosts:
    - present
    - user: {{ user }}

# create filesync dirs
{% for dir in filesync_dirs %}
{{ args['config']['home'] }}/files/{{ dir }}:
  file.directory:
    - makedirs: True
    - user: {{ user }}
    {% if jail.samba_group is defined %} 
    - group: {{ jail.samba_group }}
    {% else %}
    - group: {{ user }}
    {% endif %}
    - dir_mode: 2770
{% endfor %}

{% if jail.samba_group is defined %} 
setgid_on_inbound:
  file.directory:
    - name: {{ args['config']['home'] }}/files/inbound
    - dir_mode: 2770
{% endif %}
{% endif %}
{% endfor %}

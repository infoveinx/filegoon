{% import slspath+'/map.jinja' as jail with context %}

# required directories in jail
{% for user, configs in jail.users %}
{% for dir in jail.directories %} 
{{ configs['config']['home'] }}/{{ dir }}:
  file.directory:
    - makedirs: True
    - user: root
    - group: root
    - dir_mode: 0755
    - recurse:
      - user
      - group
      - mode
{% endfor %}
    
# create /dev nodes
{% for name, args in jail.dev_nodes %}
{{ configs['config']['home'] }}/dev/{{ name }}:
  file.mknod:
    - ntype: {{ args['ntype'] }} 
    - major: {{ args['major'] }} 
    - minor: {{ args['minor'] }} 
    - user: root
    - group: root
    - mode: 666
{% endfor %}

copy_bash_libaries:
  module.run:
    - sshjail.sys_files:
      - jailhome: {{ configs['config']['home'] }}
      - rsync: True
    
copy_binary_files:
  module.run:
    - sshjail.exec_files:
      - jailhome: {{ configs['config']['home'] }}
      - filelist: {{ jail.exec_files }}
      - rsync: True
    - require:
      - file: {{ configs['config']['home'] }}/bin

copy_etc_files:
  module.run:
    - sshjail.etc_files:
      - jailhome: {{ configs['config']['home'] }}
{% endfor %}

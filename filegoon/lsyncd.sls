{% import slspath+'/map.jinja' as jail with context %}
{% set lsyncd_dirs = ['bin', 'etc'] %}

# create lsyncd directory structure
{% for dir in lsyncd_dirs %}
{{ jail.lsyncd_home }}/{{ dir }}:
  file.directory:
    - makedirs: True
    - user: root
    - group: root
    - dir_mode: 755
{% endfor %}

install_lsyncd_binary:
  file.managed: 
    - name: {{ jail.lsyncd_home }}/bin/lsyncd
    - source: {{ jail.lsyncd_source }}
    - source_hash: {{ jail.lsyncd_hash }}
    - mode: 0755
    - user: root
    - group: root
    - require:
      - file: {{ jail.lsyncd_home }}/bin

{% for user, args in jail.users %}

# create lsyncd config for user
{{ jail.lsyncd_home }}/etc/lsyncd.conf.{{ user }}.lua:
  file.managed:
    - source: salt://{{ slspath }}/templates/lsyncd.conf.lua.j2
    - template: jinja
    - user: {{ user }}
    - delete_flag: {{ jail.lsyncd_delete }}
    - source_dir: {{ args['lsyncd']['source_dir'] }}
    - remote_host: {{ args['lsyncd']['remote_host'] }}
    - remote_dir: {{ args['lsyncd']['remote_dir'] }}
    - delay: {{ args['lsyncd']['delay'] }}
    - bw_limit: {{ args['lsyncd']['bw_limit'] }}
    - key_path: {{ args['lsyncd']['key_path'] }}
    {% if jail.samba_group is defined %}
    - samba_group: {{ jail.samba_group }}
    {% endif %}
    - require:
      - file: {{ jail.lsyncd_home }}/etc

lsyncd_systemd_unit_{{ user }}:
  file.managed:
    - name: /etc/systemd/system/lsyncd-{{ user }}.service
    - source: salt://{{ slspath }}/templates/lsyncd_systemd.j2
    - template: jinja
    - lsyncd_user: {{ user }}
    - lsyncd_home: {{ jail.lsyncd_home }}
  module.run:
    - name: service.systemctl_reload
    - onchanges:
      - file: lsyncd_systemd_unit_{{ user }} 

lsyncd_running:
  service.running:
    - name: lsyncd-{{ user }} 
    - enable: True
    - watch:
      - module: lsyncd_systemd_unit_{{ user }}
      - file: {{ jail.lsyncd_home }}/etc/lsyncd.conf.{{ user }}.lua
{% endfor %}

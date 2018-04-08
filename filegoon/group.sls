{% import slspath+'/map.jinja' as jail with context %}

create_jail_group:
  group.present:
  {% for k, v in jail.group_config %}
    - {{ k }}: {{ v }}
  {% endfor %}

  

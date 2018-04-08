{% import slspath+'/map.jinja' as jail with context %}

install_packages:
  pkg.installed:
    - pkgs: {{ jail.packages }}


{% set apache2 = pillar['apache2'] %}

apach2 install:
  pkg.installed:
    - pkgs:
      - apache2

{% if apache2['remove-default-html'] == True %}
remove_default_index.html:
  file.absent:
    - name: /var/www/html/index.html
    - require:
      - pkg: apache2
{% endif %}

{% if salt['pillar.get']('apache2:config') %}
{% for file in salt['pillar.get']('apache2:config') %}
/etc/apache2/{{ file }}:
  file.managed:
    - contents_pillar: apache2:config:{{ file }}:contents
    - user: www-data
    - group: www-data
    - mode: 644
    - require:
      - pkg: apache2
{% endfor %}
{% endif %}

apache2:
  pkg.installed: []
  service.running:
  - enable: true
  - require:
    - pkg: apache2
{% if salt['pillar.get']('apache2:config') %}
  - watch:
{% for file in salt['pillar.get']('apache2:config') %}
    - file: /etc/apache2/{{ file }}
{% endfor %}
{% endif %}

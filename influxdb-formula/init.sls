{% set influxdb = pillar['influxdb'] %}

influxdb dependencies:
  pkg.installed:
    - pkgs:
      - python3-influxdb
      - python3-toml
    - reload_modules: true

add influx repo:
  pkgrepo.managed:
    - humanname: InfluxDB Repo
    - name: deb https://repos.influxdata.com/ubuntu focal stable
    - dist: focal
    - file: /etc/apt/sources.list.d/influxdb.list
    - key_url: https://repos.influxdata.com/influxdb.key

install influxdb:
  pkg.installed:
    - name: influxdb
    - require:
      - pkgrepo: add influx repo

{% if salt['pillar.get']('influxdb:config') %}
create influxdb config:
  file.serialize:
    - name: /etc/influxdb/influxdb.conf
    - dataset_pillar: influxdb:config
    - formatter: toml
    - user: root
    - group: root
    - mode: 644
    - require:
      - influxdb dependencies
{% endif %}

influxdb:
  service.running:
    - require:
      - pkg: install influxdb
    {% if salt['pillar.get']('influxdb:config') %}
    - watch:
      - file: /etc/influxdb/influxdb.conf
    {% endif %}

{% if salt['pillar.get']('influxdb:database') %}
  {% for database in salt['pillar.get']('influxdb:database') %}
influxdb configuration {{ database }}:
  influxdb_database.present:
    - name: {{ database }}
    - retry:
      - attempts: 5
      - interval: 10
    - require:
      - pkg: influxdb
  {% endfor %}

  {% if salt['pillar.get']('influxdb:retention') %}
    {% for policy in salt['pillar.get']('influxdb:retention') %}
      {% for name, database, duration, replication in salt['pillar.get']('influxdb:retention:{{ policy }}', {}).items() %}
influxdb retention policy {{ policy }}:
   influxdb_retention_policy.present:
    - name: {{ name }}
    - database: {{ database }}
    - duration: {{ duration }}
    - replication: {{ replication }}
    - require:
      - pkg: influxdb
      {% endfor %}
    {% endfor %}
  {% endif %}

{% endif %}

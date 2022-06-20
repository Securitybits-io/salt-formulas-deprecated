{% set grafana = pillar['grafana'] %}

grafana dependencies:
  pkg.installed:
    - pkgs:
      - apt-transport-https
      - software-properties-common
      - python3-toml

add grafana repo:
  pkgrepo.managed:
    - humanname: Grafana Repo
    - name: deb https://packages.grafana.com/oss/deb stable main
    - dist: stable
    - file: /etc/apt/sources.list.d/grafana.list
    - key_url: https://packages.grafana.com/gpg.key

install grafana:
  pkg.installed:
    - name: grafana
    - version: {{ grafana['version'] }}
    - hold: {{ grafana['hold'] | default(False) }}
    - require:
      - pkgrepo: add grafana repo

grafana-server:
  service.running:
    - restart: {{ grafana['restart'] | default(True) }}
    - enable: {{ grafana['enable'] | default(True) }}
    - require:
      - install grafana
    - watch:
      - pkg: grafana
      {% if salt['pillar.get']('grafana:config', {}) %}
      - file: /etc/grafana/grafana.ini
      {% endif %}
      {% if salt['pillar.get']('grafana:provisioning:dashboards', {}) %}
      - file: /etc/grafana/provisioning/dashboards/*.yaml
      {% endif %}
      {% if salt['pillar.get']('grafana:provisioning:datasources', {}) %}
      - file: /etc/grafana/provisioning/datasources/*.yaml
      {% endif %}
      {% if salt['pillar.get']('grafana:provisioning:notifiers', {}) %}
      - file: /etc/grafana/provisioning/notifiers/*.yaml
      {% endif %}
      {% if salt['pillar.get']('grafana:provisioning:plugins', {}) %}
      - file: /etc/grafana/provisioning/plugins/*.yaml
      {% endif %}

{% if salt['pillar.get']('grafana:config') %}
create grafana config:
  file.serialize:
    - name: /etc/grafana/grafana.ini
    - dataset_pillar: grafana:config
    - formatter: toml
    - user: root
    - group: grafana
    - mode: 640
    - require:
      - grafana dependencies
      - install grafana
{% endif %}

{% if salt['pillar.get']('grafana:plugins') %}
{% for plugin in salt['pillar.get']('grafana:plugins') %}
install plugin {{ plugin }}:
  cmd.run:
    - name: grafana-cli plugins install {{ plugin }}
    - creates: /var/lib/grafana/plugins/{{ plugin }}
    - require:
      - install grafana

{% endfor %}

restart grafana:
  cmd.run:
    - name: systemctl restart grafana-server.service
    - require:
      - install grafana
{% endif %}



{% if salt['pillar.get']('grafana:provisioning') %}
{% if salt['pillar.get']('grafana:provisioning:dashboards') %}
{% set dashboard_provision = salt['pillar.get']('grafana:provisioning:dashboards_parent_path') %}
create dashboard provisioning folder:
  file.directory:
    - name: {{ dashboard_provision }}
    - user: grafana
    - group: grafana
    - dir_mode: 0751
    - require:
      - install grafana

{% for dashboard in salt['pillar.get']('grafana:provisioning:dashboards') %}
/etc/grafana/provisioning/dashboards/{{ dashboard }}.yaml:
  file.serialize:
    - dataset_pillar: grafana:provisioning:dashboards:{{ dashboard }}
    - formatter: yaml
    - user: root
    - group: grafana
    - file_mode: 640
    - dir_mode: 751
    - include_empty: true
    - require:
      - install grafana

create provision folder {{ dashboard }}:
  file.directory:
    - name: {{ dashboard_provision }}/{{ dashboard }}
    - user: grafana
    - group: grafana
    - dir_mode: 0751
    - require:
      - install grafana
      - create dashboard provisioning folder
{% endfor %}
{% endif %}

{% if salt['pillar.get']('grafana:provisioning:datasources') %}
{% for datasource in salt['pillar.get']('grafana:provisioning:datasources') %}
/etc/grafana/provisioning/datasources/{{ datasource }}.yaml:
  file.serialize:
    - dataset_pillar: grafana:provisioning:datasources:{{ datasource }}
    - formatter: yaml
    - user: root
    - group: grafana
    - file_mode: 640
    - dir_mode: 751
    - include_empty: true
    - require:
      - install grafana
{% endfor %}
{% endif %}

{% if salt['pillar.get']('grafana:provisioning:notifiers') %}
{% for notifier in salt['pillar.get']('grafana:provisioning:notifiers') %}
/etc/grafana/provisioning/notifiers/{{ notifier }}.yaml:
  file.serialize:
    - dataset_pillar: grafana:provisioning:notifiers:{{ notifier }}
    - formatter: yaml
    - user: root
    - group: grafana
    - file_mode: 640
    - dir_mode: 751
    - include_empty: true
    - require:
      - install grafana
{% endfor %}
{% endif %}

{% if salt['pillar.get']('grafana:provisioning:plugins') %}
{% for plugin in salt['pillar.get']('grafana:provisioning:plugins') %}
/etc/grafana/provisioning/plugins/{{ plugin }}.yaml:
  file.serialize:
    - dataset_pillar: grafana:provisioning:plugins:{{ plugin }}
    - formatter: yaml
    - user: root
    - group: grafana
    - file_mode: 640
    - dir_mode: 751
    - include_empty: true
    - require:
      - install grafana
{% endfor %}
{% endif %}
{% endif %}

{% if salt['pillar.get']('grafana:dashboards') %}
{% set dashboard_provision = salt['pillar.get']('grafana:provisioning:dashboards_parent_path') %}
  {% for dashboards, dashboards_items in salt['pillar.get']('grafana:dashboards', {}).items() %}
    {% for dashboard, dashboard_config in dashboards_items.items() %}

create {{ dashboard }} dashboard json:
  file.serialize:
    - name: {{ dashboard_provision }}/{{ dashboards }}/{{ dashboard }}.json
    - dataset_pillar: grafana:dashboards:{{ dashboards }}:{{ dashboard }}
    - formatter: json
    - user: grafana
    - group: grafana
    - file_mode: 640
    - require:
      - install grafana

    {% endfor %}
  {% endfor %}
{% endif %}

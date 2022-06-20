{% set varken = pillar['varken'] %}
varken dependencies:
  pkg.installed:
    - pkgs:
      - git
      - python3
      - python3-pip
      - python3-distutils
      - python3-toml

clone varken repo:
  git.cloned:
    - name: https://github.com/Boerderij/Varken.git
    - target: /opt/varken
    - branch: {{ varken['branch'] }}
    - require:
      - varken dependencies

add varken group:
  group.present:
    - name: varken

add varken user:
  user.present:
    - fullname: Varken user
    - name: varken
    - shell: /bin/nologin
    - createhome: False
    - groups:
      - varken
    - require:
      - add varken group

change varken permissions:
  file.directory:
    - name: /opt/varken
    - user: varken
    - group: varken
    - recurse:
      - user
      - group
    - require:
      - add varken user
      - clone varken repo

install varken requirements:
  cmd.run:
    - name: python3 -m pip install -r requirements.txt
    - cwd: /opt/varken
    - require:
      - clone varken repo

add varken service file:
  file.managed:
    - name: /lib/systemd/system/varken.service
    - user: root
    - group: root
    - mode: 0777
    - require:
      - install varken requirements
    - contents: |
        [Unit]
        Description=Varken - Command-line utility to aggregate data from the Plex ecosystem into InfluxDB.
        After=network-online.target
        StartLimitInterval=200
        StartLimitBurst=3

        [Service]
        Type=simple
        User=varken
        Group=varken
        WorkingDirectory=/opt/varken
        ExecStart=python3 /opt/varken/Varken.py
        Restart=always
        RestartSec=30

        [Install]
        WantedBy=multi-user.target

{% if salt['pillar.get']('varken:config') %}
create varken config:
  file.managed:
    - name: /opt/varken/data/varken.ini
    - contents_pillar: varken:config
    - user: varken
    - group: varken
    - mode: 644
    - require:
      - install varken requirements
{% endif %}

service.systemctl_reload:
  module.run:
    - onchanges:
      - file: /lib/systemd/system/varken.service
    - require:
      - add varken service file

varken:
  service.running:
    - enable: true
    - require:
      - add varken service file

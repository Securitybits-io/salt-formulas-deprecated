{% set sonarr = pillar['sonarr'] %}
{% if sonarr['install'] == True %}
sonarr dependencies:
  pkg.installed:
    - pkgs:
      - libmono-cil-dev
      - curl
      - mediainfo

add sonarr repo:
  pkgrepo.managed:
    - humanname: Sonarr Repo
    - name: deb https://apt.sonarr.tv/ubuntu focal main
    - file: /etc/apt/sources.list.d/sonarr.list
    - keyid: "2009837CBFFD68F45BC180471F4F90DE2A9B4BF8"
    - keyserver: keyserver.ubuntu.com

install sonarr:
  pkg.installed:
    - name: sonarr
    - version: {{ sonarr['version'] }}
    - require:
      - sonarr dependencies
      - add sonarr repo
{# 
add sonarr service file:
  file.managed:
    - name: /lib/systemd/system/sonarr.service
    - user: root
    - group: root
    - mode: 0777
    - require:
      - install sonarr
    - contents: |
        [Unit]
        Description=Sonarr Daemon
        After=network.target

        [Service]
        User=root
        Group=root
        ExecStart=/usr/bin/mono --debug /opt/NzbDrone/NzbDrone.exe -nobrowser

        Type=simple
        TimeoutStopSec=20
        KillMode=process
        Restart=on-failure

        [Install]
        WantedBy=multi-user.target

service.systemctl_reload:
  module.run:
    - onchanges:
      - file: /lib/systemd/system/sonarr.service
    - require:
      - add sonarr service file 
#}

sonarr:
  service.running:
    - enable: true
    - require:
      - install sonarr
      #- add sonarr service file
{% endif %}

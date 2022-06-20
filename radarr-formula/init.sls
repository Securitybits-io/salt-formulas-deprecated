{% set radarr = pillar['radarr'] %}
{% if radarr['install'] == True %}
radarr dependencies:
  pkg.installed:
    - pkgs:
      - libcurl4-openssl-dev
      - bzip2
      - curl
      - mediainfo
      - sqlite3

extract radarr:
  archive.extracted:
    - name: /opt
    - source: https://github.com/Radarr/Radarr/releases/download/v3.2.1.5070/Radarr.master.3.2.1.5070.linux-core-x64.tar.gz
    - skip_verify: True
    - user: root
    - group: root

add radarr service file:
  file.managed:
    - name: /lib/systemd/system/radarr.service
    - user: root
    - group: root
    - mode: 0777
    - require:
      - extract radarr
    - contents: |
        [Unit]
        Description=Radarr Daemon
        After=syslog.target network.target

        [Service]
        User=root
        Group=root
        Type=simple
        ExecStart=/opt/Radarr/Radarr -nobrowser -data=/root/.config/Radarr/
        TimeoutStopSec=20
        KillMode=process
        Restart=on-failure

        [Install]
        WantedBy=multi-user.target

service.systemctl_reload:
  module.run:
    - onchanges:
      - file: /lib/systemd/system/radarr.service
    - require:
      - add radarr service file

radarr:
  service.running:
    - enable: true
    - require:
      - add radarr service file
{% endif %}

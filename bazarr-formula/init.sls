{% set bazarr = pillar['bazarr'] %}
{% if bazarr['install'] == True %}
bazarr dependencies:
  pkg.installed:
    - pkgs:
      - git
      - python3
      - python3-pip
      - python3-distutils

clone bazarr repo:
  git.cloned:
    - name: https://github.com/morpheus65535/bazarr
    - target: /opt/bazarr
    - branch: {{ bazarr['branch'] }}
    - require:
      - bazarr dependencies

install bazarr requirements:
  cmd.run:
    - name: python3 -m pip install -r requirements.txt
    - cwd: /opt/bazarr
    - require:
      - clone bazarr repo

add bazarr service file:
  file.managed:
    - name: /lib/systemd/system/bazarr.service
    - user: root
    - group: root
    - mode: 0777
    - require:
      - install bazarr requirements
    - contents: |
        [Unit]
        Description=Bazarr Daemon
        After=syslog.target network.target

        [Service]
        WorkingDirectory=/opt/bazarr/
        User=root
        Group=root
        UMask=0002
        Restart=on-failure
        RestartSec=5
        Type=simple
        ExecStart=/usr/bin/python3 /opt/bazarr/bazarr.py
        KillSignal=SIGINT
        TimeoutStopSec=20
        SyslogIdentifier=bazarr
        ExecStartPre=/bin/sleep 30

        [Install]
        WantedBy=multi-user.target

service.systemctl_reload:
  module.run:
    - onchanges:
      - file: /lib/systemd/system/bazarr.service
    - require:
      - add bazarr service file

bazarr:
  service.running:
    - enable: true
    - require:
      - add bazarr service file
{% endif %}

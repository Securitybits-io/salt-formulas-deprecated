{% set tautulli = pillar['tautulli'] %}
{% if tautulli['install'] == True %}
tautulli dependencies:
  pkg.installed:
    - pkgs:
      - python3
      - python3-setuptools
      - git      

add tautulli group:
  group.present:
    - name: tautulli

add tautulli user:
  user.present:
    - fullname: tautulli user
    - name: tautulli
    - shell: /bin/nologin
    - createhome: False
    - groups:
      - tautulli
    - require:
      - add tautulli group

clone tautulli repo:
  git.cloned:
    - name: https://github.com/Tautulli/Tautulli.git
    - target: /opt/Tautulli
    - branch: {{ tautulli['branch'] }}
    - require:
      - tautulli dependencies

change tautulli permissions:
  file.directory:
    - name: /opt/Tautulli
    - user: tautulli
    - group: tautulli
    - recurse:
      - user
      - group
    - require:
      - clone tautulli repo

add tautulli service file:
  file.managed:
    - name: /lib/systemd/system/tautulli.service
    - user: root
    - group: root
    - mode: 0777
    - require:
      - change tautulli permissions
    - contents: |
        [Unit]
        Description=Tautulli - Stats for Plex Media Server usage
        Wants=network-online.target
        After=network-online.target

        [Service]
        ExecStart=python3 /opt/Tautulli/Tautulli.py --config /opt/Tautulli/config.ini --datadir /opt/Tautulli --quiet --daemon --nolaunch
        GuessMainPID=no
        Type=forking
        User=tautulli
        Group=tautulli
        Restart=on-abnormal
        RestartSec=5
        StartLimitInterval=90
        StartLimitBurst=3

        [Install]
        WantedBy=multi-user.target


service.systemctl_reload:
  module.run:
    - onchanges:
      - file: /lib/systemd/system/tautulli.service
    - require:
      - add tautulli service file

tautulli:
  service.running:
    - enable: true
    - require:
      - add tautulli service file

{% endif %}

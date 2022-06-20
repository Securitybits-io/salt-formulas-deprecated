#Package.transmission init.sls
{% set transmission = pillar['transmission'] %}
# Install package
install transmission:
  pkg.installed:
    - name: transmission-daemon

{% if salt['pillar.get']('transmission:config') %}
stop transmission configure:
  service.dead:
    - name: transmission-daemon
    - require:
      - pkg: install transmission

configure transmission-daemon:
  file.managed:
    - name: /var/lib/transmission-daemon/info/settings.json
    - contents_pillar: transmission:config
    - user: root
    - group: root
    - mode: 777
    - require:
      - stop transmission configure
      - pkg: install transmission
{% endif %}

{% if salt['pillar.get']('transmission:systemd') %}
stop transmission systemd:
  service.dead:
    - name: transmission-daemon
    - require:
      - pkg: install transmission

configure transmission-service:
  file.managed:
    - name: /lib/systemd/system/transmission-daemon.service
    - contents_pillar: transmission:systemd
    - user: root
    - group: root
    - mode: 644
    - require:
      - stop transmission systemd
      - pkg: install transmission

systemctl daemon-reload:
  cmd.run:
    - watch:
      - file: /lib/systemd/system/transmission-daemon.service

{% endif %}


#Enable Package
transmission enabled:
  service.running:
    - name: transmission-daemon
    #- restart: {{ transmission['restart'] | default(True) }}
    - enable: {{ transmission['enable'] | default(True) }}
    - watch:
      - file: /var/lib/transmission-daemon/info/settings.json

{% set jackett = pillar['jackett'] %}
{% if jackett['install'] == True %}
jackett dependencies:
  pkg.installed:
    - pkgs:
      - libcurl4-openssl-dev
      - bzip2
      - mono-devel
      - ca-certificates-mono
      - libmono-cil-dev
      - curl
      - mediainfo

add jackett group:
  group.present:
    - name: jackett

add jackett user:
  user.present:
    - fullname: Jackett user
    - name: jackett
    - shell: /bin/nologin
    - createhome: True
    - groups:
      - jackett
    - require:
      - add jackett group

extract jackett:
  archive.extracted:
    - name: /opt
    - source: https://github.com/Jackett/Jackett/releases/download/{{ jackett['version'] }}/Jackett.Binaries.LinuxAMDx64.tar.gz
    - skip_verify: True
    - user: jackett
    - group: jackett
    - require:
      - add jackett user
      - jackett dependencies

install jackett as a service:
  cmd.script:
    - name: /opt/Jackett/install_service_systemd.sh
    - cwd: /opt/Jackett
    - creates: /etc/systemd/system/jackett.service
    - require:
      - extract jackett
{% endif %}

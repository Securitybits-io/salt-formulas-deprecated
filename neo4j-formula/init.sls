#Package.neo4j init.sls
{% set neo4j = pillar['neo4j'] %}

add neo4j repo:
  pkgrepo.managed:
    - humanname: Neo4j Repo
    - name: deb https://debian.neo4j.com stable {{ neo4j['repo'] }}
    - file: /etc/apt/sources.list.d/neo4j.list
    - key_url: https://debian.neo4j.org/neotechnology.gpg.key

# Install package
install neo4j:
  pkg.installed:
    - name: neo4j
    - version: {{ neo4j['version'] }}
    - hold: {{ neo4j['hold'] | default(False) }}
    - require:
      - add neo4j repo

#Enable Package
neo4j enabled:
  service.running:
    - name: neo4j
    #- restart: {{ neo4j['restart'] | default(True) }}
    - enable: {{ neo4j['enable'] | default(True) }}
    - require:
      - pkg: install neo4j
    - watch:
      - file: /etc/neo4j/neo4j.conf
    {% if salt['pillar.get']('neo4j:password', {}) %}
      - file: /var/lib/neo4j/data/dbms/auth
    {% endif %}


#remove auth file
delete auth file:
  file.absent:
    - name: /var/lib/neo4j/data/dbms/auth
    - require:
      - install neo4j

#set password
set neo4j default password:
  cmd.run:
    - name: neo4j-admin set-initial-password "{{ neo4j['password'] }}"
    - require:
      - delete auth file

#if true set public listen address
{% if neo4j['public_listen_address'] is defined %}
set neo4j public address:
  file.uncomment:
    - name: /etc/neo4j/neo4j.conf
    - regex: dbms.connectors.default_listen_address
    - require:
      - install neo4j

restart neo4j service:
  cmd.run:
    - name: systemctl restart neo4j && touch /etc/neo4j/neo4j.restarted
    - creates: /etc/neo4j/neo4j.restarted
    - require:
      - set neo4j public address
    - order: last
{% endif %}

{% set jkkwebcalendar = pillar['jkkwebcalendar'] %}
{% if jkkwebcalendar['install'] == True %}

jkk webcalendar dependencies:
  pkg.installed:
    - pkgs:
      - git
      - php
      - php-pear
      - php-mysql
    - require:
      - pkg: apache2

#make sure apache2 is installed
#git clone jkk welcalendar
clone jkk webcalendar:
  git.latest:
    - name: https://github.com/Securitybits-io/jkk-webcalendar.git
    - target: {{ jkkwebcalendar['directory'] }}
    - branch: {{ jkkwebcalendar['branch'] }}
    - force_clone: True
    - require:
      - jkk webcalendar dependencies

#set permissions
set www-data permissions:
  file.directory:
    - name: /var/www/html
    - file_mode: 0640
    - dir_mode: 0751
    - user: www-data
    - group: www-data
    - require:
      - clone jkk webcalendar
{% endif %}

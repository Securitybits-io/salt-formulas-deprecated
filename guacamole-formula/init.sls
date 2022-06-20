{% set guacamole = pillar['guacamole'] %}
{% set version = salt['pillar.get']('guacamole:version') %} #https://downloads.apache.org/guacamole/

guacamole dependencies:
  pkg.installed:
    - pkgs:        
        - gcc
        - vim
        - curl
        - wget
        - g++
        - libcairo2-dev
        - libjpeg-turbo8-dev
        - libpng-dev
        - libtool-bin
        - libossp-uuid-dev
        - libavcodec-dev
        - libavutil-dev
        - libswscale-dev
        - build-essential
        - libpango1.0-dev
        - libssh2-1-dev
        - libvncserver-dev
        - libtelnet-dev
        - libssl-dev
        - libvorbis-dev
        - libwebp-dev
        - openjdk-11-jdk
        - freerdp2-dev
        - freerdp2-x11
    - reload_modules: true

##########################################
######### -= Guacamole Server =-##########
##########################################
install tomcat 9:
  pkg.installed:
    - pkgs:
      - tomcat9
      - tomcat9-admin
    - require:
      - guacamole dependencies

download and extract guacamole server source:
  archive.extracted:
    - name: /opt
    - source: https://downloads.apache.org/guacamole/{{ version }}/source/guacamole-server-{{ version }}.tar.gz
    - skip_verify: True
    - user: root
    - group: root
    - trim_output: 10
    - require: 
      - install tomcat 9

configure guacamole:
  cmd.run:
    - name: ./configure --with-init-dir=/etc/init.d
    - creates: /opt/guacamole-server-{{ version }}/Makefile
    - cwd: /opt/guacamole-server-{{ version }}
    - hide_output: True
    - require: 
      - download and extract guacamole server source
  
make guacamole:
  cmd.run:
    - name: make
    - cwd: /opt/guacamole-server-{{ version }}
    - hide_output: True
    - require: 
      - configure guacamole

make install guacamole:
  cmd.run:
    - name: make install
    - cwd: /opt/guacamole-server-{{ version }}
    - hide_output: True
    - require: 
      - make guacamole

ldconfig guacamole:
  cmd.run:
    - name: ldconfig
    - cwd: /opt/guacamole-server-{{ version }}
    - require: 
      - make install guacamole

enable and start guacd:
  service.running:
    - name: guacd
    - enable: True
    - reload: True
    - require: 
      - ldconfig guacamole

##########################################
######### -= Guacamole Client =-##########
##########################################
create guacamole config dir:
  file.directory:
    - name: /etc/guacamole
    - user: root
    - group: root

download guacamole war:
  file.managed:
    - name: /etc/guacamole/guacamole.war
    - source: https://downloads.apache.org/guacamole/{{ version }}/binary/guacamole-{{ version }}.war
    - skip_verify: True
    - user: root
    - group: root
    - require: 
      - create guacamole config dir

link guacamole war file:
  file.symlink:
    - name: /var/lib/tomcat9/webapps/guacamole.war
    - target: /etc/guacamole/guacamole.war
    - require:
      - download guacamole war

set tomcat9 defaults:
  file.managed:
    - name: /etc/default/tomcat9
    - user: root
    - group: root
    - mode: 0644
    - contents: |
        #### !WARNING! This file is managed by Saltstack ####
        # The home directory of the Java development kit (JDK). You need at least
        # JDK version 8. If JAVA_HOME is not set, some common directories for
        # OpenJDK and the Oracle JDK are tried.
        #JAVA_HOME=/usr/lib/jvm/java-8-openjdk

        # You may pass JVM startup parameters to Java here. If you run Tomcat with
        # Java 8 instead of 9 or newer, add "-XX:+UseG1GC" to select a suitable GC.
        # If unset, the default options will be: -Djava.awt.headless=true
        JAVA_OPTS="-Djava.awt.headless=true"

        # To enable remote debugging uncomment the following line.
        # You will then be able to use a Java debugger on port 8000.
        #JAVA_OPTS="${JAVA_OPTS} -agentlib:jdwp=transport=dt_socket,address=8000,server=y,suspend=n"

        # Java compiler to use for translating JavaServer Pages (JSPs). You can use all
        # compilers that are accepted by Ant's build.compiler property.
        #JSP_COMPILER=javac

        # Enable the Java security manager? (true/false, default: false)
        #SECURITY_MANAGER=true

        # Whether to compress logfiles older than today's
        #LOGFILE_COMPRESS=1

        # Guacamole home for config files
        GUACAMOLE_HOME=/etc/guacamole
    - require:
      - install tomcat 9

set guacamole properties:
  file.managed:
    - name: /etc/guacamole/guacamole.properties
    - user: root
    - group: root
    - mode: 0644
    - contents: |
        guacd-hostname: localhost
        guacd-port:     4822
        user-mapping:   /etc/guacamole/user-mapping.xml
        auth-provider:  net.sourceforge.guacamole.net.basic.BasicFileAuthenticationProvider
    - require: 
      - create guacamole config dir

{% if salt['pillar.get']('guacamole:user-mapping') %}
create user mapping xml:
  file.managed:
    - name: /etc/guacamole/user-mapping.xml
    - user: root
    - group: root
    - mode: 0644
    - contents_pillar: guacamole:user-mapping
    - require:
      - create guacamole config dir
{% endif %}




restart tomcat9:
  cmd.run:
    - name: systemctl restart tomcat9

restart guacd:
  cmd.run:
    - name: systemctl restart guacd
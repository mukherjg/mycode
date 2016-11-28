#
{% set current_path = salt['environ.get']('PATH', '/bin:/usr/bin') %}

firewalld:
  service.disabled: []

selinux-state:
  cmd.run:
    - name: setenforce 0

apigee:
  group.present:
    - gid: 4000
  user.present:
    - fullname: "APIGEE admin user"
    - shell: /sbin/nologin
    - home: /opt/apigee
    - uid: 4000
    - gid: 4000
    - groups:
      - apigee

create_apigee_root:
  file.directory:
    - name: /srv/apigee
    - makedirs: True
    - user: apigee
    - group: apigee
    - dir_mode: 755
    - file_mode: 755
    - recurse:
      - user
      - group
      - mode

create_apigee_root_symlink:
  file.symlink:
    - name: /opt/apigee
    - target: /srv/apigee
    - force: True
    - makedirs: True
    - user: apigee
    - group: apigee
    - mode: 755

/tmp/bootstrap.sh:
 file.managed:
   - source: salt://apigee/files/bootstrap.sh
   - user: root
   - group: root
   - mode: 755

apigee_install_dependancies:
  cmd.run:
    - name: '/tmp/bootstrap.sh apigeeuser={{ pillar['apigeerepo']['apigeeuser'] }} apigeepassword={{ pillar['apigeerepo']['apigeepassword'] }}'
    - runas: root
    - cwd: /tmp
    - env:
      - JAVA_HOME: /usr/lib/java 
      - PATH: {{ [current_path, '/usr/lib/java/bin']|join(':') }}
    - require:
      - /tmp/bootstrap.sh
      - create_apigee_root_symlink
      - create_apigee_root
      - apigee 
      - firewalld
      - selinux-state

apigee_install_apigee_service:
  cmd.run:
    - name: /opt/apigee/apigee-service/bin/apigee-service apigee-setup install
    - runas: root
    - cwd: /tmp
    - env:
      - JAVA_HOME: /usr/lib/java
      - PATH: {{ [current_path, '/usr/lib/java/bin']|join(':') }}
    - require:
      - apigee_install_dependancies


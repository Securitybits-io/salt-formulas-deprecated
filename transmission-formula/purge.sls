transmission disable:
  service.dead:
    - name: transmission
    - enable: False

transmission uninstall:
  pkg.purged:
    - name: transmission

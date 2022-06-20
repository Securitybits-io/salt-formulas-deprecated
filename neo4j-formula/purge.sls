neo4j disable:
    service.dead:
        - name: neo4j
        - enable: False

neo4j uninstall:
    pkg.purged:
        - name: neo4j

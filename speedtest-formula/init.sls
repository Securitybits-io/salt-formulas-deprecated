speedtest dependencies:
  pkg.installed:
    - pkgs:
      - python3-influxdb
    - reload_modules: true

install speedtest:
  pip.installed:
    - name: speedtest-cli
    - require:
      - speedtest dependencies

create speedtest script:
  file.managed:
    - name: /opt/measure_internetspeed.py
    - contents: |
        #!/usr/bin/env python3
        import datetime
        import logging
        import os
        import speedtest
        import time
        from influxdb import InfluxDBClient

        logging.basicConfig(level=logging.INFO)
        current_dir = os.path.dirname(os.path.abspath(__file__))
        influxdb_host     = "10.0.40.150"
        influxdb_port     = 8086
        influxdb_database = "internetspeed"
        def persists(measurement, fields, time):
            logging.info("{} {} {}".format(time, measurement, fields))
            influx_client.write_points([{
                "measurement": measurement,
                "time": time,
                "fields": fields
            }])

        influx_client = InfluxDBClient(host=influxdb_host, port=influxdb_port, database=influxdb_database)
        
        def get_speed():
            logging.info("Calculating speed ...")
            s = speedtest.Speedtest()
            s.get_best_server()
            s.download()
            s.upload()
            return s.results.dict()
        
        def loop(sleep):
            current_time = datetime.datetime.utcnow().isoformat()
            speed = get_speed()
            persists(measurement='download', fields={"value": speed['download']}, time=current_time)
            persists(measurement='upload', fields={"value": speed['upload']}, time=current_time)
            persists(measurement='ping', fields={"value": speed['ping']}, time=current_time)
            time.sleep(sleep)
        
        loop (1)
    - user: root
    - group: root
    - mode: "0711"
    - require:
      - install speedtest

speedtest cronjob:
  cron.present:
    - name: /usr/bin/python3 /opt/measure_internetspeed.py & > /dev/null
    - user: root
    - require:
      - create speedtest script
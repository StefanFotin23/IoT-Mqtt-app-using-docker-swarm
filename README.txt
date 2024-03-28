I've made an IoT platform using microservices (docker swarm). It consists of multiple services: Grafana for data visualization with dashboards, Mosquitto MQTT broker, a node-red app that was used for receiving MQTT messages, processing data and enquiring it to the DB (influxDB) and a MQTT Python client, that exposed an GET endpoint providing message and topic for the client to send to the mqtt broker. Also the node-red app was used to send automatic requests (every 1 seconds) to simulate the sensor data flow and also to populate the DB at start (10000 entries or more). I automated this projects deployment using docker swarm, bash scripts for every service that needed (Grafana for creating dashboards for data by every TAG, building docker images for build process etc.) and also a Makefile that was used to integrate every command and the whole app flow in a easy to use way providing various commands for the end user: make all (--build), start, stop, status and logs for every container. I did this project alone, following the requirements asked by the course.


RULARE
run --build ==> make all

stop ==> make stop
start ==> make start

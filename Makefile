.PHONY: all build start status stop logs logs-grafana logs-influxdb logs-mosquitto logs-mqtt-client logs-node-red

NETWORK_NAME := Tema3-IoT_default

all: stop wait build start wait_status

build:
	./build_images.sh
	@if [ -z "$$(docker network ls -q -f name=$(NETWORK_NAME))" ]; then \
		docker network create $(NETWORK_NAME); \
	fi

start:
	docker stack deploy -c deployment.yml Tema3-IoT

status:
	docker stack ps Tema3-IoT

stop:
	docker stack rm Tema3-IoT

logs: logs-grafana logs-influxdb logs-mosquitto logs-mqtt-client logs-node-red

logs-grafana:
	docker service logs Tema3-IoT_grafana

logs-influxdb:
	docker service logs Tema3-IoT_influxdb

logs-mosquitto:
	docker service logs Tema3-IoT_mosquitto

logs-mqtt-client:
	docker service logs Tema3-IoT_mqtt-client

logs-node-red:
	docker service logs Tema3-IoT_node-red

wait:
	sleep 5

wait_status:
	@echo "Waiting for services to be in 'Running' state..."
	@while [ "$$(docker stack ps --filter 'desired-state=Running' --format '{{.CurrentState}}' Tema3-IoT | grep -v 'Running' | wc -l)" -gt 0 ]; do \
		sleep 5; \
	done
	@echo "All services are now in 'Running' state."
	docker stack ps Tema3-IoT

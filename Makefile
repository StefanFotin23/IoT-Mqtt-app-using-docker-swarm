.PHONY: all build start status stop logs logs-grafana logs-influxdb logs-mosquitto logs-mqtt-client logs-node-red create-volumes

NAME := sprc3

all: stop wait create-volumes build start wait_status

build:
	./build_images.sh

start:
	docker stack deploy -c stack.yml $(NAME)

status:
	docker stack ps $(NAME)

stop:
	docker stack rm $(NAME)

logs: logs-grafana logs-influxdb logs-mosquitto logs-mqtt-client logs-node-red

logs-grafana:
	docker service logs $(NAME)_grafana

logs-influxdb:
	docker service logs $(NAME)_influxdb

logs-mosquitto:
	docker service logs $(NAME)_mosquitto

logs-mqtt-client:
	docker service logs $(NAME)_mqtt-client

logs-node-red:
	docker service logs $(NAME)_node-red

wait:
	sleep 5

wait_status:
	@echo "Waiting for services to be in 'Running' state..."
	@while [ "$$(docker stack ps --filter 'desired-state=Running' --format '{{.CurrentState}}' $(NAME) | grep -v 'Running' | wc -l)" -gt 0 ]; do \
		sleep 5; \
	done
	@echo "All services are now in 'Running' state."
	docker stack ps $(NAME)

create-volumes:
	docker volume create $(NAME)_influxdb_data
	docker volume create $(NAME)_grafana_data
	docker volume create $(NAME)_mosquitto_data
	docker volume create $(NAME)_mosquitto_config

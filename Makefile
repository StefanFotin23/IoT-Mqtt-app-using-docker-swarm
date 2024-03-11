.PHONY: all build start status stop logs logs-grafana logs-influxdb logs-mosquitto logs-mqtt-client logs-node-red create-volumes

NAME := sprc3

all: stop wait build start

build:
	@if docker volume inspect $(NAME)_influxdb_data > /dev/null 2>&1; then \
		while [ "$$(docker ps -q -f volume=$(NAME)_influxdb_data | wc -l)" -gt 0 ]; do \
			echo "$(NAME)_influxdb_data is in use."; \
			sleep 5; \
		done; \
		docker volume rm $(NAME)_influxdb_data; \
		echo "Deleted volume: $(NAME)_influxdb_data"; \
	fi
	@if docker volume inspect $(NAME)_grafana_data > /dev/null 2>&1; then \
		while [ "$$(docker ps -q -f volume=$(NAME)_grafana_data | wc -l)" -gt 0 ]; do \
			echo "$(NAME)_grafana_data is in use."; \
			sleep 5; \
		done; \
		docker volume rm $(NAME)_grafana_data; \
		echo "Deleted volume: $(NAME)_grafana_data"; \
	fi
	@if docker volume inspect $(NAME)_mosquitto_data > /dev/null 2>&1; then \
		while [ "$$(docker ps -q -f volume=$(NAME)_mosquitto_data | wc -l)" -gt 0 ]; do \
			echo "$(NAME)_mosquitto_data is in use."; \
			sleep 5; \
		done; \
		docker volume rm $(NAME)_mosquitto_data; \
		echo "Deleted volume: $(NAME)_mosquitto_data"; \
	fi
	@if docker volume inspect $(NAME)_mosquitto_config > /dev/null 2>&1; then \
		while [ "$$(docker ps -q -f volume=$(NAME)_mosquitto_config | wc -l)" -gt 0 ]; do \
			echo "$(NAME)_mosquitto_config is in use."; \
			sleep 5; \
		done; \
		docker volume rm $(NAME)_mosquitto_config; \
		echo "Deleted volume: $(NAME)_mosquitto_config"; \
	fi
	./build_images.sh
	docker volume create $(NAME)_influxdb_data
	docker volume create $(NAME)_grafana_data
	docker volume create $(NAME)_mosquitto_data
	docker volume create $(NAME)_mosquitto_config

start:
	docker stack deploy -c stack.yml $(NAME)
	@echo "Waiting for services to be in 'Running' state..."
	@while [ "$$(docker stack ps --filter 'desired-state=Running' --format '{{.CurrentState}}' $(NAME) | grep -v 'Running' | wc -l)" -gt 0 ]; do \
		sleep 5; \
	done
	@echo "All services are now in 'Running' state."
	docker stack ps $(NAME)

status:
	docker stack ps $(NAME)

stop:
	docker stack rm $(NAME)

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
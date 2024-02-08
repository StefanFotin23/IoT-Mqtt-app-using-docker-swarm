#!/bin/bash

# Build MQTT Client Docker image
docker build -t mqtt-client-image -f mqtt-client/Dockerfile-mqtt-client .

# Build Mosquitto Server Docker image
docker build -t mosquitto-server -f mosquitto/Dockerfile-mosquitto .

# Build Node-Red Client Docker image
docker build -t node-red-client -f node-red/Dockerfile-node-red .

# Build Grafana Docker image
docker build -t grafana-server -f grafana/Dockerfile-grafana .

# Build Ngrok Docker Image
docker build -t ngrok-server -f ngrok/Dockerfile-ngrok .
#!/bin/bash

# Build MQTT Client Docker image
docker build -t mqtt-client-image:latest -f mqtt-client/Dockerfile-mqtt-client .

# Build Mosquitto Server Docker image
docker build -t mosquitto-server:latest -f mosquitto/Dockerfile-mosquitto .

# Build Node-Red Client Docker image
docker build -t node-red-client -f node-red/Dockerfile-node-red .
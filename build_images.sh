#!/bin/bash

# Install required tools in ubuntu
#sudo apt install -y maven
# Build the Java jar
#mvn clean install -f pom.xml

# Build MQTT Client Docker image
docker build -t mqtt-client-image:latest -f mqtt-client/Dockerfile-mqtt-client .

# Build Mosquitto Server Docker image
docker build -t mosquitto-server:latest -f mosquitto/Dockerfile-mosquitto .
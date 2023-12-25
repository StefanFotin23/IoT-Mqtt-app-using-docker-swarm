#!/bin/sh

DIR=`pwd`

cd /data

# Install Node-RED nodes
npm install node-red-contrib-influxdb


cd "$DIR"
npm start -- --userDir /data

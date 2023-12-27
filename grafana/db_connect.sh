#!/bin/bash

# Wait for InfluxDB to be ready
until curl -G "http://sprc3_influxdb:8086/ping" >/dev/null 2>&1; do
    echo "Waiting for InfluxDB..."
    sleep 5
done

# Create InfluxDB data source in Grafana
curl -XPOST -H "Content-Type: application/json" \
    -u admin:grafana_password \
    http://sprc3_grafana:3000/api/datasources \
    -d @- <<EOF
{
    "name": "InfluxDB",
    "type": "influxdb",
    "url": "http://sprc3_influxdb:8086",
    "access": "proxy",
    "database": "iot_data",
    "user": "admin",
    "password": "grafana_password",
    "basicAuth": false
}
EOF

echo "Grafana data source configured successfully."

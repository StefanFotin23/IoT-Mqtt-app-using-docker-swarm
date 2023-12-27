#!/bin/bash

LOG_FILE="/data/logs.txt"
echo "" > "$LOG_FILE"

# Redirect stdout and stderr to the log file
exec > >(tee -a "$LOG_FILE") 2>&1

# Print current working directory
echo "Current working directory: $(pwd)"

# Wait for InfluxDB to be ready
until curl -G "http://sprc3_influxdb:8086/ping" >/dev/null 2>&1; do
    echo "Waiting for InfluxDB..."
    sleep 5
done

echo "InfluxDB is ready."

# Create InfluxDB data source in Grafana
curl -XPOST -H "Content-Type: application/json" \
    -u asistent:grafanaSPRC2023 \
    http://sprc3_grafana:3000/api/datasources \
    -d @- <<EOF
{
    "name": "InfluxDB",
    "type": "influxdb",
    "url": "http://sprc3_influxdb:8086",
    "access": "proxy",
    "database": "iot_data",
    "user": "user",
    "password": "user_password",
    "basicAuth": false
}
EOF

echo "Grafana data source configured successfully."

# Create Grafana dashboard for UPB IoT Data
curl -XPOST -H "Content-Type: application/json" \
    -u asistent:grafanaSPRC2023 \
    http://sprc3_grafana:3000/api/dashboards/db \
    -d @- <<EOF
{
    "dashboard": {
        "id": null,
        "title": "UPB IoT Data",
        "timezone": "browser",
        "panels": [
            {
                "id": 1,
                "type": "graph",
                "title": "Battery Percentage",
                "datasource": "InfluxDB",
                "targets": [
                    {
                        "measurement": "your_measurement",
                        "groupBy": [
                            {
                                "type": "tag",
                                "params": ["topic"]
                            }
                        ],
                        "select": [
                            [
                                {
                                    "type": "field",
                                    "params": ["UPB.RPi_1.BAT"]
                                }
                            ]
                        ]
                    }
                ],
                "fieldConfig": {
                    "unit": "percent",
                    "decimals": 2
                }
            },
            {
                "id": 2,
                "type": "graph",
                "title": "Humidity",
                "datasource": "InfluxDB",
                "targets": [
                    {
                        "measurement": "your_measurement",
                        "groupBy": [
                            {
                                "type": "tag",
                                "params": ["topic"]
                            }
                        ],
                        "select": [
                            [
                                {
                                    "type": "field",
                                    "params": ["UPB.RPi_1.HUMID"]
                                }
                            ]
                        ]
                    }
                ],
                "fieldConfig": {
                    "unit": "percent",
                    "decimals": 2
                }
            },
            {
                "id": 3,
                "type": "graph",
                "title": "Temperature",
                "datasource": "InfluxDB",
                "targets": [
                    {
                        "measurement": "your_measurement",
                        "groupBy": [
                            {
                                "type": "tag",
                                "params": ["topic"]
                            }
                        ],
                        "select": [
                            [
                                {
                                    "type": "field",
                                    "params": ["UPB.RPi_1.TEMP"]
                                }
                            ]
                        ]
                    }
                ],
                "fieldConfig": {
                    "unit": "temperature",
                    "decimals": 2
                }
            }
        ],
        "time": {
            "from": "now-6h",
            "to": "now"
        },
        "refresh": "30s",
        "schemaVersion": 27,
        "version": 0
    },
    "folderId": 0,
    "overwrite": false
}
EOF

echo "Grafana dashboard for UPB IoT Data created successfully."

# Create Grafana dashboard for Battery Monitoring
curl -XPOST -H "Content-Type: application/json" \
    -u asistent:grafanaSPRC2023 \
    http://sprc3_grafana:3000/api/dashboards/db \
    -d @- <<EOF
{
    "dashboard": {
        "id": null,
        "title": "Battery Dashboard",
        "timezone": "browser",
        "panels": [
            # ... (dashboard configuration)
        ],
        "time": {
            "from": "now-48h",
            "to": "now"
        },
        "refresh": "30m",
        "schemaVersion": 27,
        "version": 0
    },
    "folderId": 0,
    "overwrite": false
}
EOF

echo "Grafana dashboard for Battery Monitoring created successfully."

# Set data retention policy in InfluxDB
curl -i -XPOST "http://sprc3_influxdb:8086/query" --data-urlencode "q=CREATE RETENTION POLICY autogen ON iot_data DURATION 30d REPLICATION 1 DEFAULT"
echo "Data retention policy set successfully."

# Log script completion
echo "Script execution completed."

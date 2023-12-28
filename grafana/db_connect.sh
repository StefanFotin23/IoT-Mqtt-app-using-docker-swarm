#!/bin/bash

LOG_FILE="/data/logs.txt"
echo "" > "$LOG_FILE"

# Redirect stdout and stderr to the log file
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Script started"

# Print current working directory
echo "Current working directory: $(pwd)"

# Grafana Credentials
GRAFANA_USER="asistent"
GRAFANA_PASSWORD="grafanaSPRC2023"

# InfluxDB Credentials
INFLUXDB_USER="user"
INFLUXDB_PASSWORD="user_password"

# Wait for InfluxDB to be ready
until curl -G "http://sprc3_influxdb:8086/ping" >/dev/null 2>&1; do
    echo "Waiting for InfluxDB..."
    sleep 5
done
echo "InfluxDB is ready."

# Configure Grafana data source
curl -XPOST -H "Content-Type: application/json" \
    -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
    http://sprc3_grafana:3000/api/datasources \
    -d @- <<EOF
{
    "name": "InfluxDB",
    "type": "influxdb",
    "url": "http://sprc3_influxdb:8086",
    "access": "proxy",
    "database": "iot_data",
    "user": "$INFLUXDB_USER",
    "password": "$INFLUXDB_PASSWORD",
    "basicAuth": false,
    "jsonData": {
        "organization": "UPB"
    }
}
EOF

# Create Grafana dashboard with a single graph panel aggregating all fields for all stations
curl -XPOST -H "Content-Type: application/json" \
    -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
    http://sprc3_grafana:3000/api/dashboards/db \
    -d @- <<EOF
{
    "dashboard": {
        "id": null,
        "title": "Aggregated IoT Data",
        "timezone": "browser",
        "panels": [
            {
                "id": 1,
                "type": "graph",
                "title": "Aggregated IoT Data",
                "datasource": "InfluxDB",
                "targets": [
                    {
                        "measurement": "iot_data",
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
                                    "params": ["UPB.RPi_1.BAT"],
                                    "alias": "UPB/RPi Battery Percentage",
                                    "groupBy": [],
                                    "color": "#3366cc"
                                }
                            ],
                            [
                                {
                                    "type": "field",
                                    "params": ["Dorinel.Zeus.Alarm"],
                                    "alias": "Dorinel/Zeus Alarm",
                                    "groupBy": [],
                                    "color": "#dc3912"
                                }
                            ],
                            [
                                {
                                    "type": "field",
                                    "params": ["UPB.RPi_1.HUMID"],
                                    "alias": "UPB/RPi Humidity",
                                    "groupBy": [],
                                    "color": "#ff9900"
                                }
                            ],
                            [
                                {
                                    "type": "field",
                                    "params": ["Dorinel.Zeus.RSSI"],
                                    "alias": "Dorinel/Zeus RSSI",
                                    "groupBy": [],
                                    "color": "#109618"
                                }
                            ],
                            [
                                {
                                    "type": "field",
                                    "params": ["UPB.RPi_1.TEMP"],
                                    "alias": "UPB/RPi Temperature",
                                    "groupBy": [],
                                    "color": "#990099"
                                }
                            ],
                            [
                                {
                                    "type": "field",
                                    "params": ["Dorinel.Zeus.AQI"],
                                    "alias": "Dorinel/Zeus AQI",
                                    "groupBy": [],
                                    "color": "#0099c6"
                                }
                            ]
                        ]
                    }
                ],
                "fieldConfig": {
                    "unit": "percent",
                    "decimals": 2
                },
                "legend": {
                    "show": true,
                    "values": false,
                    "min": false,
                    "max": false,
                    "current": false,
                    "total": false,
                    "avg": false
                },
                "color": {
                    "mode": "palette-classic"
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
    "overwrite": true
}
EOF

# Create Grafana dashboard with a single graph panel for BAT field for Dorinel/Zeus and UPB/RPi stations
curl -XPOST -H "Content-Type: application/json" \
    -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
    http://sprc3_grafana:3000/api/dashboards/db \
    -d @- <<EOF
{
    "dashboard": {
        "id": null,
        "title": "Battery Level Monitoring",
        "timezone": "browser",
        "panels": [
            {
                "id": 1,
                "type": "graph",
                "title": "Battery Level Monitoring",
                "datasource": "InfluxDB",
                "targets": [
                    {
                        "measurement": "iot_data",
                        "groupBy": [
                            {
                                "type": "tag",
                                "params": ["device"]
                            }
                        ],
                        "select": [
                            [
                                {
                                    "type": "field",
                                    "params": ["Dorinel.Zeus.BAT"],
                                    "alias": "Dorinel/Zeus Battery Percentage",
                                    "groupBy": [],
                                    "color": "#3366cc"
                                }
                            ],
                            [
                                {
                                    "type": "field",
                                    "params": ["UPB.RPi_1.BAT"],
                                    "alias": "UPB/RPi Battery Percentage",
                                    "groupBy": [],
                                    "color": "#dc3912"
                                }
                            ]
                        ]
                    }
                ],
                "fieldConfig": {
                    "unit": "percent",
                    "decimals": 2
                },
                "legend": {
                    "show": true,
                    "values": false,
                    "min": false,
                    "max": false,
                    "current": false,
                    "total": false,
                    "avg": false
                },
                "color": {
                    "mode": "palette-classic"
                }
            }
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
    "overwrite": true
}
EOF

# Log script completion
echo "Script execution completed."

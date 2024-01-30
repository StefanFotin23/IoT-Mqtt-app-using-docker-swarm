#!/bin/bash

# Function to check if Grafana is ready
grafana_ready() {
    curl -G "http://sprc3_grafana:3000/api/health" >/dev/null 2>&1
}

# Run Grafana in the background
grafana-server &

# Wait for Grafana to be ready
until grafana_ready; do
    echo "Waiting for Grafana to start..."
    sleep 5
done
echo "Grafana is ready."

# Log initialization start
echo "Initialization started"

LOG_FILE="/data/logs.txt"
echo "" > "$LOG_FILE"

# Redirect stdout and stderr to the log file
exec > >(tee -a "$LOG_FILE") 2>&1

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

# Function to get InfluxDB tags for a measurement
get_influxdb_tags() {
    local measurement="$1"
    curl -G "http://sprc3_influxdb:8086/query" --data-urlencode "q=SHOW TAG KEYS ON iot_data FROM \"$measurement\"" | jq -r '.results[0].series[0].values[][0]'
}

# Function to create Grafana dashboard for a measurement and its fields
create_grafana_dashboard() {
    local measurement="$1"
    local title="$2"

    tags=($(get_influxdb_tags "$measurement"))

    targets=""
    for tag in "${tags[@]}"; do
        targets+="
        [
            {
                \"type\": \"field\",
                \"params\": [\"$tag\"],
                \"alias\": \"$measurement/$tag\",
                \"groupBy\": [],
                \"color\": \"#$((RANDOM % 0x1000000))\"  # Random color for each field
            }
        ],"
    done

    targets=${targets%,}  # Remove the trailing comma

    curl -XPOST -H "Content-Type: application/json" \
        -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
        http://sprc3_grafana:3000/api/dashboards/db \
        -d @- <<EOF
{
    "dashboard": {
        "id": null,
        "title": "$title",
        "timezone": "browser",
        "panels": [
            {
                "id": 1,
                "type": "graph",
                "title": "$title",
                "datasource": "InfluxDB",
                "targets": [
                    {
                        "measurement": "$measurement",
                        "groupBy": [
                            {
                                "type": "tag",
                                "params": ["topic"]
                            }
                        ],
                        "select": [$targets]
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
}

# Create Grafana dashboard for aggregated IoT data
create_grafana_dashboard "iot_data" "Aggregated IoT Data"

# Create Grafana dashboard for battery level monitoring
create_grafana_dashboard "iot_data" "Battery Level Monitoring"

# Log initialization completion
echo "Initialization completed."

# Sleep to keep the script running in the background
sleep infinity

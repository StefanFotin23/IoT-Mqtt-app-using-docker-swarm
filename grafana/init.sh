#!/bin/bash

# Docker swarm stack name
stack_name="sprc3"
# InfluxDB measurement name
measurement="iot_data"
# Logfile name
LOG_FILE="/data/logs.txt"
# Grafana Credentials
GRAFANA_USER="asistent"
GRAFANA_PASSWORD="grafanaSPRC2023"
# InfluxDB Credentials
INFLUXDB_USER="user"
INFLUXDB_PASSWORD="user_password"

# List of tags
DEVICES=("Dorinel.Zeus" "UPB.RPi_1" "Stefan.TempSensor")

# Function to check if Grafana is ready
grafana_ready() {
    curl -G "http://${stack_name}_grafana:3000/api/health" >/dev/null 2>&1
}

# Run Grafana in the background
grafana-server &

# Wait for Grafana to be ready
until grafana_ready; do
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Waiting for Grafana to start..."
    sleep 5
done
echo "$(date '+%Y-%m-%d %H:%M:%S') - Grafana is ready."

# Log initialization start
echo "$(date '+%Y-%m-%d %H:%M:%S') - Initialization started"

echo "" > "$LOG_FILE"

# Redirect stdout and stderr to the log file
exec > >(tee -a "$LOG_FILE") 2>&1

# Print current working directory
echo "$(date '+%Y-%m-%d %H:%M:%S') - Current working directory: $(pwd)"

# Wait for InfluxDB to be ready
until curl -G "http://${stack_name}_influxdb:8086/ping" >/dev/null 2>&1; do
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Waiting for InfluxDB..."
    sleep 5
done
echo "$(date '+%Y-%m-%d %H:%M:%S') - InfluxDB is ready."

# Configure Grafana data source
curl -XPOST -H "Content-Type: application/json" \
    -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
    http://${stack_name}_grafana:3000/api/datasources \
    -d @- <<EOF
{
    "name": "InfluxDB",
    "type": "influxdb",
    "url": "http://${stack_name}_influxdb:8086",
    "access": "proxy",
    "database": "$measurement",
    "user": "$INFLUXDB_USER",
    "password": "$INFLUXDB_PASSWORD",
    "basicAuth": false,
    "jsonData": {
        "organization": "UPB"
    }
}
EOF

echo "$(date '+%Y-%m-%d %H:%M:%S') - Datasource InfluxDB configured."

# Function to create Grafana dashboard for a measurement and its fields
create_grafana_dashboard() {
    local tag="$1"
    local measurement="$2"
    local title="$3"

    echo "$(date '+%Y-%m-%d %H:%M:%S') - create_grafana_dashboard(Tag: $tag, Measurement: $measurement, Title: $title)"

    curl -XPOST -H "Content-Type: application/json" \
        -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
        http://${stack_name}_grafana:3000/api/dashboards/db \
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
      "datasource": {
        "type": "influxdb",
        "uid": "e40458de-ef88-4e4c-8877-6ee62ed53974"
      },
      "refId": "A",
      "policy": "default",
      "resultFormat": "time_series",
      "orderByTime": "ASC",
      "tags": [
        {
          "key": "device::tag",
          "value": "$tag",
          "operator": "="
        }
      ],
      "groupBy": [
        {
          "type": "time",
          "params": ["$__interval"]
        },
        {
          "type": "fill",
          "params": ["previous"]
        }
      ],
      "select": [
        [
          {
            "type": "field",
            "params": ["value"],
            "alias": "$tag"
          }
        ]
      ],
      "measurement": "$measurement",
      "query": "SELECT * FROM \"$measurement\" WHERE (\"device\"::tag = '$tag')",
      "rawQuery": true
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

for tag in "${DEVICES[@]}"; do
    create_grafana_dashboard "$tag" "$measurement" "Dashboard for $tag"
done

# List to store existing devices
existing_devices=()

while true; do
    # Get unique device values from InfluxDB using sed
    devices=$(curl -sG "http://${stack_name}_influxdb:8086/query" --data-urlencode "db=$measurement" --data-urlencode "q=SHOW TAG VALUES FROM \"$measurement\" WITH KEY = \"device\"")
    echo "${existing_devices[@]}"
    # Extract device values from JSON response using Bash
    device_values=$(echo "$devices" | grep -o '\[device,[^]]*' | tr ',' '\n' | sed 's/]//')

    # Loop through device values and create dashboards
    while IFS= read -r device_value; do
        # Remove leading spaces
        device_value=$(echo "$device_value" | tr -d '[:space:]')

        # Check if device_value is not empty nor "[device"
        if [ -n "$device_value" ] && [ "$device_value" != "[device" ]; then
            # Check if device_value is not in the list of existing devices
            if ! [[ " ${existing_devices[*]} " =~ $device_value ]]; then
                # Add the device to the list of existing devices
                existing_devices+=("$device_value")
                # Display device_value
                echo "$(date '+%Y-%m-%d %H:%M:%S') - New Device Value: $device_value"
                create_grafana_dashboard "${device_value}" "${measurement}" "Dashboard for ${device_value}"
                # Display All Devices
                echo "$(date '+%Y-%m-%d %H:%M:%S') - All Device Values: ${existing_devices[*]}"
            fi
        fi
    done <<< "$device_values"

    # Sleep for 10 seconds before checking again
    sleep 10
done

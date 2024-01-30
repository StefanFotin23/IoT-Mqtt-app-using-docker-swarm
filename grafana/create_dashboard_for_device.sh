#!/bin/bash

# Function to create Grafana dashboard for a measurement and its fields
create_grafana_dashboard() {
    local tag="$1"
    local measurement="$2"
    local title="$3"
    # Echo the values for debugging
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
                        "measurement": "$measurement",
                        "groupBy": [
                            {
                                "type": "tag",
                                "params": ["$tag"]
                            }
                        ],
                        "select": [
                            [
                                {
                                    "type": "field",
                                    "params": ["$tag"],
                                    "alias": "$measurement/$tag",
                                    "groupBy": [],
                                    "color": "#$(printf '%06x\n' $((RANDOM & 0xFFFFFF)))"
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
}
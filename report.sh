#!/bin/bash

path=$(cd -- $(dirname -- "${BASH_SOURCE[0]}") && pwd)
folder=$(echo $path | awk -F/ '{print $NF}')
json=~/logs/report-$folder
source ~/.bash_profile
source $path/env

service=$(systemctl is-active forerunner-sync)

health_json=$(curl -sS http://localhost:7080/health)
health=$(echo $health_json | jq -r .status)

status_json=$(curl -sS http://localhost:7080/status)
connection=$(echo $status_json | jq -r .status)

status="ok" && message="health=$health connection=$connection"
[ "$connection" != "Connected" ] && status="warning" && message="not connected ($connection)"
[ "$health" != "ok" ] && status="warning" && message="health check failed ($health)"
[ "$service" != "active" ] && status="error" && message="service not running ($service)"

cat >$json << EOF
{
  "updated":"$(date --utc +%FT%TZ)",
  "measurement":"report",
  "tags": {
       "id":"$folder-$ID",
       "machine":"$MACHINE",
       "grp":"node",
       "owner":"$OWNER"
  },
  "fields": {
        "network":"$NETWORK",
        "chain":"$CHAIN",
        "status":"$status",
        "message":"$message",
        "m1":"health=$health connection=$connection",
        "m2":"service=$service"
  }
}
EOF

cat $json | jq

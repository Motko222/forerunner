#!/bin/bash

path=$(cd -- $(dirname -- "${BASH_SOURCE[0]}") && pwd)
folder=$(echo $path | awk -F/ '{print $NF}')
json=~/logs/report-$folder
source ~/.bash_profile
source $path/env
source /root/.forerunner/env

wallet=$(jq -r .address /root/.forerunner/sync-wallet.json)

service=$(systemctl is-active forerunner-sync)
errors=$(journalctl -u forerunner-sync --since "1 hour ago" --no-hostname -o cat | grep -c -E "rror|ERR")

health_json=$(curl -sS http://localhost:7080/health)
health=$(echo $health_json | jq -r .status)

status_json=$(curl -sS http://localhost:7080/status)
connection=$(echo $status_json | jq -r .status)

status="ok" && message="health=$health connection=$connection"
[ "$connection" != "Connected" ] && status="warning" && message="not connected ($connection)"
[ "$health" != "ok" ] && status="warning" && message="health check failed ($health)"
[ $errors -gt 10 ] && status="warning" && message="$errors errors last hour"
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
        "network":"monad",
        "chain":"testnet",
        "status":"$status",
        "message":"$message",
        "m1":"health=$health connection=$connection",
        "errors":"$errors",
        "m2":"service=$service",
        "m3":"license=$LICENSE_TOKEN_ID pubkey=$NODE_PUBKEY",
        "wallet":"$wallet"
  }
}
EOF

cat $json | jq

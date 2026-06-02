#!/bin/bash

path=$(cd -- $(dirname -- "${BASH_SOURCE[0]}") && pwd)
folder=forerunner
source $path/env

read -p "Sure? " c
case $c in y|Y) ;; *) exit ;; esac

# Stop and remove service
systemctl stop forerunner-sync.service
systemctl disable forerunner-sync.service
rm /etc/systemd/system/forerunner-sync.service
systemctl daemon-reload

# Create project backup folder
mkdir -p /root/backup/$folder

# Backup node data into project folder
mv /root/forerunner /root/backup/$folder/forerunner
mv /root/.forerunner /root/backup/$folder/.forerunner

# Backup scripts into project folder (no .git)
rsync -a --exclude='.git' $path/ /root/backup/$folder/$folder-scripts/
rm -rf $path

# Remove from influx monitoring
bash /root/scripts/system/influx-delete-id.sh "$folder-$ID"

echo "Done. Backups in /root/backup/$folder/"

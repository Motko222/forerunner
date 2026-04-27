#!/bin/bash

systemctl restart forerunner-sync
sleep 2s
journalctl -n 200 -u forerunner-sync -f --no-hostname -o cat

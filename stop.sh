#!/bin/bash

echo "=== Stopping ICMP Guard Lab ==="

sudo mn -c >/dev/null 2>&1

sudo docker exec ryu-controller sh -c \
"pkill -f 'ryu-manager.*icmp_guard_v1_6_lts.py' || true" \
>/dev/null 2>&1

sudo docker stop ryu-controller >/dev/null 2>&1

echo "Lab stopped and cleaned."

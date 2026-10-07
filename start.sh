#!/bin/bash

echo "=== Starting ICMP Guard Lab ==="

# Clean old Mininet state
sudo mn -c >/dev/null 2>&1

# Start existing Docker container
sudo docker start ryu-controller >/dev/null 2>&1

# Stop any old Ryu process inside container
sudo docker exec ryu-controller sh -c \
"pkill -f 'ryu-manager.*icmp_guard_v1_6_lts.py' || true" \
>/dev/null 2>&1

# Start Ryu in background
sudo docker exec -d ryu-controller sh -c \
"cd /project && ryu-manager --ofp-tcp-listen-port 6653 /project/icmp_guard_v1_6_lts.py > /project/ryu.log 2>&1"

echo "Waiting for Ryu..."
sleep 3

echo
echo "Ryu started."
echo "Starting Mininet..."
echo

sudo mn --topo=single,3 --mac --controller=remote,ip=127.0.0.1,port=6653

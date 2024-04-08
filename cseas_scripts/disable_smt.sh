#!/bin/bash 

for node in node2 node1 node0
do
    ssh $node 'echo "off" | sudo tee /sys/devices/system/cpu/smt/control'
done
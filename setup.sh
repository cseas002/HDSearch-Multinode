#!/bin/bash

for node in node0 node1 node2
do
    ssh -A $node "sudo apt update && sudo apt-get install -y lmbench; sudo apt-get -y install libgsl-dev; sudo apt -y install python3-pip"
done

# ssh -A node2 "sudo apt-get install -y wireshark; sudo usermod -aG wireshark $USER; sudo apt install -y tshark"

# ssh -A node1 "sudo apt-get -y install libgsl-dev"
ssh -A node1 "pip install numpy"
pip install scipy
pip install matplotlib
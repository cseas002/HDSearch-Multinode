#!/bin/bash

for node in node0 node1 node2
do
ssh -A $node 'cd /tmp;
wget https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB;
sudo apt-key add GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB;
rm GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB;
echo "deb https://apt.repos.intel.com/oneapi all main" | sudo tee /etc/apt/sources.list.d/oneAPI.list;
sudo apt update;
sudo apt install intel-oneapi-vtune -y;'
# I added this to make it tickless
ssh -A $node "sudo sed -i 's/^\(GRUB_CMDLINE_LINUX_DEFAULT=\".*\)\"/\1 nohz=on\"/' /etc/default/grub;
sudo update-grub;
sudo reboot;"
done
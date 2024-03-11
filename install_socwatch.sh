#!/bin/bash

for node in node2 node1 node0
do
ssh -A $node 'sudo env RESIZEROOT=200 ./grow-rootfs.sh;
wget -O- https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB | gpg --dearmor | sudo tee /usr/share/keyrings/oneapi-archive-keyring.gpg > /dev/null;
echo "deb [signed-by=/usr/share/keyrings/oneapi-archive-keyring.gpg] https://apt.repos.intel.com/oneapi all main" | sudo tee /etc/apt/sources.list.d/oneAPI.list;
sudo apt-get update;
sudo apt install -y intel-basekit;
sudo apt install -y linux-tools-common linux-tools-$(uname -r);
make'
# I added this to make it tickless
# ssh -A $node "sudo sed -i 's/^\(GRUB_CMDLINE_LINUX_DEFAULT=\".*\)\"/\1 nohz=on\"/' /etc/default/grub;
# ssh -A $node "sudo sed -i 's/^\(GRUB_CMDLINE_LINUX_DEFAULT=\".*\)\"/\1 nohz_full=1-10\"/' /etc/default/grub;
# sudo update-grub;
# sudo reboot;"
done
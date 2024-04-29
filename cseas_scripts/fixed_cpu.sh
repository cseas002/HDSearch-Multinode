# change /etc/default/grub

# sed GRUB_CMDLINE_LINUX (both lines) and add intel_pstate=disable in the end
# sudo update-grub2
# sudo reboot


# sudo cpupower frequency-set -g userspace
# sudo cpupower frequency-set -f 2200MHz

for node in node2 node1 node0
do
    ssh $node "sudo sed -i 's/^\(GRUB_CMDLINE_LINUX_DEFAULT=\".*\)\"/\1 intel_pstate=disable\"/' /etc/default/grub && sudo update-grub"
    ssh $node "sudo reboot"
done

# Then, run:
for node in node2 node1 node0
do
    ssh $node "sudo apt-get update; sudo apt-get install -y linux-tools-common linux-tools-generic; sudo apt-get install -y linux-tools-5.4.0-164-generic; sudo apt-get install -y linux-cloud-tools-5.4.0-164-generic"
    ssh $node "sudo cpupower frequency-set -g userspace"
    ssh $node "sudo cpupower frequency-set -f 2200MHz"
done




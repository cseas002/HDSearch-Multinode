change /etc/default/grub

sed GRUB_CMDLINE_LINUX (both lines) and add intel_pstate=disable in the end
sudo update-grub2
sudo reboot


sudo cpupower frequency-set -g userspace
sudo cpupower frequency-set -f 2200MHz


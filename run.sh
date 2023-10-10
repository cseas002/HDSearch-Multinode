#!/bin/bash

# Setting up the kernel
sudo /usr/local/etc/emulab/mkextrafs.pl /mydata
sudo apt -y update
sudo apt-get -y install build-essential linux-source bc kmod cpio flex libncurses5-dev libelf-dev libssl-dev
sudo chmod a+rwx /mydata
cd /mydata
wget https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.15.18.tar.xz
sudo tar -xf linux-4.15.18.tar.xz
cd linux-4.15.18
sudo cp /boot/config-4.15.0-169-generic .config
sudo chmod +rwx .config 

sudo sed -i 's/CONFIG_LOCALVERSION="[^"]*"/CONFIG_LOCALVERSION="c1-2-2-c1e-10-20"/' .config
sudo sed -i 's/CONFIG_SYSTEM_TRUSTED_KEYS="[^"]*"/CONFIG_SYSTEM_TRUSTED_KEYS=""/' .config

# CONFIG_LOCALVERSION="c1-2-2-c1e-10-20"
# CONFIG_SYSTEM_TRUSTED_KEYS=""

make oldconfig

make -j`nproc` bindeb-pkg

sudo dpkg -i linux-headers-4.15.18-c1-2-2-c1e-10-20_4.15.18-c1-2-2-c1e-10-20-1_amd64.deb linux-image-4.15.18-c1-2-2-c1e-10-20_4.15.18-c1-2-2-c1e-10-20-1_amd64.deb
sudo dpkg -i linux-headers-4.15.18-c1-1-1-c1e-10-20_4.15.18-c1-1-1-c1e-10-20-2_amd64.deb linux-image-4.15.18-c1-1-1-c1e-10-20_4.15.18-c1-1-1-c1e-10-20-2_amd64.deb
sudo dpkg -i linux-headers-4.15.18-c1-1-1-c1e-05-20_4.15.18-c1-1-1-c1e-05-20-3_amd64.deb linux-image-4.15.18-c1-1-1-c1e-05-20_4.15.18-c1-1-1-c1e-05-20-3_amd64.deb


make -C tools/perf
sudo apt install pciutils-dev
make -C tools/power/cpupower


ssh -n node1 'cd ~/mcperf; sudo python3 configure.py -v --kernelconfig=baseline -v'



# Setting up the program (hdsearch)
cd 
git clone https://github.com/cseas002/HDSearch-Multinode.git
# OR git clone git@github.com:cseas002/HDSearch-Multinode.git
# git clone https://github.com/georgiantoniou/HDSearch-Multinode.git
# cd ./HDSearch-Multinode
# git clone https://github.com/georgiantoniou/profiler.git
chmod 777 ./*/*/*



# Go to website https://github.com/cseas002/HDSearch-Multinode and read the README.
# Download the file with --output HDSearch-dataset.tgz

# wget -O HDSearch-dataset.tgz "https://uc402c83c33160d514fc99d4a81a.dl.dropboxusercontent.com/cd/0/get/CDf2u569O6ZeejjtsLlZjUP6vRbrv58p8rmikiwP7OcDlC80O-lfPx7TlcDIONSrTWGK8qcLRPaIPYXqDZkWL3Ebh3IXv8LLyvzXWSKZyqkVDg5Vnl_5dmnbxeo3ZnaLG9bdkMb2_R5P_tW5JMSfyyJM82-b7yVfgN5vW3GmSZKcPA/file?_download_id=6446070377334989781222253284475905963223322560229476539695788832&_notify_domain=www.dropbox.com&dl=1"
curl 'https://uc25bf119f610f360299ec8e717d.dl.dropboxusercontent.com/cd/0/get/CDgmBrri9t9OhAW7vpWNsYzO34yYMf6uOOE-k6pbNy5sdcZGKjhXMdHT8WI9OWUtX_cF7E0S9T3RUajIoeNFwm23bPPnrqWxkAQQv8gBFRVdDKubtizI3dy_Ms1-nGKfMfedq6O-BSrW3C73HaveSLsmHewMRRh_q3fabJsjOSDTeQ/file?_download_id=62201443360263962537267717758733389373151770888717149365355517432&_notify_domain=www.dropbox.com&dl=1' \
  -H 'authority: uc25bf119f610f360299ec8e717d.dl.dropboxusercontent.com' \
  -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7' \
  -H 'accept-language: en-US,en;q=0.9' \
  -H 'cache-control: no-cache' \
  -H 'pragma: no-cache' \
  -H 'referer: https://www.dropbox.com/' \
  -H 'sec-ch-ua: "Chromium";v="116", "Not)A;Brand";v="24", "Microsoft Edge";v="116"' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'sec-ch-ua-platform: "Windows"' \
  -H 'sec-fetch-dest: iframe' \
  -H 'sec-fetch-mode: navigate' \
  -H 'sec-fetch-site: cross-site' \
  -H 'sec-fetch-user: ?1' \
  -H 'upgrade-insecure-requests: 1' \
  -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Safari/537.36 Edg/116.0.1938.76' \
  --compressed --output HDSearch-dataset.tgz
tar -xzvf HDSearch-dataset.tgz
sudo cp -r HDSearch /mydata/
cd

find . -type d -exec chmod 700 {} \;
find . -type f -exec chmod 700 {} \;


# mkdir /mydata/HDSearch
sudo cp ./HDSearch-Multinode/microsuite_files/client/* /mydata/HDSearch
sudo cp ./HDSearch-Multinode/microsuite_files/midtier/* /mydata/HDSearch
sudo cp ./HDSearch-Multinode/microsuite_files/bucket/* /mydata/HDSearch  # This doesn't do anything but whatever

for node in node1 node2 
do
scp -r /mydata/HDSearch cseas002@$node:/mydata/
done

cd ~/HDSearch-Multinode/
bash hdsearch-multinode.sh build_install

# Socwatch
for node in node0 node1 node2
do
ssh -A $node "cd /tmp;
 wget https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB; 
 sudo apt-key add GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB;
 rm GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB;
 echo "deb https://apt.repos.intel.com/oneapi all main" | sudo tee /etc/apt/sources.list.d/oneAPI.list;
 sudo apt update;
 sudo apt install -y intel-oneapi-vtune;"
 done 
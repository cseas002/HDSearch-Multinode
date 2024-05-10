#!/bin/bash

# Run without pre-request
sed -i 's/send_request_time = .*/send_request_time = -1;/' ./microsuite_files/midtier/mid_tier_server.cc

sudo cp /users/cseas002/HDSearch-Multinode/microsuite_files/client/* /mydata/HDSearch
sudo cp /users/cseas002/HDSearch-Multinode/microsuite_files/midtier/* /mydata/HDSearch
for node in node1 node2 
do
sudo scp -r /mydata/HDSearch cseas002@$node:/mydata/
done

mkdir -p ~/results
mkdir -p ~/results/WITHOUT_PRE2

# Check if the directory exists, if not, create it
ssh node2 'mkdir -p ~/results/WITHOUT_PRE2'

nohup python3 run_experiment.py > ../no_pre.txt WITHOUT_PRE2 &

# # Wait for 1 minute
# sleep 60

# # Start Wireshark capture on node2, filtering traffic from node1
# ssh node2 'tshark -i ens1f0 -w ~/results/WITHOUT_PRE/wireshark.pcap host 10.10.1.2' &

# # Wait for 10 minutes (Wireshark will be capturing during this time)
# sleep 600

# # Stop Wireshark capture
# ssh node2 'sudo pkill tshark'

# # Convert the captured pcap file to a readable format
# ssh node2 'sudo tshark -r ~/results/WITHOUT_PRE/wireshark.pcap -Y "ip.src==10.10.1.2" -T fields -e frame.number -e frame.time -e ip.src -e ip.dst -e frame.len > ~/results/WITHOUT_PRE/wireshark.txt'


# ssh node2 'sudo tshark -f "dst port 50050 or dst port 8080" -i any >> ~/results/WITHOUT_PRE/wireshark.txt' &

# NOW, YOU MUST WAIT
wait 

ssh node2 "sudo pkill tshark"
# Transfer the Wireshark text file to your local machine
scp node2:~/results/WITHOUT_PRE2/wireshark.txt ~/results/WITHOUT_PRE2/

scp node2:~/turbo* ~/results/WITHOUT_PRE2/




# Run with pre-request immediately
sed -i 's/send_request_time = .*/send_request_time = 0;/' ./microsuite_files/midtier/mid_tier_server.cc

sudo cp /users/cseas002/HDSearch-Multinode/microsuite_files/client/* /mydata/HDSearch
sudo cp /users/cseas002/HDSearch-Multinode/microsuite_files/midtier/* /mydata/HDSearch
for node in node1 node2 
do
sudo scp -r /mydata/HDSearch cseas002@$node:/mydata/
done

mkdir -p ~/results/0us_PRE2

# Check if the directory exists, if not, create it
ssh node2 'mkdir -p ~/results/0us_PRE2'

nohup python3 run_experiment.py > ../pre2.txt 0us_PRE2 &


# # Wait for 1 minute
# sleep 60

# # Start Wireshark capture on node2, filtering traffic from node1
# ssh node2 "tshark -i ens1f0 -w ~/results/0us_PRE/wireshark.pcap host 10.10.1.2" &

# # Wait for 10 minutes (Wireshark will be capturing during this time)
# sleep 600

# # Stop Wireshark capture
# ssh node2 'sudo pkill tshark'

# # Convert the captured pcap file to a readable format
# ssh node2 'sudo tshark -r ~/results/0us_PRE/wireshark.pcap -Y "ip.src==10.10.1.2" -T fields -e frame.number -e frame.time -e ip.src -e ip.dst -e frame.len > ~/results/0us_PRE/wireshark.txt'

# # Transfer the Wireshark text file to node0
# scp node2:~/results/0us_PRE/wireshark.txt ~/results/0us_PRE/

# ssh node2 'sudo tshark -f "dst port 50050 or dst port 8080" -i any >> ~/results/0us_PRE/wireshark.txt' &

wait

ssh node2 "sudo pkill tshark"
# Transfer the Wireshark text file to your local machine
scp node2:~/results/0us_PRE2/wireshark.txt ~/results/0us_PRE2/

scp node2:~/turbo* ~/results/0us_PRE2/
# # Run with pre-request 50 us after
# sed -i 's/send_request_time = .*/send_request_time = 50;/' ./microsuite_files/midtier/mid_tier_server.cc

# sudo cp /users/cseas002/HDSearch-Multinode/microsuite_files/client/* /mydata/HDSearch
# sudo cp /users/cseas002/HDSearch-Multinode/microsuite_files/midtier/* /mydata/HDSearch
# for node in node1 node2 
# do
# sudo scp /mydata/HDSearch/microsuite_files/midtier/* cseas002@$node:/mydata/HDSearch/microsuite_files/midtier/*
# done

# nohup python3 run_experiment.py > ../50pre2.txt WITH_PRE_50US &

# wait 

# mkdir -p ~/results/WITH_PRE_50US
# scp node2:~/turbo* ~/results/WITH_PRE_50US/

# # Run with pre-request 100 us after
# sed -i 's/send_request_time = .*/send_request_time = 100;/' ./microsuite_files/midtier/mid_tier_server.cc

# sudo cp /users/cseas002/HDSearch-Multinode/microsuite_files/midtier/* /mydata/HDSearch
# for node in node1 node2 
# do
# sudo scp /mydata/HDSearch/microsuite_files/midtier/* cseas002@$node:/mydata/HDSearch/microsuite_files/midtier/*
# done

# nohup python3 run_experiment.py > ../100pre.txt WITH_PRE_100US &

# wait 

# mkdir -p ~/results/WITH_PRE_100US
# scp node2:~/turbo* ~/results/WITH_PRE_100US/
# # Run with pre-request 150 us after
# sed -i 's/send_request_time = .*/send_request_time = 150;/' ./microsuite_files/midtier/mid_tier_server.cc

# sudo cp /users/cseas002/HDSearch-Multinode/microsuite_files/client/* /mydata/HDSearch
# sudo cp /users/cseas002/HDSearch-Multinode/microsuite_files/midtier/* /mydata/HDSearch
# for node in node1 node2 
# do
# sudo scp /mydata/HDSearch/microsuite_files/midtier/* cseas002@$node:/mydata/HDSearch/microsuite_files/midtier/*
# done

# nohup python3 run_experiment.py > ../1502pre.txt WITH_PRE_150US &

# wait

# mkdir -p ~/results/WITH_PRE_150US
# scp node2:~/turbo* ~/results/WITH_PRE_150US/

cd cseas_scripts
for name in 0us_PRE2 WITHOUT_PRE2
do
    bash get_times_script.sh $name $name.txt
done
#!/bin/bash

ssh node1 "sudo apt-get update && sudo apt-get install linux-tools-common && sudo apt-get -y install linux-tools-5.4.0-164-generic"




# Run with adaptive pre
sed -i 's/send_request_time = .*/send_request_time = 0;/' ./microsuite_files/midtier/mid_tier_server.cc
sed -i 's/adaptive = .*/adaptive = true;/' ./microsuite_files/midtier/mid_tier_server.cc

sudo cp /users/cseas002/HDSearch-Multinode/microsuite_files/client/* /mydata/HDSearch
sudo cp /users/cseas002/HDSearch-Multinode/microsuite_files/midtier/* /mydata/HDSearch
for node in node1 node2 
do
sudo scp -r /mydata/HDSearch cseas002@$node:/mydata/
done

mkdir -p ~/results
mkdir -p ~/results/midtier
mkdir -p ~/results/ADAPTIVE_EXP_NEW_MID
mkdir -p ~/results/midtier/ADAPTIVE_EXP_NEW_MID

# Check if the directory exists, if not, create it
ssh node2 'mkdir -p ~/results/ADAPTIVE_EXP_NEW_MID'



nohup python3 run_experiment.py > ../no_pre.txt ADAPTIVE_EXP_NEW_MID &


# NOW, YOU MUST WAIT
wait 

ssh node2 "sudo pkill tshark"
# Transfer the Wireshark text file to your local machine
scp node2:~/results/ADAPTIVE_EXP_NEW_MID/wireshark.txt ~/results/ADAPTIVE_EXP_NEW_MID/

scp node2:~/turbo* ~/results/ADAPTIVE_EXP_NEW_MID/
scp node1:~/turbo* ~/results/midtier/ADAPTIVE_EXP_NEW_MID/


# Run without pre-request
sed -i 's/send_request_time = .*/send_request_time = -1;/' ./microsuite_files/midtier/mid_tier_server.cc
sed -i 's/adaptive = .*/adaptive = false;/' ./microsuite_files/midtier/mid_tier_server.cc

sudo cp /users/cseas002/HDSearch-Multinode/microsuite_files/client/* /mydata/HDSearch
sudo cp /users/cseas002/HDSearch-Multinode/microsuite_files/midtier/* /mydata/HDSearch
for node in node1 node2 
do
sudo scp -r /mydata/HDSearch cseas002@$node:/mydata/
done

mkdir -p ~/results
mkdir -p ~/results/WITHOUT_PRE_EXP_NEW_MID
mkdir -p ~/results/midtier/WITHOUT_PRE_EXP_NEW_MID

# Check if the directory exists, if not, create it
ssh node2 'mkdir -p ~/results/WITHOUT_PRE_EXP_NEW_MID'

nohup python3 run_experiment.py > ../no_pre.txt WITHOUT_PRE_EXP_NEW_MID &


# NOW, YOU MUST WAIT
wait 
scp node2:~/turbo* ~/results/WITHOUT_PRE_EXP_NEW_MID/
scp node1:~/turbo* ~/results/midtier/WITHOUT_PRE_EXP_NEW_MID/


# Run with 0us pre-request
sed -i 's/send_request_time = .*/send_request_time = 0;/' ./microsuite_files/midtier/mid_tier_server.cc
sed -i 's/adaptive = .*/adaptive = false;/' ./microsuite_files/midtier/mid_tier_server.cc

sudo cp /users/cseas002/HDSearch-Multinode/microsuite_files/client/* /mydata/HDSearch
sudo cp /users/cseas002/HDSearch-Multinode/microsuite_files/midtier/* /mydata/HDSearch
for node in node1 node2 
do
sudo scp -r /mydata/HDSearch cseas002@$node:/mydata/
done

mkdir -p ~/results
mkdir -p ~/results/0US_PRE_EXP_NEW_MID
mkdir -p ~/results/midtier/0US_PRE_EXP_NEW_MID

# Check if the directory exists, if not, create it
ssh node2 'mkdir -p ~/results/0US_PRE_EXP_NEW_MID'

nohup python3 run_experiment.py > ../no_pre.txt 0US_PRE_EXP_NEW_MID &

# NOW, YOU MUST WAIT
wait 
scp node2:~/turbo* ~/results/0US_PRE_EXP_NEW_MID/
scp node1:~/turbo* ~/results/midtier/0US_PRE_EXP_NEW_MID/


cd cseas_scripts
for name in ADAPTIVE_EXP_NEW_MID WITHOUT_PRE_EXP_NEW_MID # 0US_PRE_FIXED_CSTATES_DIS 50US_PRE_FIXED_CSTATES_DIS 100US_PRE_FIXED_CSTATES_DIS 150US_PRE_FIXED_CSTATES_DIS
do
    bash get_times_script.sh $name $name.txt
done
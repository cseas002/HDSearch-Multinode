#!/bin/bash

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
mkdir -p ~/results/ADAPTIVE_FIXED

# Check if the directory exists, if not, create it
ssh node2 'mkdir -p ~/results/ADAPTIVE_FIXED'

nohup python3 run_experiment.py > ../no_pre.txt ADAPTIVE_FIXED &


# NOW, YOU MUST WAIT
wait 

ssh node2 "sudo pkill tshark"
# Transfer the Wireshark text file to your local machine
scp node2:~/results/ADAPTIVE_FIXED/wireshark.txt ~/results/ADAPTIVE_FIXED/

scp node2:~/turbo* ~/results/ADAPTIVE_FIXED/


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
mkdir -p ~/results/WITHOUT_PRE_FIXED

# Check if the directory exists, if not, create it
ssh node2 'mkdir -p ~/results/WITHOUT_PRE_FIXED'

nohup python3 run_experiment.py > ../no_pre.txt WITHOUT_PRE_FIXED &


# NOW, YOU MUST WAIT
wait 
scp node2:~/turbo* ~/results/WITHOUT_PRE_FIXED/


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
mkdir -p ~/results/0US_PRE_FIXED

# Check if the directory exists, if not, create it
ssh node2 'mkdir -p ~/results/0US_PRE_FIXED'

nohup python3 run_experiment.py > ../no_pre.txt 0US_PRE_FIXED &


# NOW, YOU MUST WAIT
wait 
scp node2:~/turbo* ~/results/0US_PRE_FIXED/


# Run with 50us pre-request
sed -i 's/send_request_time = .*/send_request_time = 50;/' ./microsuite_files/midtier/mid_tier_server.cc
sed -i 's/adaptive = .*/adaptive = false;/' ./microsuite_files/midtier/mid_tier_server.cc

sudo cp /users/cseas002/HDSearch-Multinode/microsuite_files/client/* /mydata/HDSearch
sudo cp /users/cseas002/HDSearch-Multinode/microsuite_files/midtier/* /mydata/HDSearch
for node in node1 node2 
do
sudo scp -r /mydata/HDSearch cseas002@$node:/mydata/
done

mkdir -p ~/results
mkdir -p ~/results/50US_PRE_FIXED

# Check if the directory exists, if not, create it
ssh node2 'mkdir -p ~/results/50US_PRE_FIXED'

nohup python3 run_experiment.py > ../no_pre.txt 50US_PRE_FIXED &

wait
scp node2:~/turbo* ~/results/50US_PRE_FIXED/

# Run with 100us pre-request
sed -i 's/send_request_time = .*/send_request_time = 100;/' ./microsuite_files/midtier/mid_tier_server.cc
sed -i 's/adaptive = .*/adaptive = false;/' ./microsuite_files/midtier/mid_tier_server.cc

sudo cp /users/cseas002/HDSearch-Multinode/microsuite_files/client/* /mydata/HDSearch
sudo cp /users/cseas002/HDSearch-Multinode/microsuite_files/midtier/* /mydata/HDSearch
for node in node1 node2 
do
sudo scp -r /mydata/HDSearch cseas002@$node:/mydata/
done

mkdir -p ~/results
mkdir -p ~/results/100US_PRE_FIXED

# Check if the directory exists, if not, create it
ssh node2 'mkdir -p ~/results/100US_PRE_FIXED'

nohup python3 run_experiment.py > ../no_pre.txt 100US_PRE_FIXED &

# NOW, YOU MUST WAIT
wait 
scp node2:~/turbo* ~/results/100US_PRE_FIXED/

# Run with 150us pre-request
sed -i 's/send_request_time = .*/send_request_time = 150;/' ./microsuite_files/midtier/mid_tier_server.cc
sed -i 's/adaptive = .*/adaptive = false;/' ./microsuite_files/midtier/mid_tier_server.cc

sudo cp /users/cseas002/HDSearch-Multinode/microsuite_files/client/* /mydata/HDSearch
sudo cp /users/cseas002/HDSearch-Multinode/microsuite_files/midtier/* /mydata/HDSearch
for node in node1 node2 
do
sudo scp -r /mydata/HDSearch cseas002@$node:/mydata/
done

mkdir -p ~/results
mkdir -p ~/results/150US_PRE_FIXED

# Check if the directory exists, if not, create it
ssh node2 'mkdir -p ~/results/150US_PRE_FIXED'

nohup python3 run_experiment.py > ../no_pre.txt 150US_PRE_FIXED &

wait
scp node2:~/turbo* ~/results/150US_PRE_FIXED/

cd cseas_scripts
for name in ADAPTIVE_FIXED WITHOUT_PRE_FIXED 0US_PRE_FIXED 50US_PRE_FIXED 100US_PRE_FIXED 150US_PRE_FIXED
do
    bash get_times_script.sh $name $name.txt
done
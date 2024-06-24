#!/bin/bash

# Run with adaptive pre
sed -i 's/send_request_usecs_wait = .*/send_request_usecs_wait = 0;/' ./microsuite_files/midtier/mid_tier_server.cc
sed -i 's/adaptive = .*/adaptive = true;/' ./microsuite_files/midtier/mid_tier_server.cc

sudo cp /users/cseas002/HDSearch-Multinode/microsuite_files/client/* /mydata/HDSearch
sudo cp /users/cseas002/HDSearch-Multinode/microsuite_files/midtier/* /mydata/HDSearch
for node in node1 node2 
do
sudo scp -r /mydata/HDSearch cseas002@$node:/mydata/
done

mkdir -p ~/results
mkdir -p ~/results/bucket
mkdir -p ~/results/midtier
mkdir -p ~/results/bucket/ADAPTIVE_FIXEDNBW2
mkdir -p ~/results/midtier/ADAPTIVE_FIXEDNBW2

# Check if the directory exists, if not, create it
ssh node2 'mkdir -p ~/results/ADAPTIVE_FIXEDNBW2'

nohup python3 run_experiment.py > ../no_pre.txt ADAPTIVE_FIXEDNBW2 &


# NOW, YOU MUST WAIT
wait 

ssh node2 "sudo pkill tshark"
# Transfer the Wireshark text file to your local machine
scp node2:~/results/ADAPTIVE_FIXEDNBW2/wireshark.txt ~/results/ADAPTIVE_FIXEDNBW2/

scp node2:~/turbo* ~/results/bucket/ADAPTIVE_FIXEDNBW2/
scp node1:~/turbo* ~/results/midtier/ADAPTIVE_FIXEDNBW2/


# Run without pre-request
sed -i 's/send_request_usecs_wait = .*/send_request_usecs_wait = -1;/' ./microsuite_files/midtier/mid_tier_server.cc
sed -i 's/adaptive = .*/adaptive = false;/' ./microsuite_files/midtier/mid_tier_server.cc

sudo cp /users/cseas002/HDSearch-Multinode/microsuite_files/client/* /mydata/HDSearch
sudo cp /users/cseas002/HDSearch-Multinode/microsuite_files/midtier/* /mydata/HDSearch
for node in node1 node2 
do
sudo scp -r /mydata/HDSearch cseas002@$node:/mydata/
done

mkdir -p ~/results
mkdir -p ~/results/bucket/WITHOUT_PRE_FIXEDNBW2
mkdir -p ~/results/midtier/WITHOUT_PRE_FIXEDNBW2

# Check if the directory exists, if not, create it
ssh node2 'mkdir -p ~/results/WITHOUT_PRE_FIXEDNBW2'

nohup python3 run_experiment.py > ../no_pre.txt WITHOUT_PRE_FIXEDNBW2 &


# NOW, YOU MUST WAIT
wait 
scp node2:~/turbo* ~/results/bucket/WITHOUT_PRE_FIXEDNBW2
scp node1:~/turbo* ~/results/midtier/WITHOUT_PRE_FIXEDNBW2


# Run with 0us pre-request
sed -i 's/send_request_usecs_wait = .*/send_request_usecs_wait = 0;/' ./microsuite_files/midtier/mid_tier_server.cc
sed -i 's/adaptive = .*/adaptive = false;/' ./microsuite_files/midtier/mid_tier_server.cc

sudo cp /users/cseas002/HDSearch-Multinode/microsuite_files/client/* /mydata/HDSearch
sudo cp /users/cseas002/HDSearch-Multinode/microsuite_files/midtier/* /mydata/HDSearch
for node in node1 node2 
do
sudo scp -r /mydata/HDSearch cseas002@$node:/mydata/
done

mkdir -p ~/results
mkdir -p ~/results/bucket/0US_PRE_FIXEDNBW2
mkdir -p ~/results/midtier/0US_PRE_FIXEDNBW2

# Check if the directory exists, if not, create it
ssh node2 'mkdir -p ~/results/0US_PRE_FIXEDNBW2'

nohup python3 run_experiment.py > ../no_pre.txt 0US_PRE_FIXEDNBW2 &


# NOW, YOU MUST WAIT
wait 
scp node2:~/turbo* ~/results/bucket/0US_PRE_FIXEDNBW2
scp node1:~/turbo* ~/results/midtier/0US_PRE_FIXEDNBW2


# # Run with 50us pre-request
# sed -i 's/send_request_usecs_wait = .*/send_request_usecs_wait = 50;/' ./microsuite_files/midtier/mid_tier_server.cc
# sed -i 's/adaptive = .*/adaptive = false;/' ./microsuite_files/midtier/mid_tier_server.cc

# sudo cp /users/cseas002/HDSearch-Multinode/microsuite_files/client/* /mydata/HDSearch
# sudo cp /users/cseas002/HDSearch-Multinode/microsuite_files/midtier/* /mydata/HDSearch
# for node in node1 node2 
# do
# sudo scp -r /mydata/HDSearch cseas002@$node:/mydata/
# done

# mkdir -p ~/results
# mkdir -p ~/results/50US_PRE_FIXED

# # Check if the directory exists, if not, create it
# ssh node2 'mkdir -p ~/results/50US_PRE_FIXED'

# nohup python3 run_experiment.py > ../no_pre.txt 50US_PRE_FIXED &

# wait
# scp node2:~/turbo* ~/results/50US_PRE_FIXED/

# # Run with 100us pre-request
# sed -i 's/send_request_usecs_wait = .*/send_request_usecs_wait = 100;/' ./microsuite_files/midtier/mid_tier_server.cc
# sed -i 's/adaptive = .*/adaptive = false;/' ./microsuite_files/midtier/mid_tier_server.cc

# sudo cp /users/cseas002/HDSearch-Multinode/microsuite_files/client/* /mydata/HDSearch
# sudo cp /users/cseas002/HDSearch-Multinode/microsuite_files/midtier/* /mydata/HDSearch
# for node in node1 node2 
# do
# sudo scp -r /mydata/HDSearch cseas002@$node:/mydata/
# done

# mkdir -p ~/results
# mkdir -p ~/results/100US_PRE_FIXED

# # Check if the directory exists, if not, create it
# ssh node2 'mkdir -p ~/results/100US_PRE_FIXED'

# nohup python3 run_experiment.py > ../no_pre.txt 100US_PRE_FIXED &

# # NOW, YOU MUST WAIT
# wait 
# scp node2:~/turbo* ~/results/100US_PRE_FIXED/

# # Run with 150us pre-request
# sed -i 's/send_request_usecs_wait = .*/send_request_usecs_wait = 150;/' ./microsuite_files/midtier/mid_tier_server.cc
# sed -i 's/adaptive = .*/adaptive = false;/' ./microsuite_files/midtier/mid_tier_server.cc

# sudo cp /users/cseas002/HDSearch-Multinode/microsuite_files/client/* /mydata/HDSearch
# sudo cp /users/cseas002/HDSearch-Multinode/microsuite_files/midtier/* /mydata/HDSearch
# for node in node1 node2 
# do
# sudo scp -r /mydata/HDSearch cseas002@$node:/mydata/
# done

# mkdir -p ~/results
# mkdir -p ~/results/150US_PRE_FIXED

# # Check if the directory exists, if not, create it
# ssh node2 'mkdir -p ~/results/150US_PRE_FIXED'

# nohup python3 run_experiment.py > ../no_pre.txt 150US_PRE_FIXED &

# wait
# scp node2:~/turbo* ~/results/150US_PRE_FIXED/

cd cseas_scripts
for name in ADAPTIVE_FIXEDNBW2 WITHOUT_PRE_FIXEDNBW2 0US_PRE_FIXEDNBW2 # 50US_PRE_FIXED 100US_PRE_FIXED 150US_PRE_FIXED
do
    bash get_times_script.sh $name $name.txt
done
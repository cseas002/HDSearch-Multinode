#!/bin/bash

# Run without pre-request
# sed -i 's/send_request_time = .*/send_request_time = -1;/' ./microsuite_files/midtier/mid_tier_server.cc

# sudo cp /users/cseas002/HDSearch-Multinode/microsuite_files/client/* /mydata/HDSearch
# sudo cp /users/cseas002/HDSearch-Multinode/microsuite_files/midtier/* /mydata/HDSearch
# for node in node1 node2 
# do
# sudo scp -r /mydata/HDSearch cseas002@$node:/mydata/
# done

# nohup python3 run_experiment.py > ../no_pre.txt WITHOUT_PRE_SMT_DIS_NO_TASKSET2 &

# NOW, YOU MUST WAIT
# wait 

# # Run with pre-request immediately
sed -i 's/send_request_time = .*/send_request_time = 0;/' ./microsuite_files/midtier/mid_tier_server.cc

sudo cp /users/cseas002/HDSearch-Multinode/microsuite_files/client/* /mydata/HDSearch
sudo cp /users/cseas002/HDSearch-Multinode/microsuite_files/midtier/* /mydata/HDSearch
for node in node1 node2 
do
sudo scp -r /mydata/HDSearch cseas002@$node:/mydata/
done

nohup python3 run_experiment.py > ../pre2.txt WITH_PRE_0US_SMT_DIS_NO_TASKSET2 &

wait 

# Run with pre-request 50 us after
sed -i 's/send_request_time = .*/send_request_time = 50;/' ./microsuite_files/midtier/mid_tier_server.cc

sudo cp /users/cseas002/HDSearch-Multinode/microsuite_files/client/* /mydata/HDSearch
sudo cp /users/cseas002/HDSearch-Multinode/microsuite_files/midtier/* /mydata/HDSearch
for node in node1 node2 
do
sudo scp /mydata/HDSearch/microsuite_files/midtier/* cseas002@$node:/mydata/HDSearch/microsuite_files/midtier/*
done

nohup python3 run_experiment.py > ../50pre2.txt WITH_PRE_50US_SMT_DIS_NO_TASKSET2 &

wait 

# Run with pre-request 100 us after
sed -i 's/send_request_time = .*/send_request_time = 100;/' ./microsuite_files/midtier/mid_tier_server.cc

sudo cp /users/cseas002/HDSearch-Multinode/microsuite_files/midtier/* /mydata/HDSearch
for node in node1 node2 
do
sudo scp /mydata/HDSearch/microsuite_files/midtier/* cseas002@$node:/mydata/HDSearch/microsuite_files/midtier/*
done

nohup python3 run_experiment.py > ../100pre.txt WITH_PRE_100US_SMT_DIS_NO_TASKSET2 &

wait 
# Run with pre-request 150 us after
sed -i 's/send_request_time = .*/send_request_time = 150;/' ./microsuite_files/midtier/mid_tier_server.cc

sudo cp /users/cseas002/HDSearch-Multinode/microsuite_files/client/* /mydata/HDSearch
sudo cp /users/cseas002/HDSearch-Multinode/microsuite_files/midtier/* /mydata/HDSearch
for node in node1 node2 
do
sudo scp /mydata/HDSearch/microsuite_files/midtier/* cseas002@$node:/mydata/HDSearch/microsuite_files/midtier/*
done

nohup python3 run_experiment.py > ../1502pre.txt WITH_PRE_150US_SMT_DIS_NO_TASKSET2 &

wait

cd cseas_scripts
for name in WITHOUT_PRE_SMT_DIS_NO_TASKSET WITH_PRE_0US_SMT_DIS_NO_TASKSET WITH_PRE_50US_SMT_DIS_NO_TASKSET WITH_PRE_100US_SMT_DIS_NO_TASKSET WITH_PRE_150US_SMT_DIS_NO_TASKSET
do
    bash get_times_script.sh $name $name.txt
done
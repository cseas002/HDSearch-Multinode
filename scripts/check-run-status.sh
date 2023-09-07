#!/bin/bash

while [[ 1 -eq 1 ]]; 
do

output=$(sudo docker service logs microsuite_client --raw | grep -a "End of Actual Run" | wc -l)

if [[ $output -eq 1 ]]; then
	break
fi


output=$(sudo docker service logs microsuite_client --raw | grep -a "Average Response Time(ms):" | wc -l)

if [[ $output -eq 1 ]]; then
	break
fi

output=$(sudo docker service logs microsuite_client --raw | grep -a "Load generator failed" | wc -l)

if [[ $output -eq 1 ]]; then
	exit 1
fi

output=$(sudo docker service logs microsuite_client --raw | grep -a "Call Status Error Code:" | wc -l)

if [[ $output -eq 1 ]]; then
	exit 1
fi

sleep 1

done
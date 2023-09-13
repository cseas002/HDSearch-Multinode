#!/bin/bash

while [[ 1 -eq 1 ]]; 
do

output=$(sudo docker service logs microsuite_client --raw | grep "Calculate knn time" | wc -l)

if [[ $output -eq 1 ]]; then
	break
fi

sleep 1

done
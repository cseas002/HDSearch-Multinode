#!/bin/bash
###################
#
# Parameters 1: log file destination
# Parameters 2: hosts file
# Parameters 3: iteration
# Calculate PID by itself
#
############


#execute  telnet for memcached processing time
if [[ -z $1 || -z $2 ]]; then

        echo "Wrong arguments"
        echo "Enter log file, hosts file and iteration"
        exit
fi

host_file=$1
iteration=$2
echo "$host_file"
while [[ `sudo docker service logs microsuite_client --raw  | grep "End of Warmup Period" | wc -l ` != 1 ]];
do

     if [[ `sudo docker service logs microsuite_client --raw | grep -a "Call Status Error Code:" | wc -l` -eq "1"  ]]; then
        echo "!!!ERROR!!!!"
        exit 1
    fi

    echo "sleep"
    sleep 1
done

#extract hosts and PID
flag=0
i=0
while read -r line;
do
    if [[ "$line" == "[bucket]" ]]; then
        flag=1
        continue
    fi
    if [[ "$line" == "\n" && $flag -eq 1 ]]; then
        flag=0
        i=0
        break
    fi
    if [[ $flag -eq 1 ]]; then
        bucket_nodes[$i]=$line
        ((i=i+1))
    fi
  #  echo "$line"
done <$host_file


flag=0
i=0
while read -r line;
do
    if [[ "$line" == "[midtier]" ]]; then
        flag=1
        continue
    fi
    if [[ "$line" == "[bucket]" && $flag -eq 1 ]]; then
        flag=0
        i=0
        break
    fi
    if [[ $flag -eq 1 ]]; then
        midtier_nodes[$i]=$line
        ((i=i+1))
    fi
#    echo "$line"
done <$host_file

i=0
for item in ${bucket_nodes[*]};
do
    out=$(ssh $item "ps aux")
    bucket_pid[$i]=`echo "$out" | grep "bucket_server" | awk '{print $2}' | head -1`
    ((i=i+1))

done

i=0
for item in ${midtier_nodes[*]};
do
   echo "$item"
    out=$(ssh $item "ps aux")
    midtier_pid[$i]=`echo "$out" | grep "mid_tier_server" | awk '{print $2}' | head -1`
    ((i=i+1))
done

for i in "${!bucket_nodes[@]}";
do
    echo "${bucket_pid[$i]}"
    ssh ${bucket_nodes[$i]} "cd /users/ganton12/HDSearch-Multinode/profiler/; sudo /users/ganton12/HDSearch-Multinode/profiler/profiler.sh run_profiler $iteration ${bucket_pid[$i]}"
done

for i in "${!midtier_nodes[@]}";
do
    ssh ${midtier_nodes[$i]} "cd /users/ganton12/HDSearch-Multinode/profiler/; sudo /users/ganton12/HDSearch-Multinode/profiler/profiler.sh run_profiler $iteration ${midtier_pid[$i]}"

done

for item in ${bucket_nodes[*]};
do
    sudo python3 /users/ganton12/HDSearch-Multinode/profiler/profiler.py -n $item start
done

for item in ${midtier_nodes[*]};
do
    sudo python3 /users/ganton12/HDSearch-Multinode/profiler/profiler.py -n $item start
done

exit 0
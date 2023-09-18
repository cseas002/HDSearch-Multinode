#!/bin/bash

#!/bin/bash

export ANSIBLE_HOST_KEY_CHECKING=False
export PROFILER_HOME=~/HDSearch-Multinode/profiler

if [ -z $1 ]; then
  echo "wrong arguments pass number of nodes to monitor and range"
  echo "e.g ./setHosts.sh 2 2 4"
  exit
else
  start=$2
  end=$3
fi

echo "[profiler]" > hosts
for i in $(seq $start $end);
do
  echo $i
  echo "node$i" >> hosts
done



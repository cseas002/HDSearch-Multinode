#!/bin/bash

stop_processes() {
    ssh -A node1 "pkill \"server\""
    ssh -A node2 "pkill \"server\""
    echo "Processes killed"
}


start_processes() {
    stop_processes
    make

    
    # Copy the 'server' file to node1 and node2
    scp server node1:~/
    scp server node2:~/

    # Run server on node1 in the background and redirect output to a file
    ssh -A node1 "nohup ./server > server_node1.log 2>&1 & disown" &

    # Run server on node2 in the background and redirect output to a file
    ssh -A node2 "nohup ./server > server_node2.log 2>&1 & disown" &
}

case "$1" in
    start)
        start_processes 
        ;;
    stop)
        stop_processes
        ;;
    *)
        echo "Usage: $0 {setup|start|stop}"
        exit 1
        ;;
esac

exit 0

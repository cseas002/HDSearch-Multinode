#!/bin/bash

stop_processes() {
    ssh -A node1 "pkill \"server\""
    ssh -A node2 "pkill \"server\""
    echo "Processes killed"
}


start_processes() {
    stop_processes
    make

    scp server node1:~/
    scp server node2:~/

    ssh -A node1 "./server " &
    ssh -A node2 "./server " &
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

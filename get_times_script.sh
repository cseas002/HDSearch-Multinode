#!/bin/bash

if [ -z "$1" ]; then
    echo "Please provide a valid argument."
    exit 1
fi

if [ ! -d ~/data/$1 ]; then
    echo "Directory ~/data/$1 does not exist."
    exit 1
fi

mkdir -p ~/data2/
cp -r ~/data/$1 ~/data2/
cd ~/data2/$1

for folder in *
do
    cd $folder
    rm -r hdsearch
    echo $folder
    strings hdsearch_client | grep "Average Response Time"
    cd ..
done
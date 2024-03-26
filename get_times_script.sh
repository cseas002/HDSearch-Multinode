#!/bin/bash

if [ -z "$1" ]; then
    echo "Please provide the folder name (e.g., RUN_1)."
    exit 1
fi

if [ -z "$2" ]; then
    echo "Please provide the output file name ONLY THE NAME, IT WILL BE SAVED UNDER HOME DIRECTORY (~/)"
    exit 1
fi

if [ ! -d ~/data/$1 ]; then
    echo "Directory ~/data/$1 does not exist."
    exit 1
fi

output_file=~/$2

rm $output_file

mkdir -p ~/data2/
cp -r ~/data/$1 ~/data2/
cd ~/data2/$1

# Array to store the average and 99th percentile values for each m
declare -A averages
declare -A percentiles

# Function to calculate average
calculate_average() {
    local sum=0
    local count=0
    for value in "$@"; do
        sum=$(echo "$sum + $value" | bc)
        count=$((count + 1))
    done
    echo "scale=2; $sum / $count" | bc
}

# Function to calculate 99th percentile average
calculate_percentile_average() {
    local sum=0
    local count=0
    for value in "$@"; do
        sum=$(echo "$sum + $value" | bc)
        count=$((count + 1))
    done
    echo "scale=2; $sum / $count" | bc
}

# Loop through each folder
for folder in *; do
    # Extract the 'm' value from folder name
    qps_value=$(echo "$folder" | awk -F '=' '{print $NF}' | awk -F'-' '{print $(NF-1)}')
    cd "$folder"
    rm -r hdsearch
    
    echo "$folder" >> "$output_file"
    output=$(strings hdsearch_client | grep -A 1 "Average Response Time")
    echo "$output" >> "$output_file"

    # Extract average and 99th percentile values
    average=$(echo "$output" | head -n 1 | awk '{print $4}')
    percentile_99=$(echo "$output" | tail -n 1 | awk '{print $(NF-2)}')


    # Store values in arrays indexed by 'm'
    if [ -z "${averages[$qps_value]}" ]; then
        averages[$qps_value]="$average"
    else
        averages[$qps_value]="${averages[$qps_value]} $average"
    fi
    
    if [ -z "${percentiles[$qps_value]}" ]; then
        percentiles[$qps_value]="$percentile_99"
    else
        percentiles[$qps_value]="${percentiles[$qps_value]} $percentile_99"
    fi
    
    cd ..
done

# Calculate averages for each 'm'
printf "\nResults:\n\n" >> "$output_file"

for qps_value in "${!averages[@]}"; do
    average=$(calculate_average ${averages[$qps_value]})
    percentile_average=$(calculate_percentile_average ${percentiles[$qps_value]})
    echo "Average $qps_value: $average" >> "$output_file"
    echo "99th Percentile tail latency $qps_value: $percentile_average" >> "$output_file"
    echo "" >> "$output_file"
done

echo "Results saved to $output_file"

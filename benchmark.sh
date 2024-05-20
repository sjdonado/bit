#!/bin/bash

api_url="http://localhost:4001/api/links"
num_links=100
num_requests=10
resource_usage_interval=1  # Interval in seconds for resource usage logging

function get_resource_usage {
    while true; do
        docker stats --no-stream --format "{{.MemUsage}} {{.CPUPerc}}" url-shortener >> resource_usage.txt
        sleep $resource_usage_interval
    done
}

function calculate_average_usage {
    total_mem=0
    count=0

    while read -r line; do
        mem=$(echo $line | awk '{print $1}')

        # Convert memory to MiB if necessary
        if [[ $mem == *MiB ]]; then
            mem=$(echo $mem | sed 's/MiB//')
        elif [[ $mem == *GiB ]]; then
            mem=$(echo $mem | sed 's/GiB//')
            mem=$(echo "$mem * 1024" | bc)
        fi

        total_mem=$(echo "$total_mem + $mem" | bc)
        ((count++))
    done < resource_usage.txt

    avg_mem=$(echo "scale=2; $total_mem / $count" | bc)
    rm resource_usage.txt

    echo "Average Memory Usage: $avg_mem MiB"
}

function measure {
    total_time=0
    declare -a refer_links

    # Start resource usage logging in the background
    nohup bash -c "$(declare -f get_resource_usage); get_resource_usage" &> /dev/null &
    resource_usage_pid=$!
    disown

    echo "Creating $num_links short links..."
    for ((i=1; i<=num_links; i++)); do
        response=$(curl --silent --request POST \
                        --url $api_url \
                        --header "X-Api-Key: $api_key" \
                        --header "Content-Type: application/json" \
                        --data "{ \"url\": \"https://kagi.com\" }")
        # echo "API Response for link $i: $response"

        refer=$(echo $response | awk -F'"' '/"refer":/{print $(NF-1)}')
        if [[ -n $refer ]]; then
            refer_links+=("$refer")
        else
            echo "Failed to create short link $i"
        fi
    done

    echo "Accessing each link $num_requests times concurrently..."
    > times.txt  # Ensure times.txt is created and empty

    for refer in "${refer_links[@]}"; do
        for ((i=1; i<=num_requests; i++)); do
            (
                start_time=$(date +%s%6N)
                curl -s "$refer" >> /dev/null
                end_time=$(date +%s%6N)
                elapsed_time=$(echo "$end_time - $start_time" | bc)
                echo $elapsed_time >> times.txt
            ) &
        done
    done

    wait

    # Stop resource usage logging
    if kill -0 $resource_usage_pid 2>/dev/null; then
        kill $resource_usage_pid
    fi

    # Read all elapsed times and calculate total
    while read -r time; do
        total_time=$(echo "$total_time + $time" | bc)
    done < times.txt
    rm times.txt

    echo "****Results****"

    calculate_average_usage
    echo "Average Response Time: $(echo "scale=2; $total_time / ($num_links * $num_requests)" | bc) µs"
}

echo "Setup..."

docker-compose up -d
# Ensure migrations are done
docker-compose exec -T app migrate

# Create a new user and capture the API key
output=$(docker-compose exec -T app cli --create-user=Admin)
api_key=$(echo "$output" | awk -F' ' '/X-Api-Key:/{print $NF}')
echo "Captured API Key: $api_key"

echo "Waiting for database to be ready..."
sleep 5

measure

# Clean up
docker-compose down

#!/bin/bash

api_url="http://localhost:4001/api/links"
num_links=1000
num_requests=10
resource_usage_interval=1  # Interval in seconds for resource usage logging

semaphore="/tmp/semaphore"
max_concurrent_processes=$(ulimit -u)  # Adjust this number based on your system's capability

# Initialize semaphore
mkfifo $semaphore
exec 3<> $semaphore
rm $semaphore

for ((i=0; i<max_concurrent_processes; i++)); do
    echo >&3
done

echo "Semaphore initialized with $max_concurrent_processes slots."

function get_resource_usage {
    while true; do
        docker stats --no-stream --format "table {{.MemUsage}} {{.CPUPerc}}" bit-app-1 | awk 'NR>1 {print "Memory:", $1, "CPU:", $2}' >> resource_usage.txt
        sleep $resource_usage_interval
    done
}

function calculate_average_usage {
    total_mem=0
    total_cpu=0
    count=0

    while read -r line; do
        if echo $line | grep -q 'Memory'; then
            mem=$(echo $line | awk '{print $2}' | sed 's/MiB//')
            total_mem=$(echo "$total_mem + $mem" | bc)
        elif echo $line | grep -q 'CPU'; then
            cpu=$(echo $line | awk '{print $2}' | sed 's/%//')
            total_cpu=$(echo "$total_cpu + $cpu" | bc)
        fi
        ((count++))
    done < resource_usage.txt

    avg_mem=$(echo "scale=2; $total_mem / ($count / 2)" | bc)  # Since there are 2 lines per interval
    avg_cpu=$(echo "scale=2; $total_cpu / ($count / 2)" | bc)
    rm resource_usage.txt

    echo "Average Memory Usage: $avg_mem MiB"
    echo "Average CPU Usage: $avg_cpu%"
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
        refer=$(echo $response | awk -F'"' '/"refer":/{print $(NF-1)}')

        if [[ -n $refer ]]; then
            refer_links+=("$refer")
            if (( i % 100 == 0 )); then
                echo "Created short link $i/$num_links"
            fi
        else
            echo "Failed to create short link $i"
            echo $response
            exit 1
        fi
    done

    echo "Accessing each link $num_requests times concurrently..."
    > times.txt  # Ensure times.txt is created and empty

    total_accesses=$((num_links * num_requests))
    accesses_done=0

    for refer in "${refer_links[@]}"; do
        for ((i=1; i<=num_requests; i++)); do
            # Wait for a slot
            read -u 3
            {
                start_time=$(date +%s%6N)
                curl -s "$refer" >> /dev/null
                end_time=$(date +%s%6N)
                elapsed_time=$(echo "$end_time - $start_time" | bc)
                echo $elapsed_time >> times.txt
                # Release the slot
                echo >&3

                ((accesses_done++))
                if (( accesses_done % 10 == 0 )); then
                    echo "Accessed $accesses_done/$total_accesses"
                fi
            } &
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
if [ $? -ne 0 ]; then
    echo "Failed to start Docker containers."
    exit 1
fi

# Create a new user and capture the API key
output=$(docker-compose exec -T app cli --create-user=Admin)
api_key=$(echo "$output" | awk -F' ' '/X-Api-Key:/{print $NF}')
echo "Captured API Key: $api_key"

echo "Waiting for database to be ready..."
sleep 5

measure

# Clean up
docker-compose down

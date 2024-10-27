#!/bin/bash

# Check dependencies
if ! command -v bombardier &> /dev/null; then
    echo "Error: bombardier is not installed. Please install it to proceed."
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed. Please install it to proceed."
    exit 1
fi

server_url="http://localhost:4001"
api_url="${server_url}/api/links"
num_links=10000     # Total number of links to create by curl
num_requests=10000  # Total number of requests to perform by bombardier
concurrency=100     # Number of multiple requests to make at a time
resource_usage_interval=1  # Interval in seconds for resource usage logging
container_name="bit"

function monitor_resource_usage {
    echo "Timestamp,CPU(%),Memory(MB)" > resource_usage.csv
    while :; do
        stats=$(docker stats --no-stream --format "{{.CPUPerc}},{{.MemUsage}}" $container_name)
        cpu=$(echo $stats | awk -F',' '{print $1}' | sed 's/%//')
        mem=$(echo $stats | awk -F',' '{print $2}' | awk '{print $1}')
        timestamp=$(date +%s)
        echo "$timestamp,$cpu,$mem" >> resource_usage.csv
        sleep $resource_usage_interval
    done
}

echo "Setting up..."

docker compose up -d
if [ $? -ne 0 ]; then
    echo "Failed to start Docker containers."
    exit 1
fi

output=$(docker compose exec -T app cli --create-user=Admin)
api_key=$(echo "$output" | awk -F' ' '/X-Api-Key:/{print $NF}')
echo "Captured API Key: $api_key"

# Ensure the API key is valid
if [[ -z "$api_key" ]]; then
    echo "Error: API key could not be retrieved."
    exit 1
fi

echo "Waiting for the application to be ready..."
until curl --silent --head --fail --header "X-Api-Key: $api_key" "$server_url/api/ping"; do
    sleep 2
done

echo "Starting resource usage monitoring..."
monitor_resource_usage &  # Run in the background
monitor_pid=$!

echo "Creating $num_links short links..."
batch_size=$((num_links / 10))
progress_bar_width=50

for ((batch=1; batch<=num_links; batch+=batch_size)); do
    progress=$(( (batch - 1) * progress_bar_width / num_links))
    bar=$(printf "%-${progress_bar_width}s" "#" | tr ' ' '#')
    printf "\r[%-${progress_bar_width}s] %d%%" "${bar:0:progress}" $(((batch - 1) * 100 / num_links))

    # Launch a batch of background processes
    for ((i=batch; i<batch+batch_size && i<=num_links; i++)); do
        unique_url="https://example.com/${RANDOM}-${i}"
        curl --silent --request POST \
             --url "$api_url" \
             --header "X-Api-Key: $api_key" \
             --header "Content-Type: application/json" \
             --data "{ \"url\": \"$unique_url\" }" > /dev/null &
    done
    wait  # Wait for all processes in the current batch to finish

    progress=$((batch * progress_bar_width / num_links))
    bar=$(printf "%-${progress_bar_width}s" "#" | tr ' ' '#')
    printf "\r[%-${progress_bar_width}s] %d%%" "${bar:0:progress}" $((batch * 100 / num_links))
done

printf "\r[%-${progress_bar_width}s] 100%%\n" "$(printf "%-${progress_bar_width}s" "#" | tr ' ' '#')"
echo "Link creation complete: $num_links links created."

echo "Fetching all created links from /api/links..."
all_links_response=$(curl --silent --request GET \
                          --url "$api_url" \
                          --header "X-Api-Key: $api_key" \
                          --header "Content-Type: application/json")

links=($(echo "$all_links_response" | jq -r '.data[] | .refer'))
if [[ ${#links[@]} -ne $num_links ]]; then
    echo "Error: Expected $num_links links but found ${#links[@]}."
    exit 1
fi

random_link="${links[RANDOM % ${#links[@]}]}"
echo "Selected link for benchmarking: $random_link"

echo "Starting benchmark with Bombardier..."
bombardier -c $concurrency -n $num_requests "$random_link"

echo "Benchmark completed."

# Stop resource monitoring
kill $monitor_pid 2>/dev/null

echo "Analyzing resource usage..."

total_cpu=0
total_mem=0
count=0

# Process each line in the resource usage log
while IFS=',' read -r timestamp cpu mem; do
    # Skip the header line
    if [[ $timestamp != "Timestamp" ]]; then
        total_cpu=$(echo "$total_cpu + $cpu" | bc)
        total_mem=$(echo "$total_mem + $mem" | bc)
        ((count++))
    fi
done < resource_usage.csv

# Calculate averages; if count is 0, output will be 0.00
avg_cpu=$(echo "scale=2; $total_cpu / ($count == 0 ? 1 : $count)" | bc)
avg_mem=$(echo "scale=2; $total_mem / ($count == 0 ? 1 : $count)" | bc)

echo "**** Results ****"
echo "Average CPU Usage: $avg_cpu%"
echo "Average Memory Usage: $avg_mem MiB"

echo "Cleaning up..."
rm resource_usage.csv
docker compose down

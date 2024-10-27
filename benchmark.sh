#!/bin/bash

# Configuration variables
server_url="http://localhost:4000"
api_url="${server_url}/api/links"
num_links=1000
num_requests=100000
concurrency=100
resource_usage_interval=1
container_name="bit"

pipe="/tmp/progress_pipe"

check_dependencies() {
    if ! command -v bombardier &> /dev/null; then
        echo "Error: bombardier is not installed. Please install it to proceed."
        exit 1
    fi

    if ! command -v jq &> /dev/null; then
        echo "Error: jq is not installed. Please install it to proceed."
        exit 1
    fi
}

setup_containers() {
    echo "Setting up..."
    docker compose up -d
    if [ $? -ne 0 ]; then
        echo "Failed to start Docker containers."
        exit 1
    fi

    output=$(docker compose exec -T app cli --create-user=Admin)
    api_key=$(echo "$output" | awk -F' ' '/X-Api-Key:/{print $NF}')
    echo "Captured API Key: $api_key"

    if [[ -z "$api_key" ]]; then
        echo "Error: API key could not be retrieved."
        exit 1
    fi

    echo "Waiting for the application to be ready..."
    until curl --silent --head --fail --header "X-Api-Key: $api_key" "$server_url/api/ping"; do
        sleep 2
    done
}

monitor_resource_usage() {
    echo "Starting resource usage monitoring..."
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

create_links() {
    local batch_size=$((num_links / 10))
    local progress_bar_width=50
    local completed_links=0
    local active_requests=0

    local -a url_queue
    mkfifo "$pipe"
    echo "Creating $num_links short links concurrently in batches of $batch_size..."

    # Populate the queue with unique URLs
    for ((i=1; i<=num_links; i++)); do
        url_queue+=("https://example.com/${i}-${num_links}")
    done

    # Background reader to update progress bar
    while read -r line < "$pipe"; do
        ((completed_links++))

        progress=$((completed_links * progress_bar_width / num_links))
        bar=$(printf "%-${progress_bar_width}s" "#" | tr ' ' '#')
        printf "\r[%-${progress_bar_width}s] %d%%" "${bar:0:progress}" $((completed_links * 100 / num_links))
    done &

    # Main loop for processing links
    while [ "${#url_queue[@]}" -gt 0 ] || [ "$active_requests" -gt 0 ]; do
        if (( active_requests < batch_size )) && [ "${#url_queue[@]}" -gt 0 ]; then
            next_url="${url_queue[0]}"
            url_queue=("${url_queue[@]:1}")

            # Send the request and update active_requests counter
            (curl --silent --request POST \
                  --url "$api_url" \
                  --header "X-Api-Key: $api_key" \
                  --header "Content-Type: application/json" \
                  --data "{ \"url\": \"$next_url\" }" > /dev/null && echo "done" > "$pipe" && ((active_requests--))) &
            ((active_requests++))
        else
            sleep 0.1
        fi
    done

    printf "\r[%-${progress_bar_width}s] 100%%\n" "$(printf "%-${progress_bar_width}s" "#" | tr ' ' '#')"
    echo "Link creation complete: $num_links links created."
}

run_benchmark() {
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
}

analyze_resource_usage() {
    echo "Analyzing resource usage..."
    total_cpu=0
    total_mem=0
    count=0

    while IFS=',' read -r timestamp cpu mem; do
        if [[ $timestamp != "Timestamp" ]]; then
            total_cpu=$(echo "$total_cpu + $cpu" | bc)
            total_mem=$(echo "$total_mem + $mem" | bc)
            ((count++))
        fi
    done < resource_usage.csv

    avg_cpu=$(echo "scale=2; $total_cpu / ($count == 0 ? 1 : $count)" | bc)
    avg_mem=$(echo "scale=2; $total_mem / ($count == 0 ? 1 : $count)" | bc)

    echo "**** Results ****"
    echo "Average CPU Usage: $avg_cpu%"
    echo "Average Memory Usage: $avg_mem MiB"
}

cleanup() {
    rm -f "$pipe" resource_usage.csv
    docker compose down
}

main() {
    check_dependencies
    setup_containers

    monitor_resource_usage &  # Start monitoring in the background
    monitor_pid=$!
    trap 'kill $monitor_pid; cleanup; exit' INT

    create_links
    run_benchmark
    analyze_resource_usage
    cleanup
}

mainain

#!/bin/bash

# Configuration variables
server_url="http://localhost:4000"
api_url="${server_url}/api/links"
num_links=10000
num_requests=10000
concurrency=100
resource_usage_interval=1
container_name="bit"

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
    echo "Timestamp,CPU,Memory" > resource_usage.csv
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
    local temp_file=$(mktemp)

    echo "Creating $num_links short links with $concurrency conrurrent requests..."

    # Populate URLs into a file to feed into curl
    for ((i=1; i<=num_links; i++)); do
        url="https://example.com/${i}-${num_links}"
        echo "--next" >> "$temp_file"
        echo "--request POST" >> "$temp_file"
        echo "--url \"$api_url\"" >> "$temp_file"
        echo "--header \"X-Api-Key: $api_key\"" >> "$temp_file"
        echo "--header \"Content-Type: application/json\"" >> "$temp_file"
        echo "--data \"{ \\\"url\\\": \\\"$url\\\" }\"" >> "$temp_file"
    done

    curl --parallel --parallel-immediate --parallel-max $concurrency --config "$temp_file" --silent --write-out "%{http_code}\n" > /dev/null

    echo "Link creation complete: $num_links links created."

    # Clean up
    rm -f "$temp_file"
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
        # Skip header line and lines with empty cpu or mem values
        if [[ $timestamp != "Timestamp" && -n $cpu && -n $mem ]]; then
            mem=${mem%MiB}

            total_cpu=$(echo "$total_cpu + $cpu" | bc)
            total_mem=$(echo "$total_mem + $mem" | bc)
            ((count++))
        fi
    done < resource_usage.csv

    avg_cpu=0.00
    avg_mem=0.00

    if (( count > 0 )); then
        avg_cpu=$(echo "scale=2; $total_cpu / $count" | bc)
        avg_mem=$(echo "scale=2; $total_mem / $count" | bc)
    fi

    echo "**** Results ****"
    echo "Average CPU Usage: $avg_cpu%"
    echo "Average Memory Usage: $avg_mem MiB"
}

cleanup() {
    rm -f resource_usage.csv
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

    kill $monitor_pid
    analyze_resource_usage
    cleanup
}

main

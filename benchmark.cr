#!/usr/bin/env crystal

require "http/client"
require "json"
require "file_utils"

# Configuration variables
SERVER_URL = "http://localhost:4000"
API_URL = "#{SERVER_URL}/api/links"
API_KEY = "secure_api_key_1"
NUMBER_OF_REQUESTS = 100000

CONTAINER_NAME = "bit"
STATS_FILE = "resource_usage.txt"

class ResourceMonitor
  def initialize(@container_name : String)
    @running = false
    @stats = [] of {timestamp: Time, cpu: Float64, memory: Float64}
  end

  def start
    @running = true
    @stats.clear

    # Initialize stats file with header
    File.write(STATS_FILE, "Timestamp\tCPU(%)\tMemory(MiB)\n")

    spawn do
      while @running
        if stat = capture_stats
          # Append each measurement directly to the file
          File.open(STATS_FILE, "a") do |file|
            file.puts "#{stat[:timestamp].to_unix}\t#{stat[:cpu]}\t#{stat[:memory]}"
          end
          @stats << stat
        end
      end
    end
  end

  def stop
    @running = false
  end

  def avg_stats
    return {cpu: 0.0, memory: 0.0} if @stats.empty?

    total_cpu = 0.0
    total_memory = 0.0
    @stats.each do |stat|
      total_cpu += stat[:cpu]
      total_memory += stat[:memory]
    end

    {
      cpu: total_cpu / @stats.size,
      memory: total_memory / @stats.size
    }
  end

  private def capture_stats
    output = IO::Memory.new
    process = Process.run(
      "docker", ["stats", "--no-stream", "--format", "{{.CPUPerc}},{{.MemUsage}}", @container_name],
      output: output
    )

    if process.success?
      line = output.to_s.strip
      parts = line.split(",")
      if parts.size == 2
        cpu_part = parts[0].gsub("%", "").to_f

        # Extract the memory value properly by removing the "MiB" suffix
        mem_string = parts[1].split.first
        mem_part = mem_string.gsub(/[A-Za-z]+$/, "").to_f

        return {timestamp: Time.utc, cpu: cpu_part, memory: mem_part}
      end
    end
    nil
  end
end

def check_dependencies
  {"docker", "jq", "bombardier"}.each do |cmd|
    process = Process.run("which", [cmd], output: Process::Redirect::Close)
    unless process.success?
      puts "Error: #{cmd} is not installed. Please install it to proceed."
      exit(1)
    end
  end
end

def setup_containers
  puts "Setting up..."

  process = Process.run("docker", ["compose", "up", "-d"])
  unless process.success?
    puts "Failed to start Docker containers."
    exit(1)
  end

  puts "Waiting for the application to be ready..."
  until begin
          HTTP::Client.get("#{SERVER_URL}/api/ping").success?
        rescue
          false
        end
    sleep 1.seconds
  end

  puts "Seeding the database..."
  process = Process.run("docker", ["compose", "exec", "app", "sh", "-c", "sqlite3 ./sqlite/data.db < ./db/seed.sql"])

  unless process.success?
    puts "Error on seeding database"
    exit(1)
  end

  puts "Checking seed results..."
  until begin
          HTTP::Client.get(
            "#{API_URL}?limit=1",
            headers: HTTP::Headers{"X-Api-Key" => API_KEY}
          ).success?
        rescue
          false
        end
    sleep 2.seconds
  end
end

def run_benchmark
  puts "Fetching all created links from /api/links..."

  response = HTTP::Client.get(
    "#{API_URL}?limit=10000",
    headers: HTTP::Headers{"X-Api-Key" => API_KEY}
  )

  sleep 2.seconds
  unless response.success?
    puts "Failed to fetch links. Status: #{response.status_code}"
    exit(1)
  end

  data = JSON.parse(response.body)
  links = data["data"].as_a.map { |link| link["refer"].as_s }

  random_link = links.sample
  puts "Selected link for benchmarking: #{random_link}"

  puts "Starting benchmark with Bombardier..."

  sleep 2.seconds
  process = Process.new(
    "bombardier",
    ["-n", NUMBER_OF_REQUESTS.to_s, "-l", "--disableKeepAlives", random_link],
    output: Process::Redirect::Inherit,
    error: Process::Redirect::Inherit
  )

  status = process.wait

  if status.success?
    puts "Benchmark completed successfully."
  else
    puts "Bombardier failed with error code: #{status.exit_code}"
    exit(1)
  end
end

def analyze_resource_usage
  puts "Analyzing resource usage..."

  sleep 2.seconds
  if File.exists?(STATS_FILE)
    lines = File.read_lines(STATS_FILE)
    # Skip header
    lines = lines[1..-1] if lines.size > 0

    if lines.size > 0
      total_cpu = 0.0
      total_memory = 0.0
      peak_cpu = 0.0
      peak_memory = 0.0

      lines.each do |line|
        fields = line.split("\t")
        if fields.size >= 3
          begin
            cpu = fields[1].to_f
            memory = fields[2].to_f

            total_cpu += cpu
            total_memory += memory

            # Track peaks in a single pass
            peak_cpu = cpu if cpu > peak_cpu
            peak_memory = memory if memory > peak_memory
          rescue
            # Skip invalid lines
          end
        end
      end

      avg_cpu = total_cpu / lines.size
      avg_memory = total_memory / lines.size

      stats_summary = <<-STATS
      **** Resource Usage Statistics ****
        Measurements: #{lines.size}
        Average CPU Usage: #{avg_cpu.round(2)}%
        Average Memory Usage: #{avg_memory.round(2)} MiB
        Peak CPU Usage: #{peak_cpu.round(2)}%
        Peak Memory Usage: #{peak_memory.round(2)} MiB

      STATS

      File.open(STATS_FILE, "a") do |file|
        file.puts "\n" + stats_summary
      end

      puts File.read(STATS_FILE)
    else
      puts "No resource usage data collected."
    end
  else
    puts "Resource usage file not found."
  end
end

def cleanup
  Process.run("docker", ["compose", "down"])
  puts "Cleanup completed. Resource usage data saved in #{STATS_FILE}"
end

def main
  check_dependencies
  setup_containers

  monitor = ResourceMonitor.new(CONTAINER_NAME)
  monitor.start

  begin
    run_benchmark

    monitor.stop
    analyze_resource_usage
  ensure
    cleanup
  end
end

main

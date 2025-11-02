#!/usr/bin/env crystal

require "http/client"
require "json"

SERVER_URL = "http://localhost:4000"
API_URL = "#{SERVER_URL}/api/links"
API_KEY = "secure_api_key_1"
NUMBER_OF_REQUESTS = 100000

APP_COMMAND = "./bit"
APP_ARGS = [] of String  # Add any arguments if needed
STATS_FILE = "resource_usage.log"
APP_LOG_FILE = "app_output.log"

class ResourceMonitor
  def initialize(@pid : Int32)
    @running = false
    @stats = [] of {timestamp: Time, cpu: Float64, memory: Float64}
  end

  def start
    @running = true
    @stats.clear
    File.write(STATS_FILE, "Timestamp\tCPU(%)\tMemory(MiB)\n")

    spawn do
      while @running
        if stat = capture_stats
          File.open(STATS_FILE, "a") do |file|
            file.puts "#{stat[:timestamp].to_unix}\t#{stat[:cpu]}\t#{stat[:memory]}"
          end
          @stats << stat
        end
        sleep 1.seconds
      end
    end
  end

  def stop
    @running = false
    sleep 1.seconds
  end

  private def capture_stats
    output = IO::Memory.new
    process = Process.run(
      "ps", ["-p", @pid.to_s, "-o", "%cpu,%mem,rss"],
      output: output
    )

    if process.success?
      lines = output.to_s.strip.split("\n")
      if lines.size >= 2
        data_line = lines[1].strip.split
        if data_line.size >= 3
          cpu = data_line[0].to_f
          # RSS is in KB on macOS, convert to MiB
          memory_kb = data_line[2].to_f
          memory_mib = memory_kb / 1024.0

          return {timestamp: Time.utc, cpu: cpu, memory: memory_mib}
        end
      end
    end
    nil
  end

  def print_summary
    return if @stats.empty?

    total_cpu = 0.0
    total_memory = 0.0
    peak_cpu = 0.0
    peak_memory = 0.0

    @stats.each do |stat|
      total_cpu += stat[:cpu]
      total_memory += stat[:memory]
      peak_cpu = stat[:cpu] if stat[:cpu] > peak_cpu
      peak_memory = stat[:memory] if stat[:memory] > peak_memory
    end

    avg_cpu = total_cpu / @stats.size
    avg_memory = total_memory / @stats.size

    summary = <<-STATS

    **** Resource Usage Statistics ****
      Measurements: #{@stats.size}
      Average CPU Usage: #{avg_cpu.round(2)}%
      Average Memory Usage: #{avg_memory.round(2)} MiB
      Peak CPU Usage: #{peak_cpu.round(2)}%
      Peak Memory Usage: #{peak_memory.round(2)} MiB

    STATS

    File.open(STATS_FILE, "a") do |file|
      file.puts summary
    end

    puts summary
  end
end

def start_application : Process
  puts "Starting application: #{APP_COMMAND}..."
  puts "Application output will be saved to: #{APP_LOG_FILE}"

  # Open log file for writing
  log_file = File.open(APP_LOG_FILE, "w")

  process = Process.new(
    APP_COMMAND,
    APP_ARGS,
    output: log_file,
    error: log_file
  )

  puts "Application started with PID: #{process.pid}"
  process
end

def stop_application(process : Process)
  puts "\nStopping application..."
  process.signal(Signal::TERM)

  # Give it a few seconds to shut down gracefully
  sleep 3.seconds

  # Force kill if still running
  begin
    process.signal(Signal::KILL)
  rescue
    # Process already terminated
  end

  puts "Application stopped."
end

def check_dependencies
  {"bombardier", "sqlite3"}.each do |cmd|
    process = Process.run("which", [cmd], output: Process::Redirect::Close)
    unless process.success?
      puts "Error: #{cmd} is not installed. Please install it to proceed."
      case cmd
      when "bombardier"
        puts "  brew install bombardier"
      when "sqlite3"
        puts "  brew install sqlite3"
      end
      exit(1)
    end
  end
end

def wait_for_server
  puts "Checking if server is ready at #{SERVER_URL}..."

  30.times do
    begin
      if HTTP::Client.get("#{SERVER_URL}/api/ping").success?
        puts "Server is ready!"
        return
      end
    rescue
      # Server not ready yet
    end
    sleep 1.seconds
    print "."
  end

  puts "\nError: Server is not responding. Please start your application first."
  exit(1)
end

def run_benchmark
  puts "Fetching links from API..."

  response = HTTP::Client.get(
    "#{API_URL}?limit=10000",
    headers: HTTP::Headers{"X-Api-Key" => API_KEY}
  )

  unless response.success?
    puts "Failed to fetch links. Status: #{response.status_code}"
    puts "Make sure your server is running and the API key is correct."
    exit(1)
  end

  data = JSON.parse(response.body)
  links = data["data"].as_a.map { |link| link["refer"].as_s }

  if links.empty?
    puts "No links found. Please seed your database first."
    exit(1)
  end

  random_link = links.sample
  puts "Selected link: #{random_link}"
  puts "\nStarting benchmark with #{NUMBER_OF_REQUESTS} requests..."

  sleep 2.seconds

  process = Process.new(
    "bombardier",
    ["-n", NUMBER_OF_REQUESTS.to_s, "-l", "--disableKeepAlives", random_link],
    output: Process::Redirect::Inherit,
    error: Process::Redirect::Inherit
  )

  status = process.wait

  if status.success?
    puts "\nBenchmark completed successfully."
  else
    puts "\nBombardier failed with error code: #{status.exit_code}"
    exit(1)
  end
end

def seed_database
  puts "Seeding database..."

  unless File.exists?("./db/seed.sql")
    puts "Warning: ./db/seed.sql not found. Skipping database seeding."
    return
  end

  unless File.exists?("./sqlite/data.db")
    puts "Warning: ./sqlite/data.db not found. Database may not be initialized."
  end

  process = Process.run(
    "sqlite3",
    ["./sqlite/data.db"],
    input: File.open("./db/seed.sql"),
    output: Process::Redirect::Inherit,
    error: Process::Redirect::Inherit
  )

  if process.success?
    puts "Database seeded successfully."
  else
    puts "Warning: Database seeding failed. Continuing anyway..."
  end
end

def main
  check_dependencies

  app_process = start_application

  begin
    wait_for_server

    seed_database

    # Give it a moment to settle
    sleep 2.seconds

    monitor = ResourceMonitor.new(app_process.pid.to_i32)
    monitor.start

    run_benchmark

    monitor.stop
    monitor.print_summary

    puts "\n**** Files Generated ****"
    puts "  Resource stats: #{STATS_FILE}"
    puts "  Application log: #{APP_LOG_FILE}"
  ensure
    # Always stop the application
    stop_application(app_process)
  end
end

main

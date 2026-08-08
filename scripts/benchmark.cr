#!/usr/bin/env crystal

require "http/client"
require "json"

PORT               = "4001"
APP_URL            = "http://localhost:#{PORT}"
API_URL            = "#{APP_URL}/api/links"
API_KEY            = "secure_api_key_1"
NUMBER_OF_REQUESTS = ENV["BENCHMARK_REQUESTS"]?.try(&.to_i) || 100000
CONNECTIONS        = ENV["BENCHMARK_CONNECTIONS"]?.try(&.to_i) || 125
DISABLE_KEEP_ALIVES = ENV["BENCHMARK_DISABLE_KEEP_ALIVES"]? != "false"

APP_COMMAND  = "./bin/bit"
APP_ARGS     = [] of String
STATS_FILE   = "resource_usage.log"
APP_LOG_FILE = "app_output.log"

DATABASE_URL  = "sqlite3://./sqlite/data.benchmark.db?journal_mode=wal&synchronous=normal&foreign_keys=true"
DATABASE_FILE = "./sqlite/data.benchmark.db"

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

  log_file = File.open(APP_LOG_FILE, "w")

  process = Process.new(
    APP_COMMAND,
    APP_ARGS,
    output: log_file,
    error: log_file,
    env: {
      "DATABASE_URL" => DATABASE_URL,
      "APP_URL"      => APP_URL,
      "PORT"         => PORT,
    }
  )

  puts "Application started with PID: #{process.pid}"
  puts "Using database: #{DATABASE_FILE}"
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
  {"bombardier", "sqlite3", "micrate"}.each do |cmd|
    process = Process.run("which", [cmd], output: Process::Redirect::Close)
    unless process.success?
      puts "Error: #{cmd} is not installed. Please install it to proceed."
      case cmd
      when "bombardier"
        puts "  brew install bombardier"
      when "sqlite3"
        puts "  brew install sqlite3"
      when "micrate"
        puts "  shards install"
      end
      exit(1)
    end
  end
end

def wait_for_server
  puts "Checking if server is ready at #{APP_URL}..."

  30.times do
    begin
      if HTTP::Client.get("#{APP_URL}/api/ping").success?
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
    "#{API_URL}?limit=1",
    headers: HTTP::Headers{"X-Api-Key" => API_KEY}
  )

  unless response.success?
    puts "Failed to fetch links. Status: #{response.status_code}"
    puts "Make sure your server is running and the API key is correct."
    exit(1)
  end

  data = JSON.parse(response.body)
  links = data["data"].as_a

  if links.empty?
    puts "No links found. Please seed your database first."
    exit(1)
  end

  link = links.sample
  url = link["refer"].as_s
  link_id = link["id"].as_i64
  puts "Selected link: #{url}"

  initial_clicks = click_count(link_id)
  warm_up(url)
  expected_warm_up_clicks = initial_clicks + 1
  initial_clicks = wait_for_clicks(link_id, expected_warm_up_clicks)
  if initial_clicks < expected_warm_up_clicks
    puts "Warm-up click was not recorded within 30 seconds."
    exit(1)
  end

  puts "\nStarting benchmark with #{NUMBER_OF_REQUESTS} requests using #{CONNECTIONS} connections..."

  sleep 2.seconds

  args = ["-n", NUMBER_OF_REQUESTS.to_s, "-c", CONNECTIONS.to_s, "-l"]
  args << "--disableKeepAlives" if DISABLE_KEEP_ALIVES
  args << url

  process = Process.new(
    "bombardier",
    args,
    output: Process::Redirect::Inherit,
    error: Process::Redirect::Inherit
  )

  status = process.wait

  if status.success?
    recorded_clicks = wait_for_clicks(link_id, initial_clicks + NUMBER_OF_REQUESTS)
    if recorded_clicks < initial_clicks + NUMBER_OF_REQUESTS
      puts "Click tracking did not drain: #{recorded_clicks - initial_clicks}/#{NUMBER_OF_REQUESTS} clicks recorded."
      exit(1)
    end

    puts "Click tracking drained: #{recorded_clicks - initial_clicks}/#{NUMBER_OF_REQUESTS} clicks recorded."
    puts "\nBenchmark completed successfully."
  else
    puts "\nBombardier failed with error code: #{status.exit_code}"
    exit(1)
  end
end

def warm_up(url : String)
  response = HTTP::Client.get(url)
  return if response.status_code == 301

  puts "Warm-up request failed with status: #{response.status_code}"
  exit(1)
end

def click_count(link_id : Int64) : Int64
  output = IO::Memory.new
  process = Process.run(
    "sqlite3",
    [DATABASE_FILE, "SELECT COUNT(*) FROM clicks WHERE link_id = #{link_id}"],
    output: output
  )
  raise "Failed to count clicks" unless process.success?

  output.to_s.strip.to_i64
end

def wait_for_clicks(link_id : Int64, expected : Int64) : Int64
  deadline = Time.monotonic + 30.seconds

  loop do
    count = click_count(link_id)
    return count if count >= expected
    break if Time.monotonic >= deadline
    sleep 0.5.seconds
  end

  click_count(link_id)
end

def cleanup_database
  puts "Cleaning up benchmark database..."

  if File.exists?(DATABASE_FILE)
    File.delete(DATABASE_FILE)
    puts "Deleted existing database: #{DATABASE_FILE}"
  end

  # Also remove WAL and SHM files if they exist
  ["#{DATABASE_FILE}-wal", "#{DATABASE_FILE}-shm"].each do |file|
    if File.exists?(file)
      File.delete(file)
      puts "Deleted: #{file}"
    end
  end

  # Ensure sqlite directory exists
  Dir.mkdir_p("./sqlite")
  puts "Database cleanup completed."
end

def run_migrations
  puts "Running database migrations..."

  process = Process.run("which", ["micrate"], output: Process::Redirect::Close)
  unless process.success?
    puts "Error: micrate is not installed. Please install it to proceed."
    puts "  shards install"
    exit(1)
  end

  process = Process.run(
    "micrate",
    ["up"],
    env: {"DATABASE_URL" => DATABASE_URL},
    output: Process::Redirect::Inherit,
    error: Process::Redirect::Inherit
  )

  if process.success?
    puts "Migrations completed successfully."
  else
    puts "Error: Migrations failed."
    exit(1)
  end
end

def seed_database
  puts "Seeding benchmark database..."

  unless File.exists?("./db/seed.sql")
    puts "Warning: ./db/seed.sql not found. Skipping database seeding."
    return
  end

  unless File.exists?(DATABASE_FILE)
    puts "Warning: #{DATABASE_FILE} not found. Database may not be initialized."
  end

  process = Process.run(
    "sqlite3",
    [DATABASE_FILE],
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

  # Setup benchmark database
  cleanup_database
  run_migrations
  seed_database

  app_process = start_application

  begin
    wait_for_server

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
    puts "  Database: #{DATABASE_FILE}"
  ensure
    # Always stop the application
    stop_application(app_process)
  end
end

main

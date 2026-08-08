require "spec"
require "http/client"
require "json"

private def wait_for_server(url : String)
  80.times do
    begin
      return if HTTP::Client.get("#{url}/api/ping").success?
    rescue IO::Error | Socket::Error
    end
    sleep 0.25.seconds
  end
  raise "application did not start"
end

describe "bit application" do
  it "serves the complete link lifecycle over HTTP" do
    port = Random.rand(42000..49000)
    app_url = "http://127.0.0.1:#{port}"
    api_key = Random::Secure.urlsafe_base64
    database_file = "/tmp/bit-e2e-#{Process.pid}.db"
    log_file = "/tmp/bit-e2e-#{Process.pid}.log"
    log = File.open(log_file, "w")
    success = false
    process = Process.new(
      "./bin/bit",
      env: {
        "ENV"           => "production",
        "PORT"          => port.to_s,
        "HOST"          => "127.0.0.1",
        "APP_URL"       => app_url,
        "DATABASE_URL"  => "sqlite3://#{database_file}?journal_mode=wal&synchronous=normal&foreign_keys=true",
        "ADMIN_NAME"    => "E2E Admin",
        "ADMIN_API_KEY" => api_key,
      },
      output: log,
      error: log
    )

    begin
      wait_for_server(app_url)
      headers = HTTP::Headers{"Content-Type" => "application/json", "X-Api-Key" => api_key}

      unauthorized = HTTP::Client.get("#{app_url}/api/links")
      unauthorized.status_code.should eq(401)

      created = HTTP::Client.post("#{app_url}/api/links", headers: headers, body: {"url" => "https://example.com/e2e"}.to_json)
      created.status_code.should eq(201)
      data = JSON.parse(created.body)["data"]
      link_id = data["id"].as_i64
      refer = data["refer"].as_s

      redirect = HTTP::Client.get(refer, headers: HTTP::Headers{
        "User-Agent" => "Mozilla/5.0 Firefox/127.0",
        "Referer"    => "https://source.example.com/page",
      })
      redirect.status_code.should eq(301)
      redirect.headers["Location"].should eq("https://example.com/e2e")
      redirect.headers["Cache-Control"].should eq("private, no-store")

      clicks = nil
      40.times do
        response = HTTP::Client.get("#{app_url}/api/links/#{link_id}/clicks", headers: headers)
        clicks = JSON.parse(response.body)["data"].as_a
        break unless clicks.empty?
        sleep 0.05.seconds
      end
      clicks.not_nil!.size.should eq(1)
      clicks.not_nil!.first["referer"].as_s.should eq("source.example.com")

      deleted = HTTP::Client.delete("#{app_url}/api/links/#{link_id}", headers: headers)
      deleted.status_code.should eq(204)
      HTTP::Client.get(refer).status_code.should eq(404)
      success = true
    ensure
      process.signal(Signal::TERM) rescue nil
      sleep 0.2.seconds
      process.signal(Signal::KILL) rescue nil
      process.wait
      log.close
      STDERR.puts File.read(log_file) unless success
      [database_file, "#{database_file}-wal", "#{database_file}-shm"].each do |file|
        File.delete(file) if File.exists?(file)
      end
      File.delete(log_file) if success && File.exists?(log_file)
    end
  end
end

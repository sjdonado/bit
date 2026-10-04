require "../spec_helper"

# Runs against the files in data/, so the Update Parsers workflow checks each download before opening its PR.
describe "Parser data" do
  it "resolves countries from the GeoLite2 database" do
    App::Lib::IpLookup.country("8.8.8.8").should eq("US")
    App::Lib::IpLookup.country("2001:4860:4860::8888").should eq("US")
  end

  it "parses common user agents with the uap-core regexes" do
    {
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36"                                    => {"Chrome", "Windows"},
      "Mozilla/5.0 (iPhone; CPU iPhone OS 17_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.6 Mobile/15E148 Safari/604.1"             => {"Mobile Safari", "iOS"},
      "Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Mobile Safari/537.36"                              => {"Chrome Mobile", "Android"},
      "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"                                                                            => {"Googlebot", nil},
    }.each do |user_agent, (browser, os)|
      family, _, _, parsed_os = App::Lib::UserAgent.parse(user_agent)
      family.should eq(browser)
      parsed_os.try(&.[0]).should eq(os)
    end
  end
end

require "kemal"
require "./controllers/**"

module Pa
  get "/api/ping" do |env|
    Controllers::Ping::Get.new.call(env)
  end
end

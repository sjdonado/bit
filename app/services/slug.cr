require "digest"
require "base64"

module App::Services::SlugService
  def self.shorten_url(url : String, user_id : Int64) : String
    combined = "#{user_id}-#{url}"
    Base64.urlsafe_encode(Digest::SHA256.digest(combined))[0, 8]
  end
end

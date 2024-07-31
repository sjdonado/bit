require "digest"
require "base64"

module App::Services::SlugService
  def self.shorten_url(url : String, user_id : String) : String
    combined = "#{user_id}-#{url}"
    crc32_hash = Digest::CRC32.digest(combined)
    base62_encoded = Base64.urlsafe_encode(crc32_hash).strip.tr("-_=", "")

    base62_encoded
  end
end

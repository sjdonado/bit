require "digest"
require "base64"

module App::Services::SlugService
  def self.shorten_url(url : String) : String
    crc32_hash = Digest::CRC32.digest(url)
    base62_encoded = Base64.urlsafe_encode(crc32_hash).strip.tr("-_=", "")

    base62_encoded
  end
end

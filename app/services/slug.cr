require "digest"

module App::Services::SlugService
  def self.generate_base64(link : String, size : Int32) : String
    hash = Digest::SHA256.digest(link)
    base64_encoded = Base64.urlsafe_encode(hash).strip.tr("+/", "")
    base64_encoded[0, size]
  end
end

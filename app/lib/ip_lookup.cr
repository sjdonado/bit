require "maxminddb"
require "log"

struct IpLookup
  MMDB_PATH = "data/GeoLite2-Country.mmdb"

  record Country, code : String? = nil, name : String? = nil

  def self.country(ip_address : String) : Country?
    return nil if ip_address == "Unknown" || ip_address.empty?

    begin
      reader = MaxMindDB.open(MMDB_PATH)
      lookup = reader.get(ip_address)

      country_code = lookup["country"]?.try &.["iso_code"]?.try &.as_s
      country_name = lookup["country"]?.try &.["names"]?.try &.["en"]?.try &.as_s

      if country_code || country_name
        Country.new(
          code: country_code,
          name: country_name
        )
      else
        nil
      end
    rescue ex
      Log.error { "IP lookup failed: #{ex.message}" }
      nil
    end
  end

  def self.ip_from_address(address_string : String?) : String?
    return nil if address_string.nil?

    if address_string.includes?('[') # IPv6 with port: [2001:db8::1]:8080
      address_string.split(']').first.sub('[', '\'')
    elsif address_string.includes?(':')
      if address_string.count(':') > 1 # IPv6 without port
        address_string
      else # IPv4 with port: 192.168.1.1:8080
        address_string.split(':').first
      end
    else # Address without port
      address_string
    end
  end
end

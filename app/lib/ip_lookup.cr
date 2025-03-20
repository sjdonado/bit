require "maxminddb"

class IpLookup
  @@instance : MaxMindDB::Reader? = nil

  record Country, code : String? = nil, name : String? = nil

  getter ip : String
  getter country : Country?

  def self.load_mmdb(mmdb_file_path : String)
    @@instance = MaxMindDB.open(mmdb_file_path)
  end

  def initialize(ip_address : String)
    @ip = ip_address
    @country = nil

    return if @@instance.nil? || ip_address == "Unknown" || ip_address.empty?

    begin
      lookup = @@instance.not_nil!.get(ip_address)

      country_code = lookup["country"]?.try &.["iso_code"]?.try &.as_s
      country_name = lookup["country"]?.try &.["names"]?.try &.["en"]?.try &.as_s

      if country_code || country_name
        @country = Country.new(
          code: country_code,
          name: country_name
        )
      end
    rescue ex
      # Silently handle lookup errors
      Log.error { "IP lookup failed: #{ex.message}" }
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

require "maxminddb"
require "log"

module App::Lib
  struct IpLookup
    MMDB_PATH          = "data/GeoLite2-Country.mmdb"
    COUNTRY_CACHE_SIZE = 4096
    MAX_IP_SIZE        = 45

    @@reader : MaxMindDB::Reader? = nil
    @@country_cache = {} of String => String
    @@reader_mutex = Mutex.new

    private def self.get_reader : MaxMindDB::Reader
      @@reader_mutex.synchronize do
        @@reader ||= MaxMindDB.open(MMDB_PATH)
      end
    end

    def self.country(ip_address : String) : String?
      return nil if ip_address == "Unknown" || ip_address.empty?
      cacheable = ip_address.bytesize <= MAX_IP_SIZE
      if cacheable && (cached = @@reader_mutex.synchronize { @@country_cache[ip_address]? })
        return cached.empty? ? nil : cached
      end

      country = begin
        lookup = get_reader.get(ip_address)
        lookup["country"]?.try &.["iso_code"]?.try &.as_s
      rescue ex
        Log.error { "IP lookup failed: #{ex.message}" }
        nil
      end

      if cacheable
        @@reader_mutex.synchronize do
          @@country_cache.clear if @@country_cache.size >= COUNTRY_CACHE_SIZE
          @@country_cache[ip_address] = country || ""
        end
      end
      country
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
end

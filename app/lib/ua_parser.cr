require "yaml"
require "semantic_version"

module App::Lib
  struct UserAgent
    REGEXES_PATH = "data/uap_core_regexes.yaml"

    @@regexes_cache : YAML::Any? = nil
    @@compiled_regexes = {} of String => Array(Tuple(Regex, YAML::Any))
    @@mutex = Mutex.new

    private def self.load_regexes
      @@mutex.synchronize do
        if @@regexes_cache.nil?
          begin
            regexes_yaml = File.read(REGEXES_PATH)
            @@regexes_cache = YAML.parse(regexes_yaml)

            # Pre-compile all regexes for better performance
            ["user_agent_parsers", "os_parsers", "device_parsers"].each do |parser_type|
              @@compiled_regexes[parser_type] = [] of Tuple(Regex, YAML::Any)

              @@regexes_cache.not_nil![parser_type].as_a.each do |parser|
                regex_str = parser["regex"].as_s
                options = parser["regex_flag"]?.try(&.as_s) == "i" ?
                  Regex::Options::IGNORE_CASE : Regex::Options::None

                begin
                  compiled_regex = Regex.new(regex_str, options)
                  @@compiled_regexes[parser_type] << {compiled_regex, parser}
                rescue
                  # Skip invalid regexes
                end
              end
            end
          rescue ex
            # If loading fails, set an empty cache to prevent repeated failures
            @@regexes_cache = YAML.parse("{}")
            @@compiled_regexes = {} of String => Array(Tuple(Regex, YAML::Any))
          end
        end
      end
    end

    def self.parse(user_agent_string : String)
      return {nil, nil, nil, nil} if user_agent_string.empty?

      # Load regexes only once and cache them
      load_regexes

      family = nil
      version = nil
      device = nil
      os = nil

      @@compiled_regexes["user_agent_parsers"]?.try &.each do |regex_tuple|
        regex, parser = regex_tuple
        match = regex.match(user_agent_string)
        next unless match

        family = match[1]? || nil
        v1 = (match[2]? || "0").to_i
        v2 = (match[3]? || "0").to_i
        v3 = (match[4]? || "0").to_i

        # Apply replacements if defined
        if replacement = parser["family_replacement"]?
          family = replacement.as_s.gsub("$1", family.to_s)
        end

        version = SemanticVersion.new(v1, v2, v3)
        break
      end

      @@compiled_regexes["os_parsers"]?.try &.each do |regex_tuple|
        regex, parser = regex_tuple
        match = regex.match(user_agent_string)
        next unless match

        os_family = match[1]? || nil
        os_v1 = (match[2]? || "0").to_i
        os_v2 = (match[3]? || "0").to_i
        os_v3 = (match[4]? || "0").to_i

        # Apply replacements if defined
        if replacement = parser["os_replacement"]?
          os_family = replacement.as_s.gsub("$1", os_family.to_s)
        end

        os = {os_family, SemanticVersion.new(os_v1, os_v2, os_v3)}
        break
      end

      @@compiled_regexes["device_parsers"]?.try &.each do |regex_tuple|
        regex, parser = regex_tuple
        match = regex.match(user_agent_string)
        next unless match

        model = match[1]? || nil
        device_name = model
        brand = nil

        # Apply replacements if defined
        if device_replacement = parser["device_replacement"]?
          device_name = device_replacement.as_s.gsub("$1", device_name.to_s)
        end

        if model_replacement = parser["model_replacement"]?
          model = model_replacement.as_s.gsub("$1", model.to_s)
        end

        if brand_replacement = parser["brand_replacement"]?
          brand = brand_replacement.as_s
        end

        device = {model, brand, device_name}
        break
      end

      {family, version, device, os}
    end
  end
end

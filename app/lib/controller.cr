module App::Lib
  abstract class BaseController
    protected getter env : HTTP::Server::Context

    def initialize(@env : HTTP::Server::Context); end

    # Convert changeset errors to API-friendly format
    protected def map_changeset_errors(errors)
      errors.reduce({} of String => Array(String)) do |memo, error|
        field = error[:field].to_s
        message = error[:message].to_s

        memo[field] ||= [] of String
        memo[field] << message
        memo
      end
    end

    protected def parse_body(required_fields : Array(String) = [] of String)
      json_params = @env.params.json.try(&.to_h) || {} of String => JSON::Any
      json_params = json_params.transform_values(&.to_s) # Convert JSON::Any to String

      missing_fields = required_fields.reject { |field| json_params.has_key?(field) }

      unless missing_fields.empty?
        error_message = missing_fields.join(", ") + " required"
        raise App::BadRequestException.new(@env, error_message)
      end

      json_params
    end

    protected def render_json(data, status_code : Int32 = 200)
      @env.response.status_code = status_code
      @env.response.content_type = "application/json"
      data.to_json
    end

    protected def param(key : String) : String
      @env.params.url[key]
    rescue KeyError
      raise App::BadRequestException.new(@env, "Missing required parameter: #{key}")
    end
  end
end

module App::Lib
  abstract class BaseController
    def map_changeset_errors(errors)
      errors.reduce({} of String => Array(String)) do |memo, error|
        memo[error[:field]] = memo[error[:field]]? || [] of String
        memo[error[:field]] << error[:message]
        memo
      end
    end

    def parse_body(env, fields)
      json_params = env.params.json.to_h
      missing_fields = [] of String

      fields.each do |field|
        unless json_params.has_key?(field)
          missing_fields << field
        end
      end

      unless missing_fields.empty?
        error_message = missing_fields.map { |field| "#{field}: Required field" }.join(", ")
        raise App::BadRequestException.new(env, error_message)
      end

      json_params
    end
  end
end

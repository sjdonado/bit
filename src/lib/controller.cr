module App::Lib
  abstract class BaseController
     def map_changeset_errors(errors)
      errors.reduce({} of String => Array(String)) do |memo, error|
        memo[error[:field]] = memo[error[:field]]? || [] of String
        memo[error[:field]] << error[:message]
        memo
      end
    end
  end
end

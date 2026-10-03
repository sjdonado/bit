require "kemal"

module App
  # Kemal discards a body written before raising, so the body travels with the exception and the `error` handlers in routes.cr print it.
  abstract class HttpException < Kemal::Exceptions::CustomException
    getter body : String

    def initialize(context, status_code : Int32, @body : String)
      context.response.content_type = "application/json"
      context.response.status_code = status_code
      super(context)
    end
  end

  class InternalServerErrorException < HttpException
    def initialize(context)
      super(context, 500, { "error" => "Internal Server Error" }.to_json)
    end
  end

  class BadRequestException < HttpException
    def initialize(context, message : String)
      super(context, 400, { "error" => message }.to_json)
    end
  end

  class UnauthorizedException < HttpException
    def initialize(context)
      super(context, 401, { "error" => "Unauthorized access" }.to_json)
    end
  end

  class ForbiddenException < HttpException
    def initialize(context)
      super(context, 403, { "error" => "Access not allowed" }.to_json)
    end
  end

  class NotFoundException < HttpException
    def initialize(context)
      super(context, 404, { "error" => "Resource not found" }.to_json)
    end
  end

  class UnprocessableEntityException < HttpException
    def initialize(context, message : Hash(String, Array(String)))
      super(context, 422, { "errors" => message }.to_json)
    end
  end
end

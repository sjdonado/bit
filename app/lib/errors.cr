require "kemal"

module App
  class InternalServerErrorException < Kemal::Exceptions::CustomException
    def initialize(context)
      context.response.content_type = "application/json"
      context.response.status_code = 500
      context.response.print({ "error" => "Internal Server Error" }.to_json)
      super(context)
    end
  end

  class BadRequestException < Kemal::Exceptions::CustomException
    def initialize(context, message : String)
      context.response.content_type = "application/json"
      context.response.status_code = 400
      context.response.print({ "error" => message }.to_json)
      super(context)
    end
  end

  class UnauthorizedException < Kemal::Exceptions::CustomException
    def initialize(context)
      context.response.content_type = "application/json"
      context.response.status_code = 401
      context.response.print({ "error" => "Unauthorized access" }.to_json)
      super(context)
    end
  end

  class ForbiddenException < Kemal::Exceptions::CustomException
    def initialize(context)
      context.response.content_type = "application/json"
      context.response.status_code = 403
      context.response.print({ "error" => "Access not allowed" }.to_json)
      super(context)
    end
  end

  class NotFoundException < Kemal::Exceptions::CustomException
    def initialize(context)
      context.response.content_type = "application/json"
      context.response.status_code = 404
      context.response.print({ "error" => "Resource not found" }.to_json)
      super(context)
    end
  end

  class UnprocessableEntityException < Kemal::Exceptions::CustomException
    def initialize(context, message : Hash(String, Array(String)))
      context.response.content_type = "application/json"
      context.response.status_code = 422
      context.response.print({ "errors" => message }.to_json)
      super(context)
    end
  end
end

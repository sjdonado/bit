require "kemal"

module App
  class BadRequestException < Kemal::Exceptions::CustomException
    def initialize(context, message = Hash(String, String))
      context.response.status_code = 400
      context.response.print({ "error" => message }.to_json)
      super(context)
    end
  end

  class NotFoundException < Kemal::Exceptions::CustomException
    def initialize(context)
      context.response.status_code = 404
      super(context)
    end
  end

  class UnprocessableEntityException < Kemal::Exceptions::CustomException
    def initialize(context, message = Hash(String, String))
      context.response.status_code = 422
      context.response.print({ "error" => message }.to_json)
      super(context)
    end
  end
end

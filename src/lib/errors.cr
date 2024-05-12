require "kemal"

module App
  class BadRequestException < Kemal::Exceptions::CustomException
    def initialize(context)
      context.response.status_code = 400
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
    def initialize(context, @content = "")
      context.response.status_code = 422
      super(context)
    end

    getter :content
  end
end

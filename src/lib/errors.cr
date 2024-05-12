require "kemal"

module App
  class UnauthorizedException < Kemal::Exceptions::CustomException
    def initialize(context)
      context.response.status_code = 401
      super(context)
    end
  end

  class ForbiddenException < Kemal::Exceptions::CustomException
    def initialize(context)
      context.response.status_code = 403
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

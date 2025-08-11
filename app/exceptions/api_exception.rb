module ApiException
  class BaseException < StandardError
    attr_reader :status, :error_code, :details

    def initialize(message = nil, status: :unprocessable_entity, error_code: nil, details: {})
      super(message)
      @status = status
      @error_code = error_code || self.class.name.demodulize.underscore
      @details = details
    end

    def to_hash
      {
        error_code: @error_code,
        message: message,
        details: @details,
      }
    end
  end

  class AuthenticationError < BaseException
    def initialize(message = "Authentication required", **options)
      super(message, status: :unauthorized, **options)
    end
  end

  class AuthorizationError < BaseException
    def initialize(message = "Access denied", **options)
      super(message, status: :forbidden, **options)
    end
  end

  class ValidationError < BaseException
    def initialize(message = "Validation failed", **options)
      super(message, status: :unprocessable_entity, **options)
    end
  end

  class NotFoundError < BaseException
    def initialize(message = "Resource not found", **options)
      super(message, status: :not_found, **options)
    end
  end

  class TokenExpiredError < AuthenticationError
    def initialize(message = "Token has expired", **options)
      super(message, **options)
    end
  end

  class InvalidTokenError < AuthenticationError
    def initialize(message = "Invalid token", **options)
      super(message, **options)
    end
  end

  class RateLimitError < BaseException
    def initialize(message = "Rate limit exceeded", **options)
      super(message, status: :too_many_requests, **options)
    end
  end

  class ServerError < BaseException
    def initialize(message = "Internal server error", **options)
      super(message, status: :internal_server_error, **options)
    end
  end
end

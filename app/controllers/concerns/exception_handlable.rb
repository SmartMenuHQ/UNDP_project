module ExceptionHandlable
  extend ActiveSupport::Concern

  included do
    # Handle API exceptions - more specific exceptions first
    rescue_from ApiException::TokenExpiredError, with: :handle_token_expired_error
    rescue_from ApiException::InvalidTokenError, with: :handle_invalid_token_error
    rescue_from ApiException::AuthenticationError, with: :handle_authentication_error
    rescue_from ApiException::AuthorizationError, with: :handle_authorization_error
    rescue_from ApiException::ValidationError, with: :handle_validation_error
    rescue_from ApiException::NotFoundError, with: :handle_not_found_error
    rescue_from ApiException::BaseException, with: :handle_api_exception

    # Handle ActiveRecord exceptions
    rescue_from ActiveRecord::RecordNotFound, with: :handle_record_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :handle_record_invalid
    rescue_from ActiveRecord::RecordNotSaved, with: :handle_record_not_saved

    # Handle Pundit exceptions
    rescue_from Pundit::NotAuthorizedError, with: :handle_pundit_authorization_error
    rescue_from Pundit::AuthorizationNotPerformedError, with: :handle_pundit_not_performed_error
    rescue_from Pundit::PolicyScopingNotPerformedError, with: :handle_pundit_scoping_not_performed_error

    # Handle parameter exceptions
    rescue_from ActionController::ParameterMissing, with: :handle_parameter_missing
    rescue_from ActionController::UnpermittedParameters, with: :handle_unpermitted_parameters
  end

  protected

  def handle_api_exception(exception)
    @status = :error
    @errors = [exception.to_hash]
    @data = {}

    render status: exception.status
  end

  def handle_authentication_error(exception)
    @status = :error
    @errors = [
      {
        error_code: "authentication_required",
        message: exception.message,
        details: exception.details,
      },
    ]
    @data = {}

    render status: :unauthorized
  end

  def handle_authorization_error(exception)
    @status = :error
    @errors = [
      {
        error_code: "access_denied",
        message: exception.message,
        details: exception.details,
      },
    ]
    @data = {}

    render status: :forbidden
  end

  def handle_validation_error(exception)
    @status = :error
    @errors = [
      {
        error_code: "validation_failed",
        message: exception.message,
        details: exception.details,
      },
    ]
    @data = {}

    render status: :unprocessable_entity
  end

  def handle_not_found_error(exception)
    @status = :error
    @errors = [
      {
        error_code: "resource_not_found",
        message: exception.message,
        details: exception.details,
      },
    ]
    @data = {}

    render status: :not_found
  end

  def handle_token_expired_error(exception)
    @status = :error
    @errors = [
      {
        error_code: "token_expired",
        message: exception.message,
        details: exception.details.merge(action: "Please refresh your token"),
      },
    ]
    @data = {}

    render status: :unauthorized
  end

  def handle_invalid_token_error(exception)
    @status = :error
    @errors = [
      {
        error_code: "invalid_token",
        message: exception.message,
        details: exception.details.merge(action: "Please provide a valid token"),
      },
    ]
    @data = {}

    render status: :unauthorized
  end

  def handle_record_not_found(exception)
    @status = :error
    @errors = [
      {
        error_code: "record_not_found",
        message: "Resource not found",
        details: { model: exception.model },
      },
    ]
    @data = {}

    render status: :not_found
  end

  def handle_record_invalid(exception)
    @status = :error
    @errors = exception.record.errors.full_messages.map do |message|
      {
        error_code: "validation_error",
        message: message,
        details: { field: extract_field_from_message(message) },
      }
    end
    @data = {}

    render status: :unprocessable_entity
  end

  def handle_record_not_saved(exception)
    @status = :error
    @errors = [
      {
        error_code: "record_not_saved",
        message: "Failed to save record",
        details: { model: exception.record.class.name },
      },
    ]
    @data = {}

    render status: :unprocessable_entity
  end

  def handle_pundit_authorization_error(exception)
    @status = :error
    @errors = [
      {
        error_code: "authorization_failed",
        message: "You are not authorized to perform this action",
        details: {
          policy: exception.policy.class.name,
          action: exception.query,
          record: exception.record.class.name,
        },
      },
    ]
    @data = {}

    render status: :forbidden
  end

  def handle_pundit_not_performed_error(exception)
    @status = :error
    @errors = [
      {
        error_code: "authorization_not_performed",
        message: "Authorization check was not performed",
        details: { controller: exception.controller.class.name },
      },
    ]
    @data = {}

    render status: :internal_server_error
  end

  def handle_pundit_scoping_not_performed_error(exception)
    @status = :error
    @errors = [
      {
        error_code: "policy_scoping_not_performed",
        message: "Policy scoping was not performed",
        details: { controller: exception.controller.class.name },
      },
    ]
    @data = {}

    render status: :internal_server_error
  end

  def handle_parameter_missing(exception)
    @status = :error
    @errors = [
      {
        error_code: "parameter_missing",
        message: "Required parameter is missing",
        details: { parameter: exception.param },
      },
    ]
    @data = {}

    render status: :bad_request
  end

  def handle_unpermitted_parameters(exception)
    @status = :error
    @errors = [
      {
        error_code: "unpermitted_parameters",
        message: "Unpermitted parameters provided",
        details: { parameters: exception.params },
      },
    ]
    @data = {}

    render status: :bad_request
  end

  private

  def extract_field_from_message(message)
    # Extract field name from validation error message
    # e.g., "Email can't be blank" -> "email"
    message.split(" ").first&.downcase
  end
end

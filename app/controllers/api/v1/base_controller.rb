class Api::V1::BaseController < ActionController::Base
  include Pundit::Authorization
  include ExceptionHandlable

  # Skip CSRF protection for API endpoints
  skip_before_action :verify_authenticity_token

  # Setup API response structure
  before_action :setup_layout_elements
  before_action :authenticate_with_token!

  # Clear Current attributes after each request
  after_action :clear_current_attributes

  protected

  def setup_layout_elements
    @status = :ok
    @errors = []
    @notes = []
    @data = {}
  end

  def error!(message, status_code = :unprocessable_entity)
    @status = :error
    @errors << message
    render status: status_code
    nil
  end

  def note!(message)
    @notes << message
  end

  def redirect!(url, message = nil)
    @status = :redirect
    @data[:redirect_url] = url
    note!(message) if message
    render status: :ok
  end

  def success!(data = {}, message = nil)
    @status = :ok
    @data = data
    note!(message) if message
    render status: :ok
  end

  def current_user
    Current.user
  end

  def current_session
    Current.session
  end

  def authenticate_with_token!
    token = extract_token_from_header

    unless token
      raise ApiException::AuthenticationError.new("Authorization token required")
    end

    session = Session.find_by(token: token)

    unless session
      raise ApiException::InvalidTokenError.new("Invalid authorization token")
    end

    if session.expired?
      raise ApiException::TokenExpiredError.new("Authorization token has expired")
    end

    # Set the current session and user in Current attributes
    Current.session = session

    # Refresh token expiration on each use
    session.refresh! if should_refresh_token?(session)

    Current.user
  end

  def authenticate_with_token
    return nil unless extract_token_from_header

    begin
      authenticate_with_token!
      Current.user
    rescue ApiException::BaseException
      Current.session = nil
      nil
    end
  end

  def authenticate_user!
    unless current_user
      raise ApiException::AuthenticationError.new("Authentication required")
    end
    true
  end

  def optional_authentication!
    # Allow endpoints to work with or without authentication
    authenticate_with_token if extract_token_from_header
  end

  private

  def extract_token_from_header
    auth_header = request.headers["Authorization"]
    return nil unless auth_header

    # Support both "Bearer TOKEN" and "TOKEN" formats
    if auth_header.start_with?("Bearer ")
      auth_header.split(" ").last
    else
      auth_header
    end
  end

  def should_refresh_token?(session)
    # Refresh token if it expires within 7 days
    session&.expires_at && session.expires_at < 7.days.from_now
  end

  def clear_current_attributes
    Current.reset
  end

  def pundit_user
    current_user
  end
end

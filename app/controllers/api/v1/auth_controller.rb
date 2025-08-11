class Api::V1::AuthController < Api::V1::BaseController
  skip_before_action :authenticate_with_token!, only: [:login]

  # POST /api/v1/auth/login
  def login
    @user = User.find_by(email_address: login_params[:email_address])

    unless @user&.authenticate(login_params[:password])
      raise ApiException::AuthenticationError, "Invalid email or password"
    end

    unless @user.profile_completed?
      raise ApiException::ValidationError.new("Profile must be completed before accessing the API",
                                              details: { profile_completion_required: true })
    end

    # Create new session
    @session = @user.sessions.create!(
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
    )

    @data = {
      user: @user,
      session: {
        token: @session.token,
        expires_at: @session.expires_at,
      },
    }

    note!("Login successful")
  end

  # DELETE /api/v1/auth/logout
  def logout
    if current_session
      current_session.destroy
      @data = { message: "Logged out successfully" }
      note!("Logout successful")
    else
      raise ApiException::AuthenticationError, "No active session found"
    end
  end

  # POST /api/v1/auth/refresh
  def refresh
    current_session.refresh!

    @data = {
      session: {
        token: current_session.token,
        expires_at: current_session.expires_at,
      },
    }

    note!("Token refreshed successfully")
  end

  # GET /api/v1/auth/me
  def me
    @data = {
      user: current_user,
      session: {
        token: current_session.token,
        expires_at: current_session.expires_at,
        ip_address: current_session.ip_address,
      },
    }
  end

  # DELETE /api/v1/auth/logout_all
  def logout_all
    current_user.sessions.destroy_all
    @data = { message: "Logged out from all devices" }
    note!("Logged out from all devices")
  end

  private

  def login_params
    params.require(:auth).permit(:email_address, :password)
  end
end

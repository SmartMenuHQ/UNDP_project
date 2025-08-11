class Api::V1::UsersController < Api::V1::BaseController
  before_action :authenticate_user!
  before_action :set_user, only: [:show, :update]
  before_action :authorize_user_action, only: [:show, :update]

  # GET /api/v1/users/:id (own profile only)
  def show
    @data = {
      user: @user,
      invitation_status: @user.invited_by ? {
        invited_by: @user.invited_by,
        invited_at: @user.invited_at,
        invitation_accepted_at: @user.invitation_accepted_at,
      } : nil,
    }

    note!("Business profile retrieved successfully")
  end

  # PATCH/PUT /api/v1/users/:id (own profile only)
  def update
    if @user.update(business_user_update_params)
      @data = { user: @user }
      note!("Business profile updated successfully")
    else
      raise ApiException::ValidationError.new("Profile update failed",
                                              details: { errors: @user.errors.full_messages })
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    raise ApiException::NotFoundError.new("User not found")
  end

  def authorize_user_action
    # Business users can only access their own profile
    unless @user == current_user
      raise ApiException::AuthorizationError.new("You can only access your own profile")
    end
  end

  def business_user_update_params
    # Business users can only update basic profile fields (not admin status or email)
    params.require(:user).permit(:first_name, :last_name, :country_id, :default_language, :password)
  end
end

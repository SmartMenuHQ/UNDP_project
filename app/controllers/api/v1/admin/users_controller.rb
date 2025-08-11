class Api::V1::Admin::UsersController < Api::V1::Admin::BaseController
  before_action :set_user, only: [:show, :update, :destroy, :make_admin, :remove_admin]

  # GET /api/v1/admin/users
  def index
    @users = policy_scope(User).includes(:country, :invited_by)
    @total_count = @users.count

    @data = {
      users: @users,
      total_count: @total_count,
      admin_count: User.admin.count,
      business_count: User.regular.count,
    }

    note!("Users retrieved successfully")
  end

  # GET /api/v1/admin/users/:id
  def show
    authorize @user

    @data = {
      user: @user,
      invitation_status: @user.invited_by ? {
        invited_by: @user.invited_by,
        invited_at: @user.invited_at,
        invitation_accepted_at: @user.invitation_accepted_at,
      } : nil,
      statistics: {
        sessions_count: @user.sessions.count,
        active_sessions_count: @user.sessions.active.count,
        response_sessions_count: @user.assessment_response_sessions.count,
      },
    }

    note!("User retrieved successfully")
  end

  # POST /api/v1/admin/users
  def create
    @user = User.new(user_create_params)
    @user.invited_by = current_user if user_create_params[:invited_by_id].blank?

    if @user.save
      @data = { user: @user }
      note!("User created successfully")
    else
      raise ApiException::ValidationError.new("User creation failed",
                                              details: { errors: @user.errors.full_messages })
    end
  end

  # PATCH/PUT /api/v1/admin/users/:id
  def update
    authorize @user

    if @user.update(admin_user_update_params)
      @data = { user: @user }
      note!("User updated successfully")
    else
      raise ApiException::ValidationError.new("User update failed",
                                              details: { errors: @user.errors.full_messages })
    end
  end

  # DELETE /api/v1/admin/users/:id
  def destroy
    authorize @user

    if @user == current_user
      raise ApiException::ValidationError.new("Cannot delete your own account")
    end

    if @user.destroy
      @data = { deleted_id: @user.id }
      note!("User deleted successfully")
    else
      raise ApiException::ValidationError.new("User deletion failed",
                                              details: { errors: @user.errors.full_messages })
    end
  end

  # POST /api/v1/admin/users/invite
  def invite
    user_params = invite_params
    @user = User.new(user_params.except(:send_email))
    @user.invited_by = current_user
    @user.invited_at = Time.current

    if @user.save
      # TODO: Send invitation email if send_email is true
      @data = {
        user: @user,
        invitation_sent: invite_params[:send_email] || false,
      }
      note!("User invitation sent successfully")
    else
      raise ApiException::ValidationError.new("User invitation failed",
                                              details: { errors: @user.errors.full_messages })
    end
  end

  # PATCH /api/v1/admin/users/:id/make_admin
  def make_admin
    authorize @user, :make_admin?

    if @user.update(admin: true)
      @data = { user: @user }
      note!("User promoted to admin successfully")
    else
      raise ApiException::ValidationError.new("Failed to promote user to admin",
                                              details: { errors: @user.errors.full_messages })
    end
  end

  # PATCH /api/v1/admin/users/:id/remove_admin
  def remove_admin
    authorize @user, :remove_admin?

    if @user == current_user
      raise ApiException::ValidationError.new("Cannot remove admin privileges from yourself")
    end

    if @user.update(admin: false)
      @data = { user: @user }
      note!("Admin privileges removed successfully")
    else
      raise ApiException::ValidationError.new("Failed to remove admin privileges",
                                              details: { errors: @user.errors.full_messages })
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    raise ApiException::NotFoundError.new("User not found")
  end

  def user_create_params
    params.require(:user).permit(:email_address, :password, :first_name, :last_name,
                                 :country_id, :default_language, :admin, :invited_by_id)
  end

  def admin_user_update_params
    # Admin can update all fields including email and admin status
    params.require(:user).permit(:email_address, :password, :first_name, :last_name,
                                 :country_id, :default_language, :admin)
  end

  def invite_params
    params.require(:user).permit(:email_address, :password, :first_name, :last_name,
                                 :country_id, :default_language, :admin, :send_email)
  end
end

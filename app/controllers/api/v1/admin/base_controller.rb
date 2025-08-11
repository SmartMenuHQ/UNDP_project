class Api::V1::Admin::BaseController < Api::V1::BaseController
  before_action :authenticate_admin!

  private

  def authenticate_admin!
    authenticate_user!
    unless current_user&.admin?
      raise ApiException::AuthorizationError.new("Admin access required")
    end
  end
end

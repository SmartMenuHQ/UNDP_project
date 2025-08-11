class ApplicationController < ActionController::Base
  # include Authentication
  # include Pundit::Authorization

  # # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # allow_browser versions: :modern

  # # Pundit configuration
  # after_action :verify_authorized, except: [:index], unless: :skip_authorization?
  # after_action :verify_policy_scoped, only: [:index], unless: :skip_policy_scope?

  # # Rescue from Pundit authorization errors
  # rescue_from Pundit::NotAuthorizedError, with: :handle_unauthorized

  protected

  # Override this in controllers that don't need authorization
  def skip_authorization?
    false
  end

  # Override this in controllers that don't need policy scoping
  def skip_policy_scope?
    false
  end

  private

  def handle_unauthorized
    if current_user
      flash[:alert] = "You are not authorized to perform this action."
      redirect_back(fallback_location: root_path)
    else
      flash[:alert] = "Please sign in to continue."
      redirect_to new_session_path
    end
  end

  # Helper method for Pundit to get current user
  def pundit_user
    current_user
  end
end

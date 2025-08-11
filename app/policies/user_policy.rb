# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  def index?
    user&.admin?
  end

  def show?
    return true if user&.admin?
    user == record  # Users can view their own profile
  end

  def create?
    user&.admin?  # Only admins can create users (invite system)
  end

  def update?
    return true if user&.admin?
    user == record  # Users can update their own profile
  end

  def destroy?
    return false if user == record  # Users cannot delete themselves
    user&.admin?
  end

  def invite?
    user&.admin?
  end

  def make_admin?
    user&.admin? && user != record  # Admins can promote others but not themselves
  end

  def remove_admin?
    user&.admin? && user != record  # Admins can demote others but not themselves
  end

  def complete_profile?
    return true if user&.admin?
    user == record  # Users can complete their own profile
  end

  def view_invitation_status?
    return true if user&.admin?
    user == record
  end

  def resend_invitation?
    user&.admin?
  end

  class Scope < Scope
    def resolve
      if user&.admin?
        scope.all
      elsif user
        scope.where(id: user.id)  # Users can only see themselves
      else
        scope.none
      end
    end
  end
end

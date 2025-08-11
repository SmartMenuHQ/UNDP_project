# frozen_string_literal: true

class CountryPolicy < ApplicationPolicy
  def index?
    true  # All users can see available countries (for profile completion)
  end

  def show?
    true  # All users can view country details
  end

  def create?
    user&.admin?
  end

  def update?
    user&.admin?
  end

  def destroy?
    return false unless user&.admin?
    record.can_be_deleted?  # Only allow deletion if no users are associated
  end

  def activate?
    user&.admin?
  end

  def deactivate?
    user&.admin?
  end

  def manage_restrictions?
    user&.admin?
  end

  def view_statistics?
    user&.admin?
  end

  class Scope < Scope
    def resolve
      if user&.admin?
        scope.all
      else
        scope.active  # Regular users only see active countries
      end
    end
  end
end

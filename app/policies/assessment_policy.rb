# frozen_string_literal: true

class AssessmentPolicy < ApplicationPolicy
  def index?
    true  # All users can see available assessments
  end

  def show?
    return true if user&.admin?
    return false unless user

    # Regular users can only view assessments accessible to their country
    user.can_access_content_with_restrictions?(record.restricted_countries)
  end

  def create?
    user&.admin?
  end

  def update?
    user&.admin?
  end

  def destroy?
    user&.admin?
  end

  def preview?
    user&.admin?
  end

  def manage_sections?
    user&.admin?
  end

  def manage_questions?
    user&.admin?
  end

  def manage_marking?
    user&.admin?
  end

  def take_assessment?
    return false unless user
    return true if user.admin?

    # Regular users can take assessments if:
    # 1. They have completed their profile
    # 2. The assessment is accessible from their country
    user.profile_completed? &&
      user.can_access_content_with_restrictions?(record.restricted_countries)
  end

  class Scope < Scope
    def resolve
      if user&.admin?
        scope.all
      elsif user
        # Regular users see assessments accessible from their country
        scope.accessible_to_country(user.country&.code)
      else
        scope.none
      end
    end
  end
end

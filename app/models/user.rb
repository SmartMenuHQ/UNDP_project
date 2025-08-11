# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  admin                  :boolean          default(FALSE), not null
#  default_language       :string           default("en")
#  email_address          :string           not null
#  first_name             :string
#  invitation_accepted_at :datetime
#  invited_at             :datetime
#  last_name              :string
#  password_digest        :string           not null
#  profile_completed      :boolean          default(FALSE), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  country_id             :bigint
#  invited_by_id          :bigint
#
# Indexes
#
#  index_users_on_admin              (admin)
#  index_users_on_country_id         (country_id)
#  index_users_on_default_language   (default_language)
#  index_users_on_email_address      (email_address) UNIQUE
#  index_users_on_invited_by_id      (invited_by_id)
#  index_users_on_profile_completed  (profile_completed)
#
# Foreign Keys
#
#  fk_rails_...  (country_id => countries.id)
#  fk_rails_...  (invited_by_id => users.id)
#
class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  # Associations
  belongs_to :country, optional: true
  belongs_to :invited_by, class_name: "User", optional: true
  has_many :invited_users, class_name: "User", foreign_key: "invited_by_id"

  # Response sessions for assessments
  has_many :assessment_response_sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  # Validations
  validates :email_address, presence: true, uniqueness: true
  validates :first_name, presence: true, if: :profile_completed?
  validates :last_name, presence: true, if: :profile_completed?
  validates :country, presence: true, if: :profile_completed?
  validates :default_language, presence: true, inclusion: { in: %w[en es fr it ja] }

  # Scopes
  scope :admins, -> { where(admin: true) }
  scope :admin, -> { where(admin: true) }
  scope :regular_users, -> { where(admin: false) }
  scope :regular, -> { where(admin: false) }
  scope :with_completed_profiles, -> { where(profile_completed: true) }
  scope :pending_invitations, -> { where.not(invited_at: nil).where(invitation_accepted_at: nil) }
  scope :by_country, ->(country) { where(country: country) }

  # Admin methods
  def admin?
    admin
  end

  def can_invite_users?
    admin?
  end

  def full_name
    return email_address unless first_name.present? || last_name.present?
    "#{first_name} #{last_name}".strip
  end

  def display_name
    full_name.present? ? full_name : email_address
  end

  # Profile completion
  def complete_profile!(first_name:, last_name:, country:, default_language: "en")
    update!(
      first_name: first_name,
      last_name: last_name,
      country: country,
      default_language: default_language,
      profile_completed: true,
    )
  end

  def profile_completion_percentage
    total_fields = 4 # first_name, last_name, country, default_language
    completed_fields = 0

    completed_fields += 1 if first_name.present?
    completed_fields += 1 if last_name.present?
    completed_fields += 1 if country.present?
    completed_fields += 1 if default_language.present?

    (completed_fields.to_f / total_fields * 100).round
  end

  # Invitation methods
  def invite!(invited_by_user)
    return false unless invited_by_user.can_invite_users?

    update!(
      invited_by: invited_by_user,
      invited_at: Time.current,
    )
  end

  def accept_invitation!
    update!(invitation_accepted_at: Time.current)
  end

  def pending_invitation?
    invited_at.present? && invitation_accepted_at.nil?
  end

  def invitation_accepted?
    invitation_accepted_at.present?
  end

  # Country restrictions
  def restricted_from_country?(country_code)
    return false unless country
    country.code == country_code
  end

  def can_access_content_with_restrictions?(restricted_countries)
    return true if restricted_countries.blank?
    return true unless country

    !restricted_countries.include?(country.code)
  end

  # Available languages for this user's country/region
  def available_languages
    case country&.region
    when "Europe"
      %w[en es fr it]
    when "Asia"
      %w[en ja]
    when "Americas"
      %w[en es]
    else
      %w[en]
    end
  end

  # Assessment access
  def accessible_assessments
    user_country_code = country&.code
    return Assessment.all unless user_country_code

    Assessment.joins("LEFT JOIN assessment_sections ON assessments.id = assessment_sections.assessment_id")
              .joins("LEFT JOIN assessment_questions ON assessments.id = assessment_questions.assessment_id")
              .where(
                "(assessment_sections.has_country_restrictions = false OR assessment_sections.restricted_countries = '[]' OR NOT (assessment_sections.restricted_countries @> ?)) AND " \
                "(assessment_questions.has_country_restrictions = false OR assessment_questions.restricted_countries = '[]' OR NOT (assessment_questions.restricted_countries @> ?))",
                [user_country_code].to_json, [user_country_code].to_json
              ).distinct
  end

  private

  def should_validate_profile_fields?
    profile_completed? || (first_name.present? || last_name.present? || country.present?)
  end
end

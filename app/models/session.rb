# == Schema Information
#
# Table name: sessions
#
#  id         :bigint           not null, primary key
#  expires_at :datetime         not null
#  ip_address :string
#  token      :string           not null
#  user_agent :string
#  user_id    :bigint           not null
#
# Indexes
#
#  index_sessions_on_expires_at  (expires_at)
#  index_sessions_on_token       (token) UNIQUE
#  index_sessions_on_user_id     (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Session < ApplicationRecord
  belongs_to :user

  before_validation :set_token_and_expiration, on: :create

  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true

  scope :active, -> { where("expires_at > ?", Time.current) }
  scope :expired, -> { where("expires_at <= ?", Time.current) }

  def refresh!
    update!(expires_at: 30.days.from_now)
  end

  def self.find_by_token(token)
    active.find_by(token: token)
  end

  def self.cleanup_expired
    expired.delete_all
  end

  def expired?
    expires_at <= Time.current
  end

  def active?
    !expired?
  end

  private

  def set_token_and_expiration
    self.token ||= generate_token
    self.expires_at ||= 30.days.from_now
  end

  def generate_token
    loop do
      token = SecureRandom.urlsafe_base64(32)
      break token unless Session.exists?(token: token)
    end
  end
end

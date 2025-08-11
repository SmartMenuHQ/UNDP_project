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
FactoryBot.define do
  factory :session do
    association :user
    ip_address { Faker::Internet.ip_v4_address }
    user_agent { Faker::Internet.user_agent }

    # Token and expires_at are generated automatically in the model

    trait :expired do
      after(:create) do |session|
        session.update_column(:expires_at, 1.day.ago)
      end
    end

    trait :expiring_soon do
      after(:create) do |session|
        session.update_column(:expires_at, 1.hour.from_now)
      end
    end
  end
end

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
FactoryBot.define do
  factory :user do
    email_address { Faker::Internet.unique.email }
    password { "password123" }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    default_language { "en" }
    profile_completed { true }
    admin { false }

    # Associate with a country
    association :country

    trait :admin do
      admin { true }
    end

    trait :incomplete_profile do
      profile_completed { false }
      first_name { nil }
      last_name { nil }
      country { nil }
    end

    trait :chinese do
      association :country, :china
      default_language { "en" }  # Changed from "zh" to valid language
    end

    trait :american do
      association :country, :usa
      default_language { "en" }
    end

    trait :spanish do
      association :country, :spain
      default_language { "es" }
    end
  end
end

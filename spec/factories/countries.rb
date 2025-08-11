# == Schema Information
#
# Table name: countries
#
#  id         :bigint           not null, primary key
#  active     :boolean          default(TRUE), not null
#  code       :string(3)        not null
#  name       :string           not null
#  region     :string
#  sort_order :integer          default(0)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_countries_on_active                 (active)
#  index_countries_on_active_and_sort_order  (active,sort_order)
#  index_countries_on_code                   (code) UNIQUE
#  index_countries_on_region                 (region)
#  index_countries_on_sort_order             (sort_order)
#
FactoryBot.define do
  factory :country do
    sequence(:name) { |n| "#{Faker::Address.country} #{n}" }
    sequence(:code) { |n| "TS#{("A".."Z").to_a[n % 26]}" }
    region { %w[Africa Americas Asia Europe Oceania].sample }
    active { true }
    sort_order { 0 }

    trait :usa do
      name { "United States" }
      code { "USA" }
      region { "Americas" }
    end

    trait :china do
      name { "China" }
      code { "CHN" }
      region { "Asia" }
    end

    trait :spain do
      name { "Spain" }
      code { "ESP" }
      region { "Europe" }
    end

    trait :japan do
      name { "Japan" }
      code { "JPN" }
      region { "Asia" }
    end

    trait :inactive do
      active { false }
    end
  end
end

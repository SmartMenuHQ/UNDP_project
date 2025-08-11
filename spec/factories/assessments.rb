# == Schema Information
#
# Table name: assessments
#
#  id                       :bigint           not null, primary key
#  active                   :boolean          default(TRUE)
#  description              :text
#  has_country_restrictions :boolean          default(FALSE), not null
#  restricted_countries     :jsonb
#  title                    :string
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#
# Indexes
#
#  index_assessments_on_has_country_restrictions  (has_country_restrictions)
#  index_assessments_on_restricted_countries      (restricted_countries) USING gin
#
FactoryBot.define do
  factory :assessment do
    title { Faker::Lorem.sentence(word_count: 3) }
    description { Faker::Lorem.paragraph(sentence_count: 2) }
    active { true }
    has_country_restrictions { false }
    restricted_countries { [] }

    trait :with_country_restrictions do
      has_country_restrictions { true }
      restricted_countries { ["CHN"] }
    end

    trait :inactive do
      active { false }
    end

    trait :with_sections do
      after(:create) do |assessment|
        create_list(:assessment_section, 3, assessment: assessment)
      end
    end

    trait :complete do
      after(:create) do |assessment|
        sections = []
        2.times do |i|
          sections << create(:assessment_section, assessment: assessment, order: i + 1)
        end
        sections.each_with_index do |section, section_index|
          2.times do |q_index|
            create(:assessment_question,
                   assessment_section: section,
                   assessment: assessment,
                   order: q_index + 1)
          end
        end
      end
    end
  end
end

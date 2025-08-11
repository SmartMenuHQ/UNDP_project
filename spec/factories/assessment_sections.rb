# == Schema Information
#
# Table name: assessment_sections
#
#  id                       :bigint           not null, primary key
#  has_country_restrictions :boolean          default(FALSE), not null
#  is_conditional           :boolean          default(FALSE)
#  metadata                 :jsonb
#  name                     :string
#  order                    :integer
#  restricted_countries     :jsonb
#  visibility_conditions    :jsonb
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  assessment_id            :bigint           not null
#
# Indexes
#
#  index_assessment_sections_on_assessment_id             (assessment_id)
#  index_assessment_sections_on_has_country_restrictions  (has_country_restrictions)
#  index_assessment_sections_on_is_conditional            (is_conditional)
#  index_assessment_sections_on_restricted_countries      (restricted_countries) USING gin
#  index_assessment_sections_on_visibility_conditions     (visibility_conditions) USING gin
#
# Foreign Keys
#
#  fk_rails_...  (assessment_id => assessments.id)
#
FactoryBot.define do
  factory :assessment_section do
    association :assessment
    name { Faker::Lorem.sentence(word_count: 2) }
    order { 1 }
    metadata { {} }
    is_conditional { false }
    has_country_restrictions { false }
    visibility_conditions { {} }
    restricted_countries { [] }

    trait :conditional do
      is_conditional { true }
      visibility_conditions do
        {
          trigger_question_id: 1,
          trigger_response_type: "option",
          trigger_values: ["1", "2"],
          operator: "contains",
          logic_operator: "and",
        }
      end
    end

    trait :with_country_restrictions do
      has_country_restrictions { true }
      restricted_countries { ["CHN", "IRN"] }
    end
  end
end

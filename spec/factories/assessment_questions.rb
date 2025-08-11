# == Schema Information
#
# Table name: assessment_questions
#
#  id                       :bigint           not null, primary key
#  active                   :boolean          default(TRUE)
#  default_locale           :string
#  has_country_restrictions :boolean          default(FALSE), not null
#  is_conditional           :boolean          default(FALSE)
#  is_required              :boolean          default(FALSE)
#  meta_data                :jsonb
#  options_json             :jsonb
#  order                    :integer
#  restricted_countries     :jsonb
#  sub_type                 :string
#  text                     :jsonb
#  type                     :string
#  visibility_conditions    :jsonb
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  assessment_id            :bigint
#  assessment_section_id    :bigint
#
# Indexes
#
#  index_assessment_questions_on_assessment_id             (assessment_id)
#  index_assessment_questions_on_assessment_section_id     (assessment_section_id)
#  index_assessment_questions_on_has_country_restrictions  (has_country_restrictions)
#  index_assessment_questions_on_is_conditional            (is_conditional)
#  index_assessment_questions_on_restricted_countries      (restricted_countries) USING gin
#  index_assessment_questions_on_visibility_conditions     (visibility_conditions) USING gin
#
FactoryBot.define do
  factory :assessment_question do
    association :assessment
    association :assessment_section
    text { { "en" => Faker::Lorem.sentence(word_count: 8) } }
    type { "AssessmentQuestions::RichText" }
    sub_type { nil }
    order { 1 }
    is_required { true }
    active { true }
    meta_data { {} }
    is_conditional { false }
    has_country_restrictions { false }
    visibility_conditions { {} }
    restricted_countries { [] }

    trait :multiple_choice do
      type { "AssessmentQuestions::MultipleChoice" }

      after(:create) do |question|
        create_list(:assessment_question_option, 3, assessment_question: question)
      end
    end

    trait :radio do
      type { "AssessmentQuestions::Radio" }

      after(:create) do |question|
        create_list(:assessment_question_option, 4, assessment_question: question)
      end
    end

    trait :boolean_type do
      type { "AssessmentQuestions::BooleanType" }

      after(:create) do |question|
        create(:assessment_question_option, assessment_question: question, text: { "en" => "Yes" }, order: 1)
        create(:assessment_question_option, assessment_question: question, text: { "en" => "No" }, order: 2)
      end
    end

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

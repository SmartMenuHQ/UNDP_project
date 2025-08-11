# == Schema Information
#
# Table name: assessment_question_responses
#
#  id                          :bigint           not null, primary key
#  metadata                    :jsonb
#  value                       :jsonb
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  assessment_id               :bigint           not null
#  assessment_question_id      :bigint           not null
#  assessment_response_session_id :bigint
#
# Indexes
#
#  index_assessment_question_responses_on_assessment_id                (assessment_id)
#  index_assessment_question_responses_on_assessment_question_id       (assessment_question_id)
#  index_assessment_question_responses_on_assessment_response_session_id (assessment_response_session_id)
#
# Foreign Keys
#
#  fk_rails_...  (assessment_id => assessments.id)
#  fk_rails_...  (assessment_question_id => assessment_questions.id)
#  fk_rails_...  (assessment_response_session_id => assessment_response_sessions.id)
#

FactoryBot.define do
  factory :assessment_question_response do
    association :assessment
    association :assessment_question
    association :assessment_response_session
    value { Faker::Lorem.sentence }
    metadata { {} }

    trait :with_text_value do
      value { Faker::Lorem.paragraph }
    end

    trait :with_numeric_value do
      value { Faker::Number.between(from: 1, to: 100) }
    end

    trait :with_boolean_value do
      value { [true, false].sample }
    end

    trait :with_date_value do
      value { Faker::Date.between(from: 1.year.ago, to: Date.current) }
    end
  end
end

# == Schema Information
#
# Table name: assessment_response_sessions
#
#  id                :bigint           not null, primary key
#  feedback          :text
#  respondent_name   :string
#  state             :string           default("draft")
#  completed_at      :datetime
#  started_at        :datetime
#  submitted_at      :datetime
#  total_score       :decimal(8, 2)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  assessment_id     :bigint           not null
#  user_id           :bigint
#
# Indexes
#
#  index_assessment_response_sessions_on_assessment_id  (assessment_id)
#  index_assessment_response_sessions_on_user_id        (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (assessment_id => assessments.id)
#  fk_rails_...  (user_id => users.id)
#

FactoryBot.define do
  factory :assessment_response_session do
    association :assessment
    association :user
    respondent_name { user&.full_name || Faker::Name.name }
    state { "draft" }
    feedback { nil }
    total_score { 0.0 }
    started_at { nil }
    submitted_at { nil }
    completed_at { nil }

    trait :started do
      state { "started" }
      started_at { Time.current }
    end

    trait :submitted do
      state { "submitted" }
      started_at { 1.hour.ago }
      submitted_at { Time.current }
    end

    trait :completed do
      state { "completed" }
      started_at { 2.hours.ago }
      submitted_at { 1.hour.ago }
      completed_at { Time.current }
      total_score { Faker::Number.decimal(l_digits: 2, r_digits: 2) }
    end

    trait :with_feedback do
      feedback { Faker::Lorem.paragraph(sentence_count: 3) }
    end
  end
end

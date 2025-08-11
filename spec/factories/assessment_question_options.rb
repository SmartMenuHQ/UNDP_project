# == Schema Information
#
# Table name: assessment_question_options
#
#  id                     :bigint           not null, primary key
#  default_locale         :string
#  is_correct_answer      :boolean          default(FALSE)
#  metadata               :jsonb
#  order                  :integer
#  points                 :decimal(10, 2)   default(0.0)
#  text                   :jsonb
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  assessment_id          :bigint           not null
#  assessment_question_id :bigint           not null
#
# Indexes
#
#  index_assessment_question_options_on_assessment_id           (assessment_id)
#  index_assessment_question_options_on_assessment_question_id  (assessment_question_id)
#  index_assessment_question_options_on_is_correct_answer       (is_correct_answer)
#  index_assessment_question_options_on_points                  (points)
#
# Foreign Keys
#
#  fk_rails_...  (assessment_id => assessments.id)
#  fk_rails_...  (assessment_question_id => assessment_questions.id)
#
FactoryBot.define do
  factory :assessment_question_option do
    association :assessment_question
    # Automatically set assessment from the question
    assessment { assessment_question&.assessment }
    text { { "en" => Faker::Lorem.sentence(word_count: 2) } }
    order { 1 }
    is_correct_answer { false }
    points { 0 }
    metadata { {} }

    trait :correct do
      is_correct_answer { true }
      points { 1 }
    end

    trait :with_points do
      points { rand(1..5) }
    end

    trait :negative_points do
      points { rand(-2..-1) }
    end
  end
end

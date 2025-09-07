# == Schema Information
#
# Table name: selected_options
#
#  id                              :bigint           not null, primary key
#  created_at                      :datetime         not null
#  updated_at                      :datetime         not null
#  assessment_question_option_id   :bigint           not null
#  assessment_question_response_id :bigint           not null
#

FactoryBot.define do
  factory :selected_option do
    association :assessment_question_response
    association :assessment_question_option

    # Ensure the option belongs to the same question as the response
    after(:build) do |selected_option|
      if selected_option.assessment_question_response &&
         selected_option.assessment_question_option &&
         selected_option.assessment_question_option.assessment_question != selected_option.assessment_question_response.assessment_question

        # Create a new option that belongs to the response's question
        selected_option.assessment_question_option = create(:assessment_question_option,
          assessment_question: selected_option.assessment_question_response.assessment_question
        )
      end
    end
  end
end

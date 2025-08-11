class AddSessionToAssessmentQuestionResponses < ActiveRecord::Migration[8.0]
  def change
    add_reference :assessment_question_responses, :assessment_response_session, null: true, foreign_key: true
  end
end

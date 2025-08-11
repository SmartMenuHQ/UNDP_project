class AddPointsToAssessmentQuestionOptions < ActiveRecord::Migration[8.0]
  def change
    add_column :assessment_question_options, :points, :decimal, precision: 10, scale: 2, default: 0
    add_column :assessment_question_options, :is_correct_answer, :boolean, default: false

    add_index :assessment_question_options, :points
    add_index :assessment_question_options, :is_correct_answer
  end
end

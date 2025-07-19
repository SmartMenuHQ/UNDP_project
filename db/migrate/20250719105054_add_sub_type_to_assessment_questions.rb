class AddSubTypeToAssessmentQuestions < ActiveRecord::Migration[8.0]
  def change
    add_column :assessment_questions, :sub_type, :string
  end
end

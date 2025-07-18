class AddActiveToAssessmentQuestions < ActiveRecord::Migration[8.0]
  def change
    add_column :assessment_questions, :active, :boolean, default: true
  end
end

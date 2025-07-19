class CreateAssessmentQuestionResponses < ActiveRecord::Migration[8.0]
  def change
    create_table :assessment_question_responses do |t|
      t.references :assessment_question, null: false, foreign_key: true
      t.references :assessment, null: false, foreign_key: true
      t.jsonb :value, default: {}
      t.jsonb :metadata, default: {}

      t.timestamps
    end
  end
end

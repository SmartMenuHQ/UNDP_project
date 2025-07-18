class CreateAssessmentQuestionOptions < ActiveRecord::Migration[8.0]
  def change
    create_table :assessment_question_options do |t|
      t.references :assessment, null: false, foreign_key: true
      t.references :assessment_question, null: false, foreign_key: true
      t.text :text
      t.integer :order
      t.jsonb :metadata

      t.timestamps
    end
  end
end

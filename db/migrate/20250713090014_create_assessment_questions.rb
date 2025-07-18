class CreateAssessmentQuestions < ActiveRecord::Migration[8.0]
  def change
    create_table :assessment_questions do |t|
      t.string :type
      t.boolean :is_required, default: false
      t.integer :order
      t.string :default_locale
      t.text :text
      t.jsonb :meta_data
      t.references :assessment_sections
      t.references :assessments

      t.timestamps
    end
  end
end

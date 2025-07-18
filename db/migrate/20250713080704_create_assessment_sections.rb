class CreateAssessmentSections < ActiveRecord::Migration[8.0]
  def change
    create_table :assessment_sections do |t|
      t.string :name
      t.integer :order
      t.jsonb :metadata
      t.references :assessment, null: false, foreign_key: true

      t.timestamps
    end
  end
end

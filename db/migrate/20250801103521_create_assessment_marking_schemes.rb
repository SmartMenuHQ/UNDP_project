class CreateAssessmentMarkingSchemes < ActiveRecord::Migration[8.0]
  def change
    create_table :assessment_marking_schemes do |t|
      t.string :name, null: false
      t.text :description
      t.decimal :total_possible_score, precision: 10, scale: 2, default: 0
      t.boolean :is_active, default: true
      t.jsonb :settings, default: {}
      t.references :assessment, null: false, foreign_key: true
      t.timestamps
    end

    add_index :assessment_marking_schemes, :name
    add_index :assessment_marking_schemes, :is_active
  end
end

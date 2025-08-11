class CreateAssessmentQuestionMarkingRules < ActiveRecord::Migration[8.0]
  def change
    create_table :assessment_question_marking_rules do |t|
      t.string :rule_type, null: false
      t.decimal :points, precision: 10, scale: 2, default: 0
      t.jsonb :criteria, default: {}
      t.boolean :is_active, default: true
      t.integer :order, default: 0
      t.references :assessment_question, null: false, foreign_key: true
      t.references :assessment_marking_scheme, null: false, foreign_key: true
      t.timestamps
    end

    add_index :assessment_question_marking_rules, :rule_type
    add_index :assessment_question_marking_rules, :is_active
    add_index :assessment_question_marking_rules, :order
  end
end

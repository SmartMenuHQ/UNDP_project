class AddConditionalVisibilityToQuestionsAndSections < ActiveRecord::Migration[7.1]
  def change
    # Add conditional visibility to assessment_questions
    add_column :assessment_questions, :visibility_conditions, :jsonb, default: {}
    add_column :assessment_questions, :is_conditional, :boolean, default: false
    add_index :assessment_questions, :is_conditional
    add_index :assessment_questions, :visibility_conditions, using: :gin

    # Add conditional visibility to assessment_sections
    add_column :assessment_sections, :visibility_conditions, :jsonb, default: {}
    add_column :assessment_sections, :is_conditional, :boolean, default: false
    add_index :assessment_sections, :is_conditional
    add_index :assessment_sections, :visibility_conditions, using: :gin
  end
end

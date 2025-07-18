class RenameAssessmentForeignKeys < ActiveRecord::Migration[8.0]
  def change
    # Rename foreign key columns to follow Rails conventions
    rename_column :assessment_questions, :assessments_id, :assessment_id
    rename_column :assessment_questions, :assessment_sections_id, :assessment_section_id
  end
end

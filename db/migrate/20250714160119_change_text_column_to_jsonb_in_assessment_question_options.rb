class ChangeTextColumnToJsonbInAssessmentQuestionOptions < ActiveRecord::Migration[8.0]
  def up
    # Change column type with USING clause to convert text to jsonb
    execute <<-SQL
      ALTER TABLE assessment_question_options
      ALTER COLUMN text TYPE jsonb
      USING CASE
        WHEN text IS NULL THEN '{}'::jsonb
        ELSE ('{"en": "' || REPLACE(text, '"', '\"') || '"}')::jsonb
      END;
    SQL

    # Set default value for new records
    change_column_default :assessment_question_options, :text, {}
  end

  def down
    # Convert jsonb back to text (extracting 'en' locale)
    execute <<-SQL
      UPDATE assessment_question_options
      SET text = CASE
        WHEN text IS NULL THEN NULL
        ELSE (text->>'en')::text
      END;
    SQL

    # Change column type back
    change_column :assessment_question_options, :text, :text
    change_column_default :assessment_question_options, :text, nil
  end
end

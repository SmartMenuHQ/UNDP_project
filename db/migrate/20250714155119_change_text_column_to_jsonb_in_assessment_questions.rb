class ChangeTextColumnToJsonbInAssessmentQuestions < ActiveRecord::Migration[8.0]
    def up
    # Change column type with USING clause to convert text to jsonb
    execute <<-SQL
      ALTER TABLE assessment_questions
      ALTER COLUMN text TYPE jsonb
      USING CASE
        WHEN text IS NULL THEN NULL
        ELSE ('{"en": "' || REPLACE(text, '"', '\"') || '"}')::jsonb
      END;
    SQL
  end

  def down
    # Convert jsonb back to text (extracting 'en' locale)
    execute <<-SQL
      UPDATE assessment_questions
      SET text = (text->>'en')::text
      WHERE text IS NOT NULL;
    SQL

    # Change column type back
    change_column :assessment_questions, :text, :text
  end
end

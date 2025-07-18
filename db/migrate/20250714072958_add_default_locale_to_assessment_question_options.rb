class AddDefaultLocaleToAssessmentQuestionOptions < ActiveRecord::Migration[8.0]
  def change
    add_column :assessment_question_options, :default_locale, :string
  end
end

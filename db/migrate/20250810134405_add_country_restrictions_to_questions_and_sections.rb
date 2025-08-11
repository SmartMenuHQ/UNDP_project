class AddCountryRestrictionsToQuestionsAndSections < ActiveRecord::Migration[7.1]
  def change
    # Add country restrictions to assessment_questions
    add_column :assessment_questions, :restricted_countries, :jsonb, default: []
    add_column :assessment_questions, :has_country_restrictions, :boolean, default: false, null: false

    # Add country restrictions to assessment_sections
    add_column :assessment_sections, :restricted_countries, :jsonb, default: []
    add_column :assessment_sections, :has_country_restrictions, :boolean, default: false, null: false

    # Add indexes for performance
    add_index :assessment_questions, :has_country_restrictions
    add_index :assessment_questions, :restricted_countries, using: :gin
    add_index :assessment_sections, :has_country_restrictions
    add_index :assessment_sections, :restricted_countries, using: :gin
  end
end

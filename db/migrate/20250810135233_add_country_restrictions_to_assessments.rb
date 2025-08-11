class AddCountryRestrictionsToAssessments < ActiveRecord::Migration[7.1]
  def change
    # Add country restrictions to assessments
    add_column :assessments, :restricted_countries, :jsonb, default: []
    add_column :assessments, :has_country_restrictions, :boolean, default: false, null: false

    # Add indexes for performance
    add_index :assessments, :has_country_restrictions
    add_index :assessments, :restricted_countries, using: :gin
  end
end

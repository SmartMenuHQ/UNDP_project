class CreateCountries < ActiveRecord::Migration[7.1]
  def change
    create_table :countries do |t|
      t.string :name, null: false
      t.string :code, null: false, limit: 3  # ISO 3166-1 alpha-3 codes
      t.boolean :active, default: true, null: false
      t.string :region, null: true  # Continent/region for grouping
      t.integer :sort_order, default: 0

      t.timestamps
    end

    add_index :countries, :code, unique: true
    add_index :countries, :active
    add_index :countries, :region
    add_index :countries, :sort_order
    add_index :countries, [:active, :sort_order]
  end
end

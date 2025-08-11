class AddFieldsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :admin, :boolean, default: false, null: false
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    add_reference :users, :country, null: true, foreign_key: true
    add_column :users, :default_language, :string, default: "en"
    add_column :users, :profile_completed, :boolean, default: false, null: false
    add_column :users, :invited_by_id, :bigint, null: true
    add_column :users, :invited_at, :datetime, null: true
    add_column :users, :invitation_accepted_at, :datetime, null: true

    # Add indexes for performance (country_id index already created by add_reference)
    add_index :users, :admin
    add_index :users, :default_language
    add_index :users, :profile_completed
    add_index :users, :invited_by_id

    # Add foreign key for invited_by
    add_foreign_key :users, :users, column: :invited_by_id
  end
end

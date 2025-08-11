class AddTokenToSessions < ActiveRecord::Migration[7.1]
  def change
    add_column :sessions, :token, :string, null: false
    add_index :sessions, :token, unique: true
    add_column :sessions, :expires_at, :datetime, null: false
    add_index :sessions, :expires_at
  end
end

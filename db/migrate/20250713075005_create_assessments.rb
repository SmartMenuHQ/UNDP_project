class CreateAssessments < ActiveRecord::Migration[8.0]
  def change
    create_table :assessments do |t|
      t.string :title
      t.text :description
      t.boolean :active, default: true

      t.timestamps
    end
  end
end

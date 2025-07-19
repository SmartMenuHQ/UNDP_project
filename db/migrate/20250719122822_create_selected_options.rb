class CreateSelectedOptions < ActiveRecord::Migration[8.0]
  def change
    create_table :selected_options do |t|
      t.references :assessment_question_response, null: false, foreign_key: true
      t.references :assessment_question_option, null: false, foreign_key: true

      t.timestamps
    end

    add_index :selected_options, [:assessment_question_response_id, :assessment_question_option_id],
              unique: true, name: 'index_selected_options_unique'
  end
end

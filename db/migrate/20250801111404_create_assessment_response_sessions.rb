class CreateAssessmentResponseSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :assessment_response_sessions do |t|
      t.references :assessment, null: false, foreign_key: true
      t.string :respondent_name, null: false
      t.string :respondent_email
      t.string :state, null: false, default: "draft"
      t.datetime :started_at
      t.datetime :completed_at
      t.datetime :submitted_at
      t.datetime :marked_at
      t.decimal :total_score, precision: 10, scale: 2, default: 0.0
      t.decimal :max_possible_score, precision: 10, scale: 2, default: 0.0
      t.string :grade
      t.text :feedback
      t.jsonb :metadata, default: {}
      t.timestamps
    end

    # Add indexes for performance
    add_index :assessment_response_sessions, :state
    add_index :assessment_response_sessions, :respondent_email
    add_index :assessment_response_sessions, :started_at
    add_index :assessment_response_sessions, :completed_at
    add_index :assessment_response_sessions, :submitted_at
    add_index :assessment_response_sessions, :marked_at
    add_index :assessment_response_sessions, :total_score
    add_index :assessment_response_sessions, [:assessment_id, :state]
    add_index :assessment_response_sessions, [:respondent_email, :assessment_id], unique: true, name: "index_sessions_on_respondent_assessment"
  end
end

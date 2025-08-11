class RemoveRespondentEmailFromAssessmentResponseSessions < ActiveRecord::Migration[7.1]
  def up
    # Make user_id not null after data migration
    change_column_null :assessment_response_sessions, :user_id, false

    # Remove the old email column
    remove_column :assessment_response_sessions, :respondent_email, :string
  end

  def down
    # Add back the email column
    add_column :assessment_response_sessions, :respondent_email, :string

    # Make user_id nullable again
    change_column_null :assessment_response_sessions, :user_id, true

    # Populate email from user_id
    execute <<-SQL
      UPDATE assessment_response_sessions
      SET respondent_email = users.email_address
      FROM users
      WHERE assessment_response_sessions.user_id = users.id
    SQL
  end
end

class MigrateRespondentEmailToUserId < ActiveRecord::Migration[7.1]
  def up
    # Populate user_id based on respondent_email
    execute <<-SQL
      UPDATE assessment_response_sessions
      SET user_id = users.id
      FROM users
      WHERE assessment_response_sessions.respondent_email = users.email_address
      AND assessment_response_sessions.user_id IS NULL
    SQL

    # Log any sessions that couldn't be matched
    unmatched_count = execute(<<-SQL).cmdtuples
      SELECT COUNT(*) FROM assessment_response_sessions
      WHERE user_id IS NULL AND respondent_email IS NOT NULL
    SQL

    if unmatched_count > 0
      puts "Warning: #{unmatched_count} assessment_response_sessions could not be matched to users"
    end
  end

  def down
    # Populate respondent_email from user_id (in case we need to rollback)
    execute <<-SQL
      UPDATE assessment_response_sessions
      SET respondent_email = users.email_address
      FROM users
      WHERE assessment_response_sessions.user_id = users.id
      AND assessment_response_sessions.respondent_email IS NULL
    SQL
  end
end

class MarkingNotificationJob < ApplicationJob
  queue_as :default

  # Retry configuration for email delivery issues
  retry_on Net::SMTPError, wait: :exponentially_longer, attempts: 3
  retry_on StandardError, wait: :exponentially_longer, attempts: 2

  # Discard if session not found
  discard_on ActiveRecord::RecordNotFound

  def perform(session_id)
    session = AssessmentResponseSession.find(session_id)

    # Only send notification if session is marked and has email
    unless session.marked? && session.user&.email_address.present?
      Rails.logger.warn "Notification job discarded: Session #{session_id} not marked or no email"
      return
    end

    Rails.logger.info "Sending marking notification for session #{session_id} to #{session.user.email_address}"

    # Send the notification email
    AssessmentMailer.marking_complete(session).deliver_now

    # Update session metadata to track notification
    session.update!(
      metadata: session.metadata.merge({
        "notification_sent_at" => Time.current.iso8601,
        "notification_email" => session.user.email_address,
      }),
    )

    Rails.logger.info "Marking notification sent successfully for session #{session_id}"
  rescue => e
    Rails.logger.error "Failed to send marking notification for session #{session_id}: #{e.message}"

    # Update session with error information
    begin
      session.update(
        metadata: session.metadata.merge({
          "notification_error" => e.message,
          "notification_failed_at" => Time.current.iso8601,
        }),
      )
    rescue
      # Ignore metadata update errors
    end

    raise e
  end
end

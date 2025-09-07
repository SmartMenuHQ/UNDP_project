class BulkMarkingJob < ApplicationJob
  queue_as :default

  # Retry configuration
  retry_on StandardError, wait: :exponentially_longer, attempts: 2

  def perform(session_ids, marking_scheme_id = nil)
    Rails.logger.info "Starting bulk marking job for #{session_ids.count} sessions"

    # Track progress
    processed = 0
    successful = 0
    failed = 0
    errors = []

    session_ids.each do |session_id|
      begin
        # Queue individual marking job for each session
        MarkingJob.perform_later(session_id, marking_scheme_id)
        successful += 1
      rescue => e
        failed += 1
        error_msg = "Session #{session_id}: #{e.message}"
        errors << error_msg
        Rails.logger.error "Failed to queue marking job for session #{session_id}: #{e.message}"
      end

      processed += 1

      # Log progress every 10 sessions
      if processed % 10 == 0
        Rails.logger.info "Bulk marking progress: #{processed}/#{session_ids.count} sessions processed"
      end
    end

    Rails.logger.info "Bulk marking job completed: #{successful} successful, #{failed} failed"

    # Store results in cache for status checking
    cache_key = "bulk_marking_job_#{Time.current.to_i}_#{session_ids.count}"
    Rails.cache.write(cache_key, {
      total: session_ids.count,
      successful: successful,
      failed: failed,
      errors: errors,
      completed_at: Time.current,
    }, expires_in: 1.hour)

    # Send summary notification if there were failures
    if failed > 0
      Rails.logger.error "Bulk marking had #{failed} failures: #{errors.join(", ")}"
      # Could send admin notification here
    end
  rescue => e
    Rails.logger.error "Bulk marking job failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end
end

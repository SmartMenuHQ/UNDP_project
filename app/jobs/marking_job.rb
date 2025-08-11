class MarkingJob < ApplicationJob
  queue_as :default

  # Retry configuration for failed jobs
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  # Discard job if session is not found or in invalid state
  discard_on ActiveRecord::RecordNotFound
  discard_on AASM::InvalidTransition

  def perform(session_id, marking_scheme_id = nil)
    session = AssessmentResponseSession.find(session_id)

    # Validate session can be marked
    unless session.can_be_marked?
      Rails.logger.warn "Marking job discarded: Session #{session_id} cannot be marked (state: #{session.state})"
      return
    end

    # Use provided marking scheme or active one
    marking_scheme = if marking_scheme_id
        AssessmentMarkingScheme.find(marking_scheme_id)
      else
        session.assessment.assessment_marking_schemes.find_by(is_active: true)
      end

    unless marking_scheme
      Rails.logger.error "No active marking scheme found for assessment #{session.assessment.id}"
      raise "No marking scheme available for marking"
    end

    Rails.logger.info "Starting marking job for session #{session_id} with scheme #{marking_scheme.id}"

    # Perform the marking in a transaction
    ActiveRecord::Base.transaction do
      # Calculate scores for each response
      total_earned = 0
      total_possible = 0
      responses_graded = 0

      session.assessment_question_responses.includes(:assessment_question).find_each do |response|
        begin
          # Grade the individual response
          score = response.grade_response(marking_scheme.id)

          total_earned += score.score_earned
          total_possible += score.max_possible_score
          responses_graded += 1

          Rails.logger.debug "Graded response #{response.id}: #{score.score_earned}/#{score.max_possible_score}"
        rescue => e
          Rails.logger.error "Error grading response #{response.id}: #{e.message}"
          # Continue with other responses rather than failing the entire job
        end
      end

      # Update session with calculated totals
      session.update!(
        total_score: total_earned,
        max_possible_score: total_possible,
        grade: calculate_letter_grade(total_earned, total_possible, marking_scheme),
      )

      # Generate feedback
      generate_session_feedback(session, marking_scheme)

      # Transition to marked state
      session.mark!

      Rails.logger.info "Completed marking job for session #{session_id}: #{total_earned}/#{total_possible} (#{responses_graded} responses)"

      # Send notification if configured
      send_marking_notification(session) if should_send_notification?(session)
    end
  rescue => e
    Rails.logger.error "Marking job failed for session #{session_id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    # Update session with error information
    begin
      session.update(
        metadata: session.metadata.merge({
          "marking_error" => e.message,
          "marking_failed_at" => Time.current.iso8601,
        }),
      )
    rescue
      # Ignore metadata update errors
    end

    raise e
  end

  private

  def calculate_letter_grade(earned, possible, scheme)
    return "F" if possible.zero?

    percentage = (earned / possible * 100).round(2)
    boundaries = scheme.settings&.dig("grade_boundaries") || {}

    boundaries.each do |grade, threshold|
      return grade if percentage >= threshold
    end

    "F"
  end

  def generate_session_feedback(session, marking_scheme)
    # Get feedback template based on grade
    templates = marking_scheme.settings&.dig("feedback_templates") || {}
    template = templates[session.grade]

    if template.present?
      # Replace placeholders in template
      feedback = template.gsub("%{score}", session.total_score.to_s)
        .gsub("%{max_score}", session.max_possible_score.to_s)
        .gsub("%{percentage}", session.score_percentage.to_s)
        .gsub("%{grade}", session.grade)
        .gsub("%{name}", session.respondent_name)

      session.update!(feedback: feedback)
    end
  end

  def should_send_notification?(session)
    # Check if notifications are enabled for this assessment
    session.assessment.metadata&.dig("notifications", "marking_complete") == true ||
    session.user&.email_address.present?
  end

  def send_marking_notification(session)
    return unless session.user&.email_address.present?

    # Queue notification email job
    MarkingNotificationJob.perform_later(session.id)
  rescue => e
    Rails.logger.error "Failed to queue marking notification for session #{session.id}: #{e.message}"
  end
end

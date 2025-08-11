class AssessmentMailer < ApplicationMailer
  default from: "noreply@questionnaire-cms.com"

  def marking_complete(session)
    @session = session
    @assessment = session.assessment
    @respondent_name = session.respondent_name
    @score = session.total_score
    @max_score = session.max_possible_score
    @percentage = session.score_percentage
    @grade = session.grade
    @passed = session.passed?
    @feedback = session.feedback

    mail(
      to: session.user.email_address,
      subject: "Your #{@assessment.title} results are ready",
    )
  end

  def submission_received(session)
    @session = session
    @assessment = session.assessment
    @respondent_name = session.respondent_name
    @submitted_at = session.submitted_at

    mail(
      to: session.user.email_address,
      subject: "We received your #{@assessment.title} submission",
    )
  end

  def assessment_invitation(assessment, email, name = nil)
    @assessment = assessment
    @respondent_name = name || "there"
    @assessment_url = assessment_url(assessment)

    mail(
      to: email,
      subject: "You're invited to take: #{@assessment.title}",
    )
  end

  def bulk_marking_complete(assessment, admin_email, stats)
    @assessment = assessment
    @stats = stats
    @completed_at = Time.current

    mail(
      to: admin_email,
      subject: "Bulk marking completed for #{@assessment.title}",
    )
  end
end

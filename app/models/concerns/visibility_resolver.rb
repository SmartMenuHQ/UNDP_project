module VisibilityResolver
  extend ActiveSupport::Concern

  # Get all visible sections for a session (using session's user)
  def visible_sections_for_session(session)
    return assessment_sections.none unless session&.user

    visible_sections_for_user(session.user, session)
  end

  # Get all visible questions for a session (using session's user)
  def visible_questions_for_session(session)
    return assessment_questions.none unless session&.user

    visible_questions_for_user(session.user, session)
  end

  # Get all visible sections for a user in this assessment
  def visible_sections_for_user(user, session = nil)
    return assessment_sections.none unless user

    # Start with sections accessible from user's country
    country_accessible_sections = assessment_sections.accessible_to_country(user.country&.code)

    # If we have a session, filter by conditional visibility
    if session
      conditionally_visible_ids = country_accessible_sections.conditionally_visible_ids_for_session(session)
      country_accessible_sections.where(
        "(is_conditional = false) OR (id IN (?))",
        conditionally_visible_ids.presence || [0]
      )
    else
      # Without session, only show unconditional sections
      country_accessible_sections.where(is_conditional: false)
    end.ordered
  end

  # Get all visible questions for a user in this assessment
  def visible_questions_for_user(user, session = nil)
    return assessment_questions.none unless user

    # Start with questions accessible from user's country
    country_accessible_questions = assessment_questions.accessible_to_country(user.country&.code)

    # Filter by sections that are visible
    visible_section_ids = visible_sections_for_user(user, session).pluck(:id)
    questions_in_visible_sections = country_accessible_questions.where(assessment_section_id: visible_section_ids)

    # If we have a session, filter by conditional visibility
    if session
      conditionally_visible_ids = questions_in_visible_sections.conditionally_visible_ids_for_session(session)
      questions_in_visible_sections.where(
        "(is_conditional = false) OR (id IN (?))",
        conditionally_visible_ids.presence || [0]
      )
    else
      # Without session, only show unconditional questions
      questions_in_visible_sections.where(is_conditional: false)
    end.ordered
  end

  # Get visible questions within a specific section for a user
  def visible_questions_in_section_for_user(section, user, session = nil)
    return AssessmentQuestion.none unless user
    return AssessmentQuestion.none unless section_visible_to_user?(section, user, session)

    # Start with questions in this section accessible from user's country
    country_accessible_questions = section.assessment_questions.accessible_to_country(user.country&.code)

    # If we have a session, filter by conditional visibility
    if session
      conditionally_visible_ids = country_accessible_questions.conditionally_visible_ids_for_session(session)
      country_accessible_questions.where(
        "(is_conditional = false) OR (id IN (?))",
        conditionally_visible_ids.presence || [0]
      )
    else
      # Without session, only show unconditional questions
      country_accessible_questions.where(is_conditional: false)
    end.ordered
  end

  # Check if a specific section is visible to a user
  def section_visible_to_user?(section, user, session = nil)
    return false unless user
    return false unless section.accessible_to_user?(user)

    # If session provided, check conditional visibility
    if session
      section.visible_for_session?(session)
    else
      # Without session, only unconditional sections are visible
      !section.is_conditional?
    end
  end

  # Check if a specific question is visible to a user
  def question_visible_to_user?(question, user, session = nil)
    return false unless user
    return false unless question.accessible_to_user?(user)

    # Question must be in a visible section
    return false unless section_visible_to_user?(question.assessment_section, user, session)

    # If session provided, check conditional visibility
    if session
      question.visible_for_session?(session)
    else
      # Without session, only unconditional questions are visible
      !question.is_conditional?
    end
  end

  # Get the next visible section after the current one
  def next_visible_section_for_user(current_section, user, session = nil)
    visible_sections = visible_sections_for_user(user, session)
    current_index = visible_sections.index(current_section)

    return nil unless current_index
    return visible_sections[current_index + 1] if current_index < visible_sections.length - 1

    nil
  end

  # Get the previous visible section before the current one
  def previous_visible_section_for_user(current_section, user, session = nil)
    visible_sections = visible_sections_for_user(user, session)
    current_index = visible_sections.index(current_section)

    return nil unless current_index && current_index > 0
    visible_sections[current_index - 1]
  end

  # Get the next visible question after the current one (across all sections)
  def next_visible_question_for_user(current_question, user, session = nil)
    visible_questions = visible_questions_for_user(user, session)
    current_index = visible_questions.index(current_question)

    return nil unless current_index
    return visible_questions[current_index + 1] if current_index < visible_questions.length - 1

    nil
  end

  # Get the previous visible question before the current one (across all sections)
  def previous_visible_question_for_user(current_question, user, session = nil)
    visible_questions = visible_questions_for_user(user, session)
    current_index = visible_questions.index(current_question)

    return nil unless current_index && current_index > 0
    visible_questions[current_index - 1]
  end

  # Get the next visible question within the same section
  def next_visible_question_in_section_for_user(current_question, user, session = nil)
    section = current_question.assessment_section
    visible_questions = visible_questions_in_section_for_user(section, user, session)
    current_index = visible_questions.index(current_question)

    return nil unless current_index
    return visible_questions[current_index + 1] if current_index < visible_questions.length - 1

    nil
  end

  # Get the previous visible question within the same section
  def previous_visible_question_in_section_for_user(current_question, user, session = nil)
    section = current_question.assessment_section
    visible_questions = visible_questions_in_section_for_user(section, user, session)
    current_index = visible_questions.index(current_question)

    return nil unless current_index && current_index > 0
    visible_questions[current_index - 1]
  end

  # Check if user has completed all required visible questions
  def all_required_visible_questions_completed_for_user?(user, session = nil)
    return false unless user && session

    required_visible_questions = visible_questions_for_user(user, session).where(is_required: true)

    required_visible_questions.all? do |question|
      response = session.assessment_question_responses.find_by(assessment_question: question)
      response&.has_valid_response?
    end
  end

  # Check if user has completed all required visible questions in a specific section
  def all_required_visible_questions_in_section_completed_for_user?(section, user, session = nil)
    return false unless user && session

    required_visible_questions = visible_questions_in_section_for_user(section, user, session).where(is_required: true)

    required_visible_questions.all? do |question|
      response = session.assessment_question_responses.find_by(assessment_question: question)
      response&.has_valid_response?
    end
  end

  # Get completion statistics for visible content
  def visible_completion_stats_for_user(user, session = nil)
    return { sections: {}, questions: {}, overall: {} } unless user

    visible_sections = visible_sections_for_user(user, session)
    visible_questions = visible_questions_for_user(user, session)

    # Section completion stats
    completed_sections = visible_sections.count do |section|
      all_required_visible_questions_in_section_completed_for_user?(section, user, session)
    end

    # Question completion stats
    answered_questions = 0
    required_answered_questions = 0
    total_required_questions = 0

    if session
      visible_questions.each do |question|
        response = session.assessment_question_responses.find_by(assessment_question: question)
        has_response = response&.has_valid_response?

        answered_questions += 1 if has_response

        if question.is_required?
          total_required_questions += 1
          required_answered_questions += 1 if has_response
        end
      end
    end

    {
      sections: {
        total: visible_sections.count,
        completed: completed_sections,
        percentage: visible_sections.count > 0 ? (completed_sections.to_f / visible_sections.count * 100).round(1) : 0,
      },
      questions: {
        total: visible_questions.count,
        answered: answered_questions,
        percentage: visible_questions.count > 0 ? (answered_questions.to_f / visible_questions.count * 100).round(1) : 0,
      },
      required_questions: {
        total: total_required_questions,
        answered: required_answered_questions,
        percentage: total_required_questions > 0 ? (required_answered_questions.to_f / total_required_questions * 100).round(1) : 0,
        all_completed: total_required_questions > 0 && required_answered_questions == total_required_questions,
      },
      overall: {
        can_complete: all_required_visible_questions_completed_for_user?(user, session),
        is_fully_answered: visible_questions.count > 0 && answered_questions == visible_questions.count,
      },
    }
  end

  # Get the first unanswered required question for navigation
  def first_unanswered_required_question_for_user(user, session = nil)
    return nil unless user && session

    visible_questions_for_user(user, session).where(is_required: true).find do |question|
      response = session.assessment_question_responses.find_by(assessment_question: question)
      !response&.has_valid_response?
    end
  end

  # Get all unanswered required questions
  def unanswered_required_questions_for_user(user, session = nil)
    return AssessmentQuestion.none unless user && session

    required_questions = visible_questions_for_user(user, session).where(is_required: true)

    unanswered_ids = required_questions.select do |question|
      response = session.assessment_question_responses.find_by(assessment_question: question)
      !response&.has_valid_response?
    end.map(&:id)

    AssessmentQuestion.where(id: unanswered_ids).ordered
  end

  # Get completion statistics for a session (using session's user)
  def completion_stats_for_session(session)
    return { sections: {}, questions: {}, overall: {} } unless session&.user

    visible_completion_stats_for_user(session.user, session)
  end

  # Check if session has completed all required visible questions
  def session_can_complete?(session)
    return false unless session&.user

    all_required_visible_questions_completed_for_user?(session.user, session)
  end

  # Get the next visible question for a session
  def next_visible_question_for_session(session, current_question = nil)
    return nil unless session&.user

    if current_question
      next_visible_question_for_user(current_question, session.user, session)
    else
      visible_questions_for_user(session.user, session).first
    end
  end

  # Get the next visible section for a session
  def next_visible_section_for_session(session, current_section = nil)
    return nil unless session&.user

    if current_section
      next_visible_section_for_user(current_section, session.user, session)
    else
      visible_sections_for_user(session.user, session).first
    end
  end

  # Get unanswered required questions for a session
  def unanswered_required_questions_for_session(session)
    return AssessmentQuestion.none unless session&.user

    unanswered_required_questions_for_user(session.user, session)
  end

  # Get first unanswered required question for a session
  def first_unanswered_required_question_for_session(session)
    return nil unless session&.user

    first_unanswered_required_question_for_user(session.user, session)
  end

  # Check if a specific question is visible to a session
  def question_visible_to_session?(question, session)
    return false unless session&.user

    question_visible_to_user?(question, session.user, session)
  end

  # Check if a specific section is visible to a session
  def section_visible_to_session?(section, session)
    return false unless session&.user

    section_visible_to_user?(section, session.user, session)
  end

  # Get visible questions within a specific section for a session
  def visible_questions_in_section_for_session(section, session)
    return AssessmentQuestion.none unless session&.user

    visible_questions_in_section_for_user(section, session.user, session)
  end

  # Get the previous visible question for a session
  def previous_visible_question_for_session(session, current_question)
    return nil unless session&.user

    previous_visible_question_for_user(current_question, session.user, session)
  end

  # Get the previous visible section for a session
  def previous_visible_section_for_session(session, current_section)
    return nil unless session&.user

    previous_visible_section_for_user(current_section, session.user, session)
  end

  # Get visibility summary for a session (using session's user)
  def visibility_summary_for_session(session)
    return {} unless session&.user

    visibility_summary_for_user(session.user, session)
  end

  # Get visibility summary for debugging/admin purposes
  def visibility_summary_for_user(user, session = nil)
    total_sections = assessment_sections.count
    total_questions = assessment_questions.count

    visible_sections = visible_sections_for_user(user, session)
    visible_questions = visible_questions_for_user(user, session)

    country_restricted_sections = assessment_sections.restricted_for_country(user.country&.code).count
    country_restricted_questions = assessment_questions.restricted_for_country(user.country&.code).count

    conditionally_hidden_sections = assessment_sections.conditional.count -
                                    (session ? assessment_sections.conditional.conditionally_visible_ids_for_session(session).count : 0)
    conditionally_hidden_questions = assessment_questions.conditional.count -
                                     (session ? assessment_questions.conditional.conditionally_visible_ids_for_session(session).count : 0)

    {
      user: {
        email: user.email_address,
        country: user.country&.display_name,
        profile_completed: user.profile_completed?,
      },
      sections: {
        total: total_sections,
        visible: visible_sections.count,
        country_restricted: country_restricted_sections,
        conditionally_hidden: conditionally_hidden_sections,
        visibility_percentage: total_sections > 0 ? (visible_sections.count.to_f / total_sections * 100).round(1) : 0,
      },
      questions: {
        total: total_questions,
        visible: visible_questions.count,
        country_restricted: country_restricted_questions,
        conditionally_hidden: conditionally_hidden_questions,
        visibility_percentage: total_questions > 0 ? (visible_questions.count.to_f / total_questions * 100).round(1) : 0,
      },
      session: session ? {
        id: session.id,
        status: session.state,
        has_responses: session.assessment_question_responses.any?,
      } : nil,
    }
  end
end

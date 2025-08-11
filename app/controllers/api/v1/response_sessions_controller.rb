class Api::V1::ResponseSessionsController < Api::V1::BaseController
  before_action :authenticate_user!
  before_action :set_session, only: [:show, :update, :submit, :start]

  # GET /api/v1/response-sessions
  def index
    @sessions = current_user.assessment_response_sessions.includes(:assessment)

    # Apply filtering
    @sessions = @sessions.where(state: params[:state]) if params[:state].present?
    @sessions = @sessions.joins(:assessment).where(assessments: { id: params[:assessment_id] }) if params[:assessment_id].present?

    # Apply date filtering
    if params[:started_after].present?
      @sessions = @sessions.where("started_at >= ?", params[:started_after])
    end

    if params[:started_before].present?
      @sessions = @sessions.where("started_at <= ?", params[:started_before])
    end

    # Apply sorting
    sort_by = params[:sort_by].presence || "created_at"
    sort_order = params[:sort_order].presence || "desc"
    @sessions = @sessions.order("#{sort_by} #{sort_order}")

    # Apply pagination
    page = params[:page].presence || 1
    per_page = [params[:per_page].to_i, 100].min
    per_page = 25 if per_page <= 0

    @sessions = @sessions.page(page).per(per_page) if defined?(Kaminari)

    @data = {
      sessions: @sessions,
      total_count: current_user.assessment_response_sessions.count,
      pagination: {
        current_page: page.to_i,
        per_page: per_page,
        total_pages: (current_user.assessment_response_sessions.count.to_f / per_page).ceil,
      },
      statistics: {
        total_sessions: current_user.assessment_response_sessions.count,
        completed_sessions: current_user.assessment_response_sessions.where(state: "completed").count,
        in_progress_sessions: current_user.assessment_response_sessions.where(state: ["draft", "started"]).count,
      },
    }

    note!("Response sessions retrieved successfully")
  end

  # GET /api/v1/response-sessions/:id
  def show
    authorize @session, :show?

    @data = {
      session: @session,
      assessment: @session.assessment,
      progress: calculate_progress(@session),
      next_question: find_next_question(@session),
      current_responses: @session.assessment_question_responses.includes(:assessment_question, :selected_options),
      visibility_summary: @session.assessment.visibility_summary_for_session(@session),
    }

    note!("Response session retrieved successfully")
  end

  # POST /api/v1/response-sessions
  def create
    @assessment = Assessment.find(session_params[:assessment_id])
    authorize @assessment, :take_assessment?

    # Check if user already has a session for this assessment
    existing_session = current_user.assessment_response_sessions.find_by(assessment: @assessment)

    if existing_session
      @data = {
        session: existing_session,
        message: "Existing session found",
        can_continue: existing_session.state.in?(["draft", "started"]),
      }
      note!("Existing response session found")
      return
    end

    @session = current_user.assessment_response_sessions.build(
      assessment: @assessment,
      respondent_name: session_params[:respondent_name] || current_user.full_name,
      state: "draft",
    )

    if @session.save
      @data = { session: @session }
      note!("Response session created successfully")
    else
      raise ApiException::ValidationError.new("Session creation failed",
                                              details: { errors: @session.errors.full_messages })
    end
  end

  # PATCH /api/v1/response-sessions/:id/start
  def start
    authorize @session, :update?

    unless @session.state.in?(["draft"])
      raise ApiException::ValidationError.new("Cannot start session in current state",
                                              details: { current_state: @session.state })
    end

    @session.start! if @session.may_start?
    @session.update!(started_at: Time.current) if @session.started_at.blank?

    @data = {
      session: @session,
      next_question: find_next_question(@session),
      progress: calculate_progress(@session),
    }
    note!("Response session started successfully")
  end

  # PATCH /api/v1/response-sessions/:id
  def update
    authorize @session, :update?

    unless @session.state.in?(["draft", "started"])
      raise ApiException::ValidationError.new("Cannot update session in current state",
                                              details: { current_state: @session.state })
    end

    # Process responses
    if params[:responses].present?
      process_responses(@session, params[:responses])
    end

    # Update session attributes
    if @session.update(session_update_params)
      @data = {
        session: @session,
        progress: calculate_progress(@session),
        next_question: find_next_question(@session),
      }
      note!("Response session updated successfully")
    else
      raise ApiException::ValidationError.new("Session update failed",
                                              details: { errors: @session.errors.full_messages })
    end
  end

  # PATCH /api/v1/response-sessions/:id/submit
  def submit
    authorize @session, :update?

    unless @session.state.in?(["started"])
      raise ApiException::ValidationError.new("Cannot submit session in current state",
                                              details: { current_state: @session.state })
    end

    # Validate all required questions are answered
    validation_result = validate_required_responses(@session)

    unless validation_result[:valid]
      raise ApiException::ValidationError.new("Cannot submit - required questions not answered",
                                              details: {
                                                missing_questions: validation_result[:missing_questions],
                                                missing_count: validation_result[:missing_count],
                                              })
    end

    @session.submit! if @session.may_submit?
    @session.update!(
      submitted_at: Time.current,
      completed_at: Time.current,
    )

    # Trigger background marking if auto-marking is enabled
    if @session.assessment.auto_mark?
      MarkingJob.perform_later(@session.id)
    end

    @data = {
      session: @session,
      progress: calculate_progress(@session),
      submitted: true,
    }
    note!("Response session submitted successfully")
  end

  private

  def set_session
    @session = current_user.assessment_response_sessions.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    raise ApiException::NotFoundError.new("Response session not found")
  end

  def session_params
    params.require(:session).permit(:assessment_id, :respondent_name)
  end

  def session_update_params
    params.require(:session).permit(:respondent_name, :feedback)
  end

  def process_responses(session, responses)
    responses.each do |response_data|
      question = session.assessment.assessment_questions.find(response_data[:question_id])

      # Find or create response
      response = session.assessment_question_responses.find_or_initialize_by(
        assessment_question: question,
      )

      # Update response value
      response.value = response_data[:value]
      response.save!

      # Handle selected options for multiple choice questions
      if response_data[:selected_option_ids].present?
        response.selected_options.destroy_all
        response_data[:selected_option_ids].each do |option_id|
          option = question.assessment_question_options.find(option_id)
          response.selected_options.create!(assessment_question_option: option)
        end
      end
    end
  end

  def calculate_progress(session)
    visible_questions = session.assessment.visible_questions_for_session(session)
    answered_questions = session.assessment_question_responses.where(
      assessment_question: visible_questions,
    ).where.not(value: [nil, ""])

    total_questions = visible_questions.count
    answered_count = answered_questions.count

    {
      total_questions: total_questions,
      answered_questions: answered_count,
      percentage: total_questions > 0 ? ((answered_count.to_f / total_questions) * 100).round(2) : 0,
      is_complete: answered_count >= total_questions,
    }
  end

  def find_next_question(session)
    visible_questions = session.assessment.visible_questions_for_session(session)
    answered_question_ids = session.assessment_question_responses.where.not(value: [nil, ""]).pluck(:assessment_question_id)

    next_question = visible_questions.where.not(id: answered_question_ids).order(:order).first

    if next_question
      {
        id: next_question.id,
        text: next_question.text,
        type: next_question.type,
        section_name: next_question.assessment_section.name,
        is_required: next_question.is_required?,
      }
    else
      nil
    end
  end

  def validate_required_responses(session)
    visible_questions = session.assessment.visible_questions_for_session(session)
    required_questions = visible_questions.where(is_required: true)

    answered_required_ids = session.assessment_question_responses
      .where(assessment_question: required_questions)
      .where.not(value: [nil, ""])
      .pluck(:assessment_question_id)

    missing_questions = required_questions.where.not(id: answered_required_ids)

    {
      valid: missing_questions.empty?,
      missing_questions: missing_questions.map { |q| { id: q.id, text: q.text } },
      missing_count: missing_questions.count,
    }
  end
end
